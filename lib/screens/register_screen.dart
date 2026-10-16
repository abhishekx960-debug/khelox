import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final user = await ApiService.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      await SessionService.save(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShell(user: user)),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'CREATE ACCOUNT',
      subtitle: 'Join Khelox. Play. Win. Earn rewards.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthField(
              controller: _name,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.name],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Enter your name';
                if (s.length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _email,
              label: 'Email',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Enter email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _phone,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Enter phone number';
                if (!RegExp(r'^\+?\d{10,15}$').hasMatch(s)) {
                  return 'Enter a valid phone number (10-15 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _hide,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
              suffix: IconButton(
                icon: Icon(_hide
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 28),
            GoldButton(
              text: 'Register',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: AppColors.mist),
                ),
                GestureDetector(
                  onTap: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}