-- Bird cards (one per species per user)
create table bird_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  species_name text not null,
  rarity text not null check (rarity in ('Common', 'Somewhat Rare', 'Ultra Rare')),
  level int not null default 1,
  xp int not null default 0,
  catch_count int not null default 1,
  first_catch_date date not null,
  first_catch_location text not null,
  screenshot_url text,
  created_at timestamptz not null default now(),
  unique (user_id, species_name)
);

-- Catch logs (one per submission; enforces 1/day per bird in app layer)
create table catch_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  bird_card_id uuid not null references bird_cards(id) on delete cascade,
  caught_at timestamptz not null default now(),
  screenshot_url text
);

-- Row-level security
alter table bird_cards enable row level security;
alter table catch_logs enable row level security;

create policy "Users can manage their own bird cards"
  on bird_cards for all
  using (auth.uid() = user_id);

create policy "Users can manage their own catch logs"
  on catch_logs for all
  using (auth.uid() = user_id);

-- Storage bucket for screenshots
insert into storage.buckets (id, name, public)
values ('screenshots', 'screenshots', true);

create policy "Users can upload their own screenshots"
  on storage.objects for insert
  with check (bucket_id = 'screenshots' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Screenshots are publicly readable"
  on storage.objects for select
  using (bucket_id = 'screenshots');
