import 'package:meta/meta.dart';

import '../ansi.dart';
import 'actions/migrate_action.dart';
import 'arguments_mixin.dart';
import 'base_command.dart';
import 'command_context.dart';
import 'console.dart';
import 'reporters/migration_reporter.dart';


final class MigrateCommand extends BaseCommand with ArgumentsMixin
{
  @override
  String get category => 'Migration';

  @override
  String get name => 'migrate';

  @override
  String get description =>
    'Migrate the database according to the current set of local migrations.';

  bool get allowRollback => argResults?.flag(rollbackFlag) ?? rollbackByDefault;

  static const migrationIdentityArg = 'migration identity';
  static const rollbackFlag = 'rollback';
  static const rollbackByDefault = true;

  MigrateCommand(super.commandContextFactory)
  {
    addArgument(migrationIdentityArg,
      help: 'The identity of the migration in the format as you name it in the '
        'migrations directory.\n'
        '${bold('Optional')}.\n'
        'If specified, the database will be migrated up to this version. '
        'Otherwise, the database will be migrated up to the latest version in '
        'the migrations directory.'
    );
    argParser.addFlag(rollbackFlag,
      abbr: 'r',
      help: 'Allow to rollback the migrations already applied to the database. '
        '${bold('Optional')}.\n'
        'It is ${bold('on')} by default, which means all migrations that absent '
        'or differ from local ones will be rolled back before applying new '
        'migrations. It is not recommended to allow rollback in production '
        'environment.',
      defaultsTo: rollbackByDefault,
    );
  }

  @override
  @protected
  Future<int> execute(final CommandContext context) async
  {
    const console = Console();
    final migrateAction = MigrateAction(
      env: context.env,
      password: context.password,
      migrationsPath: context.config.migrationsPath,
      migrationIdentity: argument(migrationIdentityArg),
      allowRollback: allowRollback,
      handler: const MigrationReporter(console),
      console: console,
    );
    return await migrateAction.execute();
  }
}
