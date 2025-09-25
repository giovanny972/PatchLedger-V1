# CLAUDE.md

Ce fichier fournit des directives à Claude Code (claude.ai/code) lors du travail avec le code de ce dépôt.

## Aperçu du Projet

PatchLedger est un système de gestion automatisée des correctifs pour les sites WordPress, PrestaShop et Magento. Le MVP fournit la détection de vulnérabilités, l'application automatisée de correctifs avec environnements de staging, les capacités de rollback, et les rapports de conformité.

Objectifs clés :
- Appliquer les correctifs dans un SLA de 7 jours
- Workflow automatisé : staging → tests de fumée → diff visuel → promotion/rollback
- Vérification et contrôle de rétention des sauvegardes
- Piste d'audit avec horodatage et collecte de preuves

## Architecture

Le système suit une architecture modulaire avec ces composants principaux :

### Répertoires Principaux
- `agents/` - Agents spécifiques aux plateformes WordPress, Magento et PrestaShop
- `workers/` - Modules de traitement en arrière-plan (matching CVE, détection de vulnérabilités)
- `orchestrator/` - Couche de coordination avec scripts et tests de fumée
- `dashboard/` - Dashboard HTML simple pour la surveillance
- `examples/` - Schémas JSON et données d'exemple
- `docs/` - Documentation et rapports de conformité
- `reports/` - Rapports d'audit et de conformité générés

### Composants Clés
- **CVE Matcher** (`workers/matching_cve/matcher.py`) - Fait correspondre l'inventaire des sites aux bases de données de vulnérabilités
- **Tests de Fumée** (`orchestrator/tests/smoke_test.py`) - Vérifications de santé HTTP basiques post-déploiement
- **Scripts Auto-patch** (`orchestrator/scripts/`) - Automatisation des mises à jour spécifiques aux plateformes (WP-CLI, Magento, PrestaShop)
- **Agent WordPress** (`agents/wordpress/patchledger-agent-wp.php`) - Plugin WordPress pour la collecte d'inventaire

## Commandes de Développement

### Tests
```bash
# Exécuter les tests de fumée
python orchestrator/tests/smoke_test.py http://example.com http://staging.example.com

# Tester le matching CVE
python workers/matching_cve/matcher.py examples/site.json workers/matching_cve/sample_cves.json
```

### Mises à Jour des Plateformes
```bash
# Correctifs WordPress (nécessite la variable d'environnement WP_PATH)
WP_PATH=/var/www/html ./orchestrator/scripts/wp_autopatch.sh plugin-slug version

# Mises à jour PrestaShop
./orchestrator/scripts/prestashop_update.sh

# Mises à jour Magento
./orchestrator/scripts/magento_update.sh
```

### Dashboard
Ouvrir `dashboard/index.html` dans un navigateur pour l'interface de surveillance.

## Flux de Données

1. **Collecte d'Inventaire** : Les agents de plateforme collectent les composants installés et leurs versions
2. **Matching de Vulnérabilités** : Les workers font correspondre l'inventaire aux bases de données CVE
3. **Orchestration des Correctifs** : Les scripts appliquent les mises à jour dans les environnements de staging
4. **Validation** : Les tests de fumée vérifient la fonctionnalité post-correctif
5. **Promotion** : Les correctifs réussis sont promus en production avec piste d'audit
6. **Rollback** : Rollback automatisé en cas d'échec de validation

## Notes sur la Structure des Fichiers

- Les schémas JSON dans `examples/` définissent les contrats de données entre composants
- Tous les scripts supposent un environnement d'exécution bash/shell
- Les composants Python utilisent uniquement la bibliothèque standard (pas de dépendances externes)
- L'intégration WordPress utilise WP-CLI pour l'automatisation