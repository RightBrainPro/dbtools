class DatabaseException implements Exception
{
  final String message;

  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}


class MigrationException implements Exception
{
  final String message;

  const MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}


class ConnectionException implements Exception
{
  final String message;

  const ConnectionException(this.message);

  @override
  String toString() => 'ConnectionException: $message';
}


class AbortedException implements Exception
{
  final String message;

  const AbortedException(this.message);

  @override
  String toString() => 'AbortedException: $message';
}
