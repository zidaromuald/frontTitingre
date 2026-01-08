# Guide de Déploiement Web - Sans Documentation

## Résumé

✅ **La documentation est dans Git mais NE SERA PAS déployée sur le web**

## Comment ça fonctionne ?

### 1. Flutter ne déploie que les assets déclarés

Dans `pubspec.yaml`, seuls ces fichiers sont inclus :
```yaml
assets:
  - images/logo.png
  - images/icon.png
```

**Résultat :** Le dossier `lib/services/documentation/` n'apparaîtra jamais dans `build/web/`

### 2. Vérification automatique

Testez maintenant :

```bash
# Build web
flutter build web --release

# Vérifier que documentation n'existe pas
ls build/web/assets/lib/services/documentation
# Devrait afficher: "No such file or directory"
```

## Déploiement sur Hostinger

### Étapes simples

```bash
# 1. Build
flutter build web --release

# 2. Vérifier la taille (sans la doc, devrait être < 10 MB)
du -sh build/web

# 3. Compresser
cd build/web
zip -r titingre-web.zip .

# 4. Uploader sur Hostinger File Manager
# 5. Décompresser dans public_html/
```

### Vérification post-déploiement

Ces URLs ne doivent PAS fonctionner (404) :
```
https://www.titingre.com/assets/lib/services/documentation/README.md
https://www.titingre.com/assets/lib/services/documentation/INDEX.md
```

## Scripts disponibles

### Windows
```cmd
scripts\deploy-web.bat
```

### Linux/Mac
```bash
chmod +x scripts/deploy_web.sh
./scripts/deploy_web.sh
```

## FAQ

**Q : La documentation est-elle dans Git ?**
✅ Oui, pour le versioning et la collaboration

**Q : Sera-t-elle déployée sur Hostinger ?**
❌ Non, jamais ! Elle n'est pas dans les assets

**Q : Puis-je la voir depuis le web ?**
❌ Non, uniquement via le repository Git

**Q : Comment l'équipe y accède ?**
✅ Via `git pull` ou en naviguant dans le repository

## Checklist de déploiement

Avant chaque déploiement :

- [ ] `flutter build web --release`
- [ ] Vérifier `build/web/assets/` ne contient pas `documentation/`
- [ ] Taille du build < 10 MB
- [ ] Upload sur Hostinger
- [ ] Test : URLs de doc retournent 404

## Documentation complète

Voir : [EXCLUSION_DOCUMENTATION_WEB.md](deploiement/EXCLUSION_DOCUMENTATION_WEB.md)

---

**Dernière mise à jour** : 2026-01-08
