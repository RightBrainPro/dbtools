import 'package:meta/meta.dart';

import '../ansi.dart';
import 'actions/drop_action.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';


final class DropCommand extends BaseCommand
{
  @override
  String get category => 'Database';

  @override
  String get name => 'drop';

  @override
  String get description => 'Drop the database.\n'
    '${dim('Drops the database specified in the selected ${italic('env')} of '
    'the config in the ${bold('dbName')} parameter.')}'
  ;

  DropCommand(super.commandContextFactory);

  @override
  @protected
  Future<int> execute(final CommandContext context) async
  {
    const console = Console();
    final dropAction = DropAction(
      env: context.env,
      password: context.password,
      console: console,
    );
    return await dropAction.execute();
  }
}
