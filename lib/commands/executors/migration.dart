import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:postgresql2/postgresql.dart';

import '../models/config.dart';
import '../models/migration.dart';
import 'exceptions.dart';
import '../extensions.dart';
import 'migration_mixin.dart';
import 'types.dart';

export 'exceptions.dart'
  show ConnectionException, MigrationException, AbortedException;


class MigrationExecutor with MigrationMixin
{
  final Config config;
  final EnvConfig env;
  final PasswordProvider passwordProvider;
  final bool allowRollback;

  const MigrationExecutor({
    required this.config,
    required this.env,
    required this.passwordProvider,
    this.allowRollback = true,
  });

  Future<void> migrate({
    final String? targetIdentity,
    final MigrationDelegate? delegate,
  }) => _execute((connection) => _migrate(connection,
    targetIdentity: targetIdentity,
    delegate: delegate,
  ));

  Future<void> fixMigration(final String identity, {
    final FixingDelegate? delegate,
  }) => _execute((connection) => _fixMigration(connection,
    identity: identity,
    delegate: delegate,
  ));

  Future<String> getPostgresUrl() async
  {
    final password = await passwordProvider();
    return 'postgres://${env.user}:$password@${env.host}:${env.port}/'
      '${env.dbName}';
  }

  Future<T> _execute<T>(final AsyncOperation<T, Connection> operation) async
  {
    final connectionUrl = await getPostgresUrl();
    try {
      final connection = await connect(connectionUrl);
      try {
        return await operation(connection);
      } on AbortedException {
        rethrow;
      } on MigrationException {
        rethrow;
      } on PostgresqlException catch (e) {
        throw MigrationException(e.info);
      } catch (e) {
        throw MigrationException('$e');
      } finally {
        connection.close();
      }
    } on PostgresqlException catch (e) {
      throw ConnectionException(e.info);
    }
  }

  Future<void> _prepare(final Connection connection, {
    final PreparingDelegate? delegate,
  }) async
  {
    delegate?.onPreparingStarted();
    try {
      final script = await getScript(
        config.migrationsPath, 'before_prepare.sql'
      );
      if (script.isNotEmpty) {
        await connection.execute(script);
      }
    } on PostgresqlException catch (e) {
      delegate?.onBeforePreparingError(e.info);
      throw AbortedException(e.info);
    } catch (e) {
      delegate?.onBeforePreparingError('$e');
      throw AbortedException('$e');
    }
    try {
      final sql = 'create table if not exists ${env.tableName} ('
        'id integer primary key, '
        'name varchar(64), '
        'csum varchar(36) not null, '
        'rollback text not null, '
        'created_at timestamp not null'
      ');';
      await connection.execute(sql);
    } on PostgresqlException catch (e) {
      delegate?.onMigrationsTableError(env.tableName, e.info);
      throw AbortedException(e.info);
    } catch (e) {
      delegate?.onMigrationsTableError(env.tableName, '$e');
      throw AbortedException('$e');
    }
    try {
      final script = await getScript(
        config.migrationsPath, 'after_prepare.sql'
      );
      if (script.isNotEmpty) {
        await connection.execute(script);
      }
    } on PostgresqlException catch (e) {
      delegate?.onAfterPreparingError(e.info);
      throw AbortedException(e.info);
    } catch (e) {
      delegate?.onAfterPreparingError('$e');
      throw AbortedException('$e');
    }
    delegate?.onPreparingSucceeded();
  }

  Future<void> _migrate(final Connection connection, {
    final MigrationDelegate? delegate,
    final String? targetIdentity,
  }) async
  {
    await _prepare(connection, delegate: delegate);

    delegate?.onScanningStarted();
    final List<BriefMigration> localMigrations;
    final List<BriefMigration> dbMigrations;
    try {
      // Collect all local migrations, sorted by id.
      final orderedMigrations = SplayTreeMap<int /* id */, BriefMigration>();
      final dir = Directory(config.migrationsPath);
      await for (var entity in dir.list()) {
        if (entity is! Directory) continue;
        final brief = await getBriefMigration(entity.path);
        orderedMigrations[brief.id] = brief;
      }
      localMigrations = orderedMigrations.values.toList();
      // Query all db migrations, sorted by id.
      dbMigrations = [];
      final sql = 'select id, name, csum from ${env.tableName} order by id';
      final rows = connection.query(sql);
      await for (final row in rows) {
        final jsonValue = row.toMap();
        dbMigrations.add(BriefMigration(
          id: jsonValue['id'],
          name: jsonValue['name'],
          csum: jsonValue['csum'],
          path: '',
        ));
      }
    } on FormatException catch (e) {
      delegate?.onScanningError(e.message);
      throw AbortedException(e.message);
    } on FileSystemException catch (e) {
      delegate?.onScanningError('${e.message}, path ${e.path}');
      throw AbortedException('${e.message}, path ${e.path}');
    } catch (e) {
      delegate?.onScanningError('$e');
      throw AbortedException('$e');
    }
    delegate?.onScanningSucceeded();

    int? targetMigrationId;
    if (targetIdentity != null) {
      try {
        final identity = getMigrationIdentity(targetIdentity);
        targetMigrationId = identity.id;
      } on FormatException {
        delegate?.onBadIdentity(targetIdentity);
        throw AbortedException('Invalid identity format: $targetIdentity');
      } catch (e) {
        delegate?.onBadIdentity(targetIdentity);
        throw AbortedException('$e');
      }
      if (localMigrations.every((e) => e.id != targetMigrationId)) {
        delegate?.onIdentityNotFound(targetMigrationId);
        throw AbortedException('Migration #$targetMigrationId is not found.');
      }
    }

    delegate?.onComparingStarted();
    var actualMigrations = 0;
    var migrationsToRollback = 0;
    var targetMigrationFound = false;
    int? lastActualMigrationId;
    {
      final migrationsNumber = min(localMigrations.length, dbMigrations.length);
      for (; actualMigrations < migrationsNumber; ++actualMigrations) {
        final dbm = dbMigrations[actualMigrations];
        final localm = localMigrations[actualMigrations];
        final migrationsDiffer = dbm.id != localm.id || dbm.csum != localm.csum;
        if (migrationsDiffer || targetMigrationFound) break;
        lastActualMigrationId = dbm.id;
        if (lastActualMigrationId == targetMigrationId) {
          targetMigrationFound = true;
        }
      }
      migrationsToRollback = dbMigrations.length - actualMigrations;
    }
    delegate?.onComparingSucceeded();

    delegate?.onRollbackStarted(migrationsToRollback);
    if (migrationsToRollback > 0) {
      if (!allowRollback) {
        delegate?.onRollbackForbidden(migrationsToRollback);
        throw Exception('Aborted');
      }
      final List<RollbackMigration> rollbacks;
      try {
        var sql = 'select id, rollback from ${env.tableName}';
        if (lastActualMigrationId != null) {
          sql += ' where id > @lastActualMigrationId';
        }
        sql += ' order by id desc';
        final rows = await connection.query(sql, {
          'lastActualMigrationId': lastActualMigrationId,
        }).toList();
        rollbacks = rows
          .map((row) => RollbackMigration(id: row[0], rollback: row[1]))
          .toList();
      } on PostgresqlException catch (e) {
        delegate?.onRollbackFailed(e.info);
        throw AbortedException(e.info);
      } catch (e) {
        delegate?.onRollbackFailed('$e');
        throw AbortedException('$e');
      }
      for (final migration in rollbacks) {
        try {
          await connection.runInTransaction(() async {
            await connection.execute(migration.rollback);
            final sql = 'delete from ${env.tableName} where id = @id';
            await connection.execute(sql, { 'id': migration.id });
          });
        } on PostgresqlException catch (e) {
          delegate?.onMigrationRollbackFailed(migration.id, e.info);
          throw AbortedException(e.info);
        } catch (e) {
          delegate?.onMigrationRollbackFailed(migration.id, '$e');
          throw AbortedException('$e');
        }
      }
    }
    delegate?.onRollbackSucceeded(migrationsToRollback);

    Object? error;

    final List<BriefMigration> migrationsToApply;
    if (targetMigrationFound) {
      migrationsToApply = const [];
    } else if (targetMigrationId != null) {
      migrationsToApply = localMigrations
        .skip(actualMigrations)
        .takeWhile((e) {
          if (targetMigrationFound) return false;
          if (e.id == targetMigrationId) targetMigrationFound = true;
          return true;
        })
        .toList();
      assert(targetMigrationFound);
    } else {
      migrationsToApply = localMigrations.skip(actualMigrations).toList();
    }
    delegate?.onCommittingStarted(migrationsToApply.length);
    if (migrationsToApply.isEmpty) {
      delegate?.onCommittingFinished(0, 0);
      if (migrationsToRollback == dbMigrations.length) {
        final script = await getScript(
          config.migrationsPath, 'cleanup.sql'
        );
        if (script.isNotEmpty) {
          delegate?.onCleanupStarted();
          try {
            await connection.execute(script);
            delegate?.onCleanupSucceeded();
          } on PostgresqlException catch (e) {
            error = e;
            delegate?.onCleanupFailed(e.info);
          } catch (e) {
            error = e;
            delegate?.onCleanupFailed('$e');
          }
        }
      }
    } else {
      var migrationsApplied = 0;
      for (final migrationBrief in migrationsToApply) {
        final localMigration = await getLocalMigration(migrationBrief);
        try {
          await connection.runInTransaction(() async {
            await connection.execute(localMigration.commit);
            final sql = 'insert into ${env.tableName} '
              '(id, name, csum, rollback, created_at) values '
              '(@id, @name, @csum, @rollback, @created_at)';
            await connection.execute(sql, localMigration.toJson());
          });
          ++migrationsApplied;
        } on PostgresqlException catch (e) {
          error = e;
          delegate?.onMigrationCommitFailed(localMigration.id, e.info);
          break;
        } catch (e) {
          error = e;
          delegate?.onMigrationCommitFailed(localMigration.id, '$e');
          break;
        }
      }
      delegate?.onCommittingFinished(migrationsApplied, migrationsToApply.length);
      if (migrationsApplied > 0) {
        try {
          final script = await getScript(
            config.migrationsPath, 'after_commits.sql'
          );
          if (script.isNotEmpty) {
            await connection.execute(script);
          }
        } on PostgresqlException catch (e) {
          error = e;
          delegate?.onAfterCommittingFailed(e.info);
        } catch (e) {
          error = e;
          delegate?.onAfterCommittingFailed('$e');
        }
      }
    }

    if (error != null) throw AbortedException('$error');
  }

  Future<void> _fixMigration(final Connection connection, {
    required final String identity,
    final FixingDelegate? delegate,
  }) async
  {
    final MigrationIdentity migrationIdentity;
    try {
      migrationIdentity = getMigrationIdentity(identity);
    } on FormatException {
      delegate?.onBadIdentity(identity);
      throw AbortedException('Invalid identity format: $identity');
    } catch (e) {
      delegate?.onBadIdentity(identity);
      throw AbortedException('$e');
    }

    await _prepare(connection, delegate: delegate);

    delegate?.onUpdatingStarted(migrationIdentity.id);
    Migration? migration;
    final dir = Directory(config.migrationsPath);
    await for (var entity in dir.list()) {
      if (entity is! Directory) continue;
      final brief = await getBriefMigration(entity.path);
      if (brief.id == migrationIdentity.id) {
        migration = await getLocalMigration(brief);
        break;
      }
    }
    if (migration == null) {
      delegate?.onLocalMigrationNotFound(migrationIdentity.id);
      throw const AbortedException('The local migration is not found.');
    }
    try {
      final sql = 'update ${env.tableName} set '
          'name = @name, csum = @csum, rollback = @rollback, '
          'created_at = @created_at '
        'where id = @id';
      final updated = await connection.execute(sql, migration.toJson());
      if (updated < 1) {
        delegate?.onDbMigrationNotFound(migrationIdentity.id);
        throw const AbortedException('Migration is not found in the database');
      } else if (updated > 1) {
        throw const MigrationException('More than one migration were updated');
      } else {
        delegate?.onUpdatingSucceeded(migrationIdentity.id);
      }
    } on PostgresqlException catch (e) {
      delegate?.onUpdatingFailed(migrationIdentity.id, e.info);
      throw AbortedException(e.info);
    } catch (e) {
      delegate?.onUpdatingFailed(migrationIdentity.id, '$e');
      throw AbortedException('$e');
    }
  }
}


abstract interface class PreparingDelegate
{
  /// Occurs when the preparing process starts.
  void onPreparingStarted();

  /// Occurs when `before_prepare.sql` script fails.
  void onBeforePreparingError(final String reason);

  /// Occurs when the migrations table creation fails.
  void onMigrationsTableError(final String tableName, final String reason);

  /// Occurs when `after_prepare.sql` script fails.
  void onAfterPreparingError(final String reason);

  /// Occurs when the preparing process succeeds.
  void onPreparingSucceeded();
}


abstract interface class MigrationDelegate implements PreparingDelegate
{
  /// Occurs when the migration scanning process starts.
  void onScanningStarted();

  /// Occurs when the migration scanning process fails.
  void onScanningError(final String reason);

  /// Occurs when the migration scanning process succeeds.
  void onScanningSucceeded();

  /// Occurs when the target migration [identity] has bad format.
  void onBadIdentity(final String identity);

  /// Occurs when local migrations don't contain the target migration with the
  /// specified [id].
  void onIdentityNotFound(final int id);

  /// Occurs when the migrations comparing process starts.
  void onComparingStarted();

  /// Occurs when the migrations comparing process succeeds.
  void onComparingSucceeded();

  /// Occurs when the rollback process starts with the specified [number] of
  /// migrations to be rolled back.
  void onRollbackStarted(final int number);

  /// Occurs when the rollback process with the specified [number] of migrations
  /// is aborted for safety reason.
  void onRollbackForbidden(final int number);

  /// Occurs when the rollback process fails due to the specified [reason].
  void onRollbackFailed(final String reason);

  /// Occurs when the specified [migration] fails to rollback due to the
  /// specified [reason].
  void onMigrationRollbackFailed(final int migration, final String reason);

  /// Occurs when the rollback process succeeds with the specified [number] of
  /// rolled back migrations.
  void onRollbackSucceeded(final int number);

  /// Occurs when the migration committing process starts to handle the
  /// specified [number] of migrations.
  void onCommittingStarted(final int number);

  /// Occurs when the specified [migration] can't be commited due to the
  /// specified [reason].
  void onMigrationCommitFailed(final int migration, final String reason);

  /// Occurs when the migration process completes with the specified [number] of
  /// successful migrations out of the [total] number of migrations to be
  /// committed.
  void onCommittingFinished(final int number, final int total);

  /// Occurs when `after_commits.sql` script fails due to the specified
  /// [reason].
  void onAfterCommittingFailed(final String reason);

  /// Occurs when all migrations are rolled back in the database and there is no
  /// any migration to be committed.
  void onCleanupStarted();

  /// Occurs when the cleanup process fails due to the specified [reason].
  void onCleanupFailed(final String reason);

  /// Occurs when the cleanup process succeeds.
  void onCleanupSucceeded();
}


abstract interface class FixingDelegate implements PreparingDelegate
{
  /// Occurs when the migration [identity] has bad format.
  void onBadIdentity(final String identity);

  /// Occurs after successfull connection to the database and extract the
  /// migration [id] from the identity.
  void onUpdatingStarted(final int id);

  /// Occurs when there is no local migration with the specified [id].
  void onLocalMigrationNotFound(final int id);

  /// Occurs when the migration with the specified [id] doesn't exist in the
  /// database.
  void onDbMigrationNotFound(final int id);

  /// Occurs when updating of the migration fails due to the specified
  /// [reason].
  void onUpdatingFailed(final int id, final String reason);

  /// Occurs when the migration is successfully updated in the database.
  void onUpdatingSucceeded(final int id);
}
