import 'package:flutter/cupertino.dart';
import '../../domain/entities/goal.dart';
import '../screens/splash/splash_imports.dart';
import '../screens/auth/auth_imports.dart';
import '../screens/home/home_imports.dart';
import '../screens/dashboard/dashboard_imports.dart';
import '../screens/profile/profile_imports.dart';
import '../screens/transactions/transactions_imports.dart';
import '../screens/goals/goals_imports.dart';
import '../screens/sms_settings/sms_settings_imports.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return CupertinoPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return CupertinoPageRoute(builder: (_) => const SignupScreen());
      case '/home':
        return CupertinoPageRoute(builder: (_) => const HomeScreen());
      case '/dashboard':
        return CupertinoPageRoute(builder: (_) => const DashboardScreen());
      case '/profile':
        return CupertinoPageRoute(builder: (_) => const ProfileScreen());
      case '/sms_settings':
        return CupertinoPageRoute(builder: (_) => const SmsSettingsScreen());
      case '/transactions':
        return CupertinoPageRoute(
          builder: (_) => const TransactionListScreen(),
        );
      case '/add_transaction':
        return CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AddTransactionScreen(),
        );
      case '/goals':
        return CupertinoPageRoute(builder: (_) => const GoalsListScreen());
      case '/add_goal':
        return CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AddGoalScreen(),
        );
      case '/goal_detail':
        final goal = settings.arguments as Goal;
        return CupertinoPageRoute(
          builder: (_) => GoalDetailScreen(initialGoal: goal),
        );
      case '/goal_achieved':
        final goal = settings.arguments as Goal;
        return CupertinoPageRoute(
          builder: (_) => GoalAchievedScreen(goal: goal),
        );
      default:
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
