String reset(final Object object) => _style(0, 0).apply(object);

String bold(final Object object) => _style(1, 22).apply(object);

String dim(final Object object) => _style(2, 22).apply(object);

String italic(final Object object) => _style(3, 23).apply(object);

String underline(final Object object) => _style(4, 24).apply(object);

String inverse(final Object object) => _style(7, 27).apply(object);

String hidden(final Object object) => _style(8, 28).apply(object);

String strikeThrough(final Object object) => _style(9, 29).apply(object);

String overline(final Object object) => _style(53, 55).apply(object);


String black(final Object object) => _style(30, 39).apply(object);

String red(final Object object) => _style(31, 39).apply(object);

String green(final Object object) => _style(32, 39).apply(object);

String yellow(final Object object) => _style(33, 39).apply(object);

String blue(final Object object) => _style(34, 39).apply(object);

String magenta(final Object object) => _style(35, 39).apply(object);

String cyan(final Object object) => _style(36, 39).apply(object);

String white(final Object object) => _style(37, 39).apply(object);


String blackBright(final Object object) => _style(90, 39).apply(object);

String redBright(final Object object) => _style(91, 39).apply(object);

String greenBright(final Object object) => _style(92, 39).apply(object);

String yellowBright(final Object object) => _style(93, 39).apply(object);

String blueBright(final Object object) => _style(94, 39).apply(object);

String magentaBright(final Object object) => _style(95, 39).apply(object);

String cyanBright(final Object object) => _style(96, 39).apply(object);

String whiteBright(final Object object) => _style(97, 39).apply(object);


String grey(final Object object) => blackBright(object);

String gray(final Object object) => blackBright(object);


String bgBlack(final Object object) => _style(40, 49).apply(object);

String bgRed(final Object object) => _style(41, 49).apply(object);

String bgGreen(final Object object) => _style(42, 49).apply(object);

String bgYellow(final Object object) => _style(43, 49).apply(object);

String bgBlue(final Object object) => _style(44, 49).apply(object);

String bgMagenta(final Object object) => _style(45, 49).apply(object);

String bgCyan(final Object object) => _style(46, 49).apply(object);

String bgWhite(final Object object) => _style(47, 49).apply(object);


String bgBlackBright(final Object object) => _style(100, 49).apply(object);

String bgRedBright(final Object object) => _style(101, 49).apply(object);

String bgGreenBright(final Object object) => _style(102, 49).apply(object);

String bgYellowBright(final Object object) => _style(103, 49).apply(object);

String bgBlueBright(final Object object) => _style(104, 49).apply(object);

String bgMagentaBright(final Object object) => _style(105, 49).apply(object);

String bgCyanBright(final Object object) => _style(106, 49).apply(object);

String bgWhiteBright(final Object object) => _style(107, 49).apply(object);


_Style _style(final int open, final int close) => _Style(
  '\x1B[${open}m', '\x1B[${close}m'
);


class _Style
{
  final String open;
  final String close;

  const _Style(this.open, this.close);

  String apply(final Object object) => '$open$object$close';
}
