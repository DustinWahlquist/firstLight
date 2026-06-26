-- A player's deck is the subset of their collection they take into a match.
-- Membership is a flag on the card; the deck is simply bird_cards.in_deck = true.
alter table bird_cards
  add column if not exists in_deck boolean not null default false;

create index if not exists bird_cards_in_deck_idx
  on bird_cards (user_id) where in_deck;
