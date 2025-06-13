import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:path/path.dart';
import 'package:pointycastle/digests/md5.dart';

import '../models/migration.dart';


final rEmptyLine = RegExp(r'^\s*\n', multiLine: true);


mixin MigrationMixin
{
  Future<String> getScript(final String path, final String name) async
  {
    final file = File(join(path, name));
    final exists = await file.exists();
    if (!exists) return '';
    final result = await file.readAsString();
    return result.replaceAll(rEmptyLine, '').trim();
  }

  MigrationIdentity getMigrationIdentity(final String path)
  {
    final dirName = split(path).last;
    final r = RegExp(r'^\D*(\d+)\P{L}*(.*)$', unicode: true);
    final match = r.firstMatch(dirName);
    if (match == null) {
      throw FormatException('Invalid directory name format: $dirName');
    }
    return MigrationIdentity(
      id: int.parse(match.group(1)!),
      name: match.group(2)!.trim(),
    );
  }

  Future<BriefMigration> getBriefMigration(final String path) async
  {
    final identity = getMigrationIdentity(path);
    final digest = MD5Digest();
    {
      final commitFile = File(join(path, 'commit.sql'));
      if (!commitFile.existsSync()) {
        throw FileSystemException('Commit file is not found', commitFile.path);
      }
      final data = await commitFile.readAsBytes();
      digest.update(data, 0, data.length);
    }
    {
      final rollbackFile = File(join(path, 'rollback.sql'));
      if (!rollbackFile.existsSync()) {
        throw FileSystemException('Rollback file is not found', rollbackFile.path);
      }
      final data = await rollbackFile.readAsBytes();
      digest.update(data, 0, data.length);
    }
    var out = Uint8List(digest.digestSize);
    final len = digest.doFinal(out, 0);
    if (out.length > len) {
      out = out.sublist(0, len);
    }
    final csum = hex.encode(out);

    return BriefMigration(
      id: identity.id,
      name: identity.name,
      csum: csum,
      path: path,
    );
  }

  Future<LocalMigration> getLocalMigration(final BriefMigration brief) async
  {
    final String commit;
    {
      final commitFile = File(join(brief.path, 'commit.sql'));
      if (!commitFile.existsSync()) {
        throw FileSystemException('Commit file is not found', commitFile.path);
      }
      commit = await commitFile.readAsString();
    }
    final String rollback;
    {
      final rollbackFile = File(join(brief.path, 'rollback.sql'));
      if (!rollbackFile.existsSync()) {
        throw FileSystemException('Rollback file is not found', rollbackFile.path);
      }
      rollback = await rollbackFile.readAsString();
    }
    return LocalMigration(
      id: brief.id,
      name: brief.name,
      csum: brief.csum,
      commit: commit.replaceAll(rEmptyLine, '').trim(),
      rollback: rollback.replaceAll(rEmptyLine, '').trim(),
      createdAt: DateTime.now(),
    );
  }
}
