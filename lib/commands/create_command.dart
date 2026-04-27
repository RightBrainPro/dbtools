import 'package:meta/meta.dart';

import '../ansi.dart';
import 'actions/create_action.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';


final class CreateCommand extends BaseCommand
{
  @override
  String get category => 'Database';

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new database.\n'
    '${dim('Creates the database specified in the selected ${italic('env')} '
    'of the config in the ${bold('dbName')} parameter.')} '
  ;

  CreateCommand(super.commandContextFactory);

  @override
  @protected
  Future<int> execute(final CommandContext context) async
  {
    const console = Console();
    final createAction = CreateAction(
      env: context.env,
      password: context.password,
      console: console,
    );
    return await createAction.execute();
  }
}
