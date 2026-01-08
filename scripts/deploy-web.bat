@echo off
REM Script de déploiement web sur VPS
echo ========================================
echo Déploiement Web sur VPS - Titingre
echo ========================================

REM Configuration (à modifier selon votre VPS)
set VPS_USER=your_username
set VPS_IP=your_vps_ip
set VPS_PATH=/var/www/www.titingre.com
set LOCAL_BUILD=build\web

echo.
echo Configuration :
echo - Utilisateur VPS : %VPS_USER%
echo - IP VPS : %VPS_IP%
echo - Chemin VPS : %VPS_PATH%
echo - Build local : %LOCAL_BUILD%
echo.

REM Vérifier que le build existe
if not exist "%LOCAL_BUILD%\index.html" (
    echo ========================================
    echo ERREUR : Build web introuvable
    echo ========================================
    echo.
    echo Veuillez d'abord exécuter : build-web.bat
    echo.
    pause
    exit /b 1
)

echo ATTENTION : Ce script nécessite :
echo 1. SCP/SFTP configuré sur votre machine
echo 2. Accès SSH au VPS
echo.
echo Alternatives recommandées :
echo - Utiliser WinSCP ou FileZilla pour transférer les fichiers
echo - Utiliser Git pour déployer automatiquement
echo.
echo Fichiers à transférer :
echo - Depuis : %LOCAL_BUILD%\*
echo - Vers : %VPS_USER%@%VPS_IP%:%VPS_PATH%/
echo.

REM Si vous avez SCP installé (Git Bash, WSL, etc.)
echo Commande SCP à exécuter :
echo scp -r %LOCAL_BUILD%\* %VPS_USER%@%VPS_IP%:%VPS_PATH%/
echo.

pause

REM Décommenter si vous avez SCP installé
REM scp -r %LOCAL_BUILD%\* %VPS_USER%@%VPS_IP%:%VPS_PATH%/

echo.
echo ========================================
echo Déploiement terminé
echo ========================================
echo.
echo Vérifiez votre application sur :
echo https://www.titingre.com
echo.

pause
