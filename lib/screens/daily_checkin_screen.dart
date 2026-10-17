import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/khelox_app_bar.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  static const _rewards = <int>[10, 20, 30, 40, 60, 80, 150];
  static const _kLast = 'khelox_checkin_last';
  static const _kStreak = 'khelox_checkin_streak';

  int _streak = 0;
  bool _claimedToday = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_kLast);
    final streak = p.getInt(_kStreak) ?? 0;
    final today = _dateKey(DateTime.now());
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _claimedToday = last == today;
      _loading = false;
    });
  }

  Future<void> _checkIn() async {
    if (_claimedToday) return;
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final last = p.getString(_kLast);

    int streak;
    if (last == yesterday && _streak >= 1 && _streak < 7) {
      streak = _streak + 1;
    } else {
      streak = 1;
    }

    await p.setString(_kLast, _dateKey(now));
    await p.setInt(_kStreak, streak);
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _claimedToday = true;
    });
    showMsg(context, 'Checked in! You earned ${_rewards[streak - 1]} Fcoin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Daily Check-in'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.surfaceCard(
                    border: AppColors.gold,
                    radius: 20,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.gold,
                        size: 38,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_streak day streak',
                              style: const TextStyle(
                                fontFamily: AppFonts.heading,
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Check in daily to keep your streak going',
                              style: TextStyle(
                                color: AppColors.mist,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'REWARDS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.92,
                  children: [
                    for (var i = 0; i < _rewards.length; i++) _dayCard(i),
                  ],
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _claimedToday ? null : _checkIn,
                  child: Text(
                    _claimedToday ? 'CHECKED IN TODAY' : 'CHECK IN',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dayCard(int i) {
    final day = i + 1;
    final claimed = day <= _streak;
    final isNext = !_claimedToday && day == _streak + 1;
    final border = claimed
        ? AppColors.gold
        : (isNext ? AppColors.cyan : AppColors.line);

    return Container(
      decoration: AppTheme.surfaceCard(border: border, radius: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day $day',
            style: const TextStyle(
              color: AppColors.mist,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
            color: claimed
                ? AppColors.gold
                : (isNext ? AppColors.cyan : AppColors.mist),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            '${_rewards[i]}',
            style: TextStyle(
              color: claimed ? AppColors.gold : Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
