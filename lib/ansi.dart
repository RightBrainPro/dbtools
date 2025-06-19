import 'dart:collection';


String reset(final Object object) => const _Style(0, 0).apply(object);

String bold(final Object object) => const _Style(1, 22).apply(object);

String dim(final Object object) => const _Style(2, 22).apply(object);

String italic(final Object object) => const _Style(3, 23).apply(object);

String underline(final Object object) => const _Style(4, 24).apply(object);

String inverse(final Object object) => const _Style(7, 27).apply(object);

String hidden(final Object object) => const _Style(8, 28).apply(object);

String strikeThrough(final Object object) => const _Style(9, 29).apply(object);

String overline(final Object object) => const _Style(53, 55).apply(object);


String black(final Object object) => const _Style(30, 39).apply(object);

String red(final Object object) => const _Style(31, 39).apply(object);

String green(final Object object) => const _Style(32, 39).apply(object);

String yellow(final Object object) => const _Style(33, 39).apply(object);

String blue(final Object object) => const _Style(34, 39).apply(object);

String magenta(final Object object) => const _Style(35, 39).apply(object);

String cyan(final Object object) => const _Style(36, 39).apply(object);

String white(final Object object) => const _Style(37, 39).apply(object);


String blackBright(final Object object) => const _Style(90, 39).apply(object);

String redBright(final Object object) => const _Style(91, 39).apply(object);

String greenBright(final Object object) => const _Style(92, 39).apply(object);

String yellowBright(final Object object) => const _Style(93, 39).apply(object);

String blueBright(final Object object) => const _Style(94, 39).apply(object);

String magentaBright(final Object object) => const _Style(95, 39).apply(object);

String cyanBright(final Object object) => const _Style(96, 39).apply(object);

String whiteBright(final Object object) => const _Style(97, 39).apply(object);


String grey(final Object object) => blackBright(object);

String gray(final Object object) => blackBright(object);


String bgBlack(final Object object) => const _Style(40, 49).apply(object);

String bgRed(final Object object) => const _Style(41, 49).apply(object);

String bgGreen(final Object object) => const _Style(42, 49).apply(object);

String bgYellow(final Object object) => const _Style(43, 49).apply(object);

String bgBlue(final Object object) => const _Style(44, 49).apply(object);

String bgMagenta(final Object object) => const _Style(45, 49).apply(object);

String bgCyan(final Object object) => const _Style(46, 49).apply(object);

String bgWhite(final Object object) => const _Style(47, 49).apply(object);


String bgBlackBright(final Object object) => const _Style(100, 49).apply(object);

String bgRedBright(final Object object) => const _Style(101, 49).apply(object);

String bgGreenBright(final Object object) => const _Style(102, 49).apply(object);

String bgYellowBright(final Object object) => const _Style(103, 49).apply(object);

String bgBlueBright(final Object object) => const _Style(104, 49).apply(object);

String bgMagentaBright(final Object object) => const _Style(105, 49).apply(object);

String bgCyanBright(final Object object) => const _Style(106, 49).apply(object);

String bgWhiteBright(final Object object) => const _Style(107, 49).apply(object);


class _Style
{
  final int open;
  final int close;

  String get openTag => '\x1B[${open}m';
  String get closeTag => '\x1B[${close}m';

  const _Style(this.open, this.close);

  static const _typeBold = 1;
  static const _typeDim = 2;

  String apply(final Object object)
  {
    if (open == _typeBold || open == _typeDim) {
      return _boldDim(object, open);
    }
    return '$openTag$object$closeTag';
  }

  String _boldDim(final Object object, final int type)
  {
    const openBold = '\x1B[1m';
    const openDim = '\x1B[2m';
    const closeTag = '\x1B[22m';

    final text = object.toString();
    final buffer = StringBuffer();
    final stack = Queue<int>();

    buffer.write(openTag);
    var closed = false;
    for (var i = 0; i < text.length;) {
      if (text.startsWith(openBold, i)) {
        i += openBold.length;
        final inBold = stack.isEmpty
          ? type == _typeBold
          : stack.lastOrNull == _typeBold;
        if (!inBold) {
          stack.add(_typeBold);
          buffer.write(openBold);
        }
      } else if (text.startsWith(openDim, i)) {
        i += openDim.length;
        final inDim = stack.isEmpty
          ? type == _typeDim
          : stack.lastOrNull == _typeDim;
        if (!inDim) {
          stack.add(_typeDim);
          buffer.write(openDim);
        }
      } else if (text.startsWith(closeTag, i)) {
        i += closeTag.length;
        if (stack.isNotEmpty) {
          stack.removeLast();
          buffer.write(closeTag);
          if (stack.isEmpty) {
            if (i < text.length) {
              buffer.write(openTag);
            } else {
              closed = true;
            }
          }
        }
      } else {
        final textStart = i;
        while (i < text.length) {
          ++i;
          if (text.startsWith(openDim, i)
            || text.startsWith(openBold, i)
            || text.startsWith(closeTag, i)
          ) {
            break;
          }
        }
        buffer.write(text.substring(textStart, i));
      }
    }
    if (!closed) buffer.write(closeTag);

    return buffer.toString();
  }
}
