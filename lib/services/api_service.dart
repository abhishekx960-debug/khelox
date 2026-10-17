import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Backend folder URL (HTTPS required, no trailing slash).
const String kApiBaseUrl = 'https://blackxmarket.shop/KheloX/khelox-backend';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final double fcoin;
  final double dcoin;
  final double wcoin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.fcoin = 0,
    this.dcoin = 0,
    this.wcoin = 0,
  });

  static double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: int.parse(j['id'].toString()),
        name: j['name'].toString(),
        email: j['email'].toString(),
        phone: j['phone'].toString(),
        fcoin: _d(j['fcoin']),
        dcoin: _d(j['dcoin']),
        wcoin: _d(j['wcoin']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'fcoin': fcoin,
        'dcoin': dcoin,
        'wcoin': wcoin,
      };
}

class CarouselModel {
  final int id;
  final String title;
  final String image;
  final String moreInfoUrl;

  const CarouselModel({
    required this.id,
    required this.title,
    required this.image,
    required this.moreInfoUrl,
  });

  factory CarouselModel.fromJson(Map<String, dynamic> j) => CarouselModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        title: '${j['title'] ?? ''}',
        image: '${j['image'] ?? ''}',
        moreInfoUrl: '${j['more_info_url'] ?? ''}',
      );
}

class SupportModel {
  final String email;
  final String phone;
  final String whatsapp;
  final String telegram;
  final String note;

  const SupportModel({
    this.email = '',
    this.phone = '',
    this.whatsapp = '',
    this.telegram = '',
    this.note = '',
  });

  factory SupportModel.fromJson(Map<String, dynamic> j) => SupportModel(
        email: '${j['email'] ?? ''}'.trim(),
        phone: '${j['phone'] ?? ''}'.trim(),
        whatsapp: '${j['whatsapp'] ?? ''}'.trim(),
        telegram: '${j['telegram'] ?? ''}'.trim(),
        note: '${j['note'] ?? ''}'.trim(),
      );
}

class ApiService {
  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/$endpoint'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) return data;
      throw ApiException(data['message']?.toString() ?? 'Something went wrong');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Server is slow. Please try again.');
    } on SocketException {
      throw ApiException('Please check your internet connection.');
    } on FormatException {
      throw ApiException('Invalid response from server.');
    }
  }

  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('login.php', {
      'email': email.trim(),
      'password': password,
    });
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _post('register.php', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    });
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<UserModel> fetchUser(int id) async {
    final data = await _post('user.php', {'id': id});
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<List<CarouselModel>> fetchCarousels() async {
    final data = await _post('carousels.php', const {});
    final list = data['carousels'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) CarouselModel.fromJson(item),
    ];
  }

  static Future<SupportModel> fetchSupport() async {
    final data = await _post('support.php', const {});
    final support = data['support'];
    return support is Map<String, dynamic>
        ? SupportModel.fromJson(support)
        : const SupportModel();
  }
}

class SessionService {
  static const _key = 'khelox_user';

  static Future<void> save(UserModel user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}


/// Global realtime user/balance holder.
/// Polls every 10 sec and refreshes on app resume. UI listens via ValueListenableBuilder.
class UserStore with WidgetsBindingObserver {
  UserStore._();
  static final UserStore instance = UserStore._();

  static const _interval = Duration(seconds: 10);

  final ValueNotifier<UserModel?> user = ValueNotifier(null);
  Timer? _timer;
  bool _busy = false;

  void start(UserModel u) {
    user.value = u;
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    user.value = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => refresh());
  }

  /// Game reward / match entry ke baad bhi ye call kar sakte ho.
  /// silent=false → rethrow error (to show a message on pull-to-refresh).
  Future<void> refresh({bool silent = true}) async {
    final u = user.value;
    if (u == null || _busy) return;
    _busy = true;
    try {
      final fresh = await ApiService.fetchUser(u.id);
      if (user.value == null) return; // logged out in the meantime
      user.value = fresh;
      await SessionService.save(fresh);
    } catch (e) {
      debugPrint('UserStore.refresh failed: $e');
      if (!silent) rethrow;
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }
}