import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/network_info.dart';
import '../data/datasources/local/hive_datasource.dart';
import '../data/datasources/remote/firebase_auth_datasource.dart';
import '../data/datasources/remote/firebase_firestore_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/goal_repository_impl.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../data/repositories/transaction_repository_impl.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_goal_repository.dart';
import '../domain/repositories/i_sync_repository.dart';
import '../domain/repositories/i_transaction_repository.dart';

List<RepositoryProvider> repoProviders(HiveDataSource hive) {
  final firestore = FirebaseFirestoreDataSource();
  final connectivity = Connectivity();

  return [
    RepositoryProvider<FirebaseAuthDataSource>(
      create: (_) => FirebaseAuthDataSource(),
    ),
    RepositoryProvider<FirebaseFirestoreDataSource>(create: (_) => firestore),
    RepositoryProvider<HiveDataSource>(create: (_) => hive),
    RepositoryProvider<NetworkInfo>(
      create: (_) => NetworkInfoImpl(connectivity),
    ),
    RepositoryProvider<AuthRepository>(
      create: (context) =>
          AuthRepositoryImpl(context.read<FirebaseAuthDataSource>()),
    ),
    RepositoryProvider<TransactionRepository>(
      create: (context) => TransactionRepositoryImpl(firestore, hive),
    ),
    RepositoryProvider<GoalRepository>(
      create: (context) => GoalRepositoryImpl(firestore, hive),
    ),
    RepositoryProvider<SyncRepository>(
      create: (context) => SyncRepositoryImpl(firestore, hive, connectivity),
    ),
  ];
}
