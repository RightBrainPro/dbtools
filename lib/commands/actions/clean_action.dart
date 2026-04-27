import '../../constants.dart';
import '../console.dart';
import '../models/config.dart';
import 'executors/migration.dart';


final class CleanAction
{
  final EnvConfig env;

  final String password;

  final String migrationsPath;

  final CleaningHandler? handler;

  final Console? console;

  const CleanAction({
    required this.env,
    required this.password,
    required this.migrationsPath,
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
      await executor.clean(handler: handler);
      return resultOk;
    } on AbortedException {
      return resultError;
    } on ConnectionException catch (e) {
      console?.errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on MigrationException catch (e) {
      console?.errorCLn('Failed to migrate the database: ${e.message}.');
      return resultError;
    } catch (e) {
      console?.errorCLn('Failed to migrate the database: $e.');
      return resultError;
    }
  }
}
