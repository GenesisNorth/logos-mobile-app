import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileData {
  final String username;
  final String displayName;
  final String? covenantSignature;
  final DateTime? covenantSignedAt;
  final int birthMonth;
  final int birthDay;

  const UserProfileData({
    required this.username,
    required this.displayName,
    this.covenantSignature,
    this.covenantSignedAt,
    this.birthMonth = 1,
    this.birthDay = 1,
  });

  bool get hasSignedCovenant => covenantSignature != null && covenantSignature!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'username': username,
    'displayName': displayName,
    'covenantSignature': covenantSignature,
    'covenantSignedAt': covenantSignedAt?.toIso8601String(),
    'birthMonth': birthMonth,
    'birthDay': birthDay,
  };

  factory UserProfileData.fromJson(Map<String, dynamic> json) => UserProfileData(
    username: json['username'] as String? ?? 'seeker',
    displayName: json['displayName'] as String? ?? 'Beloved Pilgrim',
    covenantSignature: json['covenantSignature'] as String?,
    covenantSignedAt: json['covenantSignedAt'] != null
        ? DateTime.tryParse(json['covenantSignedAt'] as String)
        : null,
    birthMonth: json['birthMonth'] as int? ?? 1,
    birthDay: json['birthDay'] as int? ?? 1,
  );
}

class TearSheetData {
  final String id;
  final String dropId;
  final String verseText;
  final String reference;
  final String burdenHash;
  final String? tearSheetImagePath;
  final DateTime completedAt;

  const TearSheetData({
    required this.id,
    required this.dropId,
    required this.verseText,
    required this.reference,
    required this.burdenHash,
    this.tearSheetImagePath,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dropId': dropId,
    'verseText': verseText,
    'reference': reference,
    'burdenHash': burdenHash,
    'tearSheetImagePath': tearSheetImagePath,
    'completedAt': completedAt.toIso8601String(),
  };

  factory TearSheetData.fromJson(Map<String, dynamic> json) => TearSheetData(
    id: json['id'] as String,
    dropId: json['dropId'] as String,
    verseText: json['verseText'] as String,
    reference: json['reference'] as String,
    burdenHash: json['burdenHash'] as String,
    tearSheetImagePath: json['tearSheetImagePath'] as String?,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}

abstract class ProgressRepository {
  Future<UserProfileData> loadProfile();
  Future<void> saveProfile(UserProfileData profile);

  Future<Map<String, dynamic>> loadJourneyData();
  Future<void> saveJourneyData(Map<String, dynamic> data);

  Future<List<TearSheetData>> loadTearSheets();
  Future<void> saveTearSheet(TearSheetData sheet);
}

class LocalProgressRepository implements ProgressRepository {
  static const _profileKey = 'logos_user_profile';
  static const _journeyKey = 'logos_journey_data';
  static const _tearSheetsKey = 'logos_tear_sheets';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<UserProfileData> loadProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_profileKey);
    if (raw == null) {
      return const UserProfileData(
        username: 'pilgrim',
        displayName: 'Genesis A.',
      );
    }
    try {
      return UserProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfileData(
        username: 'pilgrim',
        displayName: 'Genesis A.',
      );
    }
  }

  @override
  Future<void> saveProfile(UserProfileData profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<Map<String, dynamic>> loadJourneyData() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_journeyKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveJourneyData(Map<String, dynamic> data) async {
    final prefs = await _getPrefs();
    await prefs.setString(_journeyKey, jsonEncode(data));
  }

  @override
  Future<List<TearSheetData>> loadTearSheets() async {
    final prefs = await _getPrefs();
    final list = prefs.getStringList(_tearSheetsKey);
    if (list == null) return [];
    return list.map((item) => TearSheetData.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveTearSheet(TearSheetData sheet) async {
    final prefs = await _getPrefs();
    final list = prefs.getStringList(_tearSheetsKey) ?? [];
    list.add(jsonEncode(sheet.toJson()));
    await prefs.setStringList(_tearSheetsKey, list);
  }
}
