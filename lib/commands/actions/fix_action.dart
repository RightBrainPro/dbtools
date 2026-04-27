import '../../constants.dart';
import '../console.dart';
import '../models/config.dart';
import 'executors/migration.dart';


final class FixAction
{
  final EnvConfig env;

  final String password;

  final String migrationsPath;

  final String migrationIdentity;

  final FixingHandler? handler;

  final Console? console;

  const FixAction({
    required this.env,
    required this.password,
    required this.migrationsPath,
    required this.migrationIdentity,
    this.handler,
    this.console,
  });

  Future<int> execute() async
  {
    final executor = MigrationExecutor(
      env: env,
      password: password,
      migrationsPath: migrationsPath,
    );
    try {
      await executor.fixMigration(migrationIdentity, handler: handler);
      return resultOk;
    } on AbortedException {
      return resultError;
    } on ConnectionException catch (e) {
      console?.errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on MigrationException catch (e) {
      console?.errorCLn('Failed to update migration: ${e.message}.');
      return resultError;
    } catch (e) {
      console?.errorCLn('Failed to update migration: $e.');
      return resultError;
    }
  }
}
