alter table bird_cards
  add column if not exists last_caught_at timestamptz;

-- Backfill from catch_logs for existing cards
update bird_cards bc
set last_caught_at = (
  select max(caught_at)
  from catch_logs cl
  where cl.bird_card_id = bc.id
)
where last_caught_at is null;
