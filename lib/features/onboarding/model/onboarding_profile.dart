import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_period_app/core/utils/date_time_utils.dart';

enum AppGender { female, male, other }

enum AppMode { solo, couple }

extension AppGenderLabel on AppGender {
  String get label {
    switch (this) {
      case AppGender.female:
        return 'Female';
      case AppGender.male:
        return 'Male';
      case AppGender.other:
        return 'Other';
    }
  }
}

extension AppModeLabel on AppMode {
  String get label {
    switch (this) {
      case AppMode.solo:
        return 'Solo';
      case AppMode.couple:
        return 'Couple';
    }
  }
}

class OnboardingProfile {
  const OnboardingProfile({
    this.name = '',
    this.gender = AppGender.female,
    this.mode = AppMode.solo,
    this.relationshipStatus,
    required this.lastPeriodDate,
    this.cycleLength = 28,
    this.periodDuration = 5,
    this.symptomsEnabled = true,
    this.moodEnabled = true,
    this.notificationsEnabled = true,
    required this.timezone,
    required this.timezoneOffsetMinutes,
    this.partnerId,
    this.generatedInviteCode,
    this.onboardingCompleted = false,
  });

  final String name;
  final AppGender gender;
  final AppMode mode;
  final String? relationshipStatus;
  final DateTime lastPeriodDate;
  final int cycleLength;
  final int periodDuration;
  final bool symptomsEnabled;
  final bool moodEnabled;
  final bool notificationsEnabled;
  final String timezone;
  final int timezoneOffsetMinutes;
  final String? partnerId;
  final String? generatedInviteCode;
  final bool onboardingCompleted;

  factory OnboardingProfile.initial() {
    final now = DateTime.now();
    return OnboardingProfile(
      lastPeriodDate: DateTime(now.year, now.month, now.day),
      timezone: now.timeZoneName,
      timezoneOffsetMinutes: DateTimeUtils.timezoneOffsetMinutesNow(),
    );
  }

  OnboardingProfile copyWith({
    String? name,
    AppGender? gender,
    AppMode? mode,
    String? relationshipStatus,
    DateTime? lastPeriodDate,
    int? cycleLength,
    int? periodDuration,
    bool? symptomsEnabled,
    bool? moodEnabled,
    bool? notificationsEnabled,
    String? timezone,
    int? timezoneOffsetMinutes,
    String? partnerId,
    String? generatedInviteCode,
    bool? onboardingCompleted,
  }) {
    return OnboardingProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      mode: mode ?? this.mode,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      symptomsEnabled: symptomsEnabled ?? this.symptomsEnabled,
      moodEnabled: moodEnabled ?? this.moodEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      timezone: timezone ?? this.timezone,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      partnerId: partnerId ?? this.partnerId,
      generatedInviteCode: generatedInviteCode ?? this.generatedInviteCode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toUserMap() {
    return {
      'name': name,
      'gender': gender.name,
      'mode': mode.name,
      'relationshipStatus': relationshipStatus,
      'notificationsEnabled': notificationsEnabled,
      'timezone': timezone,
      'timezoneOffsetMinutes': timezoneOffsetMinutes,
      'partnerId': partnerId,
      'generatedInviteCode': generatedInviteCode,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCycleSettingsMap() {
    return {
      'lastPeriodDate': Timestamp.fromDate(
        DateTimeUtils.toUtcDate(lastPeriodDate),
      ),
      'cycleLength': cycleLength,
      'periodDuration': periodDuration,
      'symptomsEnabled': symptomsEnabled,
      'moodEnabled': moodEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
