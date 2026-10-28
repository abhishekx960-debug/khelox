import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/game_tile.dart';
import '../../../widgets/khelox_app_bar.dart';
import 'free_fire_br_screen.dart';
import 'free_fire_community_screen.dart';
import 'free_fire_cs_screen.dart';

/// Premium Zone > Free Fire > "Free Fire Tournaments"
class FreeFireTournamentsScreen extends StatelessWidget {
  const FreeFireTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = <(String, IconData, Color, Widget)>[
      (
        'Free Fire BR',
        Icons.my_location_rounded,
        AppColors.gold,
        const FreeFireBrScreen(),
      ),
      (
        'Free Fire CS',
        Icons.shield_rounded,
        AppColors.cyan,
        const FreeFireCsScreen(),
      ),
      (
        'Free Fire Community',
        Icons.groups_rounded,
        AppColors.teal,
        const FreeFireCommunityScreen(),
      ),
    ];

    return Scaffold(
      appBar: const KheloxAppBar('Free Fire Tournaments'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const ZoneHeader(
            title: 'FREE FIRE TOURNAMENTS',
            subtitle: 'Pick a mode and join a tournament',
            color: AppColors.gold,
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
              for (final m in modes)
                GameTile(
                  title: m.$1,
                  icon: m.$2,
                  color: m.$3,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => m.$4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
