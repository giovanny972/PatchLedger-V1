#!/bin/bash

# Script de test des endpoints PatchLedger WordPress
# Usage: ./test-endpoints.sh [URL] [USERNAME] [PASSWORD]

set -euo pipefail

# Configuration par défaut
SITE_URL="${1:-http://localhost:8080}"
USERNAME="${2:-admin}"
PASSWORD="${3:-admin}"

echo "=== Test des Endpoints PatchLedger ==="
echo "Site: $SITE_URL"
echo "Utilisateur: $USERNAME"
echo

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de test
test_endpoint() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local auth="${4:-true}"

    echo -e "${YELLOW}Test: $method $endpoint${NC}"

    # Construction de la commande curl
    local curl_cmd="curl -s -w '\nHTTP Status: %{http_code}\n'"

    if [ "$auth" = "true" ]; then
        curl_cmd="$curl_cmd -u '$USERNAME:$PASSWORD'"
    fi

    if [ "$method" = "POST" ]; then
        curl_cmd="$curl_cmd -X POST -H 'Content-Type: application/json'"
        if [ -n "$data" ]; then
            curl_cmd="$curl_cmd -d '$data'"
        fi
    fi

    curl_cmd="$curl_cmd '$SITE_URL$endpoint'"

    # Exécution du test
    if result=$(eval $curl_cmd 2>/dev/null); then
        if echo "$result" | grep -q "HTTP Status: 2[0-9][0-9]"; then
            echo -e "${GREEN}✓ Succès${NC}"
            echo "$result" | head -20
        else
            echo -e "${RED}✗ Échec${NC}"
            echo "$result"
        fi
    else
        echo -e "${RED}✗ Erreur de connexion${NC}"
    fi

    echo "----------------------------------------"
    echo
}

# Tests des endpoints

# 1. Test de santé (pas d'auth)
test_endpoint "GET" "/wp-json/patchledger/v1/health" "" "false"

# 2. Test inventaire
test_endpoint "GET" "/wp-json/patchledger/v1/inventory"

# 3. Test statut sauvegarde
test_endpoint "GET" "/wp-json/patchledger/v1/backup-status"

# 4. Test application patch
patch_data='{"component":"hello-dolly","version":"1.7.2","type":"plugin"}'
test_endpoint "POST" "/wp-json/patchledger/v1/patch" "$patch_data"

# 5. Test patch avec paramètres invalides
invalid_data='{"component":"test"}'
echo -e "${YELLOW}Test: POST /wp-json/patchledger/v1/patch (paramètres invalides)${NC}"
test_endpoint "POST" "/wp-json/patchledger/v1/patch" "$invalid_data"

echo "=== Tests terminés ==="
echo
echo "Pour des tests plus détaillés:"
echo "1. Vérifiez que le plugin est activé dans WordPress"
echo "2. Consultez les logs dans /wp-admin/site-health.php"
echo "3. Utilisez Application Passwords pour plus de sécurité"