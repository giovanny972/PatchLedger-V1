# Agent PrestaShop (MVP)

Deux options :
1) **Module léger** qui expose `/patchledger/inventory` (liste modules + versions via `Module::getModulesOnDisk` / BDD).
2) **Script CLI** (PHP) exécuté par CRON qui écrit un `site.json` et l’envoie à l’API.

Livrables V1 : inventaire modules + version Presta + détection basique des plugins de sauvegarde.
