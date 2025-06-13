import 'dart:async';

import 'package:postgresql2/postgresql.dart';

import '../models/config.dart';
import 'exceptions.dart';
import 'types.dart';

export 'exceptions.dart' show ConnectionException, DatabaseException;

class DatabaseExecutor
{
  final EnvConfig env;
  final PasswordProvider passwordProvider;

  const DatabaseExecutor({
    required this.env,
    required this.passwordProvider,
  });

  Future<void> create() async
  {
    final sql = "create database ${env.dbName} encoding 'UTF8' "
      "lc_collate = 'en_US.UTF-8' lc_ctype = 'en_US.UTF-8' template template0";
    return _execute(sql);
  }

  Future<void> drop()
  {
    final sql = 'drop database ${env.dbName}';
    return _execute(sql);
  }

  Future<String> getPostgresHomeUrl() async
  {
    final password = await passwordProvider();
    return 'postgres://${env.user}:$password@${env.host}:${env.port}/'
      '${env.homeDbName}';
  }

  Future<void> _execute(final String sql) async
  {
    final connectionUrl = await getPostgresHomeUrl();
    try {
      final connection = await connect(connectionUrl);
      try {
        await connection.execute(sql);
      } on PostgresqlException catch (e) {
        throw DatabaseException(e.message);
      } catch (e) {
        throw DatabaseException('$e');
      } finally {
        connection.close();
      }
    } on PostgresqlException catch (e) {
      throw ConnectionException(e.message);
    }
  }
}
