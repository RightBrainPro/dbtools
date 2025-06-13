A simple CLI application for managing the PostgreSQL database during developing a dart project.

## About dbtools

**dbtools** allows to create, drop and migrate the PostgreSQL database you use in your project based on migrations located in the subdirectory of your project.

It supports:
* different environments like `dev`, `prod`, etc.;
* custom path for the migrations directory;
* intermediate scripts to perform auxiliary commands;
* quick fix the specified migration in the database;
* optional password input.

## How to use

1. Add the `dbtools` as a dev dependency and activate it.
```shell
dart pub global activate dbtools
```

2. Put the next settings in `dbtools` section in the `pubspec.yaml` or put them in `dbtools.yaml`:

```yaml
migrationsPath: migrations
dev:
  user: postgres
  dbName: your_database
prod:
  host: your.server.com
  post: 5432
  user: admin
  dbName: your_database
  tableName: migrations
  homeDbName: admin
```
* `migrationsPath` is the path to the migrations directory. Can be relative or absolute. The default value is `migrations`.
* `host` is the address of your PostgreSQL installation. `localhost` by default.
* `port` is the port your PostgreSQL is listening to. `5432` by default.
* `user` is the PostgreSQL role with privileges for manipulating databases. `postgres` by default.
* `dbName` is the target database of your project. It is required.
* `tableName` is the name of the migrations table in the target database.
* `homeDbName` is default database of the `user`. By default, has the same name as `user`.

`dev` is the default environment, but you can choose any set of environments. The only requirement is at least one environment must be presented in the config.

3. Write migrations.
In the `migrationsPath` directory you write migration folders containing two scripts:
* `commit.sql` with sql-commands to migrate the database up.
* `rollback.sql` with sql-commands to migrate the database down.
These are required and may not be empty.
Additionally you can place intermediate scripts:
* `before_prepare.sql` is executed before creating the migrations table in the database. It may be helpful to create a new schema if you prefere to place the migrations table in another schema than `public`. Also you can set the search_path to this scheme if you prefere to name tables without explicit schema in your migration scripts.
* `after_prepare.sql` is executed after creating the migrations table in the database.
* `after_commits.sql` is executed right after commiting migrations if any.
* `cleanup.sql` is executed when all migrations have been rolled back and there is no any migration to commit.

Here is an example structure:
```shell
your_project
  bin
  lib
  migrations
    ver1 Initial
      commit.sql
      rollback.sql
    ver2 Feature 1
      commit.sql
      rollback.sql
    before_prepare.sql
    after_prepare.sql
    after_commits.sql
    cleanup.sql
  dbtools.yaml
  pubspec.yaml
```

You can choose any format of your migration folder. It is recommended to stick the same format. Here are acceptable variants:
* `ver1 Initial`
* `v1-initial`
* `#1: Initial`
* `1`
* `250101`

Requirements:
* The migration identity must contain the unique number of version (`ver2 Feature 1` is the migration number 2).
* All migrations are ordered by number, that means the migration `ver2 Feature 1` will be applied strictly after the migration `ver1 Initial`, and vice versa, `ver1 Initial` will be rolled back strictly after `ver2 Feature 1` rollback.

4. Create the database
```shell
dbtools create
```

5. Migrate the database.
```shell
dbtools migrate
```

Now all migrations placed in your migrations directory are applied to the database. Don't forget to run this command after switching the current git branch to make the database actual.

Also, you can migrate to the specified version:
```shell
  dbtools migrate v5
```

You can find other details of the **dbtools** usage by typing `dart run dbtools help`.