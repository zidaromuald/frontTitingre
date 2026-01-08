#!/bin/bash

# Script de déploiement Web pour Hostinger
# Exclut automatiquement le dossier documentation du build

echo "========================================="
echo "Déploiement Web - Titingre"
echo "========================================="
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Flutter"
    exit 1
fi

# Nettoyer les builds précédents
echo "🧹 Nettoyage des builds précédents..."
rm -rf build/web
echo "✅ Nettoyage terminé"
echo ""

# Build de l'application web
echo "🔨 Build de l'application web..."
flutter build web --release --web-renderer canvaskit

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du build"
    exit 1
fi
echo "✅ Build terminé"
echo ""

# Supprimer le dossier documentation du build
echo "📂 Suppression de la documentation du build web..."
if [ -d "build/web/assets/lib/services/documentation" ]; then
    rm -rf build/web/assets/lib/services/documentation
    echo "✅ Documentation supprimée du build"
else
    echo "ℹ️  Dossier documentation non trouvé dans le build (normal)"
fi
echo ""

# Afficher la taille du build
echo "📊 Taille du build:"
du -sh build/web
echo ""

echo "========================================="
echo "✅ Build prêt pour le déploiement!"
echo "========================================="
echo ""
echo "Fichiers à déployer: build/web/"
echo ""
echo "Pour déployer sur Hostinger:"
echo "1. Compressez le dossier build/web en .zip"
echo "2. Uploadez via File Manager Hostinger"
echo "3. Décompressez dans public_html/"
echo ""
echo "Ou utilisez rsync/FTP selon votre configuration"
