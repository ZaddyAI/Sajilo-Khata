import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/goal.dart';
import '../../bloc/goal/goal_bloc.dart';
import '../../bloc/goal/goal_state.dart';
import '../../bloc/goal/goal_event.dart';

part 'goals_list.dart';
part 'add_goal.dart';
part 'goal_detail.dart';