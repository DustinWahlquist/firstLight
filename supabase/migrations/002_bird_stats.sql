-- Add bird stats + metadata to bird_cards
alter table bird_cards
  add column if not exists scientific_name text not null default '',
  add column if not exists description text not null default '',
  add column if not exists facts text[] not null default '{}',
  add column if not exists migration_speed int not null default 5,
  add column if not exists endurance int not null default 3;

-- Add sighting context to catch_logs
alter table catch_logs
  add column if not exists sighting_rarity text not null default 'Common',
  add column if not exists location text not null default '',
  add column if not exists xp_awarded int not null default 0;
