-- ── Friendships ──────────────────────────────────────────────────
create table friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  unique (requester_id, addressee_id)
);

alter table friendships enable row level security;

create policy "Users can see friendships they are part of"
  on friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users can send friend requests"
  on friendships for insert
  with check (auth.uid() = requester_id);

create policy "Users can update friendships they are part of"
  on friendships for update
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users can delete friendships they are part of"
  on friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ── Feed events ───────────────────────────────────────────────────
create table feed_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('new_lifer', 'catch', 'level_up', 'milestone')),
  bird_card_id uuid references bird_cards(id) on delete set null,
  species_name text,
  line_art_url text,
  xp_awarded int,
  sighting_rarity text,
  level int,
  milestone_value int,
  milestone_type text,
  created_at timestamptz not null default now()
);

alter table feed_events enable row level security;

create policy "Users can see their own feed events"
  on feed_events for select
  using (auth.uid() = user_id);

create policy "Friends can see each other's feed events"
  on feed_events for select
  using (
    exists (
      select 1 from friendships
      where status = 'accepted'
        and (
          (requester_id = auth.uid() and addressee_id = feed_events.user_id)
          or (addressee_id = auth.uid() and requester_id = feed_events.user_id)
        )
    )
  );

create policy "Users can insert their own feed events"
  on feed_events for insert
  with check (auth.uid() = user_id);

-- ── Pecks ─────────────────────────────────────────────────────────
create table pecks (
  user_id uuid not null references auth.users(id) on delete cascade,
  feed_event_id uuid not null references feed_events(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, feed_event_id)
);

alter table pecks enable row level security;

create policy "Pecks are publicly readable"
  on pecks for select using (true);

create policy "Users can manage their own pecks"
  on pecks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Scribbles (comments) ──────────────────────────────────────────
create table scribbles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feed_event_id uuid not null references feed_events(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

alter table scribbles enable row level security;

create policy "Scribbles are publicly readable"
  on scribbles for select using (true);

create policy "Users can manage their own scribbles"
  on scribbles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── delete_user RPC ───────────────────────────────────────────────
create or replace function delete_user()
returns void language plpgsql security definer as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;
