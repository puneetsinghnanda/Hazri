import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The few system screens the app needs to send someone to.
///
/// Behind an interface so the iOS adapter in Phase 3 is a new class rather
/// than a rewrite (PRD §6.4).
abstract interface class SystemSettings {
  /// Opens this app's notification settings.
  Future<bool> openNotificationSettings();

  /// Whether battery optimisation is off for Hazri, or null when unknown
  /// (02-notifications DP4).
  Future<bool?> ignoringBatteryOptimizations();

  /// Whether Android will leave Hazri alone when it goes unused for months
  /// ("Pause app activity if unused" off), or null when unknown or the phone
  /// has no such setting (before Android 11).
  Future<bool?> unusedAppExempt();

  /// Opens that setting for Hazri.
  Future<bool> openUnusedAppSettings();

  /// Opens Hazri's own app page, where a phone maker's battery options are.
  Future<bool> openAppSettings();

  /// Google Play's install referrer string, or null (08-sangat IV6).
  Future<String?> installReferrer();

  /// Opens [url] in a browser. False when nothing on the phone can open it.
  Future<bool> openUrl(String url);
}

class AndroidSystemSettings implements SystemSettings {
  const AndroidSystemSettings();

  static const _channel = MethodChannel('app.hazri/system');

  @override
  Future<bool> openNotificationSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Hazri: could not open notification settings ($e)');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool?> ignoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>('ignoringBatteryOptimizations');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool?> unusedAppExempt() async {
    try {
      return await _channel.invokeMethod<bool>('unusedAppExempt');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> openUnusedAppSettings() => _open('openUnusedAppSettings');

  @override
  Future<bool> openAppSettings() => _open('openAppSettings');

  Future<bool> _open(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException catch (e) {
      debugPrint('Hazri: $method failed ($e)');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String?> installReferrer() async {
    try {
      return await _channel.invokeMethod<String>('installReferrer');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
    } on PlatformException catch (e) {
      debugPrint('Hazri: could not open $url ($e)');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
