/// Biometric authentication service — Phase 2 sprint 1 step 4 (2026-05-06).
///
/// Wrapper quanh `local_auth` package. Cung cấp:
/// - isAvailable(): kiểm tra device có support biometric (FaceID/TouchID/Fingerprint) không
/// - authenticate(reason): prompt user xác thực, trả true nếu success
///
/// Web fallback: `local_auth` KHÔNG support web → check `kIsWeb` trả false ở
/// isAvailable(). UI hide button biometric trên web.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra device có support biometric + đã setup ít nhất 1 fingerprint/face không.
  /// Trả false trên web hoặc device không có hardware/setup.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      // Kiểm tra có ít nhất 1 biometric đã enroll (vd fingerprint)
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompt user xác thực biometric. Trả true nếu success.
  ///
  /// `reason`: text hiện trên dialog (vd "Mở khóa PTIT Contest")
  /// `cancelLabel`: nút cancel (default "Hủy")
  Future<bool> authenticate({
    String reason = 'Xác thực để đăng nhập PTIT Contest',
    String cancelLabel = 'Hủy',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,  // CHỈ biometric, không fallback PIN/Pattern
          stickyAuth: true,     // Giữ session khi user switch app rồi quay lại
        ),
      );
    } catch (_) {
      // User cancel hoặc lockout → trả false, caller fallback login form
      return false;
    }
  }

  /// Lấy danh sách biometric available (FaceID / TouchID / Fingerprint / Iris).
  /// Dùng để hiện icon chính xác trên UI (vd "Đăng nhập bằng Face ID" vs "Vân tay").
  Future<List<BiometricType>> availableTypes() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
