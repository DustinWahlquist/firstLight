-- Shared species content cache — generated once, reused across all users
create table if not exists bird_species (
  species_name     text primary key,
  scientific_name  text,
  rarity           text,
  description      text,
  facts            jsonb,
  migration_speed  integer,
  endurance        integer,
  line_art_url     text,
  created_at       timestamptz default now()
);

alter table bird_species enable row level security;

-- Any authenticated user can read shared species data
create policy "Authenticated users can read bird_species"
  on bird_species for select
  to authenticated
  using (true);
