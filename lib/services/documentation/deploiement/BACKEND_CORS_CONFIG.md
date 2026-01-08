# Configuration CORS Backend NestJS

## Mise à jour nécessaire pour supporter Web + Mobile

### 1. Fichier `.env` sur votre VPS Hostinger

Mettez à jour la variable `ALLOWED_ORIGINS` pour inclure l'application web :

```env
# Anciennes valeurs
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com,https://api.titingre.com

# Nouvelles valeurs (les origines web sont déjà incluses)
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com,https://api.titingre.com
```

### 2. Configuration NestJS (main.ts)

Vérifiez que votre fichier `main.ts` contient bien cette configuration :

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Configuration CORS
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  await app.listen(process.env.PORT || 3000);
}
bootstrap();
```

### 3. Redémarrer le service

Après modification, redémarrez votre application NestJS :

```bash
# Via PM2
pm2 restart your-app-name

# Ou via systemd
sudo systemctl restart your-app-name
```

### 4. Vérifier les headers CORS

Testez que les CORS fonctionnent :

```bash
curl -I -X OPTIONS https://api.titingre.com/health \
  -H "Origin: https://www.titingre.com" \
  -H "Access-Control-Request-Method: GET"
```

Vous devriez voir dans la réponse :
```
Access-Control-Allow-Origin: https://www.titingre.com
Access-Control-Allow-Credentials: true
```
