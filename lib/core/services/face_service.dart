/// Face ID / Liveness verification service
/// MVP: всегда возвращает true (mock)
/// Продакшн: раскомментировать Face++ API вызов
class FaceService {
  FaceService._();

  static bool _isMockMode = true; // Переключить в false для реального Face++

  /// Верификация живого лица (liveness detection)
  static Future<bool> verifyLiveness() async {
    if (_isMockMode) {
      // MVP MOCK — всегда возвращает verified: true
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    // TODO: Продакшн — раскомментировать когда придёт время
    // final image = await _captureImage();
    // final result = await FacePlusPlusApi.detectLiveness(
    //   apiKey: dotenv.env['FACEPP_API_KEY']!,
    //   apiSecret: dotenv.env['FACEPP_API_SECRET']!,
    //   imageBase64: image,
    // );
    // return result.confidence > 0.9;

    return true;
  }

  /// Биометрический вход (Face ID нативный)
  static Future<bool> authenticateWithBiometrics() async {
    if (_isMockMode) return true;

    // TODO: использовать local_auth пакет
    // final auth = LocalAuthentication();
    // return await auth.authenticate(
    //   localizedReason: 'Войдите через Face ID',
    //   options: const AuthenticationOptions(biometricOnly: true),
    // );

    return true;
  }
}
