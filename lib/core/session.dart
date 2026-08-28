import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? token;
  static String fullName = '';
  static String phone = '';
  static bool hasPin = false;

  static const _kToken = 'mb_token';
  static const _kName = 'mb_name';
  static const _kPhone = 'mb_phone';
  static const _kHasPin = 'mb_has_pin';

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_kToken);
    } else {
      await prefs.setString(_kToken, token!);
    }
    await prefs.setString(_kName, fullName);
    await prefs.setString(_kPhone, phone);
    await prefs.setBool(_kHasPin, hasPin);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kToken);
    fullName = prefs.getString(_kName) ?? '';
    phone = prefs.getString(_kPhone) ?? '';
    hasPin = prefs.getBool(_kHasPin) ?? false;
  }

  static Future<void> clear() async {
    token = null;
    fullName = '';
    phone = '';
    hasPin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kName);
    await prefs.remove(_kPhone);
    await prefs.remove(_kHasPin);
  }

  static String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isEmpty || parts.first.isEmpty ? 'друг' : parts.first;
  }

  static String get initials {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
