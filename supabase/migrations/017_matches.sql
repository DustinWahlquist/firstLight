-- Persisted matches — the migration-race game. Each row holds the full
-- serialized match state plus denormalized columns (turn, status, winner)
-- so the Active Games list can render without parsing the state JSON.
--
-- V1 covers bot matches (player_id owns the row, AI plays the opponent).
-- Friend matches will add an opponent_id and widen the policy.
create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references auth.users(id) on delete cascade,
  mode text not null default 'bot' check (mode in ('bot', 'friend')),
  opponent_name text not null default 'Mara',
  status text not null default 'active' check (status in ('active', 'complete')),
  turn text not null default 'you',
  winner text,
  state jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists matches_player_active_idx
  on matches (player_id, status, updated_at desc);

alter table matches enable row level security;

create policy "Users manage their own matches"
  on matches for all
  to authenticated
  using (auth.uid() = player_id)
  with check (auth.uid() = player_id);
