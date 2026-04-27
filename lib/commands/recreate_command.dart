import 'package:meta/meta.dart';

import '../ansi.dart';
import '../constants.dart';
import 'actions/create_action.dart';
import 'actions/drop_action.dart';
import 'actions/migrate_action.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';
import 'reporters/migration_reporter.dart';


final class RecreateCommand extends BaseCommand
{
  @override
  String get category => 'Database';

  @override
  String get name => 'recreate';

  @override
  String get description => 'Recreate the database.\n'
    '${dim('Drops and creates the database specified in the selected '
    '${italic('env')} of the config in the ${bold('dbName')} parameter.')}'
  ;

  bool get migrate => argResults?.flag(migrateFlag) ?? migrateByDefault;

  static const migrateFlag = 'migrate';
  static const migrateByDefault = false;

  RecreateCommand(super.commandContextFactory)
  {
    argParser.addFlag(migrateFlag,
      abbr: 'm',
      help: 'Run migrations after recreating the database. '
        '${bold('Optional')}.\n'
        'It is ${bold('off')} by default. If enabled, applies all available '
        'migrations to the newly created database.',
      defaultsTo: migrateByDefault,
    );
  }

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
    await dropAction.execute();
    final createAction = CreateAction(
      env: context.env,
      password: context.password,
      console: console,
    );
    var result = await createAction.execute();
    if (result != resultOk || !migrate) return result;
    final migrateAction = MigrateAction(
      env: context.env,
      password: context.password,
      migrationsPath: context.config.migrationsPath,
      allowRollback: false,
      handler: const MigrationReporter(console),
      console: console,
    );
    result = await migrateAction.execute();
    return result;
  }
}
