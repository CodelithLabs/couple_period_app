import 'dart:async';

import 'package:couple_period_app/app.dart';
import 'package:couple_period_app/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? bootstrapError;

  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'bootstrap',
      ),
    );
    bootstrapError = error;
  }

  runApp(ProviderScope(child: CouplePeriodApp(bootstrapError: bootstrapError)));
}
