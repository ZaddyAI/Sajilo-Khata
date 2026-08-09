import 'package:flutter/material.dart';
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
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/sms_settings':
        return MaterialPageRoute(builder: (_) => const SmsSettingsScreen());
      case '/transactions':
        return MaterialPageRoute(builder: (_) => const TransactionListScreen());
      case '/add_transaction':
        return MaterialPageRoute(builder: (_) => const AddTransactionScreen());
      case '/goals':
        return MaterialPageRoute(builder: (_) => const GoalsListScreen());
      case '/add_goal':
        return MaterialPageRoute(builder: (_) => const AddGoalScreen());
      case '/goal_detail':
        final goal = settings.arguments as Goal;
        return MaterialPageRoute(builder: (_) => GoalDetailScreen(initialGoal: goal));
      case '/goal_achieved':
        final goal = settings.arguments as Goal;
        return MaterialPageRoute(builder: (_) => GoalAchievedScreen(goal: goal));
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}