import 'package:args/command_runner.dart';

import 'ansi.dart';
import 'commands/command_context_factory.dart';
import 'commands/fix_command.dart';
import 'commands/clean_command.dart';
import 'commands/create_command.dart';
import 'commands/drop_command.dart';
import 'commands/migrate_command.dart';
import 'commands/recreate_command.dart';


class MainCommandRunner extends CommandRunner<int>
{
  MainCommandRunner()
  : super('dbtools', 'Database migration tool.')
  {
    argParser.addOption('config',
      abbr: 'c',
      help: 'Path to the configuration file. ${bold('Optional')}.\n'
        'If ommitted, first tries to read ${bold('dbtools.yaml')}, then '
        '${bold('pubspec.yaml')}.',
    );
    argParser.addOption('env',
      abbr: 'e',
      help: 'The name of the environment to be used from the configuration file. '
        '${bold('Optional')}.\n'
        'If ommitted, first tries to use ${bold('dev')}, then the first '
        'available.',
    );
    argParser.addFlag('password',
      abbr: 'W',
      help: 'Whether to ask the PostgreSQL user password. ${bold('Optional')}.\n'
        'It is ${bold('off')} by default, which means the user does not have any '
        'password. If he does, please turn on this flag to be able to provide '
        'the password. The password can be provided via pipe: ${dim('echo '
        '\$PASSWORD | dart run dbtools --env=dev --password migrate')}. If pipe '
        'is not used, you will be prompted to enter the password manually.',
      defaultsTo: false,
    );
    const commandContextFactory = DefaultCommandContextFactory();
    addCommand(CreateCommand(commandContextFactory));
    addCommand(DropCommand(commandContextFactory));
    addCommand(RecreateCommand(commandContextFactory));
    addCommand(MigrateCommand(commandContextFactory));
    addCommand(CleanCommand(commandContextFactory));
    addCommand(FixCommand(commandContextFactory));
  }
}
