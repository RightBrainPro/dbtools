class ConfigException implements Exception
{
  final String message;

  const ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}


class Config
{
  final String migrationsPath;
  final Map<String, EnvConfig> envs;

  const Config({
    this.migrationsPath = _migrationsPath,
    this.envs = const {},
  });

  factory Config.fromJson(final Map<String, dynamic> jsonValue)
  {
    var migrationsPath = _migrationsPath;
    final envs = <String, EnvConfig>{};
    for (final entry in jsonValue.entries) {
      if (entry.key == 'migrationsPath') {
        if (entry.value is! String) {
          throw const ConfigException('migrationsPath is expected to be a string.');
        }
        migrationsPath = entry.value;
        continue;
      }
      final env = entry.key;
      final jsonConnection = entry.value;
      if (jsonConnection is! Map<String, dynamic>) {
        throw ConfigException('$env is expected to be a valid object.');
      }
      envs[env] = EnvConfig.fromJson(jsonConnection);
    }
    return Config(
      envs: envs,
      migrationsPath: migrationsPath,
    );
  }

  static const _migrationsPath = 'migrations';
}


class EnvConfig
{
  final String host;
  final int port;
  final String user;
  final String dbName;
  final String tableName;
  final String homeDbName;

  const EnvConfig({
    this.host = _host,
    this.port = _port,
    this.user = _user,
    this.dbName = _dbName,
    this.tableName = _tableName,
    this.homeDbName = _user,
  });

  factory EnvConfig.fromJson(final Map<String, dynamic> jsonValue)
  {
    final jsonHost = jsonValue['host'] ?? _host;
    if (jsonHost is! String) {
      throw const ConfigException('host is expected to be a valid string.');
    }
    final jsonPort = jsonValue['port'] ?? _port;
    if (jsonPort is! int) {
      throw const ConfigException('port is expected to be a valid number.');
    }
    final jsonUser = jsonValue['user'] ?? _user;
    if (jsonUser is! String) {
      throw const ConfigException('user is expected to be a valid string.');
    }
    final jsonDbName = jsonValue['dbName'] ?? _dbName;
    if (jsonDbName is! String) {
      throw const ConfigException('dbName is expected to be a valid string.');
    }
    final jsonTableName = jsonValue['tableName'] ?? _tableName;
    if (jsonTableName is! String) {
      throw const ConfigException('tableName is expected to be a valid string.');
    }
    final jsonHomeDbName = jsonValue['homeDbName'] ?? jsonUser;
    if (jsonHomeDbName is! String) {
      throw const ConfigException('homeDbName is expected to be a valid string.');
    }
    return EnvConfig(
      host: jsonHost,
      port: jsonPort,
      user: jsonUser,
      dbName: jsonDbName,
      tableName: jsonTableName,
      homeDbName: jsonHomeDbName,
    );
  }

  static const _host = 'localhost';
  static const _port = 5432;
  static const _user = 'postgres';
  static const _dbName = '';
  static const _tableName = 'migrations';
}
