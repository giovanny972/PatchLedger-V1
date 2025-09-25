# Agent Magento 2 (MVP)

- Inventaire via `composer show -t` + lecture `app/etc/config.php` pour modules activés.
- Version core via `bin/magento --version`.
- Sortie `site.json` standardisée puis POST → `/api/v1/sites/{id}/inventory`.
- Backups : détecter stratégie (XtraBackup/snapshots) côté infra et remonter `backup_status`.
