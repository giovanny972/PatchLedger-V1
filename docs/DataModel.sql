-- Schéma de données (MVP, Postgres)

CREATE TABLE site (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  cms TEXT CHECK (cms IN ('wordpress','prestashop','magento')) NOT NULL,
  base_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE component (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES site(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('plugin','theme','module','core','lib')) NOT NULL,
  name TEXT NOT NULL,
  vendor TEXT,
  version TEXT NOT NULL,
  checksum TEXT,
  UNIQUE (site_id, type, name)
);

CREATE TABLE finding (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES site(id) ON DELETE CASCADE,
  component_name TEXT NOT NULL,
  cve_id TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('Critical','High','Medium','Low')) NOT NULL,
  fixed_in TEXT,
  status TEXT CHECK (status IN ('Open','Planned','Patched','Rejected')) DEFAULT 'Open',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE action (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES site(id) ON DELETE CASCADE,
  script TEXT NOT NULL,           -- script généré (WP-CLI/Composer)
  plan JSONB NOT NULL,            -- métadonnées d’exécution
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  outcome TEXT CHECK (outcome IN ('Success','Rollback','Failed')),
  evidence_hash TEXT
);

CREATE TABLE backup_status (
  site_id UUID PRIMARY KEY REFERENCES site(id) ON DELETE CASCADE,
  freshness_hours INT,
  retention_days INT,
  offsite BOOLEAN,
  region TEXT,
  last_restore_at TIMESTAMPTZ,
  immutable BOOLEAN
);
