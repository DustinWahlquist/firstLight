-- Move the catch-logging game rules server-side. Clients lose direct write
-- access to bird_cards / catch_logs / feed_events; the log_catch RPC is the
-- only way to record a catch, so XP and levels can't be tampered with.
--
-- The rules here mirror app/lib/domain/game_rules.dart and
-- sighting_rarity.dart — keep them in sync.

-- ── Game rules ─────────────────────────────────────────────────────
create or replace function xp_for_sighting_rarity(p_rarity text)
returns int
language sql immutable
as $$
  select case lower(trim(p_rarity))
    when 'uncommon' then 10
    when 'rare' then 15
    else 5
  end;
$$;

create or replace function level_for_xp(p_xp int)
returns int
language sql immutable
as $$
  select case
    when p_xp >= 140 then 5
    when p_xp >= 90 then 4
    when p_xp >= 50 then 3
    when p_xp >= 20 then 2
    else 1
  end;
$$;

-- ── The catch transaction ──────────────────────────────────────────
create or replace function log_catch(
  p_species_name text,
  p_scientific_name text,
  p_sighting_rarity text,
  p_caught_at timestamptz,
  p_location text,
  p_latitude double precision,
  p_longitude double precision,
  p_description text,
  p_facts text[],
  p_migration_speed int,
  p_endurance int,
  p_screenshot_url text,
  p_line_art_url text
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_card bird_cards%rowtype;
  v_updated bird_cards%rowtype;
  v_xp int;
  v_new_xp int;
  v_new_level int;
  v_lifers int;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  -- Catch date comes from the screenshot, but may never be in the future.
  if p_caught_at::date > current_date then
    return jsonb_build_object('kind', 'future_dated');
  end if;

  select * into v_card from bird_cards
  where user_id = v_user and species_name = p_species_name;

  if found then
    -- One catch per bird per calendar day.
    if exists (
      select 1 from catch_logs
      where user_id = v_user
        and bird_card_id = v_card.id
        and caught_at::date = p_caught_at::date
    ) then
      return jsonb_build_object('kind', 'duplicate');
    end if;

    v_xp := xp_for_sighting_rarity(p_sighting_rarity);
    v_new_xp := v_card.xp + v_xp;
    v_new_level := level_for_xp(v_new_xp);

    update bird_cards
    set xp = v_new_xp,
        level = v_new_level,
        catch_count = catch_count + 1,
        last_caught_at = p_caught_at
    where id = v_card.id
    returning * into v_updated;

    insert into catch_logs (user_id, bird_card_id, caught_at, screenshot_url,
                            sighting_rarity, location, latitude, longitude, xp_awarded)
    values (v_user, v_card.id, p_caught_at, p_screenshot_url,
            p_sighting_rarity, p_location, p_latitude, p_longitude, v_xp);

    insert into feed_events (user_id, type, bird_card_id, species_name,
                             line_art_url, xp_awarded, sighting_rarity)
    values (v_user, 'catch', v_card.id, v_card.species_name,
            v_card.line_art_url, v_xp, p_sighting_rarity);

    if v_new_level > v_card.level then
      insert into feed_events (user_id, type, bird_card_id, species_name,
                               line_art_url, level)
      values (v_user, 'level_up', v_card.id, v_card.species_name,
              v_card.line_art_url, v_new_level);
    end if;

    return jsonb_build_object(
      'kind', 'xp_awarded',
      'previous_level', v_card.level,
      'xp_awarded', v_xp,
      'card', to_jsonb(v_updated)
    );
  else
    insert into bird_cards (user_id, species_name, scientific_name, level, xp,
                            catch_count, first_catch_date, first_catch_location,
                            first_catch_latitude, first_catch_longitude,
                            description, facts, migration_speed, endurance,
                            screenshot_url, line_art_url, last_caught_at)
    values (v_user, p_species_name, coalesce(p_scientific_name, ''), 1, 0,
            1, p_caught_at::date, coalesce(p_location, ''),
            p_latitude, p_longitude,
            coalesce(p_description, ''), coalesce(p_facts, '{}'),
            coalesce(p_migration_speed, 5), coalesce(p_endurance, 3),
            p_screenshot_url, p_line_art_url, p_caught_at)
    returning * into v_card;

    insert into catch_logs (user_id, bird_card_id, caught_at, screenshot_url,
                            sighting_rarity, location, latitude, longitude, xp_awarded)
    values (v_user, v_card.id, p_caught_at, p_screenshot_url,
            p_sighting_rarity, p_location, p_latitude, p_longitude, 0);

    insert into feed_events (user_id, type, bird_card_id, species_name,
                             line_art_url, sighting_rarity)
    values (v_user, 'new_lifer', v_card.id, p_species_name,
            p_line_art_url, p_sighting_rarity);

    select count(*) into v_lifers from bird_cards where user_id = v_user;
    if v_lifers in (10, 25, 50, 100, 250, 500) then
      insert into feed_events (user_id, type, milestone_value, milestone_type)
      values (v_user, 'milestone', v_lifers, 'lifers');
    end if;

    return jsonb_build_object('kind', 'new_lifer', 'card', to_jsonb(v_card));
  end if;
end;
$$;

revoke all on function log_catch(text, text, text, timestamptz, text,
  double precision, double precision, text, text[], int, int, text, text)
  from public, anon;
grant execute on function log_catch(text, text, text, timestamptz, text,
  double precision, double precision, text, text[], int, int, text, text)
  to authenticated;

-- ── Clients become read-only on game-state tables ──────────────────
drop policy "Users can manage their own bird cards" on bird_cards;
create policy "Users can view their own bird cards"
  on bird_cards for select
  using (auth.uid() = user_id);

drop policy "Users can manage their own catch logs" on catch_logs;
create policy "Users can view their own catch logs"
  on catch_logs for select
  using (auth.uid() = user_id);

-- All feed events are now emitted by log_catch.
drop policy "Users can insert their own feed events" on feed_events;

-- ── Data repair ────────────────────────────────────────────────────
-- Before the rarity fix, Uncommon/Rare sightings were mis-awarded 5 XP.
-- Re-award repeat catches at the correct rate and recompute card totals.
update catch_logs
set xp_awarded = xp_for_sighting_rarity(sighting_rarity)
where xp_awarded > 0
  and xp_awarded <> xp_for_sighting_rarity(sighting_rarity);

update bird_cards bc
set xp = coalesce(
  (select sum(cl.xp_awarded) from catch_logs cl where cl.bird_card_id = bc.id), 0);

update bird_cards set level = level_for_xp(xp);
