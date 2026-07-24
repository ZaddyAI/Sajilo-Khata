import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/datasources/local/hive_datasource.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import '../../data/datasources/remote/firebase_firestore_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_goal_repository.dart';
import '../../domain/repositories/i_sync_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/usecases/auth/check_auth.dart';
import '../../domain/usecases/auth/sign_in_email.dart';
import '../../domain/usecases/auth/sign_in_google.dart';
import '../../domain/usecases/auth/sign_out.dart';
import '../../domain/usecases/auth/sign_up_email.dart';
import '../../domain/usecases/goals/add_goal.dart';
import '../../domain/usecases/goals/contribute_to_goal.dart';
import '../../domain/usecases/goals/delete_goal.dart';
import '../../domain/usecases/goals/edit_contribution.dart';
import '../../domain/usecases/goals/get_goals.dart';
import '../../domain/usecases/goals/remove_contribution.dart';
import '../../domain/usecases/goals/update_goal.dart';
import '../../domain/usecases/transactions/add_transaction.dart';
import '../../domain/usecases/transactions/delete_transaction.dart';
import '../../domain/usecases/transactions/get_transactions.dart';
import '../../domain/usecases/transactions/update_transaction.dart';

import '../network/network_info.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;
  ServiceLocator._();

  bool _initialized = false;

  late final HiveDataSource hiveDataSource;
  late final FirebaseAuthDataSource firebaseAuthDataSource;
  late final FirebaseFirestoreDataSource firebaseFirestoreDataSource;
  late final NetworkInfo networkInfo;

  late final AuthRepository authRepository;
  late final TransactionRepository transactionRepository;
  late final GoalRepository goalRepository;
  late final SyncRepository syncRepository;

  late final CheckAuth checkAuth;
  late final SignInWithGoogle signInWithGoogle;
  late final SignInWithEmail signInWithEmail;
  late final SignUpWithEmail signUpWithEmail;
  late final SignOut signOut;

  late final GetTransactions getTransactions;
  late final AddTransaction addTransaction;
  late final UpdateTransactionUsecase updateTransaction;
  late final DeleteTransactionUsecase deleteTransaction;

  late final GetGoals getGoals;
  late final AddGoalUsecase addGoal;
  late final UpdateGoalUsecase updateGoal;
  late final DeleteGoalUsecase deleteGoal;
  late final ContributeToGoalUsecase contributeToGoal;
  late final RemoveContributionUsecase removeContribution;
  late final EditContributionUsecase editContribution;

  Future<void> init() async {
    if (_initialized) return;

    hiveDataSource = HiveDataSource();
    await hiveDataSource.init();

    firebaseAuthDataSource = FirebaseAuthDataSource();
    firebaseFirestoreDataSource = FirebaseFirestoreDataSource();
    networkInfo = NetworkInfoImpl(Connectivity());

    authRepository = AuthRepositoryImpl(firebaseAuthDataSource);
    transactionRepository = TransactionRepositoryImpl(
      firebaseFirestoreDataSource,
      hiveDataSource,
    );
    goalRepository = GoalRepositoryImpl(
      firebaseFirestoreDataSource,
      hiveDataSource,
    );
    syncRepository = SyncRepositoryImpl(
      firebaseFirestoreDataSource,
      hiveDataSource,
      Connectivity(),
    );
    await syncRepository.init();

    checkAuth = CheckAuth(authRepository);
    signInWithGoogle = SignInWithGoogle(authRepository);
    signInWithEmail = SignInWithEmail(authRepository);
    signUpWithEmail = SignUpWithEmail(authRepository);
    signOut = SignOut(authRepository);

    getTransactions = GetTransactions(transactionRepository);
    addTransaction = AddTransaction(transactionRepository);
    updateTransaction = UpdateTransactionUsecase(transactionRepository);
    deleteTransaction = DeleteTransactionUsecase(transactionRepository);

    getGoals = GetGoals(goalRepository);
    addGoal = AddGoalUsecase(goalRepository);
    updateGoal = UpdateGoalUsecase(goalRepository);
    deleteGoal = DeleteGoalUsecase(goalRepository);
    contributeToGoal = ContributeToGoalUsecase(goalRepository);
    removeContribution = RemoveContributionUsecase(goalRepository);
    editContribution = EditContributionUsecase(goalRepository);

    _initialized = true;
  }
}
