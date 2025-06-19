A simple PostgreSQL database project.

## Create the database

```shell
dbtool create
```
Now an empty database with UTF-8 encoding is created from the template0.

## Migrate the database

```shell
dbtool migrate
```
Now the database schema corresponds to the local migrations.

## Clean the database

```shell
dbtool clean
```
Now the database is cleared from all migrations commited earler. It is empty now.

## Drop the database

```shell
dbtool drop
```
The database has been dropped.
