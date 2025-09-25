# SLA & CGV (Draft MVP)

- **SLA Patch Critique** : correctifs applicatifs proposés < 24 h, appliqués < 7 j lorsque l’autopatch est activé et la fenêtre de maintenance disponible.
- **Staging & Tests** : toute mise à jour passe par un environnement de staging, tests de fumée (200 OK pages clés, login, panier) puis diff visuel ; en cas d’échec → rollback.
- **Sauvegardes** : fraîcheur < 24 h (TPE par défaut), test de restauration < 30 j, offsite requis.
- **Limites** : pas de pentest “actif” en prod ; pas de garantie de conformité légale ; meilleur effort sur compatibilité plugin/module.
- **Responsabilité** : obligation de moyens renforcée, pas de garantie d’indemnisation au-delà des frais mensuels.
