class DrinkType {
  final int? id;
  final String name;
  final String emoji;
  final String colorHex;

  DrinkType({
    this.id,
    required this.name,
    required this.emoji,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color_hex': colorHex,
    };
  }

  factory DrinkType.fromMap(Map<String, dynamic> map) {
    return DrinkType(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      colorHex: map['color_hex'],
    );
  }
}
