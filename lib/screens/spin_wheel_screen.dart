import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Fallback only. Server sends the real list (same order).
  static const _defaultRewards = <int>[10, 25, 5, 50, 100, 0, 200, 20];
  static const _colors = <Color>[AppColors.gold, AppColors.cyan];

  late final AnimationController _ctrl;
  Animation<double> _anim = const AlwaysStoppedAnimation(0.0);
  double _angle = 0;
  bool _spinning = false;
  bool _requesting = false;

  List<int> _rewards = _defaultRewards;
  SpinStatus? _status;
  bool _loading = true;
  String? _loadError;

  // Countdown uses Stopwatch (monotonic), NOT device date/time.
  // Base seconds come from server; device clock change cannot affect it.
  final Stopwatch _sw = Stopwatch();
  int _baseResetSecs = 0;
  Timer? _tick;
  bool _resyncing = false;

  int get _userId => UserStore.instance.user.value?.id ?? 0;
  int get _remaining => _status?.remaining ?? 0;
  int get _limit => _status?.limit ?? 10;

  int get _secsLeft {
    final left = _baseResetSecs - _sw.elapsed.inSeconds;
    return left < 0 ? 0 : left;
  }

  bool get _limitReached => _status != null && _remaining <= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addListener(() {
        setState(() => _angle = _anim.value);
      });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_spinning) _loadStatus();
  }

  void _applyStatus(SpinStatus st) {
    _status = st;
    if (st.rewards.length >= 2) _rewards = st.rewards;
    _baseResetSecs = st.resetIn;
    _sw
      ..reset()
      ..start();
  }

  Future<void> _loadStatus() async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      final st = await ApiService.fetchSpinStatus(_userId);
      if (!mounted) return;
      setState(() {
        _applyStatus(st);
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_status == null) _loadError = e.toString();
      });
    } finally {
      _resyncing = false;
    }
  }

  void _onTick() {
    if (!mounted) return;
    // Limit window finished -> ask server for fresh limit.
    if (_limitReached && _secsLeft == 0 && !_spinning) {
      _loadStatus();
    }
    if (_limitReached) setState(() {});
  }

  String _fmt(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _spin() async {
    if (_spinning || _requesting || _limitReached) return;
    setState(() => _requesting = true);

    // Server decides reward + enforces limit.
    SpinResult result;
    try {
      result = await ApiService.spinWheel(_userId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
      _loadStatus(); // limit might have changed
      return;
    }
    if (!mounted) return;

    if (result.status.rewards.length >= 2) _rewards = result.status.rewards;
    final n = _rewards.length;
    final idx = result.index.clamp(0, n - 1);
    final seg = 2 * math.pi / n;
    final rnd = math.Random();

    // Land pointer inside segment [idx], away from the edges.
    final inSeg = seg * (0.15 + rnd.nextDouble() * 0.7);
    final target = -math.pi / 2 - (idx * seg + inSeg);
    final start = _angle;
    var delta = (target - start) % (2 * math.pi);
    if (delta < 0) delta += 2 * math.pi;
    final end = start + 2 * math.pi * (5 + rnd.nextInt(3)) + delta;

    _anim = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    setState(() {
      _requesting = false;
      _spinning = true;
      // spins left / timer update right away (server truth)
      _applyStatus(result.status);
    });
    _ctrl.reset();
    await _ctrl.forward();
    if (!mounted) return;
    setState(() {
      _angle = _anim.value;
      _spinning = false;
    });
    UserStore.instance.refresh(); // top-right Fcoin chip updates
    _showResult(result.reward);
  }

  void _showResult(int reward) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardAlt,
        title: Text(
          reward > 0 ? 'You won $reward Fcoin!' : 'Better luck next time',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          reward > 0
              ? 'Your reward has been added. Spin again!'
              : 'No reward this time. Give it another go!',
          style: const TextStyle(color: AppColors.mist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KheloxAppBar(
        'Spin Wheel',
        actions: [
          ValueListenableBuilder<UserModel?>(
            valueListenable: UserStore.instance.user,
            builder: (_, u, __) =>
                CoinChip(type: CoinType.fcoin, value: u?.fcoin ?? 0),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Spin the wheel and win Fcoin rewards.',
            style: TextStyle(color: AppColors.mist, fontSize: 14.5),
          ),
          const SizedBox(height: 26),
          Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(290, 290),
                    painter: _WheelPainter(
                      rewards: _rewards,
                      colors: _colors,
                      rotation: _angle,
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navy,
                      border: Border.all(color: AppColors.gold, width: 3),
                    ),
                    child: const Icon(
                      Icons.album_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  ),
                  const Positioned(
                    top: 0,
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.gold,
                      size: 46,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: (_spinning || _requesting || _loading || _limitReached)
                ? null
                : _spin,
            child: Text(
              _spinning || _requesting
                  ? 'SPINNING...'
                  : _limitReached
                      ? 'LIMIT REACHED'
                      : 'SPIN',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfo(),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (_status == null) {
      return Column(
        children: [
          Text(
            _loadError ?? 'Could not load spins.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mist, fontSize: 13.5),
          ),
          TextButton(onPressed: _loadStatus, child: const Text('Retry')),
        ],
      );
    }
    return Column(
      children: [
        Text(
          'Spins left: $_remaining / $_limit',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        if (_limitReached) ...[
          const SizedBox(height: 10),
          const Text(
            'Limit resets in',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mist, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(_secsLeft),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              color: AppColors.gold,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;
  final double rotation;

  _WheelPainter({
    required this.rewards,
    required this.colors,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final n = rewards.length;
    final seg = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final divider = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final start = rotation + i * seg;
      canvas.drawArc(rect, start, seg, true, Paint()..color = colors[i % colors.length]);
      final edge = center +
          Offset(math.cos(start) * radius, math.sin(start) * radius);
      canvas.drawLine(center, edge, divider);

      final mid = start + seg / 2;
      final label = rewards[i] == 0 ? 'Try' : '${rewards[i]}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: AppFonts.heading,
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(
        center.dx + math.cos(mid) * radius * 0.66,
        center.dy + math.sin(mid) * radius * 0.66,
      );
      canvas.rotate(mid);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.rotation != rotation;
}