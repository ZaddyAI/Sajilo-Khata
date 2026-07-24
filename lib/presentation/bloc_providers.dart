import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_goal_repository.dart';
import '../domain/repositories/i_transaction_repository.dart';
import '../domain/usecases/auth/check_auth.dart';
import '../domain/usecases/auth/sign_in_email.dart';
import '../domain/usecases/auth/sign_in_google.dart';
import '../domain/usecases/auth/sign_out.dart';
import '../domain/usecases/auth/sign_up_email.dart';
import '../domain/usecases/goals/add_goal.dart';
import '../domain/usecases/goals/contribute_to_goal.dart';
import '../domain/usecases/goals/delete_goal.dart';
import '../domain/usecases/goals/edit_contribution.dart';
import '../domain/usecases/goals/get_goals.dart';
import '../domain/usecases/goals/remove_contribution.dart';
import '../domain/usecases/goals/update_goal.dart';
import '../domain/usecases/transactions/add_transaction.dart';
import '../domain/usecases/transactions/delete_transaction.dart';
import '../domain/usecases/transactions/get_transactions.dart';
import '../domain/usecases/transactions/update_transaction.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/goal/goal_bloc.dart';
import 'bloc/transaction/transaction_bloc.dart';

List<BlocProvider> blocProviders = [
  BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(
      authRepository: context.read<AuthRepository>(),
      signInEmail: SignInWithEmail(context.read<AuthRepository>()),
      signUpEmail: SignUpWithEmail(context.read<AuthRepository>()),
      signInGoogle: SignInWithGoogle(context.read<AuthRepository>()),
      checkAuth: CheckAuth(context.read<AuthRepository>()),
      signOut: SignOut(context.read<AuthRepository>()),
    ),
  ),
  BlocProvider<TransactionBloc>(
    create: (context) => TransactionBloc(
      transactionRepository: context.read<TransactionRepository>(),
      getTransactions: GetTransactions(context.read<TransactionRepository>()),
      addTransaction: AddTransaction(context.read<TransactionRepository>()),
      updateTransaction: UpdateTransactionUsecase(context.read<TransactionRepository>()),
      deleteTransaction: DeleteTransactionUsecase(context.read<TransactionRepository>()),
    ),
  ),
  BlocProvider<GoalBloc>(
    create: (context) => GoalBloc(
      goalRepository: context.read<GoalRepository>(),
      getGoals: GetGoals(context.read<GoalRepository>()),
      addGoal: AddGoalUsecase(context.read<GoalRepository>()),
      updateGoal: UpdateGoalUsecase(context.read<GoalRepository>()),
      deleteGoal: DeleteGoalUsecase(context.read<GoalRepository>()),
      contributeToGoal: ContributeToGoalUsecase(context.read<GoalRepository>()),
      removeContribution: RemoveContributionUsecase(context.read<GoalRepository>()),
      editContribution: EditContributionUsecase(context.read<GoalRepository>()),
    ),
  ),
];