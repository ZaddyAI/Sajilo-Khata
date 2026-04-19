import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();

  FirebaseService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> _ensureUserExists() async {
    final userDoc = _db.collection('users').doc(_uid);
    final doc = await userDoc.get();
    if (!doc.exists) {
      await userDoc.set({'createdAt': DateTime.now().toIso8601String()});
      await _db
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .doc('_placeholder')
          .set({'_init': true});
      await _db
          .collection('users')
          .doc(_uid)
          .collection('goals')
          .doc('_placeholder')
          .set({'_init': true});
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _db.collection('users').doc(_uid).collection('transactions');

  Future<void> addTransaction(String? duplicateKey, TransactionModel tx) async {
    await _ensureUserExists();
    // Store transaction with duplicate key in metadata for deduplication
    final data = tx.toMap();
    if (duplicateKey != null) {
      data['duplicateKey'] = duplicateKey;
    }
    await _txRef.doc(tx.id).set(data);
  }

  Future<bool> checkDuplicateTransaction(String key) async {
    await _ensureUserExists();
    final snapshot = await _txRef
        .where('duplicateKey', isEqualTo: key)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _ensureUserExists();
    await _txRef.doc(tx.id).update(tx.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _ensureUserExists();
    await _txRef.doc(id).delete();
  }

  Stream<List<TransactionModel>> transactionsStream() {
    return _txRef
        .orderBy('dateAD', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _goalRef =>
      _db.collection('users').doc(_uid).collection('goals');

  Future<void> addGoal(GoalModel goal) async {
    await _ensureUserExists();
    await _goalRef.doc(goal.id).set(goal.toMap());
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _ensureUserExists();
    await _goalRef.doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(String id) async {
    await _ensureUserExists();
    await _goalRef.doc(id).delete();
  }

  Stream<List<GoalModel>> goalsStream() {
    return _goalRef
        .orderBy('deadlineAD')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Contribute an amount to a goal and recalculate its status
  Future<void> contributeToGoal(String goalId, double amount) async {
    await _ensureUserExists();
    final doc = await _goalRef.doc(goalId).get();
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
        : goal.requiredDailyAmount >
              (goal.remaining / 1)
        ? GoalStatus.behind
        : GoalStatus.onTrack;

    await _goalRef.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory.map((e) {
        return {'id': e.id, 'amount': e.amount, 'date': e.date.toIso8601String()};
      }).toList(),
    });
  }

  Future<void> removeContribution(
    String goalId,
    String contributionId,
    double amount,
  ) async {
    await _ensureUserExists();
    final doc = await _goalRef.doc(goalId).get();
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

    await _goalRef.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory.map((e) {
        return {'id': e.id, 'amount': e.amount, 'date': e.date.toIso8601String()};
      }).toList(),
    });
  }

  Future<void> editContribution(
    String goalId,
    String contributionId,
    double oldAmount,
    double newAmount,
  ) async {
    await _ensureUserExists();
    final doc = await _goalRef.doc(goalId).get();
    if (!doc.exists) return;

    final goal = GoalModel.fromMap(doc.data()!, doc.id);
    final newHistory = goal.savingsHistory.map((c) {
      if (c.id == contributionId) {
        return SavingsContribution(
          id: c.id,
          amount: newAmount,
          date: c.date,
        );
      }
      return c;
    }).toList();
    final newSaved = goal.savedAmount - oldAmount + newAmount;
    final newStatus = newSaved >= goal.targetAmount
        ? GoalStatus.achieved
        : newSaved > 0 && goal.requiredDailyAmount > (goal.remaining / 1)
            ? GoalStatus.behind
            : GoalStatus.onTrack;

    await _goalRef.doc(goalId).update({
      'savedAmount': newSaved,
      'status': newStatus == GoalStatus.achieved
          ? 'achieved'
          : newStatus == GoalStatus.behind
          ? 'behind'
          : 'on_track',
      'savingsHistory': newHistory.map((e) {
        return {'id': e.id, 'amount': e.amount, 'date': e.date.toIso8601String()};
      }).toList(),
    });
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  Future<void> saveProfile(String name, String currency) async {
    await _ensureUserExists();
    await _db.collection('users').doc(_uid).set({
      'name': name,
      'currency': currency,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // ── SMS Settings ────────────────────────────────────────────────────

  Future<void> setSmsAutoTrack(bool enabled) async {
    await _ensureUserExists();
    await _db.collection('users').doc(_uid).set({
      'smsAutoTrack': enabled,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<bool> getSmsAutoTrack() async {
    await _ensureUserExists();
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data();
    if (data == null) return true;
    return data['smsAutoTrack'] as bool? ?? true;
  }

  Stream<bool> smsAutoTrackStream() {
    return _db.collection('users').doc(_uid).snapshots().map(
          (doc) {
            final data = doc.data();
            if (data == null) return true;
            return data['smsAutoTrack'] as bool? ?? true;
          },
        );
  }

  // SMS Groups
  static List<String> availableSmsGroups = [];

  Future<void> setSelectedSmsGroups(List<String> groups) async {
    await _ensureUserExists();
    await _db.collection('users').doc(_uid).set({
      'selectedSmsGroups': groups,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getSelectedSmsGroups() async {
    await _ensureUserExists();
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data();
    if (data == null || data['selectedSmsGroups'] == null) {
      return []; // no defaults
    }
    return List<String>.from(data['selectedSmsGroups']);
  }
}
