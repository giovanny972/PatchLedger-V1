# PatchLedger — MVP (V1.0)

**Tagline** : *Autopatch. Staging. Preuves.*  
Date : 2025-09-17

Ce dépôt contient un **MVP exécutable** (squelettes + scripts) pour livrer rapidement :
- Inventaire extensions/modules/thèmes (WordPress / PrestaShop / Magento)
- Matching vulnérabilités (CVE) → **backlog exécutable**
- **Autopatch orchestré** : staging → tests de fumée → diff visuel → promote / rollback
- **Contrôle des sauvegardes** : fraîcheur, rétention, offsite, dernier test de restauration
- **Journal probatoire** : horodatage, hash, evidences, export PDF/JSON

> ⚠️ MVP = base solide, pas un produit fini. L’objectif est la **vitesse de déploiement** chez 10–20 clients pilotes.
