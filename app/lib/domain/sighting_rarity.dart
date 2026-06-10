/// Rarity of a single sighting as reported by Merlin for the time of year
/// and location. Rarity belongs to the sighting, not the species.
///
/// XP per catch is enforced server-side by xp_for_sighting_rarity in
/// supabase/migrations/014_server_side_catch.sql — keep the two in sync.
enum SightingRarity {
  common,
  uncommon,
  rare;

  int get xpPerCatch => switch (this) {
        SightingRarity.common => 5,
        SightingRarity.uncommon => 10,
        SightingRarity.rare => 15,
      };

  String get label => switch (this) {
        SightingRarity.common => 'Common',
        SightingRarity.uncommon => 'Uncommon',
        SightingRarity.rare => 'Rare',
      };

  static SightingRarity fromString(String value) =>
      switch (value.trim().toLowerCase()) {
        'uncommon' => SightingRarity.uncommon,
        'rare' => SightingRarity.rare,
        _ => SightingRarity.common,
      };
}
