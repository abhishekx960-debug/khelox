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

class FinanceSettings {
  final double dcoinInrRate;
  final double dcoinMinDeposit;
  final double dcoinMaxDeposit;
  final double fcoinInrRate;
  final double fcoinMinWithdraw;
  final double fcoinMaxWithdraw;
  final double wcoinMinWithdraw;
  final double wcoinMaxWithdraw;
  final String depositUpiId;
  final String depositQr;

  const FinanceSettings({
    this.dcoinInrRate = 1,
    this.dcoinMinDeposit = 10,
    this.dcoinMaxDeposit = 100000,
    this.fcoinInrRate = 0.5,
    this.fcoinMinWithdraw = 100,
    this.fcoinMaxWithdraw = 100000,
    this.wcoinMinWithdraw = 100,
    this.wcoinMaxWithdraw = 100000,
    this.depositUpiId = '',
    this.depositQr = '',
  });

  static double _d(dynamic v, double fallback) {
    final parsed = double.tryParse('${v ?? ''}');
    return parsed ?? fallback;
  }

  factory FinanceSettings.fromJson(Map<String, dynamic> j) => FinanceSettings(
        dcoinInrRate: _d(j['dcoin_inr_rate'], 1),
        dcoinMinDeposit: _d(j['dcoin_min_deposit'], 10),
        dcoinMaxDeposit: _d(j['dcoin_max_deposit'], 100000),
        fcoinInrRate: _d(j['fcoin_inr_rate'], 0.5),
        fcoinMinWithdraw: _d(j['fcoin_min_withdraw'], 100),
        fcoinMaxWithdraw: _d(j['fcoin_max_withdraw'], 100000),
        wcoinMinWithdraw: _d(j['wcoin_min_withdraw'], 100),
        wcoinMaxWithdraw: _d(j['wcoin_max_withdraw'], 100000),
        depositUpiId: '${j['deposit_upi_id'] ?? ''}',
        depositQr: '${j['deposit_qr'] ?? ''}',
      );
}

enum TxStatus {
  pending('Pending'),
  approved('Success'),
  rejected('Rejected');

  final String label;
  const TxStatus(this.label);

  static TxStatus parse(dynamic v) {
    switch ('$v') {
      case 'approved':
        return TxStatus.approved;
      case 'rejected':
        return TxStatus.rejected;
    }
    return TxStatus.pending;
  }
}

class DepositModel {
  final int id;
  final double coins;
  final double inrAmount;
  final String utr;
  final String proof;
  final TxStatus status;
  final String rejectReason;
  final DateTime? createdAt;

  const DepositModel({
    required this.id,
    required this.coins,
    required this.inrAmount,
    required this.utr,
    required this.proof,
    required this.status,
    required this.rejectReason,
    this.createdAt,
  });

  factory DepositModel.fromJson(Map<String, dynamic> j) => DepositModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        coins: double.tryParse('${j['coins'] ?? 0}') ?? 0,
        inrAmount: double.tryParse('${j['inr_amount'] ?? 0}') ?? 0,
        utr: '${j['utr'] ?? ''}',
        proof: '${j['proof'] ?? ''}',
        status: TxStatus.parse(j['status']),
        rejectReason: '${j['reject_reason'] ?? ''}',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      );
}

class WithdrawalModel {
  final int id;
  final String type;
  final double amount;
  final String upiId;
  final TxStatus status;
  final String remark;
  final DateTime? createdAt;

  const WithdrawalModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.remark,
    this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> j) => WithdrawalModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        type: '${j['type'] ?? 'fcoin'}',
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        upiId: '${j['upi_id'] ?? ''}',
        status: TxStatus.parse(j['status']),
        remark: '${j['remark'] ?? ''}',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
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
          .timeout(const Duration(seconds: 45));

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

  static Future<FinanceSettings> fetchFinanceSettings() async {
    final data = await _post('settings.php', const {});
    final settings = data['settings'];
    return settings is Map<String, dynamic>
        ? FinanceSettings.fromJson(settings)
        : const FinanceSettings();
  }

  static Future<List<DepositModel>> fetchDeposits(int userId) async {
    final data = await _post('deposits.php', {
      'action': 'history',
      'user_id': userId,
    });
    final list = data['deposits'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) DepositModel.fromJson(item),
    ];
  }

  static Future<DepositModel> createDeposit({
    required int userId,
    required double inrAmount,
    required String utr,
    required String proof,
  }) async {
    final data = await _post('deposits.php', {
      'action': 'create',
      'user_id': userId,
      'inr_amount': inrAmount,
      'utr': utr.trim(),
      'proof': proof,
    });
    return DepositModel.fromJson(data['deposit'] as Map<String, dynamic>);
  }

  static Future<List<WithdrawalModel>> fetchWithdrawals(int userId) async {
    final data = await _post('withdrawals.php', {
      'action': 'history',
      'user_id': userId,
    });
    final list = data['withdrawals'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) WithdrawalModel.fromJson(item),
    ];
  }

  static Future<WithdrawalModel> createWithdrawal({
    required int userId,
    required String type,
    required double amount,
    required String upiId,
  }) async {
    final data = await _post('withdrawals.php', {
      'action': 'create',
      'user_id': userId,
      'type': type,
      'amount': amount,
      'upi_id': upiId.trim(),
    });
    return WithdrawalModel.fromJson(
      data['withdrawal'] as Map<String, dynamic>,
    );
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