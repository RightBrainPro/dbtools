revoke all privileges on all tables in schema example from example_user;
revoke all privileges on all sequences in schema example from example_user;
revoke all privileges on all functions in schema example from example_user;
revoke all privileges on schema example from example_user;

alter default privileges in schema example
  revoke all privileges on tables from example_user;
alter default privileges in schema example
  revoke all privileges on sequences from example_user;
alter default privileges in schema example
  revoke all privileges on functions from example_user;
alter default privileges in schema example
  revoke all privileges on types from example_user;

drop role if exists example_user;

drop table examples;
