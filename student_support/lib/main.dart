import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_assets.dart';
import 'core/app_scroll_behavior.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Listed with the package licenses on the Open-source licenses page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'DiceBear artwork',
    ], await rootBundle.loadString('assets/images/dicebear/LICENSE.txt'));
  });
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    AppAssets.load(),
  ]);
  await initializeSupabase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When the user signs in or out, close any screens pushed on top
    // (register, report details, and so on) so the auth gate is visible.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final wasSignedIn = previous?.valueOrNull?.isAuthenticated;
      final isSignedIn = next.valueOrNull?.isAuthenticated;
      if (isSignedIn != null && wasSignedIn != isSignedIn) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    return MaterialApp(
      title: 'CampusSupport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: _navigatorKey,
      scrollBehavior: const AppScrollBehavior(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}

/// Shows the splash, then the login screen or the main app depending on the
/// auth state. The splash stays for at least [minSplash] so its animation
/// can finish even when the auth check is instant.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  static const Duration minSplash = Duration(milliseconds: 1400);

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(AuthGate.minSplash, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final Widget child;
    if (!_splashDone || !(authState.hasValue || authState.hasError)) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else {
      final auth = authState.valueOrNull;
      if (auth?.isAuthenticated != true) {
        child = const LoginScreen(key: ValueKey('login'));
      } else {
        child = const HomeScreen(key: ValueKey('home'));
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: child,
    );
  }
}
