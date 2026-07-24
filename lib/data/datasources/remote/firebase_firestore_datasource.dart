import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/goal.dart';

class FirebaseFirestoreDataSource {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirebaseFirestoreDataSource()
    : _db = FirebaseFirestore.instance,
      _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _txRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('transactions');
  }

  CollectionReference<Map<String, dynamic>>? get _goalRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('goals');
  }

  // ── Transactions ──

  Future<void> addTransaction(String? duplicateKey, Transaction tx) async {
    final ref = _txRef;
    if (ref == null) throw Exception('User not authenticated');
    final data = TransactionModel.toMap(tx);
    if (duplicateKey != null) {
      data['duplicateKey'] = duplicateKey;
    }
    await ref.doc(tx.id).set(data);
  }

  Future<bool> checkDuplicate(String key) async {
    final ref = _txRef;
    if (ref == null) return false;
    final snapshot = await ref
        .where('duplicateKey', isEqualTo: key)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateTransaction(Transaction tx) async {
    final ref = _txRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(tx.id).update(TransactionModel.toMap(tx));
  }

  Future<void> deleteTransaction(String id) async {
    final ref = _txRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(id).delete();
  }

  Stream<List<Transaction>> transactionsStream() {
    final ref = _txRef;
    if (ref == null) return const Stream.empty();
    return ref
        .orderBy('dateAD', descending: true)
        .snapshots()
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (snap, sink) {
              try {
                sink.add(
                  snap.docs
                      .map(
                        (doc) => TransactionModel.fromMap(doc.data(), doc.id),
                      )
                      .toList(),
                );
              } catch (e) {
                print('[Firestore] tx map error: $e');
                sink.add([]);
              }
            },
            handleError: (error, stack, sink) {
              print('[Firestore] tx stream error: $error');
              sink.add([]);
            },
          ),
        );
  }

  Future<List<Transaction>> fetchAllTransactions() async {
    final ref = _txRef;
    if (ref == null) return [];
    final snap = await ref.orderBy('dateAD', descending: true).get();
    return snap.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Goals ──

  Future<void> addGoal(Goal goal) async {
    final ref = _goalRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(goal.id).set(GoalModel.toMap(goal));
  }

  Future<void> updateGoal(Goal goal) async {
    final ref = _goalRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(goal.id).update(GoalModel.toMap(goal));
  }

  Future<void> deleteGoal(String id) async {
    final ref = _goalRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(id).delete();
  }

  Stream<List<Goal>> goalsStream() {
    final ref = _goalRef;
    if (ref == null) return const Stream.empty();
    return ref
        .orderBy('deadlineAD')
        .snapshots()
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (snap, sink) {
              try {
                sink.add(
                  snap.docs
                      .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
                      .toList(),
                );
              } catch (e) {
                print('[Firestore] goal map error: $e');
                sink.add([]);
              }
            },
            handleError: (error, stack, sink) {
              print('[Firestore] goal stream error: $error');
              sink.add([]);
            },
          ),
        );
  }

  Future<List<Goal>> fetchAllGoals() async {
    final ref = _goalRef;
    if (ref == null) return [];
    final snap = await ref.get();
    return snap.docs
        .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> contributeToGoal(String goalId, double amount) async {
    final ref = _goalRef;
    if (ref == null) return;
    final doc = await ref.doc(goalId).get();
    if (!doc.exists) return;

    final goal = GoalModel.fromMap(doc.data()!, doc.id);
    final contribution = SavingsContribution(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
    );
    final newHistory = [...goal.savingsHistory, contribution];
    final newSaved = goal.savedAmount + amount;
    final newStatus = newSaved >= goal.targetAmount
        ? GoalStatus.achieved
        : goal.requiredDailyAmount > (goal.remaining / 1)
        ? GoalStatus.behind
        : GoalStatus.onTrack;

    await ref.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory
          .map(
            (e) => {
              'id': e.id,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  Future<void> removeContribution(
    String goalId,
    String contributionId,
    double amount,
  ) async {
    final ref = _goalRef;
    if (ref == null) return;
    final doc = await ref.doc(goalId).get();
    if (!doc.exists) return;

    final goal = GoalModel.fromMap(doc.data()!, doc.id);
    final newHistory = goal.savingsHistory
        .where((c) => c.id != contributionId)
        .toList();
    final newSaved = (goal.savedAmount - amount).clamp(0.0, double.infinity);
    final newStatus = newSaved >= goal.targetAmount
        ? GoalStatus.achieved
        : newSaved > 0 && goal.requiredDailyAmount > (goal.remaining / 1)
        ? GoalStatus.behind
        : GoalStatus.onTrack;

    await ref.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory
          .map(
            (e) => {
              'id': e.id,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  Future<void> editContribution(
    String goalId,
    String contributionId,
    double oldAmount,
    double newAmount,
  ) async {
    final ref = _goalRef;
    if (ref == null) return;
    final doc = await ref.doc(goalId).get();
    if (!doc.exists) return;

    final goal = GoalModel.fromMap(doc.data()!, doc.id);
    final newHistory = goal.savingsHistory.map((c) {
      if (c.id == contributionId) {
        return SavingsContribution(id: c.id, amount: newAmount, date: c.date);
      }
      return c;
    }).toList();
    final newSaved = goal.savedAmount - oldAmount + newAmount;
    final newStatus = newSaved >= goal.targetAmount
        ? GoalStatus.achieved
        : newSaved > 0 && goal.requiredDailyAmount > (goal.remaining / 1)
        ? GoalStatus.behind
        : GoalStatus.onTrack;

    await ref.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory
          .map(
            (e) => {
              'id': e.id,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  // ── SMS Settings ──

  Future<void> setSmsAutoTrack(bool enabled) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'smsAutoTrack': enabled,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<bool> getSmsAutoTrack() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return true;
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['smsAutoTrack'] as bool?) ?? true;
  }

  Stream<bool> smsAutoTrackStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(true);
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => (doc.data()?['smsAutoTrack'] as bool?) ?? true);
  }

  Future<void> setSelectedSmsGroups(List<String> groups) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'selectedSmsGroups': groups,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getSelectedSmsGroups() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['selectedSmsGroups'] == null) return [];
    return List<String>.from(data['selectedSmsGroups']);
  }

  // ── Sample Data ──

  Future<void> createSampleData() async {
    final txRef = _txRef;
    final goalRef = _goalRef;
    if (txRef == null || goalRef == null) return;

    final existingTx = await txRef.limit(1).get();
    final existingGoal = await goalRef.limit(1).get();
    final now = DateTime.now();

    if (existingTx.docs.isEmpty) {
      await txRef.doc('welcome-tx').set({
        'amount': 0,
        'type': 'credit',
        'source': 'manual',
        'category': 'Other',
        'bank': null,
        'note': 'Welcome! Tap + to add your first transaction.',
        'dateAD': now.toIso8601String(),
        'dateBS': '',
        'createdAt': now.toIso8601String(),
      });
    }

    if (existingGoal.docs.isEmpty) {
      await goalRef.doc('sample-goal').set({
        'name': 'Your First Goal',
        'emoji': '🎯',
        'targetAmount': 10000,
        'savedAmount': 0,
        'deadlineAD': now.add(const Duration(days: 90)).toIso8601String(),
        'deadlineBS': '',
        'status': 'on_track',
        'createdAt': now.toIso8601String(),
        'savingsHistory': [],
      });
    }
  }
}
