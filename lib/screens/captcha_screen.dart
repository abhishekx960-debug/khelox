import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/khelox_app_bar.dart';

class CaptchaScreen extends StatefulWidget {
  const CaptchaScreen({super.key});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  static const _chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _palette = <Color>[
    AppColors.gold,
    AppColors.cyan,
    Color(0xFF6FB3A8),
  ];

  final _input = TextEditingController();
  final _rnd = math.Random();
  String _code = '';
  List<double> _angles = const [];
  List<Color> _colors = const [];

  @override
  void initState() {
    super.initState();
    _newCode();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _newCode() {
    final buf = StringBuffer();
    for (var i = 0; i < 5; i++) {
      buf.write(_chars[_rnd.nextInt(_chars.length)]);
    }
    setState(() {
      _code = buf.toString();
      _angles = List.generate(5, (_) => (_rnd.nextDouble() - 0.5) * 0.6);
      _colors = List.generate(
        5,
        (_) => _palette[_rnd.nextInt(_palette.length)],
      );
      _input.clear();
    });
  }

  void _verify() {
    final v = _input.text.trim().toUpperCase();
    if (v.isEmpty) {
      showMsg(context, 'Please enter the captcha code');
      return;
    }
    if (v == _code) {
      showMsg(context, 'Verified! You earned 15 Fcoin');
      _newCode();
    } else {
      showMsg(context, 'Incorrect captcha. Try again');
      _newCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Captcha'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Verify you are human to earn Fcoin.',
            style: TextStyle(color: AppColors.mist, fontSize: 14.5),
          ),
          const SizedBox(height: 24),
          Container(
            height: 112,
            clipBehavior: Clip.antiAlias,
            decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CaptchaNoisePainter()),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _code.length; i++)
                        Transform.rotate(
                          angle: _angles[i],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              _code[i],
                              style: TextStyle(
                                color: _colors[i],
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    tooltip: 'New code',
                    onPressed: _newCode,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.mist,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _input,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, letterSpacing: 4),
            decoration: const InputDecoration(
              labelText: 'Enter code',
              prefixIcon: Icon(Icons.verified_user_rounded),
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _verify, child: const Text('VERIFY')),
        ],
      ),
    );
  }
}

class _CaptchaNoisePainter extends CustomPainter {
  final math.Random _rnd = math.Random();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height),
        Offset(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height),
        linePaint,
      );
    }
    final dotPaint = Paint()..color = AppColors.mist.withValues(alpha: 0.25);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
