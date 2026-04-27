import '../../constants.dart';
import '../console.dart';
import '../models/config.dart';
import 'executors/database.dart';


final class CreateAction
{
  final EnvConfig env;

  final String password;

  final Console? console;

  const CreateAction({
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
      await executor.create();
      console?.infoLn(
        'The "${env.dbName}" database has been successfully created.',
      );
      return resultOk;
    } on ConnectionException catch (e) {
      console?.errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on DatabaseException catch (e) {
      console?.errorLn('Failed to create the database: ${e.message}.');
      return resultError;
    } catch (e) {
      console?.errorLn('Failed to create the database: $e.');
      return resultError;
    }
  }
}
