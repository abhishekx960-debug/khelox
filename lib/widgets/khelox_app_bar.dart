import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Shared top bar.
///
/// By default it shows the name of the currently open screen. When [brand] is
/// true it shows the KheloX logo + app name instead (used on Home).
class KheloxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool brand;

  const KheloxAppBar(
    this.title, {
    super.key,
    this.actions = const [],
    this.brand = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  Widget _title() {
    if (brand) {
      return const Row(
        children: [
          KheloxLogo(size: 32),
          SizedBox(width: 10),
          Text(
            'KheloX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const HugeIcon(
                icon: AppIcons.back,
                size: 24,
                color: Colors.white,
                strokeWidth: 1.8,
              ),
            )
          : null,
      title: _title(),
      actions: [...actions, const SizedBox(width: 12)],
    );
  }
}
