import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diagnostics (02-notifications DP6): alarms set straight through Android,
/// without the notification plugin, and what became of them. Behind an
/// interface like every platform part (CLAUDE.md rule 6).
abstract interface class AlarmProbe {
  /// Sets one probe alarm [seconds] from now: `exact` the way reminders are
  /// set, `clock` as an alarm-clock alarm. Answers when it is due, or null.
  Future<DateTime?> schedule(String kind, {required int seconds, required String title, required String body});

  /// What was set and what arrived; null when unknown.
  Future<AlarmProbeResults?> results();

  /// Opens the system list where battery optimisation is switched off.
  Future<void> openBatterySettings();
}

/// The two probes' due and arrival times; null where there is none.
class AlarmProbeResults {
  const AlarmProbeResults({this.plannedExact, this.firedExact, this.plannedClock, this.firedClock});

  final DateTime? plannedExact;
  final DateTime? firedExact;
  final DateTime? plannedClock;
  final DateTime? firedClock;
}

class AndroidAlarmProbe implements AlarmProbe {
  const AndroidAlarmProbe();

  static const _channel = MethodChannel('app.hazri/system');

  static DateTime? _at(Object? ms) =>
      ms is int && ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

  @override
  Future<DateTime?> schedule(String kind, {required int seconds, required String title, required String body}) async {
    try {
      return _at(await _channel.invokeMethod<int>(
        'probeAlarm',
        {'kind': kind, 'seconds': seconds, 'title': title, 'body': body},
      ));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<AlarmProbeResults?> results() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('probeResults');
      if (m == null) return null;
      return AlarmProbeResults(
        plannedExact: _at(m['plannedExact']),
        firedExact: _at(m['firedExact']),
        plannedClock: _at(m['plannedClock']),
        firedClock: _at(m['firedClock']),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<bool>('openBatterySettings');
    } on PlatformException {
      // Nothing to open on this phone.
    } on MissingPluginException {
      // Tests and non-Android.
    }
  }
}

final alarmProbeProvider = Provider<AlarmProbe>((ref) => const AndroidAlarmProbe());
