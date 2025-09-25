# Basic matcher: map inventory components to a fake CVE dataset (MVP placeholder).
# In production, feed from WPScan/OSV/Adobe/Presta advisories.

import json, sys

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def version_tuple(s):
    parts = []
    for token in s.split("."):
        try:
            parts.append(int(token))
        except ValueError:
            parts.append(0)
    return tuple(parts)

def version_less(a, b):
    return version_tuple(a) < version_tuple(b)

def match(site, cves):
    findings = []
    comps = site.get("components", [])
    for cve in cves:
        name = cve["component"]
        fixed = cve.get("fixed_in")
        for c in comps:
            if c["name"].lower().startswith(name.lower()):
                if fixed and version_less(c.get("version","0"), fixed):
                    findings.append({
                        "component_name": c["name"],
                        "installed": c.get("version",""),
                        "cve_id": cve["cve_id"],
                        "severity": cve["severity"],
                        "fixed_in": fixed,
                        "status": "Open"
                    })
    return findings

if __name__ == "__main__":
    site = load_json(sys.argv[1])
    cves = load_json(sys.argv[2])
    out = match(site, cves)
    print(json.dumps(out, indent=2))
