import 'package:args/command_runner.dart';

import '../ansi.dart';
import '../constants.dart';
import 'config_mixin.dart';
import 'executors/database.dart';
import 'stdout_mixin.dart';


final dropCommand = DropCommand();


class DropCommand extends Command<int> with ConfigMixin, StdoutMixin
{
  @override
  String get description => 'Drop the database.\n\n'
    'Drops the database specified in the selected ${italic('env')} of the '
    'config in the ${bold('dbName')} parameter.'
  ;

  @override
  String get name => 'drop';

  @override
  String get category => 'Database';

  @override
  Future<int> run() async
  {
    final env = await loadEnv();
    if (env == null) {
      errorLn(
        'Failed to find the env.\nPlease, specify a valid env in your config.'
      );
      return resultError;
    }
    final executor = DatabaseExecutor(
      env: env,
      passwordProvider: () => getPassword(env.user),
    );
    try {
      await executor.drop();
      infoLn('The "${env.dbName}" database has been successfully dropped.');
      return resultOk;
    } on ConnectionException catch (e) {
      errorLn('Failed to connect: ${e.message}.');
      return resultError;
    } on DatabaseException catch (e) {
      errorLn('Failed to drop the database: ${e.message}.');
      return resultError;
    } catch (e) {
      errorLn('Failed to drop the database: $e.');
      return resultError;
    }
  }
}
