-- Persist the notifications preference. Nothing sends pushes yet; this
-- records the user's choice so it survives restarts and is ready for
-- when notification delivery ships.
alter table profiles
  add column if not exists notifications_enabled boolean not null default true;
