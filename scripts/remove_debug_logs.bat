@echo off
REM Script pour supprimer les logs de débogage du profil IS
REM Usage: scripts\remove_debug_logs.bat

echo =========================================
echo Suppression des logs de debogage - Profil IS
echo =========================================
echo.

set FILE=lib\is\onglets\paramInfo\profil.dart

if not exist "%FILE%" (
    echo Erreur: Le fichier %FILE% n'existe pas
    exit /b 1
)

REM Créer une sauvegarde
echo Creation d'une sauvegarde...
copy "%FILE%" "%FILE%.backup" > nul
echo Sauvegarde creee: %FILE%.backup
echo.

REM Information pour l'utilisateur
echo Suppression des logs de debogage...
echo.
echo ATTENTION: Ce script necessite une edition manuelle sur Windows.
echo.
echo Instructions:
echo 1. Ouvrez le fichier: %FILE%
echo 2. Recherchez et supprimez toutes les lignes contenant:
echo    - print('🚀 [PROFIL IS]
echo    - print('📞 [PROFIL IS]
echo    - print('🔍 [PROFIL IS]
echo    - print('📡 [PROFIL IS]
echo    - print('✅ [PROFIL IS]
echo    - print('   📋
echo    - print('   ✓
echo    - print('   ⚠️
echo    - print('🎨 [PROFIL IS]
echo    - print('⏳ [PROFIL IS]
echo    - print('❌ [PROFIL IS]
echo    - print('   Type:
echo    - print('   Message:
echo    - print('   Stack trace:
echo.
echo 3. Sauvegardez le fichier
echo.
echo Pour restaurer depuis la sauvegarde:
echo    copy %FILE%.backup %FILE%
echo.
echo =========================================

pause
