-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
-- aviary_cards
-- One row per user per species.
-- ─────────────────────────────────────────
create table public.aviary_cards (
  id                   uuid primary key default uuid_generate_v4(),
  user_id              uuid references auth.users(id) on delete cascade not null,
  species_name         text not null,
  rarity               text not null
                         check (rarity in ('common', 'somewhat_rare', 'ultra_rare')),
  level                integer not null default 1 check (level >= 1),
  xp                   integer not null default 0 check (xp >= 0),
  first_catch_date     date not null,
  first_catch_location text,
  screenshot_url       text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  unique (user_id, species_name)
);

-- ─────────────────────────────────────────
-- catch_log
-- Every successfully parsed screenshot.
-- The unique index enforces 1 catch per bird per day.
-- ─────────────────────────────────────────
create table public.catch_log (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid references auth.users(id) on delete cascade not null,
  species_name   text not null,
  caught_at      date not null default current_date,
  screenshot_url text,
  xp_awarded     integer not null default 0,
  created_at     timestamptz not null default now()
);

-- Enforce the daily catch limit at the DB level.
create unique index catch_log_daily_limit
  on public.catch_log (user_id, species_name, caught_at);

-- ─────────────────────────────────────────
-- Row-level security
-- ─────────────────────────────────────────
alter table public.aviary_cards enable row level security;
alter table public.catch_log     enable row level security;

create policy "Users own their aviary"
  on public.aviary_cards for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users own their catch log"
  on public.catch_log for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- Storage bucket for screenshots
-- ─────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('screenshots', 'screenshots', true);

create policy "Users upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'screenshots'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Public read access for screenshots"
  on storage.objects for select
  using (bucket_id = 'screenshots');

-- ─────────────────────────────────────────
-- updated_at trigger
-- ─────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger aviary_cards_updated_at
  before update on public.aviary_cards
  for each row execute procedure public.set_updated_at();
