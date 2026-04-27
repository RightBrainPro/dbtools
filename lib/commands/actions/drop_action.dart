import '../../constants.dart';
import '../console.dart';
import '../models/config.dart';
import 'executors/database.dart';


final class DropAction
{
  final EnvConfig env;

  final String password;

  final Console? console;

  const DropAction({
    required this.env,
    required this.password,
    this.console,
  });

  Future<int> execute() async
  {
    final executor = DatabaseExecutor(
      env: env,
      password: password,
    );
    try {
      await executor.drop();
      console?.infoLn(
        'The "${env.dbName}" database has been successfully dropped.',
      );
      return resultOk;
    } on ConnectionException catch (e) {
      console?.errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on DatabaseException catch (e) {
      console?.errorLn('Failed to drop the database: ${e.message}.');
      return resultError;
    } catch (e) {
      console?.errorLn('Failed to drop the database: $e.');
      return resultError;
    }
  }
}
