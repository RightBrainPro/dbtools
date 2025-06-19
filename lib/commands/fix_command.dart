import 'package:args/command_runner.dart';

import '../ansi.dart';
import '../constants.dart';
import 'arguments_mixin.dart';
import 'config_mixin.dart';
import 'executors/migration.dart';
import 'stdout_mixin.dart';


final fixCommand = FixCommand()
  ..addArgument('migration identity',
    help: 'The identity of the migration in the format as you name it in the '
      'migrations directory.'
  )
;


class FixCommand extends Command<int>
  with ConfigMixin, StdoutMixin, ArgumentsMixin
  implements FixingDelegate
{
  @override
  String get description => 'Fix the specified migration in the database.\n'
    '${dim('Updates the specified migration in the database with the local '
    'one, i.e. rewrites the name, control summ and the rollback script.\n'
    'It is useful when the migration with a bug in the rollback code has been '
    'commited, and now it can not be rolled back due to the bug. You can fix '
    'the bug locally and use this command to push the fixed rollback.sql to '
    'the database.')}'
  ;

  @override
  String get name => 'fix';

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
    if (migrationIdentity == null) {
      usageException('Migration identity is not specified.');
    }

    final executor = MigrationExecutor(
      config: config,
      env: env,
      passwordProvider: () => getPassword(env.user),
    );
    try {
      await executor.fixMigration(migrationIdentity, delegate: this);
      return resultOk;
    } on AbortedException {
      return resultError;
    } on ConnectionException catch (e) {
      errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on MigrationException catch (e) {
      errorCLn('Failed to update migration: ${e.message}.');
      return resultError;
    } catch (e) {
      errorCLn('Failed to update migration: $e.');
      return resultError;
    }
  }

  @override
  void onBadIdentity(final String identity)
  {
    errorCLn('Invalid identity format: $identity.');
    infoLn('Updating migration ✖');
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
  void onUpdatingStarted(final int id)
  {
    info('Updating migration #$id...');
  }

  @override
  void onLocalMigrationNotFound(final int id)
  {
    errorCLn('The migration #$id is not found in the local storage.');
    infoLn('Updating migration ✖');
  }

  @override
  void onDbMigrationNotFound(final int id)
  {
    errorCLn('The migration #$id is not found in the database.');
    infoLn('Updating migration ✖');
  }

  @override
  void onUpdatingFailed(final int id, final String reason)
  {
    errorCLn('Failed to update the migration #$id: $reason.');
    infoLn('Updating migration ✖');
  }

  @override
  void onUpdatingSucceeded(final int id)
  {
    infoCLn('Updating migration #$id ✔');
  }
}
