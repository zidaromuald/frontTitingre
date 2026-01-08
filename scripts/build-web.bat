@echo off
REM Script de build pour le web
echo ========================================
echo Build Flutter Web - Titingre
echo ========================================

REM Nettoyer les builds précédents
echo.
echo [1/4] Nettoyage des builds précédents...
call flutter clean

REM Récupérer les dépendances
echo.
echo [2/4] Récupération des dépendances...
call flutter pub get

REM Build pour la production
echo.
echo [3/4] Build de l'application web...
call flutter build web --release --base-href /

REM Vérifier le build
echo.
echo [4/4] Vérification du build...
if exist "build\web\index.html" (
    echo.
    echo ========================================
    echo Build réussi !
    echo ========================================
    echo.
    echo Les fichiers sont dans : build\web\
    echo.
    echo Prochaines étapes :
    echo 1. Transférer les fichiers sur le VPS
    echo 2. Utiliser le script deploy-web.bat
    echo.
) else (
    echo.
    echo ========================================
    echo Erreur : Le build a échoué
    echo ========================================
    echo.
)

pause
