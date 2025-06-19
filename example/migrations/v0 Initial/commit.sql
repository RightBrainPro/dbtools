create schema if not exists example;

/* Database user and its privileges in the schema. */
do
$do$
begin
  if exists (select from pg_catalog.pg_roles where rolname = 'example_user') then
    raise notice 'Role "example_user" already exists.';
  else
    create role example_user login password 'example_pass';
  end if;
end
$do$;

alter role example_user set search_path to example;
grant usage on schema example to example_user;
alter default privileges in schema example
  grant select, insert, update, delete, trigger on tables to example_user;
alter default privileges in schema example
  grant usage, select, update on sequences to example_user;
alter default privileges in schema example
  grant execute on functions to example_user;
alter default privileges in schema example
  grant usage on types to example_user;

/* Example table. */
create table examples
(
  id varchar(36) primary key,
  status varchar(20) not null,
  created_at timestamp not null
);

create index examples_status_index
  on examples(status);
