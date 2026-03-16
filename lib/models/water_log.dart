class WaterLog {
  final int? id;
  final DateTime date;
  final String time;
  final int amountMl;
  final String drinkType;
  final String? note;

  WaterLog({
    this.id,
    required this.date,
    required this.time,
    required this.amountMl,
    required this.drinkType,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'amount_ml': amountMl,
      'drink_type': drinkType,
      'note': note ?? '',
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      amountMl: map['amount_ml'],
      drinkType: map['drink_type'],
      note: map['note'],
    );
  }

  WaterLog copyWith({
    int? id,
    DateTime? date,
    String? time,
    int? amountMl,
    String? drinkType,
    String? note,
  }) {
    return WaterLog(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      amountMl: amountMl ?? this.amountMl,
      drinkType: drinkType ?? this.drinkType,
      note: note ?? this.note,
    );
  }
}
