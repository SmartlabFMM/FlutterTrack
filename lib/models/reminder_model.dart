class ReminderModel {
  final String id;
  final int    hour;
  final int    minute;
  final String label;
  final bool   isActive;

  const ReminderModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.isActive = true,
  });

  String get timeLabel {
    final period = hour < 12 ? 'AM' : 'PM';
    final h      = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m      = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  ReminderModel copyWith({
    String? label, int? hour, int? minute, bool? isActive}) =>
    ReminderModel(
      id: id,
      label:    label    ?? this.label,
      hour:     hour     ?? this.hour,
      minute:   minute   ?? this.minute,
      isActive: isActive ?? this.isActive,
    );

  Map<String, dynamic> toJson() => {
    'id': id, 'hour': hour, 'minute': minute,
    'label': label, 'isActive': isActive,
  };

  factory ReminderModel.fromJson(Map<String, dynamic> j) => ReminderModel(
    id:       j['id'] as String,
    hour:     j['hour'] as int,
    minute:   j['minute'] as int,
    label:    j['label'] as String,
    isActive: j['isActive'] as bool? ?? true,
  );
}
