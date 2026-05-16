class ApiConstants {
  // Use 10.0.2.2 for Android Emulator
  // Use your computer's IP (e.g., 10.155.218.4) for physical devices
  static const String _localIp =
      '192.168.100.56'; // Updated back to 192.168.100.56
  static const String _emulatorIp = '10.0.2.2';

  // Toggle this based on whether you are using an emulator or physical device
  static const bool isEmulator = false;

  static String get baseUrl => 'https://digital-seerah-app.onrender.com/api';

  static String get chatQueryUrl => '$baseUrl/chat/query';
  static String get transcribeUrl => '$baseUrl/speech/transcribe';
  static String get quizUrl => '$baseUrl/quiz';
}
