import 'dart:io';


mixin StdoutMixin
{
  /// Append the current info line with [message].
  void info(final String message)
  {
    stdout.write(message);
  }

  /// Rewrite the current info line with [message].
  void infoC(final String message)
  {
    clearInfo();
    stdout.write(message);
  }

  /// Append the current info line with [message] and start the next line.
  void infoLn(final String message)
  {
    stdout.writeln(message);
  }

  /// Rewrite the current info line with [message] and start the next line.
  void infoCLn(final String message)
  {
    clearInfo();
    stdout.writeln(message);
  }

  /// Clear the current info line and return the caret.
  void clearInfo()
  {
    if (stdout.supportsAnsiEscapes) {
      stdout.write('\x1B[2K\r');
    } else {
      stdout.writeln();
    }
  }

  /// Append the current error line with [message].
  void error(final String message)
  {
    stderr.write(message);
  }

  /// Rewrite the current error line with [message].
  void errorC(final String message)
  {
    clearError();
    stderr.write(message);
  }

  /// Append the current error line with [message] and start the next line.
  void errorLn(final String message)
  {
    stderr.writeln(message);
  }

  /// Rewrite the current error line with [message] and start the next line.
  void errorCLn(final String message)
  {
    clearError();
    stderr.writeln(message);
  }

  /// Clear the current error line and return the caret.
  void clearError()
  {
    if (stderr.supportsAnsiEscapes) {
      stderr.write('\x1B[2K\r');
    } else {
      stderr.writeln();
    }
  }
}
