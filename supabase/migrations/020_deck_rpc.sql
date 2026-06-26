-- Deck membership is the only client-writable field on a bird card; everything
-- else (xp, level, catch_count) stays server-authoritative via log_catch.
-- bird_cards has no client UPDATE policy, so toggling in_deck goes through this
-- focused SECURITY DEFINER function, scoped to the caller's own cards.
create or replace function set_card_in_deck(p_card_id uuid, p_in_deck boolean)
returns void
language sql
security definer
set search_path = public
as $$
  update bird_cards
     set in_deck = p_in_deck
   where id = p_card_id
     and user_id = auth.uid();
$$;

grant execute on function set_card_in_deck(uuid, boolean) to authenticated;
