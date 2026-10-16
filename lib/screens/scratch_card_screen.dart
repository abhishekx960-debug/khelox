import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/khelox_app_bar.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  static const _rewards = <int>[10, 20, 30, 50, 100, 0];
  final List<Offset> _points = [];
  int _reward = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _newCard();
  }

  void _newCard() {
    setState(() {
      _reward = _rewards[math.Random().nextInt(_rewards.length)];
      _points.clear();
      _revealed = false;
    });
  }

  void _add(Offset p) {
    if (_revealed) return;
    setState(() {
      _points.add(p);
      if (_points.length > 80) _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final won = _reward > 0;
    return Scaffold(
      appBar: const KheloxAppBar('Scratch Card'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Scratch the card to reveal your Fcoin reward.',
            style: TextStyle(color: AppColors.mist, fontSize: 14.5),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 300,
              height: 210,
              clipBehavior: Clip.antiAlias,
              decoration: AppTheme.surfaceCard(
                border: AppColors.gold,
                radius: 20,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          won
                              ? Icons.monetization_on_rounded
                              : Icons.sentiment_dissatisfied_rounded,
                          color: won ? AppColors.gold : AppColors.mist,
                          size: 46,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          won
                              ? 'You won $_reward Fcoin!'
                              : 'No reward. Try again!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_revealed)
                    GestureDetector(
                      onPanStart: (d) => _add(d.localPosition),
                      onPanUpdate: (d) => _add(d.localPosition),
                      onTapDown: (d) => _add(d.localPosition),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _ScratchPainter(points: _points),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _newCard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('NEW CARD'),
          ),
        ],
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset> points;
  _ScratchPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.cardAlt);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'SCRATCH HERE',
        style: TextStyle(
          color: AppColors.mist,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      size.center(Offset.zero) - Offset(tp.width / 2, tp.height / 2),
    );

    final erase = Paint()..blendMode = BlendMode.clear;
    for (final p in points) {
      canvas.drawCircle(p, 24, erase);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter old) =>
      old.points.length != points.length;
}
