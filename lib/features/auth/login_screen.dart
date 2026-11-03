import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/theme/app_colors.dart';
import '../../core/industries.dart';
import '../../core/industries_data.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion.dart';
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
      body: AnimatedBackdrop(
        child: Stack(
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
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.centerLeft,
      child: FadeSlideIn(
        duration: const Duration(milliseconds: 800),
        offset: const Offset(-0.04, 0),
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
    return FadeSlideIn(
      delay: const Duration(milliseconds: 150),
      child: Column(
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
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(context.tr('or_divider'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          const Expanded(child: Divider(color: AppColors.border)),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showDemoPicker(context),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: Text(context.tr('try_demo')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
      ),
    );
  }
}

/// Интихоби соҳа барои режими демо (бе вуруд).
void showDemoPicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(ctx.tr('demo_title'), style: const TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ctx.tr('demo_pick_industry'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              for (var i = 0; i < kIndustryOrder.length; i++)
                FadeSlideIn(
                  delay: staggerDelay(i, stepMs: 40),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HoverLift(
                      radius: 10,
                      child: Material(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.read<AuthProvider>().enterDemo(kIndustryOrder[i]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Icon(presetOf(kIndustryOrder[i]).icon, color: AppColors.primaryLight),
                              const SizedBox(width: 12),
                              Expanded(child: Text(presetOf(kIndustryOrder[i]).name(ctx.lang), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel')))],
    ),
  );
}
