import 'package:args/command_runner.dart';

import '../ansi.dart';
import '../constants.dart';
import 'config_mixin.dart';
import 'executors/migration.dart';
import 'stdout_mixin.dart';


final cleanCommand = CleanCommand();


class CleanCommand extends Command<int>
  with ConfigMixin, StdoutMixin
  implements CleaningDelegate
{
  @override
  String get description =>
    'Clean the database.\n'
    '${dim('Rolls back all migrations from the database.')}'
  ;

  @override
  String get name => 'clean';

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
    final executor = MigrationExecutor(
      config: config,
      env: env,
      passwordProvider: () => getPassword(env.user),
    );
    try {
      await executor.clean(delegate: this);
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
