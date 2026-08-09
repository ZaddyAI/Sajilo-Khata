import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/goal.dart';
import '../../bloc/goal/goal_bloc.dart';
import '../../bloc/goal/goal_state.dart';
import '../../bloc/goal/goal_event.dart';

part 'goals_list.dart';
part 'add_goal.dart';
part 'goal_detail.dart';
part 'edit_goal.dart';
part 'goal_achieved.dart';
part 'add_savings_bottom_sheet.dart';
