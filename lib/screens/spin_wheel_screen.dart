import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/khelox_app_bar.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  static const _rewards = <int>[10, 25, 5, 50, 100, 0, 200, 20];
  static const _colors = <Color>[AppColors.gold, AppColors.cyan];

  late final AnimationController _ctrl;
  Animation<double> _anim = const AlwaysStoppedAnimation(0.0);
  double _angle = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addListener(() {
        setState(() => _angle = _anim.value);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _indexAt(double angle) {
    const n = 8;
    const seg = 2 * math.pi / n;
    var a = (-math.pi / 2 - angle) % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    return (a / seg).floor() % n;
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final rnd = math.Random();
    final start = _angle;
    final end = start +
        2 * math.pi * (5 + rnd.nextInt(3)) +
        rnd.nextDouble() * 2 * math.pi;
    _anim = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    setState(() => _spinning = true);
    _ctrl.reset();
    await _ctrl.forward();
    if (!mounted) return;
    setState(() {
      _angle = _anim.value;
      _spinning = false;
    });
    _showResult(_rewards[_indexAt(_angle)]);
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
      appBar: const KheloxAppBar('Spin Wheel'),
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
            onPressed: _spinning ? null : _spin,
            child: Text(_spinning ? 'SPINNING...' : 'SPIN'),
          ),
        ],
      ),
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
