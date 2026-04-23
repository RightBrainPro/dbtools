import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dbtools/constants.dart';
import 'package:dbtools/runner.dart';


Future<void> main(List<String> args) async
{
  try {
    final result = await mainRunner.run(args);
    exit(result ?? resultOk);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(resultCommandLineError);
  } catch (e) {
    stderr.writeln(e);
    exit(resultError);
  }
}
