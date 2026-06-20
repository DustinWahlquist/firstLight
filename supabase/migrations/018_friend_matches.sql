-- Friend (human vs human) matches. A challenge starts 'pending' until the
-- opponent accepts; both participants can then read and write the row.
alter table matches
  add column if not exists opponent_id uuid references auth.users(id) on delete cascade,
  add column if not exists challenger_name text,
  add column if not exists opponent_avatar_url text;

-- Allow the new pending status.
alter table matches drop constraint if exists matches_status_check;
alter table matches add constraint matches_status_check
  check (status in ('pending', 'active', 'complete'));

-- Both participants can see and act on a friend match.
drop policy if exists "Users manage their own matches" on matches;

create policy "Participants can read their matches"
  on matches for select
  to authenticated
  using (auth.uid() = player_id or auth.uid() = opponent_id);

create policy "Players create their own matches"
  on matches for insert
  to authenticated
  with check (auth.uid() = player_id);

create policy "Participants can update their matches"
  on matches for update
  to authenticated
  using (auth.uid() = player_id or auth.uid() = opponent_id);

create policy "Players delete their own matches"
  on matches for delete
  to authenticated
  using (auth.uid() = player_id);

-- The opponent needs to find challenges sent to them.
create index if not exists matches_opponent_idx
  on matches (opponent_id, status, updated_at desc);

-- Realtime so both clients see moves and invites live.
alter publication supabase_realtime add table matches;
