import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

import 'command_context.dart';
import 'command_context_factory.dart';


abstract base class BaseCommand extends Command<int>
{
  BaseCommand(final CommandContextFactory commandContextFactory)
  : _commandContextFactory = commandContextFactory;

  @override
  Future<int> run() async
  {
    try {
      final context = await _commandContextFactory.create(globalResults);
      return await execute(context);
    } on CommandContextException catch (e) {
      usageException(e.message);
    }
  }

  @protected
  Future<int> execute(final CommandContext context);

  final CommandContextFactory _commandContextFactory;
}
