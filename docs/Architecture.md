# Architecture (MVP)

```
 Agents (site)                 Orchestrateur (SaaS)                      Stockage/Preuves
┌────────────────┐        ┌───────────────────────────┐           ┌───────────────────────────┐
│ WP / Presta /  │  HTTPS │ Ingestion API             │           │ Evidence Store (S3/OVH)   │
│ Magento Agents │ ──────▶│ Queue (Redis)             │           │  - Captures avant/après    │
│  - inventaire  │        │ Workers                   │           │  - Logs + hashes           │
│  - backup info │        │  - Matching CVE           │           │  - Rapports PDF/JSON       │
│  - staging ctl │        │  - Staging + tests        │           └───────────────────────────┘
└────────────────┘        │  - Autopatch/rollback     │
                          │  - Contrôle sauvegardes   │           Dashboard
                          └──────────────┬────────────┘           ┌───────────────────────────┐
                                         │                        │ UI (React/Next – V2)      │
                                         ▼                        │  - SLA Patch / Backup     │
                                   Reporting                      │  - Backlog exécutable     │
                                   (PDF/JSON)                     └───────────────────────────┘
```

## Sécurité
- Agents “egress-only” (pull côté SaaS interdit). Auth par token et mTLS (V2).
- Journal probatoire : every step → horodatage, hash, versions avant/après.
- Plages de maintenance configurables.
