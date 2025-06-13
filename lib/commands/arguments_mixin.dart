import 'dart:collection';
import 'dart:math';

import 'package:args/command_runner.dart';


class Argument
{
  final String name;
  final String? help;

  const Argument(this.name, {
    this.help,
  });
}


mixin ArgumentsMixin<T> on Command<T>
{
  @override
  String get usage => wrapUsage('$description\n\n') + usageWithoutDescription;

  @override
  String get invocation
  {
    final parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);
    final invocation = parents.reversed.join(' ');
    if (subcommands.isEmpty) {
      if (arguments.isEmpty) {
        return invocation;
      } else {
        final args = arguments.map((e) => '<${e.name}>').join(' ');
        return '$invocation $args';
      }
    } else {
      return '$invocation <subcommand> [arguments]';
    }
  }

  List<Argument> get arguments => _arguments;

  String get usageWithoutDescription
  {
    final length = argParser.usageLineLength;
    const usagePrefix = 'Usage: ';
    final buffer = StringBuffer()
      ..writeln(
        usagePrefix + wrapUsage(invocation, hangingIndent: usagePrefix.length)
      );
    if (arguments.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Arguments:');
      final namesColumnWidth = arguments.map((e) => e.name.length).reduce(max)
        + 4;
      for (final argument in arguments) {
        final name = padRight(argument.name, namesColumnWidth);
        final descLines = wrapTextAsLines(argument.help ?? '',
          start: namesColumnWidth,
          length: length,
        );
        buffer.writeln('$name${descLines.first}');
        for (final line in descLines.skip(1)) {
          buffer.write(' ' * namesColumnWidth);
          buffer.writeln(line);
        }
      }
      buffer.writeln();
    }
    buffer.writeln('Options:');
    buffer.writeln(argParser.usage);

    if (subcommands.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(getCommandUsage(subcommands,
        isSubcommand: true,
        lineLength: length,
      ));
    }

    buffer.writeln();
    buffer.write(
      wrapUsage('Run "${runner!.executableName} help" to see global options.')
    );

    if (usageFooter != null) {
      buffer.writeln();
      buffer.write(wrapUsage(usageFooter!));
    }

    return buffer.toString();
  }

  void addArgument(final String name, {
    final String? help,
  }) => arguments.add(Argument(name,
    help: help,
  ));

  String? argument(final String name)
  {
    final index = arguments.indexWhere((e) => e.name == name);
    if (index < 0) return null;
    final args = argResults?.rest ?? const [];
    if (index >= args.length) return null;
    return args[index];
  }

  /// Returns a string representation of [commands] fit for use in a usage
  /// string.
  ///
  /// [isSubcommand] indicates whether the commands should be called "commands"
  /// or "subcommands".
  String getCommandUsage(final Map<String, Command> commands, {
    final bool isSubcommand = false,
    final int? lineLength,
  })
  {
    // Don't include aliases.
    var names = commands.keys
      .where((name) => !commands[name]!.aliases.contains(name));

    // Filter out hidden ones, unless they are all hidden.
    final visible = names.where((name) => !commands[name]!.hidden);
    if (visible.isNotEmpty) names = visible;

    // Show the commands alphabetically.
    names = names.toList()..sort();

    // Group the commands by category.
    final commandsByCategory = SplayTreeMap<String, List<Command>>();
    for (var name in names) {
      var category = commands[name]!.category;
      commandsByCategory.putIfAbsent(category, () => []).add(commands[name]!);
    }
    final categories = commandsByCategory.keys.toList();
    final length = names.map((name) => name.length).reduce(max);

    final buffer = StringBuffer(
      'Available ${isSubcommand ? "sub" : ""}commands:'
    );
    final columnStart = length + 5;
    for (final category in categories) {
      if (category.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
        buffer.write(category);
      }
      for (final command in commandsByCategory[category]!) {
        final lines = wrapTextAsLines(command.summary,
          start: columnStart,
          length: lineLength,
        );
        buffer.writeln();
        buffer.write('  ${padRight(command.name, length)}   ${lines.first}');

        for (final line in lines.skip(1)) {
          buffer.writeln();
          buffer.write(' ' * columnStart);
          buffer.write(line);
        }
      }
    }

    return buffer.toString();
  }

  /// Pads [source] to [length] by adding spaces at the end.
  String padRight(final String source, final int length) => source
    + ' ' * (length - source.length);

  String wrapUsage(final String text, {
    final int? hangingIndent,
  }) => wrapText(text,
    length: argParser.usageLineLength,
    hangingIndent: hangingIndent,
  );

  /// Wraps a block of text into lines no longer than [length].
  ///
  /// Tries to split at whitespace, but if that's not good enough to keep it
  /// under the limit, then it splits in the middle of a word.
  ///
  /// Preserves indentation (leading whitespace) for each line (delimited by
  /// '\n') in the input, and indents wrapped lines the same amount.
  ///
  /// If [hangingIndent] is supplied, then that many spaces are added to each
  /// line, except for the first line. This is useful for flowing text with a
  /// heading prefix (e.g. "Usage: "):
  ///
  /// ```dart
  /// var prefix = "Usage: ";
  /// print(
  ///   prefix + wrapText(invocation, hangingIndent: prefix.length, length: 40),
  /// );
  /// ```
  ///
  /// yields:
  /// ```
  /// Usage: app main_command <subcommand>
  ///        [arguments]
  /// ```
  ///
  /// If [length] is not specified, then no wrapping occurs, and the original
  /// [text] is returned unchanged.
  String wrapText(final String text, {
    final int? length,
    int? hangingIndent,
  })
  {
    if (length == null) return text;
    hangingIndent ??= 0;
    var splitText = text.split('\n');
    var result = <String>[];
    for (var line in splitText) {
      var trimmedText = line.trimLeft();
      final leadingWhitespace =
          line.substring(0, line.length - trimmedText.length);
      List<String> notIndented;
      if (hangingIndent != 0) {
        // When we have a hanging indent, we want to wrap the first line at one
        // width, and the rest at another (offset by hangingIndent), so we wrap
        // them twice and recombine.
        var firstLineWrap = wrapTextAsLines(trimmedText,
            length: length - leadingWhitespace.length);
        notIndented = [firstLineWrap.removeAt(0)];
        trimmedText = trimmedText.substring(notIndented[0].length).trimLeft();
        if (firstLineWrap.isNotEmpty) {
          notIndented.addAll(wrapTextAsLines(trimmedText,
              length: length - leadingWhitespace.length - hangingIndent));
        }
      } else {
        notIndented = wrapTextAsLines(trimmedText,
            length: length - leadingWhitespace.length);
      }
      String? hangingIndentString;
      result.addAll(notIndented.map<String>((String line) {
        // Don't return any lines with just whitespace on them.
        if (line.isEmpty) return '';
        var result = '${hangingIndentString ?? ''}$leadingWhitespace$line';
        hangingIndentString ??= ' ' * hangingIndent!;
        return result;
      }));
    }
    return result.join('\n');
  }

  /// Wraps a block of text into lines no longer than [length], starting at the
  /// [start] column, and returns the result as a list of strings.
  ///
  /// Tries to split at whitespace, but if that's not good enough to keep it
  /// under the limit, then splits in the middle of a word. Preserves embedded
  /// newlines, but not indentation (it trims whitespace from each line).
  ///
  /// If [length] is not specified, then no wrapping occurs, and the original
  /// [text] is returned after splitting it on newlines. Whitespace is not
  /// trimmed in this case.
  List<String> wrapTextAsLines(final String text, {
    final int start = 0,
    final int? length,
  })
  {
    assert(start >= 0);

    /// Returns true if the code unit at [index] in [text] is a whitespace
    /// character.
    ///
    /// Based on: https://en.wikipedia.org/wiki/Whitespace_character#Unicode
    bool isWhitespace(String text, int index) {
      var rune = text.codeUnitAt(index);
      return rune >= 0x0009 && rune <= 0x000D ||
          rune == 0x0020 ||
          rune == 0x0085 ||
          rune == 0x1680 ||
          rune == 0x180E ||
          rune >= 0x2000 && rune <= 0x200A ||
          rune == 0x2028 ||
          rune == 0x2029 ||
          rune == 0x202F ||
          rune == 0x205F ||
          rune == 0x3000 ||
          rune == 0xFEFF;
    }

    if (length == null) return text.split('\n');

    var result = <String>[];
    var effectiveLength = max(length - start, 10);
    for (var line in text.split('\n')) {
      line = line.trim();
      if (line.length <= effectiveLength) {
        result.add(line);
        continue;
      }

      var currentLineStart = 0;
      int? lastWhitespace;
      for (var i = 0; i < line.length; ++i) {
        if (isWhitespace(line, i)) lastWhitespace = i;

        if (i - currentLineStart >= effectiveLength) {
          // Back up to the last whitespace, unless there wasn't any, in which
          // case we just split where we are.
          if (lastWhitespace != null) i = lastWhitespace;

          result.add(line.substring(currentLineStart, i).trim());

          // Skip any intervening whitespace.
          while (isWhitespace(line, i) && i < line.length) {
            i++;
          }

          currentLineStart = i;
          lastWhitespace = null;
        }
      }
      result.add(line.substring(currentLineStart).trim());
    }
    return result;
  }

  final _arguments = <Argument>[];
}
