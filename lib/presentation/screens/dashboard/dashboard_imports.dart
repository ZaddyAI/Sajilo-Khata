import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';
import '../../bloc/transaction/transaction_state.dart';
import '../../bloc/goal/goal_bloc.dart';
import '../../bloc/goal/goal_event.dart';
import '../../bloc/goal/goal_state.dart';
import '../goals/goals_imports.dart';
import '../transactions/transactions_imports.dart';

part 'dashboard.dart';
