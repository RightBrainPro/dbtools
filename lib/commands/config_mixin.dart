import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

import 'models/config.dart';


mixin ConfigMixin<T> on Command<T>
{
  Future<Config> loadConfig() async
  {
    Config? config;
    final configName = globalResults?.option('config');
    if (configName != null) {
      config = await _loadConfig(fileName: configName);
    }
    config ??= await _loadConfig(fileName: 'dbtools.yaml');
    config ??= await _loadConfig(fileName: 'pubspec.yaml', fileKey: 'dbtools');
    return config ?? const Config();
  }

  Future<EnvConfig?> loadEnv([ Config? config ]) async
  {
    config ??= await loadConfig();
    final envName = globalResults?.option('env');
    final env = config.envs[envName]
      ?? config.envs['dev']
      ?? config.envs.values.firstOrNull;
    return env;
  }

  String getPassword(final String userName)
  {
    String? password;
    final askPassword = globalResults?.flag('password');
    if (askPassword == true) {
      stdout.write('Password for the user $userName: ');
      stdin.echoMode = false;
      while (password == null) {
        password = stdin.readLineSync();
      }
      stdin.echoMode = true;
    } else {
      password = '';
    }
    return password;
  }

  String getPostgresUrl(final EnvConfig env)
  {
    final password = getPassword(env.user);
    return 'postgres://${env.user}:$password@${env.host}:${env.port}/'
      '${env.dbName}';
  }

  String getPostgresHomeUrl(final EnvConfig env)
  {
    final password = getPassword(env.user);
    return 'postgres://${env.user}:$password@${env.host}:${env.port}/'
      '${env.homeDbName}';
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
