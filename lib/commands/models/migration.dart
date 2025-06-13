import '../extensions.dart';


class Migration
{
  final int id;
  final String name;
  final String csum;
  final String rollback;
  final DateTime createdAt;

  const Migration({
    required this.id,
    required this.name,
    required this.csum,
    required this.rollback,
    required this.createdAt,
  });

  factory Migration.fromJson(final Map<String, dynamic> jsonValue)
  {
    return Migration(
      id: jsonValue['id'],
      name: jsonValue['name'],
      csum: jsonValue['csum'],
      rollback: jsonValue['rollback'],
      createdAt: DateTimeExt.parseToUtc(jsonValue['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'csum': csum,
    'rollback': rollback,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}


class LocalMigration extends Migration
{
  final String commit;

  const LocalMigration({
    required super.id,
    required super.name,
    required super.csum,
    required this.commit,
    required super.rollback,
    required super.createdAt,
  });
}


class RollbackMigration
{
  final int id;
  final String rollback;

  const RollbackMigration({
    required this.id,
    required this.rollback,
  });
}


class MigrationIdentity
{
  final int id;
  final String name;

  const MigrationIdentity({
    required this.id,
    required this.name,
  });
}


class BriefMigration extends MigrationIdentity
{
  final String csum;
  final String path;

  const BriefMigration({
    required super.id,
    required super.name,
    required this.csum,
    required this.path,
  });
}
