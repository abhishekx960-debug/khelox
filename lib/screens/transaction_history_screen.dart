import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final UserModel user;

  const TransactionHistoryScreen({super.key, required this.user});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<_TxEntry> _items = const [];

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
      final depositsFuture = ApiService.fetchDeposits(widget.user.id);
      final withdrawalsFuture = ApiService.fetchWithdrawals(widget.user.id);
      final deposits = await depositsFuture;
      final withdrawals = await withdrawalsFuture;

      final items = <_TxEntry>[
        for (final d in deposits)
          _TxEntry(
            title: 'Dcoin deposit',
            subtitle: 'INR ${formatCoin(d.inrAmount)}  •  UTR ${d.utr}',
            amount: '+${formatCoin(d.coins)} Dcoin',
            status: d.status,
            reason: d.rejectReason,
            date: d.createdAt,
            color: AppColors.cyan,
            icon: Icons.south_west_rounded,
          ),
        for (final w in withdrawals)
          _TxEntry(
            title: '${w.type == 'wcoin' ? 'Wcoin' : 'Fcoin'} withdraw',
            subtitle: 'UPI ${w.upiId}'
                '${w.status == TxStatus.rejected ? '  •  Amount refunded' : ''}',
            amount: '-${formatCoin(w.amount)} ${w.type == 'wcoin' ? 'Wcoin' : 'Fcoin'}',
            status: w.status,
            reason: w.remark,
            date: w.createdAt,
            color: w.type == 'wcoin' ? AppColors.teal : AppColors.gold,
            icon: Icons.north_east_rounded,
          ),
      ]..sort((a, b) {
          final ad = a.date?.millisecondsSinceEpoch ?? 0;
          final bd = b.date?.millisecondsSinceEpoch ?? 0;
          return bd.compareTo(ad);
        });

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KheloxAppBar('Transaction History'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 140),
                            Icon(Icons.receipt_long_rounded,
                                color: AppColors.mist, size: 46),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: AppColors.mist,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _Tile(entry: _items[i]),
                        ),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.mist, size: 42),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mist),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TxEntry {
  final String title;
  final String subtitle;
  final String amount;
  final TxStatus status;
  final String reason;
  final DateTime? date;
  final Color color;
  final IconData icon;

  const _TxEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.reason,
    required this.date,
    required this.color,
    required this.icon,
  });
}

class _Tile extends StatelessWidget {
  final _TxEntry entry;

  const _Tile({required this.entry});

  Color get _statusColor {
    switch (entry.status) {
      case TxStatus.approved:
        return AppColors.teal;
      case TxStatus.rejected:
        return AppColors.danger;
      case TxStatus.pending:
        return AppColors.gold;
    }
  }

  String _dateText() {
    final d = entry.date;
    if (d == null) return '';
    final local = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}-${two(local.month)}-${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.color.withValues(alpha: 0.15),
                ),
                child: Icon(entry.icon, color: entry.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mist,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.amount,
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      color: entry.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      entry.status.label,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 6),
            child: Text(
              _dateText(),
              style: const TextStyle(color: AppColors.mist, fontSize: 11),
            ),
          ),
          if (entry.status == TxStatus.rejected && entry.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 52),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reason: ${entry.reason}',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
