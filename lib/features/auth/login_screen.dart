import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 800;

    final form = _LoginForm(
      loginCtrl: _loginCtrl,
      passCtrl: _passCtrl,
      obscure: _obscure,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      loading: auth.loading,
      error: auth.error,
      onSubmit: () => context.read<AuthProvider>().login(_loginCtrl.text.trim(), _passCtrl.text),
    );

    final formPane = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: form),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          if (isWide)
            Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 4, child: formPane),
              ],
            )
          else
            SafeArea(child: formPane),
          const Positioned(top: 8, right: 8, child: SafeArea(child: LanguageMenu())),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark.withValues(alpha: 0.55), AppColors.background, AppColors.accentDark.withValues(alpha: 0.35)],
        ),
      ),
      padding: const EdgeInsets.all(48),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 56),
          const SizedBox(height: 24),
          const Text('Senova', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Text('CRM', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 12),
          Text(context.tr('brand_tagline'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController loginCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.loginCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('welcome'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(context.tr('login_title'), style: const TextStyle(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        TextField(
          controller: loginCtrl,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: context.tr('login'), prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passCtrl,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: context.tr('password'),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 19),
              onPressed: onToggleObscure,
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(context.tr(error!), style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
        ],
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary))
              : Text(context.tr('sign_in')),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () async {
              final login = loginCtrl.text.trim();
              if (login.isEmpty) {
                showSnack(context, context.tr('enter_login_first'), error: true);
                return;
              }
              try {
                await context.read<AuthProvider>().resetPassword(login);
              } catch (_) {
                // Намоиши натиҷаи ягона — мавҷудияти логин ошкор намешавад.
              }
              if (context.mounted) showSnack(context, context.tr('reset_sent_generic'));
            },
            child: Text(context.tr('forgot_password'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
