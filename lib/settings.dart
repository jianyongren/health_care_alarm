import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefSittingMinutesName = 'sitting_minutes';
const String _prefStandingMinutesName = 'standing_minutes';
const String _prefRingDuration = 'ring_seconds'; //响铃时长

class GlobalSettings {
  static final GlobalSettings _instance = GlobalSettings._();
  SharedPreferences? _preferences;

  GlobalSettings._();

  static GlobalSettings get instance => _instance;

  Future<void> init() async {
    if (kDebugMode) {
      SharedPreferences.setPrefix('debug.');
    }
    _preferences = await SharedPreferences.getInstance();
  }

  int get sitingMinutes {
    return _preferences?.getInt(_prefSittingMinutesName) ?? 30;
  }

  set sitingMinutes(int value) {
    _preferences?.setInt(_prefSittingMinutesName, value);
  }

  int get standMinutes {
    return _preferences?.getInt(_prefStandingMinutesName) ?? 15;
  }

  set standMinutes(int value) {
    _preferences?.setInt(_prefStandingMinutesName, value);
  }

  int get ringSeconds {
    return _preferences?.getInt(_prefRingDuration) ?? 30;
  }

  set ringSeconds(int value) {
    _preferences?.setInt(_prefRingDuration, value);
  }
}