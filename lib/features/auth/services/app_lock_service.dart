import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AppLockResult { success, canceled, failed, unavailable }

abstract interface class AppLockService {
  Future<bool> get isAvailable;
  Future<AppLockResult> authenticate(String reason);
}

class LocalAuthAppLockService implements AppLockService {
  LocalAuthAppLockService([LocalAuthentication? auth]) : _auth = auth;

  LocalAuthentication? _auth;

  LocalAuthentication get _instance => _auth ??= LocalAuthentication();

  @override
  Future<bool> get isAvailable async {
    try {
      return await _instance.isDeviceSupported();
    } catch (_) {
      return false; // also covers MissingPluginException in tests
    }
  }

  @override
  Future<AppLockResult> authenticate(String reason) async {
    try {
      final ok = await _instance.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allows device passcode fallback
          stickyAuth: true,
        ),
      );
      return ok ? AppLockResult.success : AppLockResult.canceled;
    } on PlatformException catch (e) {
      const unavailable = {'NotAvailable', 'NotEnrolled', 'PasscodeNotSet'};
      return unavailable.contains(e.code)
          ? AppLockResult.unavailable
          : AppLockResult.failed;
    } catch (_) {
      return AppLockResult.unavailable;
    }
  }
}