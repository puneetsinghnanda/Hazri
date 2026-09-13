import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The few system screens the app needs to send someone to.
///
/// Behind an interface so the iOS adapter in Phase 3 is a new class rather
/// than a rewrite (PRD §6.4).
abstract interface class SystemSettings {
  /// Opens this app's notification settings.
  Future<bool> openNotificationSettings();
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
}
