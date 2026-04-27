import 'package:meta/meta.dart';

import '../ansi.dart';
import 'actions/clean_action.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';
import 'reporters/cleaning_reporter.dart';


final class CleanCommand extends BaseCommand
{
  @override
  String get category => 'Migration';

  @override
  String get name => 'clean';

  @override
  String get description =>
    'Clean the database.\n'
    '${dim('Rolls back all migrations from the database.')}'
  ;

  CleanCommand(super.commandContextFactory);

  @override
  @protected
  Future<int> execute(final CommandContext context) async
  {
    const console = Console();
    final cleanAction = CleanAction(
      env: context.env,
      password: context.password,
      migrationsPath: context.config.migrationsPath,
      handler: const CleaningReporter(console),
      console: console,
    );
    return await cleanAction.execute();
  }
}
