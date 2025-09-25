# API (ébauche MVP)

Base: `/api/v1`

## Auth
`Authorization: Bearer <token>`

## POST `/sites/{site_id}/inventory`
Payload: `site.json` (voir /examples) → crée/maj inventaire.

## POST `/sites/{site_id}/plan`
Génère un backlog à partir de l’inventaire courant (matching CVE).

## POST `/sites/{site_id}/actions/{action_id}/execute`
Déclenche le plan en **staging** (script côté orchestrateur qui pilote l’agent).

## POST `/sites/{site_id}/promote`
Promouvoir staging → prod si tests OK.

## POST `/sites/{site_id}/rollback`
Rollback prod → version N-1.

## GET `/sites/{site_id}/backup-status`
Retourne l’état backup (fraîcheur, rétention, offsite, dernier restore).

## GET `/sites/{site_id}/report`
Récupère le rapport JSON/PDF (preuves incluses – liens).
