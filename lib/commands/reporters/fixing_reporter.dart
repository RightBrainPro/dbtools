import '../actions/executors/migration.dart';
import '../console.dart';


final class FixingReporter implements FixingHandler
{
  final Console console;

  const FixingReporter(this.console);

  @override
  void onBadIdentity(final String identity)
  {
    console.errorCLn('Invalid identity format: $identity.');
    console.infoLn('Updating migration ✖');
  }

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
  void onUpdatingStarted(final int id)
  {
    console.info('Updating migration #$id...');
  }

  @override
  void onLocalMigrationNotFound(final int id)
  {
    console.errorCLn('The migration #$id is not found in the local storage.');
    console.infoLn('Updating migration ✖');
  }

  @override
  void onDbMigrationNotFound(final int id)
  {
    console.errorCLn('The migration #$id is not found in the database.');
    console.infoLn('Updating migration ✖');
  }

  @override
  void onUpdatingFailed(final int id, final String reason)
  {
    console.errorCLn('Failed to update the migration #$id: $reason.');
    console.infoLn('Updating migration ✖');
  }

  @override
  void onUpdatingSucceeded(final int id)
  {
    console.infoCLn('Updating migration #$id ✔');
  }
}
