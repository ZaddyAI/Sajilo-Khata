import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_sms_reader/android_sms_reader.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/sms_service.dart';
import '../../../data/datasources/remote/firebase_firestore_datasource.dart';

part 'sms_settings.dart';