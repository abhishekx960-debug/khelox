import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/khelox_app_bar.dart';

/// Shared screen for Free Fire BR / CS / Community.
/// Title, then a container with 3 menus: Ongoing | Upcoming | Results.
class FreeFireModeView extends StatefulWidget {
  final String title;
  final String game; // br | cs | community
  const FreeFireModeView({super.key, required this.title, required this.game});

  @override
  State<FreeFireModeView> createState() => _FreeFireModeViewState();
}

class _FreeFireModeViewState extends State<FreeFireModeView> {
  List<TournamentModel> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.fetchTournaments(widget.game);
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = <(String, String)>[
      ('Ongoing', 'ongoing'),
      ('Upcoming', 'upcoming'),
      ('Results', 'results'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: KheloxAppBar(widget.title),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: AppTheme.surfaceCard(radius: 16),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.navy,
                  unselectedLabelColor: AppColors.mist,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  splashBorderRadius: BorderRadius.circular(12),
                  tabs: [for (final t in tabs) Tab(text: t.$1, height: 40)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in tabs) _buildTab(t.$1, t.$2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String status) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _all.where((t) => t.status == status).toList();
    if (status == 'results') {
      items.sort(
        (a, b) => (b.startAt ?? DateTime(0)).compareTo(a.startAt ?? DateTime(0)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (_error != null)
            _Empty(icon: Icons.wifi_off_rounded, text: _error!)
          else if (items.isEmpty)
            _Empty(
              icon: Icons.emoji_events_outlined,
              text: 'No ${label.toLowerCase()} tournaments',
            )
          else
            for (final t in items) ...[
              _TournamentCard(t: t),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.mist.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mist, fontSize: 14.5),
            ),
          ],
        ),
      );
}

String _money(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '₹$s';
}

String _when(DateTime? d) {
  if (d == null) return '-';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${m[d.month - 1]} ${d.year}, $h12:$mm $ap';
}

class _TournamentCard extends StatelessWidget {
  final TournamentModel t;
  const _TournamentCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDetails(context, t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.surfaceCard(
          border: AppColors.gold.withValues(alpha: 0.35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.heading,
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _when(t.startAt),
              style: const TextStyle(color: AppColors.mist, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(label: 'Prizepool', value: _money(t.prizePool), color: AppColors.gold),
                _Stat(
                  label: 'Entry',
                  value: t.entryFee > 0 ? _money(t.entryFee) : 'Free',
                  color: AppColors.cyan,
                ),
                _Stat(label: 'Slots', value: '${t.slots}', color: AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.mist, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

void _showDetails(BuildContext context, TournamentModel t) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navyDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
        children: [
          Text(
            t.title,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(_when(t.startAt), style: const TextStyle(color: AppColors.mist)),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(label: 'Prizepool', value: _money(t.prizePool), color: AppColors.gold),
              _Stat(
                label: 'Entry Fees',
                value: t.entryFee > 0 ? _money(t.entryFee) : 'Free',
                color: AppColors.cyan,
              ),
              _Stat(label: 'Slots', value: '${t.slots}', color: AppColors.teal),
            ],
          ),
          if (t.description.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Description',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(t.description, style: const TextStyle(color: AppColors.mist, height: 1.5)),
          ],
          if (t.rules.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Rules',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < t.rules.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Point ${i + 1} - ${t.rules[i]}',
                  style: const TextStyle(color: AppColors.mist, height: 1.45),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
