# Agent WordPress PatchLedger

Plugin WordPress pour la collecte d'inventaire, gestion des sauvegardes et application automatisée des correctifs.

## Installation

1. Copier le fichier `patchledger-agent-wp.php` dans `/wp-content/plugins/patchledger-agent/`
2. Activer le plugin depuis l'administration WordPress
3. Le plugin expose automatiquement les endpoints REST API

## Endpoints REST API

### GET /wp-json/patchledger/v1/inventory
Collecte l'inventaire complet du site :
- Version WordPress core
- Plugins installés avec versions
- Thème actif
- Outils de sauvegarde détectés

**Permissions** : `manage_options`

### GET /wp-json/patchledger/v1/backup-status
Statut des sauvegardes :
- Fraîcheur des sauvegardes
- Configuration de rétention
- Stockage offsite
- Dernière restauration testée

**Permissions** : `manage_options`

### GET /wp-json/patchledger/v1/health
Vérification santé du système :
- Statut général
- Versions PHP/MySQL/WordPress
- Utilisation mémoire et disque
- Erreurs critiques

**Permissions** : Accès public

### POST /wp-json/patchledger/v1/patch
Application de correctifs :
```json
{
  "component": "woocommerce",
  "version": "8.9.0",
  "type": "plugin"
}
```

**Permissions** : `update_plugins`

## Fonctionnalités de Sécurité

- **Authentification** : Utilise le système de permissions WordPress
- **Validation** : Vérification stricte des paramètres d'entrée
- **Audit Trail** : Enregistrement des actions dans les options WordPress
- **Rollback** : Snapshots automatiques avant application de correctifs

## Plugins de Sauvegarde Supportés

- UpdraftPlus
- Jetpack Backup
- BlogVault
- ManageWP

## Tests

Utiliser le script `test-agent.php` pour tester les fonctionnalités :

```bash
php test-agent.php
```

## Intégration avec l'Orchestrateur

L'agent s'intègre avec les scripts d'orchestration :

```bash
# Collecte d'inventaire
curl -H "Authorization: Bearer $TOKEN" \
  https://site.com/wp-json/patchledger/v1/inventory

# Application de patch
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"component":"woocommerce","version":"8.9.0","type":"plugin"}' \
  https://site.com/wp-json/patchledger/v1/patch
```

## Structure des Données

### Inventaire
```json
{
  "site": "https://exemple.tld",
  "cms": "wordpress",
  "components": [...],
  "backup_tools": [...],
  "collected_at": "2025-09-25T19:30:00+00:00"
}
```

### Status Sauvegarde
```json
{
  "freshness_hours": 24,
  "retention_days": 30,
  "offsite": true,
  "region": "eu-west-3",
  "last_restore_at": "2025-09-01T02:00:00Z",
  "immutable": true
}
```