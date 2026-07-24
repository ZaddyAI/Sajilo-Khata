import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:provider/provider.dart';

import 'core/services/exchange_rate_service.dart';
import 'core/services/notification_service.dart';
import 'core/constants/app_theme.dart';
import 'data/datasources/local/hive_datasource.dart';
import 'domain/repositories/i_sync_repository.dart';
import 'presentation/bloc_providers.dart';
import 'presentation/repository_providers.dart';
import 'presentation/routes/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final hive = HiveDataSource();
  await hive.init();
  await NotificationService().initialize();

  runApp(SajiloKhataApp(hive: hive));
}

class SajiloKhataApp extends StatefulWidget {
  final HiveDataSource hive;
  const SajiloKhataApp({super.key, required this.hive});

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
    ExchangeRateService.instance.fetchUsdToNprRate();

    return MultiRepositoryProvider(
      providers: repoProviders(widget.hive),
      child: MultiBlocProvider(
        providers: blocProviders,
        child: ChangeNotifierProvider(
          create: (_) =>
              CurrencyNotifier()..setCurrency(CurrencyHelper.currency),
          child: MaterialApp(
            key: _appKey,
            navigatorKey: _navigatorKey,
            title: 'Sajilo Khata',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            onGenerateRoute: AppRouter.generateRoute,
            builder: (context, child) {
              context.read<SyncRepository>().init();
              return child!;
            },
          ),
        ),
      ),
    );
  }
}
