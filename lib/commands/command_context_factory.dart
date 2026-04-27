import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'command_context.dart';
import 'models/config.dart';


abstract interface class CommandContextFactory
{
  Future<CommandContext> create(ArgResults? args);
}


base class CommandContextException implements Exception
{
  final String message;

  const CommandContextException(this.message);

  @override
  String toString()
  {
    final buffer = StringBuffer('CommandContextException');
    if (message.isNotEmpty) buffer.write(': $message');
    return buffer.toString();
  }
}


final class DefaultCommandContextFactory implements CommandContextFactory
{
  const DefaultCommandContextFactory();

  @override
  Future<CommandContext> create(final ArgResults? args) async
  {
    final configName = args?.option('config');
    final envName = args?.option('env');
    final askPassword = args?.flag('password') ?? false;

    final config = await _getConfig(configName);
    final env = config.envs[envName]
      ?? config.envs['dev']
      ?? config.envs.values.firstOrNull
    ;
    if (env == null) {
      throw const CommandContextException(
        'Failed to find the env.\nPlease, specify a valid env in your config.'
      );
    }
    final password = _getPassword(env, askPassword);
    return CommandContext(config: config, env: env, password: password);
  }

  Future<Config> _getConfig(final String? configName) async
  {
    Config? config;
    if (configName != null) {
      config = await _loadConfig(fileName: configName);
    }
    config ??= await _loadConfig(fileName: 'dbtools.yaml');
    config ??= await _loadConfig(fileName: 'pubspec.yaml', fileKey: 'dbtools');
    return config ?? const Config();
  }

  String _getPassword(final EnvConfig env, final bool askPassword)
  {
    if (askPassword) {
      if (stdin.hasTerminal) {
        stdout.write('Password for the user ${env.user}: ');
        stdin.echoMode = false;
        final password = stdin.readLineSync() ?? '';
        stdin.echoMode = true;
        stdout.writeln();
        return password;
      }
      return stdin.readLineSync() ?? '';
    }
    return env.password ?? '';
  }

  Future<Config?> _loadConfig({
    final String? fileName,
    final String? fileKey,
    Map<String, dynamic>? jsonValue,
  }) async
  {
    if (jsonValue == null && fileName != null) {
      final file = File(fileName);
      if (await file.exists()) {
        final data = await file.readAsString();
        final document = _convertYaml(loadYaml(data));
        if (document is Map<String, dynamic>) {
          jsonValue = document;
          if (fileKey != null) {
            jsonValue = jsonValue[fileKey];
          }
        }
      }
    }
    if (jsonValue == null) return null;
    return Config.fromJson(jsonValue);
  }

  dynamic _convertYaml(final dynamic data) => switch (data) {
    YamlScalar(value: dynamic value) => value,
    YamlList() => [ for (final e in data) _convertYaml(e) ],
    YamlMap() => {
      for (final e in data.entries) '${e.key}' : _convertYaml(e.value)
    },
    _ => data,
  };
}
