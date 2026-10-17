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
      return Row(
        children: [
          const KheloxLogo(size: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'KheloX',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.heading,
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 8),
            action,
          ],
          const SizedBox(width: 12),
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
      actions: brand ? const [] : [...actions, const SizedBox(width: 12)],
    );
  }
}
