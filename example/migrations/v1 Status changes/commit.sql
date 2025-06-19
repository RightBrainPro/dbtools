alter table examples add column updated_at timestamp not null;

create table status_changes
(
  example_id varchar(36) not null unique
    references examples(id)
      on update cascade on delete cascade,
  updated_at timestamp not null
);

create index status_changes_updated_at_index
  on status_changes(updated_at);
