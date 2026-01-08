@echo off
REM Script de build pour Android
echo ========================================
echo Build Flutter Android - Titingre
echo ========================================

REM Nettoyer les builds précédents
echo.
echo [1/5] Nettoyage des builds précédents...
call flutter clean

REM Récupérer les dépendances
echo.
echo [2/5] Récupération des dépendances...
call flutter pub get

REM Build App Bundle (pour Play Store)
echo.
echo [3/5] Build de l'App Bundle (.aab) pour Play Store...
call flutter build appbundle --release

REM Build APK split (pour tests)
echo.
echo [4/5] Build des APK pour tests...
call flutter build apk --release --split-per-abi

REM Vérifier les builds
echo.
echo [5/5] Vérification des builds...

set AAB_FILE=build\app\outputs\bundle\release\app-release.aab
set APK_ARM64=build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

if exist "%AAB_FILE%" (
    echo.
    echo ========================================
    echo Build réussi !
    echo ========================================
    echo.
    echo App Bundle (Play Store) :
    echo %AAB_FILE%
    echo.
    echo APK (Tests) :
    echo %APK_ARM64%
    echo.
    echo Prochaines étapes :
    echo 1. Tester l'APK sur un appareil Android
    echo 2. Uploader l'App Bundle (.aab) sur Google Play Console
    echo.
) else (
    echo.
    echo ========================================
    echo Erreur : Le build a échoué
    echo ========================================
    echo.
)

pause
