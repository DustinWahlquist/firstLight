-- Rarity exists only per-sighting (catch_logs.sighting_rarity: Common /
-- Uncommon / Rare). Species have no rarity tier; drop the leftover column.
alter table bird_species drop column if exists rarity;
