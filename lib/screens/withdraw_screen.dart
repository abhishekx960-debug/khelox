import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';
import 'transaction_history_screen.dart';

class WithdrawScreen extends StatefulWidget {
  final UserModel user;
  final String initialType;

  const WithdrawScreen({
    super.key,
    required this.user,
    this.initialType = 'fcoin',
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _upi = TextEditingController();

  late String _type;
  FinanceSettings? _settings;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'wcoin' ? 'wcoin' : 'fcoin';
    _amount.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await ApiService.fetchFinanceSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
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

  bool get _isWcoin => _type == 'wcoin';

  double get _min => _isWcoin
      ? (_settings?.wcoinMinWithdraw ?? 100)
      : (_settings?.fcoinMinWithdraw ?? 100);

  double get _max => _isWcoin
      ? (_settings?.wcoinMaxWithdraw ?? 100000)
      : (_settings?.fcoinMaxWithdraw ?? 100000);

  double get _balance => _isWcoin ? widget.user.wcoin : widget.user.fcoin;

  double get _fcoinRate {
    final s = _settings;
    if (s == null) return 0;
    if (s.fcoinRateCoins > 0 && s.fcoinRateInr > 0) {
      return s.fcoinRateInr / s.fcoinRateCoins;
    }
    return s.fcoinInrRate;
  }

  String get _rateLabel {
    final s = _settings;
    if (s == null) return '';
    if (s.fcoinRateCoins > 0 && s.fcoinRateInr > 0) {
      return '${formatCoin(s.fcoinRateCoins)} Fcoin = INR ${formatCoin(s.fcoinRateInr)}';
    }
    return '1 Fcoin = INR ${formatCoin(s.fcoinInrRate)}';
  }

  double get _inrValue {
    if (_isWcoin) return 0;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    return amount * _fcoinRate;
  }

  String? _validateAmount(String? v) {
    final amount = double.tryParse((v ?? '').trim()) ?? 0;
    if (amount <= 0) return 'Enter an amount';
    if (amount < _min) return 'Minimum is ${formatCoin(_min)}';
    if (_max > 0 && amount > _max) return 'Maximum is ${formatCoin(_max)}';
    if (amount > _balance) return 'Insufficient balance';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ApiService.createWithdrawal(
        userId: widget.user.id,
        type: _type,
        amount: double.parse(_amount.text.trim()),
        upiId: _upi.text,
      );
      // Coins are held as soon as the request is created, so refresh the
      // displayed balance immediately instead of waiting for the next poll.
      await UserStore.instance.refresh();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Request sent'),
          content: Text(
            'Your ${formatCoin(double.tryParse(_amount.text.trim()) ?? 0)} '
            '${_isWcoin ? 'Wcoin' : 'Fcoin'} withdrawal request has been sent '
            'to the admin. Payment will be made after approval.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message);
    } catch (e) {
      if (mounted) showMsg(context, '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KheloxAppBar(
        'Withdraw',
        actions: [
          IconButton(
            tooltip: 'Transaction History',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionHistoryScreen(user: widget.user),
              ),
            ),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? _errorView()
              : _form(context),
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

  Widget _form(BuildContext context) {
    final accent = _isWcoin ? AppColors.teal : AppColors.gold;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fcoin', label: Text('Fcoin')),
              ButtonSegment(value: 'wcoin', label: Text('Wcoin')),
            ],
            selected: {_type},
            onSelectionChanged: (selection) {
              setState(() {
                _type = selection.first;
                _amount.clear();
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: accent.withValues(alpha: 0.2),
              selectedForegroundColor: accent,
              foregroundColor: AppColors.mist,
              side: const BorderSide(color: AppColors.line),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceCard(border: accent, radius: 16),
            child: Row(
              children: [
                Icon(
                  _isWcoin
                      ? Icons.workspace_premium_rounded
                      : Icons.monetization_on_rounded,
                  color: accent,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_isWcoin ? 'WCOIN' : 'FCOIN'} BALANCE',
                        style: const TextStyle(
                          color: AppColors.mist,
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCoin(_balance),
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isWcoin) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded,
                        color: AppColors.gold),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT RATE',
                          style: TextStyle(
                            color: AppColors.mist,
                            fontSize: 11.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rateLabel,
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ] else
            const SizedBox(height: 22),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              labelText: 'Amount (${_isWcoin ? 'Wcoin' : 'Fcoin'})',
              prefixIcon: Icon(
                _isWcoin
                    ? Icons.workspace_premium_rounded
                    : Icons.monetization_on_rounded,
              ),
            ),
            validator: _validateAmount,
          ),
          if (!_isWcoin) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceCard(border: AppColors.line, radius: 16),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.mist),
                  const SizedBox(width: 10),
                  const Text(
                    'You will get',
                    style: TextStyle(color: AppColors.mist, fontSize: 13.5),
                  ),
                  const Spacer(),
                  Text(
                    'INR ${formatCoin(_inrValue)}',
                    style: const TextStyle(
                      fontFamily: AppFonts.heading,
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Minimum: ${formatCoin(_min)}  •  Maximum: ${formatCoin(_max)}',
            style: const TextStyle(color: AppColors.mist, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _upi,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'yourname@upi',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
            ),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Enter UPI ID';
              if (s.length > 120) return 'UPI ID is too long';
              return null;
            },
          ),
          const SizedBox(height: 26),
          GoldButton(
            text: 'Request Withdraw',
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 10),
          const Text(
            'Coins are deducted as soon as you submit. If rejected, the amount '
            'is refunded and the reason is shown in Transaction History.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mist, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionHistoryScreen(user: widget.user),
              ),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Transaction History'),
          ),
        ],
      ),
    );
  }
}
