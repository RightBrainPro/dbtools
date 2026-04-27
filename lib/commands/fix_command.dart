import 'package:meta/meta.dart';

import '../ansi.dart';
import 'actions/fix_action.dart';
import 'arguments_mixin.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';
import 'reporters/fixing_reporter.dart';


final class FixCommand extends BaseCommand with ArgumentsMixin
{
  @override
  String get category => 'Migration';

  @override
  String get name => 'fix';

  @override
  String get description => 'Fix the specified migration in the database.\n'
    '${dim('Updates the specified migration in the database with the local '
    'one, i.e. rewrites the name, control summ and the rollback script.\n'
    'It is useful when the migration with a bug in the rollback code has been '
    'commited, and now it can not be rolled back due to the bug. You can fix '
    'the bug locally and use this command to push the fixed rollback.sql to '
    'the database.')}'
  ;

  static const migrationIdentityArg = 'migration identity';

  FixCommand(super.commandContextFactory)
  {
    addArgument(migrationIdentityArg,
      help: 'The identity of the migration in the format as you name it in the '
        'migrations directory.'
    );
  }

  @override
  @protected
  Future<int> execute(final CommandContext context) async
  {
    const console = Console();
    final migrationIdentity = argument(migrationIdentityArg);
    if (migrationIdentity == null) {
      usageException('Migration identity is not specified.');
    }
    final fixAction = FixAction(
      env: context.env,
      password: context.password,
      migrationsPath: context.config.migrationsPath,
      migrationIdentity: migrationIdentity,
      handler: const FixingReporter(console),
      console: console,
    );
    return await fixAction.execute();
  }
}
