import 'package:flutter/foundation.dart';

/// Configuration de l'application selon l'environnement
class AppConfig {
  // URL de base de l'API - utilisée par web et mobile
  static const String apiBaseUrl = 'https://api.titingre.com';

  // URL de l'application web
  static const String webAppUrl = 'https://www.titingre.com';

  // URL du site web
  static const String websiteUrl = 'https://titingre.com';

  // Configuration Firebase
  static const String firebaseProjectId = 'votre-project-id';

  // Paramètres de l'application
  static const String appName = 'Titingre';
  static const String appVersion = '1.0.0';

  // Taille maximale des fichiers (en bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50 MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50 MB

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Détection de l'environnement
  static bool get isProduction => !kDebugMode;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
}
