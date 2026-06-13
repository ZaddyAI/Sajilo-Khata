import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';

import 'core/services/exchange_rate_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/sync_service.dart';

import 'core/constants/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sms_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/transactions/screens/transaction_list_screen.dart';
import 'features/transactions/bloc/transaction_bloc.dart';
import 'features/transactions/bloc/transaction_event.dart';
import 'features/goals/screens/goals_list_screen.dart';
import 'features/goals/bloc/goal_bloc.dart';
import 'features/goals/bloc/goal_event.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _backgroundSmsHandler(SmsMessage message) async {
  await SmsService().processSms(message.address ?? '', message.body ?? '');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalStorageService.instance.init();
  await NotificationService().initialize();
  await SyncService.instance.init();

  try {
    final data = await FirebaseService.instance.getProfile();
    if (data != null && data['currency'] != null) {
      CurrencyHelper.setCurrency(data['currency'].toString());
    }
  } catch (_) {}

  runApp(const SajiloKhataApp());
  _initSmsListener();
}

Future<void> _initSmsListener() async {
  final telephony = Telephony.instance;
  try {
    final permissions = await telephony.requestPhoneAndSmsPermissions;
    if (permissions ?? false) {
      telephony.listenIncomingSms(
        onNewMessage: (message) async {
          try {
            final sender = message.address ?? '';
            final body = message.body ?? '';
            print('[SMS] Received from $sender: $body');
            await SmsService().processSms(sender, body);
          } catch (e) {
            print('[SMS] Error: $e');
          }
        },
        onBackgroundMessage: _backgroundSmsHandler,
      );
      print('[SMS] Listener started');
    }
  } catch (e) {
    print('[SMS] Init error: $e');
  }
}

class SajiloKhataApp extends StatefulWidget {
  const SajiloKhataApp({super.key});

  @override
  State<SajiloKhataApp> createState() => _SajiloKhataAppState();
}

class AppRestarter {
  static void restart() {
    _SajiloKhataAppState._restart();
  }
}

class _SajiloKhataAppState extends State<SajiloKhataApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  static _SajiloKhataAppState? _instance;
  Key _appKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  static void _restart() {
    _instance?.setState(() {
      _instance?._appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService.instance;

    ExchangeRateService.instance.fetchUsdToNprRate();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => firebaseService),
        ChangeNotifierProvider(
          create: (_) =>
              CurrencyNotifier()..setCurrency(CurrencyHelper.currency),
        ),
      ],
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<AuthRepository>())..add(AuthCheckRequested()),
        child: MaterialApp(
          key: _appKey,
          navigatorKey: _navigatorKey,
          title: 'Sajilo Khata',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const SplashScreen();
        }
        if (state is AuthAuthenticated) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _firebaseService = FirebaseService.instance;
  late TransactionBloc _transactionBloc;
  late GoalBloc _goalBloc;
  bool _smsListenerActive = false;

  static const _navItems = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(label: 'Ledger', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
    _NavItem(label: 'Goals', icon: Icons.savings_outlined, activeIcon: Icons.savings_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _transactionBloc = TransactionBloc(_firebaseService)
      ..add(TransactionLoadRequested());
    _goalBloc = GoalBloc(_firebaseService)..add(GoalLoadRequested());
    _initSmsListener();
  }

  Future<void> _initSmsListener() async {
    if (_smsListenerActive) return;
    final telephony = Telephony.instance;
    try {
      final permissions = await telephony.requestPhoneAndSmsPermissions;
      if (permissions ?? false) {
        _smsListenerActive = true;
        telephony.listenIncomingSms(
          onNewMessage: (message) async {
            try {
              final sender = message.address ?? '';
              final body = message.body ?? '';
              await SmsService().processSms(sender, body);
            } catch (e) {
              print('[SMS-Nav] Error: $e');
            }
          },
          onBackgroundMessage: _backgroundSmsHandler,
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('[SMS-Nav] Init error: $e');
    }
  }

  @override
  void dispose() {
    _transactionBloc.close();
    _goalBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _transactionBloc),
        BlocProvider.value(value: _goalBloc),
      ],
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DashboardScreen(),
            TransactionListScreen(),
            GoalsListScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _PremiumBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = i == currentIndex;
                final item = items[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              key: ValueKey(selected),
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.signatureGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 44,
                    color: AppTheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Sajilo Khata',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: AppTheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart expense tracking',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: AppTheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
