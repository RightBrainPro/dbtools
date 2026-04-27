import '../actions/executors/migration.dart';
import '../console.dart';


final class MigrationReporter
  implements MigrationHandler
{
  final Console console;

  const MigrationReporter(this.console);

  @override
  void onPreparingStarted()
  {
    console.info('Preparing the database...');
  }

  @override
  void onBeforePreparingError(final String reason)
  {
    console.errorCLn('Error before preparing: $reason');
    console.infoLn('Preparing the database ✖');
  }

  @override
  void onMigrationsTableError(final String tableName, final String reason)
  {
    console.errorCLn('Failed to create the migrations table "$tableName": $reason');
    console.infoLn('Preparing the database ✖');
  }

  @override
  void onAfterPreparingError(final String reason)
  {
    console.errorCLn('Error after preparing: $reason');
    console.infoLn('Preparing the database ✖');
  }

  @override
  void onPreparingSucceeded()
  {
    console.infoCLn('Preparing the database ✔');
  }

  @override
  void onScanningStarted()
  {
    console.info('Scanning migrations...');
  }

  @override
  void onScanningError(final String reason)
  {
    console.errorCLn(reason);
    console.infoLn('Scanning migrations ✖');
  }

  @override
  void onScanningSucceeded()
  {
    console.infoCLn('Scanning migrations ✔');
  }

  @override
  void onBadIdentity(final String identity)
  {
    console.infoLn('Invalid migration identity: $identity.');
  }

  @override
  void onIdentityNotFound(final int id)
  {
    console.infoLn('The migration #$id is not found.');
  }

  @override
  void onComparingStarted()
  {
    console.info('Comparing migrations...');
  }

  @override
  void onComparingSucceeded()
  {
    console.infoCLn('Comparing migrations ✔');
  }

  @override
  void onRollbackStarted(final int number)
  {
    console.info('Checking rollbacks...');
  }

  @override
  void onRollbackForbidden(final int number)
  {
    if (number == 1) {
      console.errorCLn(
        'There is a migration to rollback in the database, but rollbacks '
        'are forbidden.'
      );
    } else {
      console.errorCLn(
        'There are $number migrations to rollback in the database, but '
        'rollbacks are forbidden.'
      );
    }
    console.infoLn('Checking rollbacks ✖');
  }

  @override
  void onRollbackFailed(final String reason)
  {
    console.errorCLn(reason);
    console.infoLn('Checking rollbacks ✖');
  }

  @override
  void onMigrationRollbackFailed(final int migration, final String reason)
  {
    console.errorCLn('Failed to rollback migration #$migration: $reason');
    console.infoLn('Checking rollbacks ✖');
  }

  @override
  void onRollbackSucceeded(final int number)
  {
    if (number < 1) {
      console.infoCLn('Nothing to rollback ✔');
    } else if (number == 1) {
      console.infoCLn('1 migration has been rolled back ✔');
    } else {
      console.infoCLn('$number migrations have been rolled back ✔');
    }
  }

  @override
  void onCommittingStarted(final int number)
  {
    console.info('Applying migrations...');
  }

  @override
  void onMigrationCommitFailed(final int migration, final String reason)
  {
    console.errorCLn('Failed to apply migration #$migration: $reason');
  }

  @override
  void onCommittingFinished(final int number, final int total)
  {
    if (total <= 0) {
      console.infoCLn('Nothing to commit ✔');
    } else if (number < total) {
      if (number == 1) {
        console.infoCLn('1 / $total migration has been committed ✖');
      } else {
        console.infoCLn('$number / $total migrations have been committed ✖');
      }
    } else {
      if (number == 1) {
        console.infoCLn('1 / $total migration has been committed ✔');
      } else {
        console.infoCLn('$number / $total migrations have been committed ✔');
      }
    }
  }

  @override
  void onAfterCommittingFailed(final String reason)
  {
    console.errorLn('Error after commits: $reason');
  }

  @override
  void onCleanupStarted()
  {
    console.info('Cleaning up...');
  }

  @override
  void onCleanupFailed(final String reason)
  {
    console.errorCLn(reason);
    console.infoLn('Cleaning up ✖');
  }

  @override
  void onCleanupSucceeded()
  {
    console.infoCLn('Cleaning up ✔');
  }
}
