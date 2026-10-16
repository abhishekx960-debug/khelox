import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/game_tile.dart';
import '../widgets/khelox_app_bar.dart';

/// Modes = PREMIUM ZONE
class ModesScreen extends StatelessWidget {
  final UserModel user;
  const ModesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final games = <(String, IconData, Color)>[
      ('Free Fire', Icons.local_fire_department_rounded, AppColors.gold),
      ('BGMI', Icons.sports_esports_rounded, AppColors.cyan),
    ];

    return Scaffold(
      appBar: const KheloxAppBar('Premium Zone'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const ZoneHeader(
            title: 'PREMIUM ZONE',
            subtitle: 'Pick a game and enter matches',
            color: AppColors.cyan,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
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
        ],
      ),
    );
  }
}