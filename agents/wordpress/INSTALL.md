# Installation et Test de l'Agent WordPress

## Méthode 1: Installation Manuelle

### 1. Création du dossier plugin
```bash
# Sur votre serveur WordPress
cd /var/www/html/wp-content/plugins/
sudo mkdir patchledger-agent
sudo cp patchledger-agent-wp.php patchledger-agent/
sudo chown -R www-data:www-data patchledger-agent/
```

### 2. Activation depuis l'admin WordPress
1. Connectez-vous à votre admin WordPress (`/wp-admin`)
2. Allez dans **Extensions** → **Extensions installées**
3. Activez "PatchLedger Agent"

### 3. Test des endpoints
```bash
# Remplacez USERNAME:PASSWORD par vos identifiants admin WordPress
# Et VOTRE-SITE.COM par votre domaine

# Test inventaire
curl -u "USERNAME:PASSWORD" \
  "https://VOTRE-SITE.COM/wp-json/patchledger/v1/inventory"

# Test santé
curl "https://VOTRE-SITE.COM/wp-json/patchledger/v1/health"

# Test statut sauvegarde
curl -u "USERNAME:PASSWORD" \
  "https://VOTRE-SITE.COM/wp-json/patchledger/v1/backup-status"

# Test application patch
curl -X POST -u "USERNAME:PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"component":"akismet","version":"5.3","type":"plugin"}' \
  "https://VOTRE-SITE.COM/wp-json/patchledger/v1/patch"
```

## Méthode 2: Installation via FTP/SFTP

### 1. Upload des fichiers
1. Créez un dossier `patchledger-agent` dans `/wp-content/plugins/`
2. Uploadez `patchledger-agent-wp.php` dans ce dossier
3. Activez depuis l'admin WordPress

## Méthode 3: Test avec Docker (Environnement Local)

### 1. Créer un environnement WordPress local
```bash
# Créer le docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: wp_pass
    volumes:
      - ./agents/wordpress:/var/www/html/wp-content/plugins/patchledger-agent
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: wp_pass
      MYSQL_ROOT_PASSWORD: root_pass
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

# Démarrer l'environnement
docker-compose up -d
```

### 2. Configuration initiale
1. Ouvrez `http://localhost:8080`
2. Suivez l'installation WordPress
3. Créez un compte admin
4. Activez le plugin "PatchLedger Agent"

### 3. Tests des endpoints
```bash
# Après avoir créé votre compte admin WordPress
# Remplacez admin:password par vos vrais identifiants

# Test inventaire
curl -u "admin:password" \
  "http://localhost:8080/wp-json/patchledger/v1/inventory" | jq .

# Test santé (pas d'auth requise)
curl "http://localhost:8080/wp-json/patchledger/v1/health" | jq .

# Test patch d'un plugin existant
curl -X POST -u "admin:password" \
  -H "Content-Type: application/json" \
  -d '{"component":"hello-dolly","version":"1.7.2","type":"plugin"}' \
  "http://localhost:8080/wp-json/patchledger/v1/patch" | jq .
```

## Méthode 4: Test avec Application Password (Recommandé)

### 1. Générer un Application Password
1. Dans WordPress Admin → **Utilisateurs** → **Profil**
2. Section "Application Passwords"
3. Nom: `PatchLedger Agent`
4. Cliquer "Add New Application Password"
5. Copier le mot de passe généré (format: `xxxx xxxx xxxx xxxx`)

### 2. Tests avec Application Password
```bash
# Remplacez:
# - VOTRE-USERNAME par votre nom d'utilisateur WordPress
# - xxxx-xxxx-xxxx-xxxx par le mot de passe d'application généré
# - VOTRE-SITE.COM par votre domaine

USERNAME="VOTRE-USERNAME"
APP_PASSWORD="xxxx xxxx xxxx xxxx"  # Espaces inclus
SITE="https://VOTRE-SITE.COM"

# Test inventaire
curl -u "$USERNAME:$APP_PASSWORD" \
  "$SITE/wp-json/patchledger/v1/inventory" | jq .

# Test application patch
curl -X POST -u "$USERNAME:$APP_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"component":"woocommerce","version":"8.9.0","type":"plugin"}' \
  "$SITE/wp-json/patchledger/v1/patch" | jq .
```

## Vérification du Bon Fonctionnement

### Réponses attendues:

**Inventaire** (GET `/inventory`):
```json
{
  "site": "https://votre-site.com",
  "cms": "wordpress",
  "components": [
    {
      "type": "core",
      "name": "wordpress",
      "version": "6.5.3"
    },
    {
      "type": "plugin",
      "name": "WooCommerce",
      "version": "8.7.0",
      "vendor": "Automattic",
      "slug": "woocommerce"
    }
  ],
  "backup_tools": ["updraftplus"],
  "collected_at": "2025-09-25T20:00:00+00:00"
}
```

**Santé** (GET `/health`):
```json
{
  "status": "ok",
  "timestamp": "2025-09-25T20:00:00+00:00",
  "wordpress_version": "6.5.3",
  "php_version": "8.2.0",
  "mysql_version": "8.0.34",
  "active_plugins": 15,
  "memory_limit": "256M",
  "disk_free": 5368709120
}
```

## Dépannage

### Erreur 404 sur les endpoints
- Vérifiez que le plugin est activé
- Testez `/wp-json/` pour confirmer que l'API REST fonctionne
- Vérifiez les permaliens (Réglages → Permaliens → Enregistrer)

### Erreur 401 Unauthorized
- Vérifiez vos identifiants
- Utilisez un Application Password au lieu du mot de passe principal
- Confirmez que l'utilisateur a les droits `manage_options`

### Erreur 500
- Consultez les logs d'erreur PHP (`/var/log/php/error.log`)
- Activez le mode debug WordPress (`WP_DEBUG = true`)
- Vérifiez la syntaxe du fichier PHP