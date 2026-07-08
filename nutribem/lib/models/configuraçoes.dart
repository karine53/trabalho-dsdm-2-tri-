class AppSettings {
  final int? id;
  bool notificationsEnabled;
  bool waterReminderEnabled;
  bool dailySummaryEnabled;
  String breakfastTime;
  String lunchTime;
  String snackTime;
  String dinnerTime;

  AppSettings({
    this.id = 1,
    this.notificationsEnabled = true,
    this.waterReminderEnabled = true,
    this.dailySummaryEnabled = false,
    this.breakfastTime = '07:30',
    this.lunchTime = '12:00',
    this.snackTime = '15:30',
    this.dinnerTime = '19:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'waterReminderEnabled': waterReminderEnabled ? 1 : 0,
      'dailySummaryEnabled': dailySummaryEnabled ? 1 : 0,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'snackTime': snackTime,
      'dinnerTime': dinnerTime,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      notificationsEnabled: map['notificationsEnabled'] == 1,
      waterReminderEnabled: map['waterReminderEnabled'] == 1,
      dailySummaryEnabled: map['dailySummaryEnabled'] == 1,
      breakfastTime: map['breakfastTime'] ?? '07:30',
      lunchTime: map['lunchTime'] ?? '12:00',
      snackTime: map['snackTime'] ?? '15:30',
      dinnerTime: map['dinnerTime'] ?? '19:00',
    );
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? waterReminderEnabled,
    bool? dailySummaryEnabled,
    String? breakfastTime,
    String? lunchTime,
    String? snackTime,
    String? dinnerTime,
  }) {
    return AppSettings(
      id: this.id,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      snackTime: snackTime ?? this.snackTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
    );
  }
}
