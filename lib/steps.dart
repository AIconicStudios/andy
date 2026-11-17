import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'state.dart';

enum StepStatus { starting, counting, denied, unavailable }

/// Reads the phone's built-in step sensor. The sensor keeps counting in
/// hardware while Andy is closed, so steps are caught up whenever it opens.
class StepService extends ChangeNotifier {
  StepStatus status = kIsWeb ? StepStatus.unavailable : StepStatus.starting;
  StreamSubscription<StepCount>? _sub;

  bool get counting => status == StepStatus.counting;

  Future<void> start(AppState state) async {
    if (kIsWeb) return;
    // Android 10+ asks for "physical activity" permission. iOS asks on its
    // own the first time the motion sensor is read.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        _set(StepStatus.denied);
        return;
      }
    }
    await _sub?.cancel();
    _sub = Pedometer.stepCountStream.listen(
      (e) {
        state.recordStepCounter(e.steps);
        _set(StepStatus.counting);
      },
      onError: (Object e) {
        debugPrint('Step counter unavailable: $e');
        _set(defaultTargetPlatform == TargetPlatform.iOS &&
                '$e'.contains('denied')
            ? StepStatus.denied
            : StepStatus.unavailable);
      },
      cancelOnError: true,
    );
  }

  /// Opens the phone's settings for Andy, for when permission was refused.
  Future<void> openSettings() => openAppSettings();

  void _set(StepStatus s) {
    if (status == s) return;
    status = s;
    notifyListeners();
  }
}

final stepService = StepService();
