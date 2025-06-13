import 'package:postgresql2/postgresql.dart';

import '../ansi.dart';


extension PostgresExceptionInfo on PostgresqlException
{
  String get info
  {
    final message = serverMessage?.message ?? this.message;
    final details = serverMessage?.detail;
    return details == null
      ? red(message)
      : '${red(message)}\n$details';
  }
}


extension DateTimeExt on DateTime
{
  /// Converts [value] to the [DateTime] object in UTC.
  ///
  /// The [value] can be of type [String] or [DateTime].
  static DateTime parseToUtc(final Object value) => switch (value) {
    DateTime() => value.toUtc(),
    String() => DateTime.parse(value).toUtc(),
    _ => throw FormatException('Unexpected type ${value.runtimeType}'),
  };

  static DateTime? tryParseToUtc(final Object? value) => switch (value) {
    DateTime() => value.toUtc(),
    String() => DateTime.tryParse(value)?.toUtc(),
    _ => null,
  };
}
