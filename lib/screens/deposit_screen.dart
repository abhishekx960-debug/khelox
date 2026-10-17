import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/proof_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/coin_chip.dart';
import '../widgets/khelox_app_bar.dart';
import 'transaction_history_screen.dart';

class DepositScreen extends StatefulWidget {
  final UserModel user;

  const DepositScreen({super.key, required this.user});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();

  FinanceSettings? _settings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
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

  double get _inr => double.tryParse(_amount.text.trim()) ?? 0;

  double get _coins {
    final rate = _settings?.dcoinInrRate ?? 1;
    return rate > 0 ? _inr / rate : 0;
  }

  String? _validateAmount(double inr) {
    final s = _settings;
    if (s == null) return 'Settings load nahi hui';
    if (inr <= 0) return 'Amount daalo';
    final coins = inr / (s.dcoinInrRate > 0 ? s.dcoinInrRate : 1);
    if (coins < s.dcoinMinDeposit) {
      return 'Minimum ${formatCoin(s.dcoinMinDeposit)} Dcoin deposit hai';
    }
    if (s.dcoinMaxDeposit > 0 && coins > s.dcoinMaxDeposit) {
      return 'Maximum ${formatCoin(s.dcoinMaxDeposit)} Dcoin deposit hai';
    }
    return null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final s = _settings;
    if (s == null) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepositPaymentScreen(
          user: widget.user,
          settings: s,
          inrAmount: _inr,
          coins: _coins,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KheloxAppBar(
        'Deposit',
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
              ? _ErrorView(message: _error!, onRetry: _load)
              : _form(context, _settings!),
    );
  }

  Widget _form(BuildContext context, FinanceSettings s) {
    final rate = s.dcoinInrRate > 0 ? s.dcoinInrRate : 1;
    final minInr = s.dcoinMinDeposit * rate;
    final maxInr = s.dcoinMaxDeposit * rate;
    final quickMax = maxInr > 0 ? maxInr : double.infinity;
    final quickAmounts = <double>{
      minInr,
      100.0,
      500.0,
      1000.0,
    }.where((v) => v >= minInr && v <= quickMax).toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.surfaceCard(border: AppColors.cyan, radius: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.diamond_rounded,
                    color: AppColors.cyan),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEPOSIT RATE',
                      style: TextStyle(
                        color: AppColors.mist,
                        fontSize: 11.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 Dcoin = INR ${formatCoin(rate)}',
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
        const Text(
          'HOW MANY COINS?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            decoration: const InputDecoration(
              labelText: 'Amount (INR)',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
              prefixText: 'INR ',
            ),
            validator: (v) => _validateAmount(double.tryParse((v ?? '').trim()) ?? 0),
          ),
        ),
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
                '${formatCoin(_coins)} Dcoin',
                style: const TextStyle(
                  fontFamily: AppFonts.heading,
                  color: AppColors.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Minimum: ${formatCoin(minInr)} INR (${formatCoin(s.dcoinMinDeposit)} Dcoin)'
          '  •  Maximum: ${formatCoin(maxInr)} INR (${formatCoin(s.dcoinMaxDeposit)} Dcoin)',
          style: const TextStyle(color: AppColors.mist, fontSize: 12.5),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quick in quickAmounts)
              ActionChip(
                backgroundColor: AppColors.slate.withValues(alpha: 0.5),
                side: const BorderSide(color: AppColors.line),
                label: Text(
                  'INR ${formatCoin(quick)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
                onPressed: () => _amount.text = formatCoin(quick),
              ),
          ],
        ),
        const SizedBox(height: 26),
        GoldButton(
          text: 'Continue to payment',
          onPressed: _continue,
        ),
        const SizedBox(height: 10),
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
    );
  }
}

class DepositPaymentScreen extends StatefulWidget {
  final UserModel user;
  final FinanceSettings settings;
  final double inrAmount;
  final double coins;

  const DepositPaymentScreen({
    super.key,
    required this.user,
    required this.settings,
    required this.inrAmount,
    required this.coins,
  });

  @override
  State<DepositPaymentScreen> createState() => _DepositPaymentScreenState();
}

class _DepositPaymentScreenState extends State<DepositPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _utr = TextEditingController();
  final _proofUrl = TextEditingController();

  PickedProofImage? _picked;
  bool _submitting = false;

  @override
  void dispose() {
    _utr.dispose();
    _proofUrl.dispose();
    super.dispose();
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    showMsg(context, 'UPI ID copied');
  }

  Future<void> _pickProof() async {
    try {
      final picked = await pickProofImage();
      if (picked == null || !mounted) return;
      setState(() => _picked = picked);
    } catch (e) {
      if (mounted) showMsg(context, '$e');
    }
  }

  String get _proof {
    if (kProofPickerSupported) return _picked?.dataUrl ?? '';
    return _proofUrl.text.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proof.isEmpty) {
      showMsg(context, 'Payment proof add karo');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ApiService.createDeposit(
        userId: widget.user.id,
        inrAmount: widget.inrAmount,
        utr: _utr.text,
        proof: _proof,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Request sent'),
          content: Text(
            'Aapki ${formatCoin(widget.coins)} Dcoin deposit request admin ko '
            'bhej di gayi hai. Approve hone ke baad coins wallet me add honge.',
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
    final s = widget.settings;
    final hasPayment = s.depositUpiId.isNotEmpty || s.depositQr.isNotEmpty;

    return Scaffold(
      appBar: const KheloxAppBar('Payment'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  AppTheme.surfaceCard(border: AppColors.gold, radius: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAY THIS AMOUNT',
                          style: TextStyle(
                            color: AppColors.mist,
                            fontSize: 11.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'INR ${formatCoin(widget.inrAmount)}',
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '= ${formatCoin(widget.coins)} Dcoin',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.diamond_rounded,
                      color: AppColors.cyan, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'PAYMENT DETAILS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 12),
            if (!hasPayment)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.surfaceCard(
                    border: AppColors.danger, radius: 14),
                child: const Text(
                  'Admin ne payment details abhi set nahi ki hain. '
                  'Thodi der baad try karo ya support se contact karo.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              )
            else ...[
              if (s.depositQr.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        s.depositQr,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 200,
                          height: 120,
                          child: Center(
                            child: Text(
                              'QR load nahi hua',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (s.depositUpiId.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration:
                      AppTheme.surfaceCard(border: AppColors.line, radius: 16),
                  child: ListTile(
                    onTap: () => _copy(s.depositUpiId),
                    leading: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColors.cyan),
                    title: const Text('UPI ID'),
                    subtitle: Text(
                      s.depositUpiId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(Icons.copy_rounded,
                        size: 20, color: AppColors.mist),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 22),
            const Text(
              'PAYMENT PROOF',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 12),
            if (kProofPickerSupported)
              Container(
                padding: const EdgeInsets.all(14),
                decoration:
                    AppTheme.surfaceCard(border: AppColors.line, radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_picked == null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickProof,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Upload Payment Proof'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan),
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'JPG, PNG ya WEBP, max 3MB',
                        style:
                            TextStyle(color: AppColors.mist, fontSize: 12),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(_picked!.dataUrl.split(',').last),
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _picked!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: _pickProof,
                                  icon: const Icon(Icons.swap_horiz_rounded,
                                      size: 18),
                                  label: const Text('Change'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )
            else
              TextFormField(
                controller: _proofUrl,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Payment proof image URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded),
                  helperText: 'Screenshot ImgBB/Drive par upload karke link paste karo',
                ),
              ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _utr,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Enter Transaction ID',
                prefixIcon: Icon(Icons.receipt_long_rounded),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length < 4) return 'Transaction ID daalo';
                if (s.length > 100) return 'Transaction ID bahut lamba hai';
                return null;
              },
            ),
            const SizedBox(height: 26),
            GoldButton(
              text: 'Submit Request',
              loading: _submitting,
              onPressed: hasPayment && !_submitting ? _submit : null,
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Payment karke hi proof aur Transaction ID submit karo. '
                'Admin approve karne ke baad Dcoin wallet me add honge.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mist, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mist),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
