import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/game_tile.dart';
import '../widgets/khelox_app_bar.dart';

/// Home = FREE ZONE + PREMIUM ZONE (top switch ya swipe se badlo)
class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _zone = 0; // 0 = Free Zone, 1 = Premium Zone

  static const _freeGames = <(String, IconData, Color)>[
    ('Spin Wheel', Icons.album_rounded, AppColors.gold),
    ('Scratch Card', Icons.confirmation_number_rounded, AppColors.cyan),
    ('Captcha', Icons.verified_user_rounded, Color(0xFF6FB3A8)),
    ('Daily Check-in', Icons.event_available_rounded, AppColors.gold),
    ('Surveys', Icons.poll_rounded, AppColors.cyan),
  ];

  static const _premiumGames = <(String, IconData, Color)>[
    ('Free Fire', Icons.local_fire_department_rounded, AppColors.gold),
    ('BGMI', Icons.sports_esports_rounded, AppColors.cyan),
  ];

  void _setZone(int i) {
    if (i != _zone) setState(() => _zone = i);
  }

  Widget _grid(int zone) {
    final premium = zone == 1;
    final games = premium ? _premiumGames : _freeGames;
    return SizedBox(
      key: ValueKey(zone),
      width: double.infinity,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: premium ? 0.9 : 1.0,
        children: [
          for (final g in games)
            GameTile(
              title: g.$1,
              icon: g.$2,
              color: g.$3,
              onTap: () => showMsg(context, '${g.$1} - coming soon'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final premium = _zone == 1;

    return Scaffold(
      appBar: kheloxAppBar(
        actions: premium
            ? [
                CoinChip(type: CoinType.dcoin, value: user.dcoin),
                CoinChip(type: CoinType.wcoin, value: user.wcoin),
              ]
            : [CoinChip(type: CoinType.fcoin, value: user.fcoin)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ZoneSwitch(index: _zone, onChanged: _setZone),
          const SizedBox(height: 20),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -300) _setZone(1);
              if (v > 300) _setZone(0);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(_zone);
                final dx = (_zone == 1 ? 1.0 : -1.0) * 0.12;
                final slide = Tween<Offset>(
                  begin: Offset(incoming ? dx : -dx, 0),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _grid(_zone),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneSwitch extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _ZoneSwitch({required this.index, required this.onChanged});

  static const _dur = Duration(milliseconds: 280);

  Widget _tab(int i, String text, IconData icon) {
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: TweenAnimationBuilder<Color?>(
            duration: _dur,
            tween: ColorTween(
              end: selected ? AppColors.navy : AppColors.mist,
            ),
            builder: (_, c, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: c,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          // sliding pill
          Positioned.fill(
            child: AnimatedAlign(
              duration: _dur,
              curve: Curves.easeOutCubic,
              alignment:
                  index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: _dur,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: index == 0 ? AppColors.gold : AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab(0, 'FREE ZONE', Icons.card_giftcard_rounded),
              _tab(1, 'PREMIUM ZONE', Icons.workspace_premium_rounded),
            ],
          ),
        ],
      ),
    );
  }
}