# Instructions de Configuration Firebase

## Prérequis

1. Compte Google pour Firebase Console
2. Flutter SDK installé
3. Accès aux consoles Android/iOS (si déploiement mobile)

## Étapes de Configuration

### 1. Créer un Projet Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur "Ajouter un projet"
3. Entrer le nom du projet: `gestauth-clean` (ou autre)
4. Activer/Désactiver Google Analytics (optionnel)
5. Cliquer sur "Créer le projet"

### 2. Activer l'Authentification par Téléphone

1. Dans Firebase Console, aller dans **Authentication**
2. Cliquer sur **Get Started** (si premier usage)
3. Aller dans l'onglet **Sign-in method**
4. Trouver **Phone** dans la liste des fournisseurs
5. Cliquer dessus et **Activer** le fournisseur
6. Sauvegarder

### 3. Configuration Android

#### 3.1 Ajouter l'Application Android

1. Dans Firebase Console, cliquer sur l'icône Android
2. Entrer le nom du package Android: `com.example.gestauth_clean`
   - Trouver dans `android/app/build.gradle` → `applicationId`
3. (Optionnel) Ajouter un alias d'application
4. (Optionnel) Ajouter le SHA-1 de débogage:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copier la valeur SHA-1 du variant `debug`
5. Télécharger le fichier `google-services.json`

#### 3.2 Placer google-services.json

Copier `google-services.json` dans:
```
android/app/google-services.json
```

#### 3.3 Modifier android/build.gradle

Ajouter le classpath Google Services:

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath 'com.google.gms:google-services:4.4.0'  // ← AJOUTER CETTE LIGNE
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

#### 3.4 Modifier android/app/build.gradle

En haut du fichier, après les autres plugins:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // ← AJOUTER CETTE LIGNE
}
```

En bas du fichier, ajouter:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
}
```

Vérifier que `minSdkVersion` est au moins **21**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // ← MINIMUM 21
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

### 4. Configuration iOS

#### 4.1 Ajouter l'Application iOS

1. Dans Firebase Console, cliquer sur l'icône iOS
2. Entrer le Bundle ID: `com.example.gestauthClean`
   - Trouver dans `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`
3. (Optionnel) Ajouter un App Store ID
4. Télécharger le fichier `GoogleService-Info.plist`

#### 4.2 Placer GoogleService-Info.plist

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Glisser-déposer `GoogleService-Info.plist` dans le dossier `Runner`
3. Cocher "Copy items if needed"
4. S'assurer que la target "Runner" est sélectionnée

#### 4.3 Modifier ios/Podfile

Vérifier que la plateforme iOS est au moins **13.0**:

```ruby
# Au début du fichier
platform :ios, '13.0'  # ← MINIMUM 13.0
```

### 5. Initialiser Firebase dans l'Application

#### 5.1 Créer firebase_options.dart

Exécuter la commande FlutterFire CLI (recommandé):

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer Firebase automatiquement
flutterfire configure
```

Cette commande génère automatiquement `lib/firebase_options.dart`.

**OU** créer manuellement le fichier `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'VOTRE_WEB_API_KEY',
    appId: 'VOTRE_WEB_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    authDomain: 'VOTRE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'VOTRE_ANDROID_API_KEY',
    appId: 'VOTRE_ANDROID_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'VOTRE_IOS_API_KEY',
    appId: 'VOTRE_IOS_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.gestauthClean',
  );
}
```

Trouver ces valeurs dans Firebase Console > Project Settings > Your apps.

#### 5.2 Modifier lib/main.dart

Ajouter l'initialisation Firebase:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Obligatoire pour Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestAuth',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const LoginScreen(), // Votre écran de connexion
    );
  }
}
```

### 6. Tests de Configuration

#### 6.1 Test Android

```bash
flutter run -d android
```

Vérifier dans les logs:
```
[Firebase/Auth] Auth initialized
```

#### 6.2 Test iOS

```bash
flutter run -d ios
```

#### 6.3 Test de l'Envoi OTP

1. Lancer l'application
2. Aller sur "Mot de passe oublié"
3. Entrer un numéro de téléphone valide
4. Vérifier la réception du SMS

### 7. Configuration Avancée (Production)

#### 7.1 Quotas Firebase

Par défaut (plan gratuit Spark):
- **10,000 vérifications SMS/mois**
- Au-delà: Plan Blaze (pay-as-you-go)

#### 7.2 Domaines Autorisés

1. Firebase Console > Authentication > Settings
2. Onglet **Authorized domains**
3. Ajouter vos domaines de production

#### 7.3 Configuration reCAPTCHA (Web)

Pour le web, Firebase nécessite reCAPTCHA:

1. Aller dans Firebase Console > Authentication > Settings
2. Activer reCAPTCHA v3 pour le web
3. Ajouter les domaines autorisés

### 8. Dépannage

#### Erreur: "The SHA-1 fingerprint is invalid"

**Solution**:
```bash
cd android
./gradlew signingReport
```
Copier le SHA-1 et l'ajouter dans Firebase Console.

#### Erreur: "google-services.json not found"

**Solution**: Vérifier que le fichier est dans `android/app/google-services.json`

#### Erreur: "FirebaseApp has not been initialized"

**Solution**: Vérifier que `Firebase.initializeApp()` est appelé avant `runApp()` dans `main.dart`

#### Erreur: "invalid-phone-number"

**Solution**: S'assurer d'utiliser le format international (+226...)

#### SMS non reçu (Développement)

**Solution temporaire**: Utiliser des numéros de test dans Firebase Console:
1. Authentication > Sign-in method > Phone
2. Ajouter un "Test phone number"
3. Numéro: +1 234 567 8901
4. Code: 123456

### 9. Checklist de Validation

- [ ] Firebase project créé
- [ ] Authentification par téléphone activée
- [ ] `google-services.json` placé (Android)
- [ ] `GoogleService-Info.plist` placé (iOS)
- [ ] `firebase_options.dart` créé
- [ ] `Firebase.initializeApp()` dans main.dart
- [ ] `flutter pub get` exécuté
- [ ] Application compile sans erreur
- [ ] SMS OTP reçu lors d'un test
- [ ] Réinitialisation de mot de passe fonctionne

### 10. Ressources

- [Documentation Firebase Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Phone Authentication](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

## Support

En cas de problème, vérifier:
1. Les logs de l'application (`flutter run --verbose`)
2. Firebase Console > Authentication > Users (vérifier les tentatives)
3. Firebase Console > Analytics > Events (si activé)
