-- Rarity is a per-sighting concept (time of year + geography via Merlin),
-- not a property of the species itself. Drop the column from bird_cards.
alter table bird_cards drop column if exists rarity;
