enum Rarity {
  common,
  somewhatRare,
  ultraRare;

  int get xpPerCatch => switch (this) {
        Rarity.common => 5,
        Rarity.somewhatRare => 10,
        Rarity.ultraRare => 15,
      };

  String get label => switch (this) {
        Rarity.common => 'Common',
        Rarity.somewhatRare => 'Somewhat Rare',
        Rarity.ultraRare => 'Ultra Rare',
      };

  static Rarity fromString(String value) => switch (value.toLowerCase()) {
        'somewhat rare' || 'somewhat_rare' => Rarity.somewhatRare,
        'ultra rare' || 'ultra_rare' => Rarity.ultraRare,
        _ => Rarity.common,
      };
}
