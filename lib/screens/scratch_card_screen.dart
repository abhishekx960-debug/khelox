import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen>
    with WidgetsBindingObserver {
  static const double _cardW = 300;
  static const double _cardH = 210;
  static const double _brush = 30; // scratch radius
  static const int _cols = 15;
  static const int _rows = 11;
  static const double _revealAt = 0.55; // % area scratched -> auto reveal

  final List<List<Offset>> _strokes = [];
  final Set<int> _cells = {};

  int _reward = 0;
  bool _hasCard = false; // card issued by server & not yet finished
  bool _revealed = false;
  bool _requesting = false;

  SpinStatus? _status;
  bool _loading = true;
  String? _loadError;

  // Countdown = server seconds + Stopwatch (monotonic). Device clock unused.
  final Stopwatch _sw = Stopwatch();
  int _baseResetSecs = 0;
  Timer? _tick;
  bool _resyncing = false;

  int get _userId => UserStore.instance.user.value?.id ?? 0;
  int get _remaining => _status?.remaining ?? 0;
  int get _limit => _status?.limit ?? 10;
  bool get _limitReached => _status != null && _remaining <= 0;

  int get _secsLeft {
    final left = _baseResetSecs - _sw.elapsed.inSeconds;
    return left < 0 ? 0 : left;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadStatus();
  }

  void _applyStatus(SpinStatus st) {
    _status = st;
    _baseResetSecs = st.resetIn;
    _sw
      ..reset()
      ..start();
  }

  Future<void> _loadStatus() async {
    if (_resyncing) return;
    _resyncing = true;
    try {
      final st = await ApiService.fetchScratchStatus(_userId);
      if (!mounted) return;
      setState(() {
        // Don't touch status mid-card: spends already counted.
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
    if (_limitReached && _secsLeft == 0) _loadStatus();
    if (_limitReached) setState(() {});
  }

  String _fmt(int total) {
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _newCard() async {
    if (_requesting || _limitReached || (_hasCard && !_revealed)) return;
    setState(() => _requesting = true);
    try {
      // Server decides reward + enforces limit.
      final r = await ApiService.newScratchCard(_userId);
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _reward = r.reward;
        _strokes.clear();
        _cells.clear();
        _revealed = false;
        _hasCard = true;
        _applyStatus(r.status);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
      _loadStatus();
    }
  }

  void _markCells(Offset p) {
    final cw = _cardW / _cols;
    final ch = _cardH / _rows;
    final c0 = ((p.dx - _brush) / cw).floor().clamp(0, _cols - 1);
    final c1 = ((p.dx + _brush) / cw).floor().clamp(0, _cols - 1);
    final r0 = ((p.dy - _brush) / ch).floor().clamp(0, _rows - 1);
    final r1 = ((p.dy + _brush) / ch).floor().clamp(0, _rows - 1);
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        // count a cell only when its centre is under the brush
        final centre = Offset((c + 0.5) * cw, (r + 0.5) * ch);
        if ((centre - p).distance <= _brush) _cells.add(r * _cols + c);
      }
    }
  }

  void _scratchStart(Offset p) {
    if (!_hasCard || _revealed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _strokes.add([p]);
      _markCells(p);
    });
    _checkReveal();
  }

  void _scratchMove(Offset p) {
    if (!_hasCard || _revealed || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(p);
      _markCells(p);
    });
    _checkReveal();
  }

  void _checkReveal() {
    if (_revealed) return;
    if (_cells.length / (_cols * _rows) >= _revealAt) {
      setState(() => _revealed = true);
      HapticFeedback.mediumImpact();
      UserStore.instance.refresh(); // top-right Fcoin chip updates
    }
  }

  @override
  Widget build(BuildContext context) {
    final won = _reward > 0;
    final canGet = !(_requesting ||
        _loading ||
        _limitReached ||
        (_hasCard && !_revealed));

    return Scaffold(
      appBar: KheloxAppBar(
        'Scratch Card',
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
            'Scratch the card to reveal your Fcoin reward.',
            style: TextStyle(color: AppColors.mist, fontSize: 14.5),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: _cardW,
              height: _cardH,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ---- prize layer (under the foil) ----
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.cardAlt, AppColors.card],
                      ),
                    ),
                    // No prize drawn until a card is issued.
                    child: !_hasCard
                        ? null
                        : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            won
                                ? Icons.monetization_on_rounded
                                : Icons.sentiment_dissatisfied_rounded,
                            color: won ? AppColors.gold : AppColors.mist,
                            size: 52,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            won ? '$_reward' : 'Try Again',
                            style: TextStyle(
                              fontFamily: AppFonts.heading,
                              color: won ? AppColors.gold : Colors.white,
                              fontSize: won ? 40 : 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            won ? 'Fcoin won!' : 'Better luck next time',
                            style: const TextStyle(
                              color: AppColors.mist,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ---- silver foil (scratchable) ----
                  IgnorePointer(
                    ignoring: _revealed,
                    child: AnimatedOpacity(
                      opacity: _revealed ? 0 : 1,
                      // Fade only when revealing. Foil must snap back
                      // instantly on new card, else next prize flashes.
                      duration: _revealed
                          ? const Duration(milliseconds: 450)
                          : Duration.zero,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _scratchStart(d.localPosition),
                        onPanUpdate: (d) => _scratchMove(d.localPosition),
                        onTapDown: (d) => _scratchStart(d.localPosition),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _FoilPainter(
                              strokes: _strokes,
                              brush: _brush,
                              active: _hasCard,
                              version: _strokes.fold<int>(
                                  _strokes.length, (a, s) => a + s.length),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: canGet ? _newCard : null,
            icon: Icon(
              _limitReached
                  ? Icons.lock_clock_rounded
                  : (_hasCard && !_revealed)
                      ? Icons.touch_app_rounded
                      : Icons.confirmation_number_rounded,
            ),
            label: Text(
              _requesting
                  ? 'GETTING CARD...'
                  : _limitReached
                      ? 'LIMIT REACHED'
                      : (_hasCard && !_revealed)
                          ? 'SCRATCH TO REVEAL'
                          : _revealed
                              ? 'NEW CARD'
                              : 'GET SCRATCH CARD',
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
            _loadError ?? 'Could not load cards.',
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
          'Cards left: $_remaining / $_limit',
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

/// Silver metallic foil. Strokes erase it with BlendMode.clear,
/// so the prize underneath shows through exactly where finger scratched.
class _FoilPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double brush;
  final bool active;
  final int version;

  _FoilPainter({
    required this.strokes,
    required this.brush,
    required this.active,
    required this.version,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    // metallic base
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB9BCC8),
            Color(0xFFE9EAF0),
            Color(0xFF9EA2B2),
            Color(0xFFD9DBE4),
            Color(0xFFA8ABBA),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect),
    );

    // fine grain so it feels like scratch-off coating
    final rnd = math.Random(7);
    final grain = Paint();
    for (var i = 0; i < 700; i++) {
      grain.color = (rnd.nextBool() ? Colors.white : const Color(0xFF6D7080))
          .withValues(alpha: 0.10 + rnd.nextDouble() * 0.12);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 0.9,
        grain,
      );
    }

    // diagonal shine streaks
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = 14;
    for (var x = -size.height; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), shine);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: active ? 'SCRATCH HERE' : 'GET A CARD',
        style: const TextStyle(
          fontFamily: AppFonts.heading,
          color: Color(0xFF5E6173),
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      size.center(Offset.zero) - Offset(tp.width / 2, tp.height / 2),
    );

    // scratched areas -> transparent
    final erase = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = brush * 2;
    final dot = Paint()..blendMode = BlendMode.clear;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, brush, dot);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, erase);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) =>
      old.version != version || old.active != active;
}