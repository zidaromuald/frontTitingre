# Configuration Android pour Google Play Store

## Prérequis

- Compte Google Play Console (99$ unique)
- Clé de signature d'application
- Application prête pour la production

## Étape 1 : Configuration du fichier build.gradle

### android/app/build.gradle

Vérifiez les configurations suivantes :

```gradle
android {
    namespace "com.titingre.gestauth"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.titingre.gestauth"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

## Étape 2 : Créer une clé de signature

```bash
# Sur Windows (dans le terminal)
keytool -genkey -v -keystore c:\Users\VOTRE_NOM\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Questions à répondre :
# - Mot de passe du keystore : [CHOISIR UN MOT DE PASSE FORT]
# - Nom et prénom : Titingre
# - Nom de l'organisation : Titingre
# - Pays : [VOTRE PAYS]
```

**⚠️ IMPORTANT : Sauvegardez ce fichier et les mots de passe dans un endroit sûr !**

## Étape 3 : Configurer key.properties

Créez le fichier `android/key.properties` :

```properties
storePassword=VOTRE_STORE_PASSWORD
keyPassword=VOTRE_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\VOTRE_NOM\\upload-keystore.jks
```

**⚠️ IMPORTANT : Ajoutez `key.properties` au `.gitignore` !**

## Étape 4 : Mettre à jour AndroidManifest.xml

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>

    <!-- Pour Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

    <application
        android:label="Titingre"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">

        <!-- Configuration Firebase -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorAccent" />

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## Étape 5 : Configuration de sécurité réseau

Créez `android/app/src/main/res/xml/network_security_config.xml` :

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- Configuration pour le domaine API -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.titingre.com</domain>
        <domain includeSubdomains="true">titingre.com</domain>
    </domain-config>
</network-security-config>
```

## Étape 6 : Build de l'APK/App Bundle

### Build App Bundle (recommandé pour Play Store)

```bash
flutter clean
flutter pub get
flutter build appbundle --release

# L'App Bundle sera dans : build/app/outputs/bundle/release/app-release.aab
```

### Build APK (pour tests)

```bash
flutter build apk --release --split-per-abi

# Les APK seront dans : build/app/outputs/flutter-apk/
# - app-armeabi-v7a-release.apk (ARM 32-bit)
# - app-arm64-v8a-release.apk (ARM 64-bit)
# - app-x86_64-release.apk (x86 64-bit)
```

## Étape 7 : Préparer les assets pour Play Store

### Icône de l'application
- **Taille** : 512x512 px
- **Format** : PNG avec transparence
- **Localisation** : À uploader dans Play Console

### Screenshots
Préparez des captures d'écran pour :
- **Téléphone** : minimum 2 screenshots (1080x1920 ou 1920x1080)
- **Tablette 7"** : minimum 2 screenshots (optionnel)
- **Tablette 10"** : minimum 2 screenshots (optionnel)

### Feature Graphic
- **Taille** : 1024x500 px
- **Format** : PNG ou JPG

### Description courte
- Maximum 80 caractères
- Exemple : "Réseau social professionnel pour entrepreneurs"

### Description complète
- Maximum 4000 caractères
- Décrivez les fonctionnalités principales

## Étape 8 : Configuration Firebase pour Android

### Télécharger google-services.json

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet
3. Paramètres du projet → Général
4. Sous "Vos applications" → Android
5. Téléchargez `google-services.json`
6. Placez le fichier dans `android/app/google-services.json`

### Vérifier build.gradle

Dans `android/build.gradle` :

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Dans `android/app/build.gradle` (à la fin) :

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Étape 9 : Soumettre sur Google Play Console

1. **Créer l'application**
   - Allez sur [Google Play Console](https://play.google.com/console)
   - Créez une nouvelle application
   - Remplissez les informations de base

2. **Configuration de la fiche du Store**
   - Ajoutez les descriptions (courte et complète)
   - Uploadez les screenshots
   - Ajoutez l'icône et le feature graphic
   - Définissez la catégorie (Social, Business, etc.)

3. **Classification du contenu**
   - Remplissez le questionnaire
   - Obtenez une classification d'âge

4. **Prix et distribution**
   - Gratuit ou payant
   - Pays de distribution
   - Politiques de confidentialité

5. **Configuration de la version**
   - Production → Créer une version
   - Uploadez l'App Bundle (.aab)
   - Ajoutez les notes de version
   - Soumettez pour examen

## Étape 10 : Politique de confidentialité

Créez une page de politique de confidentialité accessible publiquement.

Exemple d'URL : `https://titingre.com/privacy-policy`

## Checklist avant soumission

- [ ] Application signée avec la clé de production
- [ ] `google-services.json` configuré
- [ ] Toutes les permissions nécessaires déclarées
- [ ] Screenshots de qualité (minimum 2)
- [ ] Icône 512x512 px
- [ ] Feature graphic 1024x500 px
- [ ] Description courte et complète
- [ ] Politique de confidentialité publiée
- [ ] URL du site web configurée
- [ ] Catégorie d'application choisie
- [ ] Classification du contenu complétée
- [ ] App Bundle (.aab) uploadé
- [ ] Notes de version ajoutées

## Délai de révision

- **Première soumission** : 7-14 jours
- **Mises à jour** : 1-3 jours

## Mises à jour futures

Pour chaque mise à jour :

1. Incrémenter `versionCode` et `versionName` dans `build.gradle`
2. Build un nouveau App Bundle
3. Créer une nouvelle version dans Play Console
4. Uploader l'App Bundle
5. Ajouter les notes de version
6. Soumettre pour examen

```gradle
defaultConfig {
    versionCode 2        // Incrémenter à chaque release
    versionName "1.0.1"  // Version visible par les utilisateurs
}
```
