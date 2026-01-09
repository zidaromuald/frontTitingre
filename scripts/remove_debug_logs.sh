#!/bin/bash

# Script pour supprimer les logs de débogage du profil IS
# Usage: ./scripts/remove_debug_logs.sh

echo "========================================="
echo "Suppression des logs de débogage - Profil IS"
echo "========================================="
echo ""

FILE="lib/is/onglets/paramInfo/profil.dart"

if [ ! -f "$FILE" ]; then
    echo "❌ Erreur: Le fichier $FILE n'existe pas"
    exit 1
fi

# Créer une sauvegarde
echo "📦 Création d'une sauvegarde..."
cp "$FILE" "${FILE}.backup"
echo "✅ Sauvegarde créée: ${FILE}.backup"
echo ""

# Compter le nombre de lignes avec print
BEFORE_COUNT=$(grep -c "print(" "$FILE" || true)
echo "📊 Nombre de lignes print() avant: $BEFORE_COUNT"
echo ""

# Supprimer les lignes contenant les logs de debug
echo "🧹 Suppression des logs de débogage..."
sed -i "/print('🚀 \[PROFIL IS\]/d" "$FILE"
sed -i "/print('📞 \[PROFIL IS\]/d" "$FILE"
sed -i "/print('🔍 \[PROFIL IS\]/d" "$FILE"
sed -i "/print('📡 \[PROFIL IS\]/d" "$FILE"
sed -i "/print('✅ \[PROFIL IS\]/d" "$FILE"
sed -i "/print('   📋/d" "$FILE"
sed -i "/print('   ✓/d" "$FILE"
sed -i "/print('   ⚠️/d" "$FILE"
sed -i "/print('🎨 \[PROFIL IS\]/d" "$FILE"
sed -i "/print('⏳ \[PROFIL IS\]/d" "$FILE"
sed -i "/print('❌ \[PROFIL IS\]/d" "$FILE"
sed -i "/print('   Type:/d" "$FILE"
sed -i "/print('   Message:/d" "$FILE"
sed -i "/print('   Stack trace:/d" "$FILE"

# Compter après suppression
AFTER_COUNT=$(grep -c "print(" "$FILE" || true)
REMOVED=$((BEFORE_COUNT - AFTER_COUNT))

echo "✅ Logs supprimés"
echo ""
echo "📊 Résultats:"
echo "   - Lignes print() avant: $BEFORE_COUNT"
echo "   - Lignes print() après: $AFTER_COUNT"
echo "   - Lignes supprimées: $REMOVED"
echo ""

if [ $REMOVED -gt 0 ]; then
    echo "✅ Suppression réussie!"
    echo ""
    echo "Pour restaurer depuis la sauvegarde:"
    echo "   cp ${FILE}.backup $FILE"
else
    echo "⚠️  Aucune ligne de debug trouvée"
    rm "${FILE}.backup"
fi

echo ""
echo "========================================="
