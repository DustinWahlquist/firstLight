-- CMS content management: status workflow, per-level stats/art, moves,
-- user reports, and an admin allowlist. The CMS signs in with Supabase Auth
-- like any user; write access is gated on cms_admins membership because app
-- players authenticate against the same project.

-- ── Content workflow columns on bird_species ─────────────────────
alter table bird_species
  add column if not exists status text not null default 'new'
    check (status in ('new', 'needs_review', 'draft', 'published')),
  add column if not exists speed_delta int not null default 0,
  add column if not exists endurance_delta int not null default 0,
  add column if not exists art_by_level jsonb not null default '{}'::jsonb;

-- ── Moves (authored per species, up to 3, unlocked at levels 1/3/5) ──
create table if not exists species_moves (
  id uuid primary key default gen_random_uuid(),
  species_name text not null references bird_species(species_name) on delete cascade,
  move_name text not null,
  category text not null check (category in ('Offense', 'Defense', 'Support')),
  description text not null default '',
  effect_type text not null default '',
  effect_value int not null default 0,
  unlock_level int not null check (unlock_level in (1, 3, 5)),
  created_at timestamptz not null default now()
);

-- ── User-filed reports on species content ─────────────────────────
create table if not exists species_reports (
  id uuid primary key default gen_random_uuid(),
  species_name text not null references bird_species(species_name) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  message text not null,
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);

-- ── Admin allowlist ────────────────────────────────────────────────
create table if not exists cms_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Locked down: only the security-definer helper below reads it.
alter table cms_admins enable row level security;

create or replace function is_cms_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from cms_admins where user_id = auth.uid());
$$;

-- ── RLS ────────────────────────────────────────────────────────────
alter table species_moves enable row level security;
alter table species_reports enable row level security;

create policy "Admins can manage bird_species"
  on bird_species for all
  to authenticated
  using (is_cms_admin())
  with check (is_cms_admin());

create policy "Authenticated users can read species_moves"
  on species_moves for select
  to authenticated
  using (true);

create policy "Admins can manage species_moves"
  on species_moves for all
  to authenticated
  using (is_cms_admin())
  with check (is_cms_admin());

create policy "Users can file reports"
  on species_reports for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users and admins can read reports"
  on species_reports for select
  to authenticated
  using (auth.uid() = user_id or is_cms_admin());

create policy "Admins can update reports"
  on species_reports for update
  to authenticated
  using (is_cms_admin());

create policy "Admins can delete reports"
  on species_reports for delete
  to authenticated
  using (is_cms_admin());

-- Stats dashboard: admins can read player data
create policy "Admins can read all bird cards"
  on bird_cards for select
  to authenticated
  using (is_cms_admin());

create policy "Admins can read all catch logs"
  on catch_logs for select
  to authenticated
  using (is_cms_admin());

-- ── A new report escalates the species to Needs Review ────────────
create or replace function escalate_species_on_report()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  update bird_species
  set status = 'needs_review'
  where species_name = new.species_name and status <> 'needs_review';
  return new;
end;
$$;

drop trigger if exists on_species_report_created on species_reports;
create trigger on_species_report_created
  after insert on species_reports
  for each row execute function escalate_species_on_report();

-- ── Storage bucket for per-level species art ───────────────────────
insert into storage.buckets (id, name, public)
values ('species-art', 'species-art', true)
on conflict (id) do nothing;

create policy "Species art is publicly readable"
  on storage.objects for select
  using (bucket_id = 'species-art');

create policy "Admins can upload species art"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'species-art' and is_cms_admin());

create policy "Admins can update species art"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'species-art' and is_cms_admin());

create policy "Admins can delete species art"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'species-art' and is_cms_admin());

-- ── Seed the first admin ───────────────────────────────────────────
insert into cms_admins (user_id)
select id from auth.users where email = 'dustin.wahlquist@gmail.com'
on conflict do nothing;
