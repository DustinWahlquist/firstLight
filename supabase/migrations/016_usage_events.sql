-- Lightweight usage analytics. Apps insert their own events; only CMS
-- admins can read them. First consumer: which aviary sort options users
-- actively choose (the default sort is never logged).
create table if not exists usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  event text not null,
  value text,
  created_at timestamptz not null default now()
);

alter table usage_events enable row level security;

create policy "Users can log their own events"
  on usage_events for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Admins can read usage events"
  on usage_events for select
  to authenticated
  using (is_cms_admin());
