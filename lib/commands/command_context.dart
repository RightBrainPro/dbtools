import 'models/config.dart';


base class CommandContext
{
  final Config config;
  final EnvConfig env;
  final String password;

  const CommandContext({
    required this.config,
    required this.env,
    required this.password,
  });
}
