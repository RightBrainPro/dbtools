import 'package:args/command_runner.dart';

import '../ansi.dart';
import '../constants.dart';
import 'config_mixin.dart';
import 'executors/migration.dart';
import 'stdout_mixin.dart';
import 'arguments_mixin.dart';


final migrateCommand = MigrateCommand()
  ..addArgument('migration identity',
    help: 'The identity of the migration in the format as you name it in the '
      'migrations directory.\n'
      '${bold('Optional')}.\n'
      'If specified, the database will be migrated up to this version. '
      'Otherwise, the database will be migrated up to the latest version in '
      'the migrations directory.'
  )
  ..argParser.addFlag('rollback',
    abbr: 'r',
    help: 'Allow to rollback the migrations already applied to the database.\n'
      '${bold('Optional')}.\n'
      'It is ${bold('on')} by default, which means all migrations that absent '
      'or differ from local ones will be rolled back before applying new '
      'migrations. It is not recommended to allow rollback in production '
      'environment.',
    defaultsTo: true,
  )
;


class MigrateCommand extends Command<int>
  with ConfigMixin, StdoutMixin, ArgumentsMixin
  implements MigrationDelegate
{
  @override
  String get description =>
    'Migrate the database according to the current set of local migrations.';

  @override
  String get name => 'migrate';

  @override
  String get category => 'Migration';

  @override
  Future<int> run() async
  {
    final config = await loadConfig();
    final env = await loadEnv(config);
    if (env == null) {
      usageException(
        'Failed to find the env.\nPlease, specify a valid env in your config.'
      );
    }
    final migrationIdentity = argument('migration identity');
    final executor = MigrationExecutor(
      config: config,
      env: env,
      passwordProvider: () => getPassword(env.user),
      allowRollback: argResults?.flag('rollback') ?? true,
    );
    try {
      await executor.migrate(delegate: this, targetIdentity: migrationIdentity);
      return resultOk;
    } on AbortedException {
      return resultError;
    } on ConnectionException catch (e) {
      errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on MigrationException catch (e) {
      errorCLn('Failed to migrate the database: ${e.message}.');
      return resultError;
    } catch (e) {
      errorCLn('Failed to migrate the database: $e.');
      return resultError;
    }
  }

  @override
  void onPreparingStarted()
  {
    info('Preparing the database...');
  }

  @override
  void onBeforePreparingError(final String reason)
  {
    errorCLn('Error before preparing: $reason');
    infoLn('Preparing the database ✖');
  }

  @override
  void onMigrationsTableError(final String tableName, final String reason)
  {
    errorCLn('Failed to create the migrations table "$tableName": $reason');
    infoLn('Preparing the database ✖');
  }

  @override
  void onAfterPreparingError(final String reason)
  {
    errorCLn('Error after preparing: $reason');
    infoLn('Preparing the database ✖');
  }

  @override
  void onPreparingSucceeded()
  {
    infoCLn('Preparing the database ✔');
  }

  @override
  void onScanningStarted()
  {
    info('Scanning migrations...');
  }

  @override
  void onScanningError(final String reason)
  {
    errorCLn(reason);
    infoLn('Scanning migrations ✖');
  }

  @override
  void onScanningSucceeded()
  {
    infoCLn('Scanning migrations ✔');
  }

  @override
  void onBadIdentity(final String identity)
  {
    infoLn('Invalid migration identity: $identity.');
  }

  @override
  void onIdentityNotFound(final int id)
  {
    infoLn('The migration #$id is not found.');
  }

  @override
  void onComparingStarted()
  {
    info('Comparing migrations...');
  }

  @override
  void onComparingSucceeded()
  {
    infoCLn('Comparing migrations ✔');
  }

  @override
  void onRollbackStarted(final int number)
  {
    info('Checking rollbacks...');
  }

  @override
  void onRollbackForbidden(final int number)
  {
    if (number == 1) {
      errorCLn(
        'There is a migration to rollback in the database, but rollbacks '
        'are forbidden.'
      );
    } else {
      errorCLn(
        'There are $number migrations to rollback in the database, but '
        'rollbacks are forbidden.'
      );
    }
    infoLn('Checking rollbacks ✖');
  }

  @override
  void onRollbackFailed(final String reason)
  {
    errorCLn(reason);
    infoLn('Checking rollbacks ✖');
  }

  @override
  void onMigrationRollbackFailed(final int migration, final String reason)
  {
    errorCLn('Failed to rollback migration #$migration: $reason');
    infoLn('Checking rollbacks ✖');
  }

  @override
  void onRollbackSucceeded(final int number)
  {
    if (number < 1) {
      infoCLn('Nothing to rollback ✔');
    } else if (number == 1) {
      infoCLn('1 migration has been rolled back ✔');
    } else {
      infoCLn('$number migrations have been rolled back ✔');
    }
  }

  @override
  void onCommittingStarted(final int number)
  {
    info('Applying migrations...');
  }

  @override
  void onMigrationCommitFailed(final int migration, final String reason)
  {
    errorCLn('Failed to apply migration #$migration: $reason');
  }

  @override
  void onCommittingFinished(final int number, final int total)
  {
    if (total <= 0) {
      infoCLn('Nothing to commit ✔');
    } else if (number < total) {
      if (number == 1) {
        infoCLn('1 / $total migration has been committed ✖');
      } else {
        infoCLn('$number / $total migrations have been committed ✖');
      }
    } else {
      if (number == 1) {
        infoCLn('1 / $total migration has been committed ✔');
      } else {
        infoCLn('$number / $total migrations have been committed ✔');
      }
    }
  }

  @override
  void onAfterCommittingFailed(final String reason)
  {
    errorLn('Error after commits: $reason');
  }

  @override
  void onCleanupStarted()
  {
    info('Cleaning up...');
  }

  @override
  void onCleanupFailed(final String reason)
  {
    errorCLn(reason);
    infoLn('Cleaning up ✖');
  }

  @override
  void onCleanupSucceeded()
  {
    infoCLn('Cleaning up ✔');
  }
}
