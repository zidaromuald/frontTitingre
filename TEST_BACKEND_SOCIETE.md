# Test Backend - Endpoint /societes/me

**Problème:** L'API retourne toujours **401 "Session expirée"** même après reconnexion.

---

## 🔍 Diagnostic

L'erreur **401** signifie que le backend rejette le token. Causes possibles:

### 1. ❌ L'endpoint `/societes/me` n'existe pas

**Vérification:**
```bash
# Dans votre backend NestJS
grep -r "societes/me" src/
```

**Attendu:**
```typescript
// src/societes/societes.controller.ts
@Get('me')
@UseGuards(JwtAuthGuard)
async getMyProfile(@Request() req) {
  return this.societesService.getProfile(req.user.id);
}
```

**Si l'endpoint manque:** Créez-le dans votre controller.

---

### 2. ❌ L'endpoint existe mais le Guard JWT échoue

**Vérification:** Regardez les logs du backend NestJS quand vous essayez d'accéder au profil.

**Attendu:**
```
[Nest] LOG [SocietesController] GET /societes/me - User ID: 1
```

**Si vous voyez:**
```
[Nest] ERROR [JwtAuthGuard] Unauthorized
```

**Cause:** Le token n'est pas valide ou n'est pas envoyé correctement.

---

### 3. ❌ Le token est envoyé mais dans le mauvais format

**Vérification:** Vérifiez comment le token est envoyé dans `ApiService`.

Le token doit être envoyé dans le header `Authorization` avec le format:
```
Authorization: Bearer <token>
```

---

## 🧪 Test Manuel de l'API

### Étape 1: Récupérez le token après connexion

Ajoutez temporairement ce log dans votre code de connexion société:

```dart
// Après connexion réussie
final token = await AuthBaseService.getToken();
print('🔑 TOKEN SOCIÉTÉ: $token');
```

### Étape 2: Testez l'endpoint avec curl

```bash
# Remplacez <TOKEN> par le token affiché dans les logs
curl -X GET http://localhost:3000/societes/me \
  -H "Authorization: Bearer <TOKEN>" \
  -v
```

**Résultat attendu (200 OK):**
```json
{
  "data": {
    "id": 1,
    "nom": "Ma Société",
    "email": "societe@example.com",
    "profile": {
      "logo": "...",
      "description": "..."
    }
  }
}
```

**Si vous obtenez 401:**
- Le token n'est pas valide
- L'endpoint nécessite un Guard différent
- Le backend n'est pas configuré pour les sociétés

---

## 🔧 Solutions Possibles

### Solution 1: Vérifier que l'endpoint existe

Dans votre backend NestJS, assurez-vous d'avoir:

```typescript
// src/societes/societes.controller.ts
@Controller('societes')
export class SocietesController {
  constructor(private readonly societesService: SocietesService) {}

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyProfile(@Request() req) {
    const societeId = req.user.id;
    const societe = await this.societesService.findOneWithProfile(societeId);

    if (!societe) {
      throw new NotFoundException('Société non trouvée');
    }

    return { data: societe };
  }
}
```

### Solution 2: Vérifier le JWT Guard

Le `JwtAuthGuard` doit être configuré pour accepter les tokens de sociétés:

```typescript
// src/auth/jwt-auth.guard.ts
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  handleRequest(err, user, info) {
    if (err || !user) {
      throw new UnauthorizedException('Token invalide ou expiré');
    }
    return user;
  }
}
```

### Solution 3: Vérifier la stratégie JWT

```typescript
// src/auth/jwt.strategy.ts
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET,
    });
  }

  async validate(payload: any) {
    return {
      id: payload.sub,
      email: payload.email,
      type: payload.type // 'user' ou 'societe'
    };
  }
}
```

### Solution 4: Utiliser un endpoint différent temporairement

Si `/societes/me` ne fonctionne pas, essayez avec l'endpoint d'authentification:

```dart
// Dans societe_auth_service.dart, remplacez temporairement:
static Future<SocieteModel> getMyProfile() async {
  final response = await ApiService.get('/auth/societe/me'); // Au lieu de /societes/me
  // ... reste du code
}
```

---

## 📊 Diagnostic Rapide

Exécutez ces commandes dans votre backend:

```bash
# 1. Vérifier que le controller existe
cat src/societes/societes.controller.ts | grep "Get('me')"

# 2. Vérifier les routes enregistrées
npm run start:dev
# Puis dans les logs, cherchez:
# [Nest] Mapped {/societes/me, GET}

# 3. Tester avec un token de test
curl http://localhost:3000/societes/me \
  -H "Authorization: Bearer eyJ..." \
  -v
```

---

## 🎯 Action Immédiate

**Option A:** Si vous avez accès au backend, ajoutez des logs:

```typescript
@Get('me')
@UseGuards(JwtAuthGuard)
async getMyProfile(@Request() req) {
  console.log('🔍 GET /societes/me appelé');
  console.log('👤 User:', req.user);
  console.log('🔑 Token présent:', !!req.headers.authorization);

  // ... reste du code
}
```

**Option B:** Si le backend n'est pas accessible, vérifiez l'URL de l'API:

```dart
// Dans lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Pour émulateur Android
  // OU
  static const String baseUrl = 'http://localhost:3000'; // Pour iOS/web
}
```

---

## ✅ Prochaine Étape

1. **Vérifiez les logs du backend** pendant que vous testez le profil
2. **Copiez les logs backend** et partagez-les moi
3. **Testez avec curl** pour voir si c'est un problème backend ou frontend

Sans accès au backend, je ne peux pas corriger directement, mais ces tests nous diront exactement où est le problème!
