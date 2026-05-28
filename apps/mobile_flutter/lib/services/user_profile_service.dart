import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  UserProfileService._internal();

  static final UserProfileService instance = UserProfileService._internal();
  factory UserProfileService() => instance;

  static const _keyName = 'htm_user_name';
  static const _keyEmail = 'htm_user_email';
  static const _keyWeight = 'htm_user_weight'; // double
  static const _keyHeight = 'htm_user_height'; // double

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get name => _prefs.getString(_keyName) ?? '';
  Future<void> setName(String value) => _prefs.setString(_keyName, value);

  String get email => _prefs.getString(_keyEmail) ?? '';
  Future<void> setEmail(String value) => _prefs.setString(_keyEmail, value);

  double get weight => _prefs.getDouble(_keyWeight) ?? 0.0;
  Future<void> setWeight(double value) => _prefs.setDouble(_keyWeight, value);

  double get height => _prefs.getDouble(_keyHeight) ?? 0.0;
  Future<void> setHeight(double value) => _prefs.setDouble(_keyHeight, value);

  Future<void> resetProfile() async {
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyWeight);
    await _prefs.remove(_keyHeight);
  }
}
