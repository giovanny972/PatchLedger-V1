# Scope Produit — MVP V1.0

## Objectif
Appliquer un **SLA patch ≤7 jours** sur plugins/thèmes/modules (WP/Presta/Magento) avec **staging automatique**, tests de fumée, **rollback**, et **preuve d’exécution**. Contrôler la **rotation des sauvegardes**.

## Non-objectifs (V1)
- DAST profond, SAST, conformité RGPD complète, WAF managé, multi-régions avancé.

## KPI
- % sites sans “Critical > 7 jours” ≥ 95 %
- MTTR patch (jours)
- Taux de restore test < 30 j ≥ 95 %
- Taux de rollback < 5 %
