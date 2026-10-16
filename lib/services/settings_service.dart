import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kNotif = 'khelox_notifications';

  static Future<bool> notificationsOn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotif) ?? true;
  }

  static Future<void> setNotifications(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotif, v);
  }
}