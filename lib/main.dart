import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_lang.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/org_config_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home_shell.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SenovaCrmApp());
}

class SenovaCrmApp extends StatelessWidget {
  const SenovaCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrgConfigProvider>(
          create: (_) => OrgConfigProvider(),
          update: (_, auth, cfg) {
            final c = cfg ?? OrgConfigProvider();
            c.bind(auth.user);
            return c;
          },
        ),
      ],
      child: Consumer2<LocaleProvider, OrgConfigProvider>(
        builder: (context, locale, orgCfg, _) => MaterialApp(
          title: 'Senova CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          // Забони матнҳои барнома (ru/tj/en) ва забони widget-ҳои стандартии Material ҷудо нигоҳ дошта мешаванд.
          builder: (context, child) => AppLang(
            code: locale.code,
            industry: orgCfg.config.industry,
            labels: orgCfg.config.overrides,
            child: child ?? const SizedBox(),
          ),
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Аз рӯи ҳолати вуруд, ё LoginScreen ё HomeShell-ро нишон медиҳад.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: LoadingView());
      case AuthStatus.authenticated:
        // ValueKey(uid): ҳангоми иваз шудани корбар тамоми state/stream-ҳои қаблӣ нест мешаванд.
        return HomeShell(key: ValueKey(auth.user?.uid));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
