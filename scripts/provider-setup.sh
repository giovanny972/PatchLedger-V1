#!/bin/bash

# Script de configuration automatique des providers cloud pour PatchLedger
# Usage: ./provider-setup.sh [provider] [region]

set -euo pipefail

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROVIDER=${1:-}
REGION=${2:-}

echo -e "${BLUE}=== Configuration Provider Cloud PatchLedger ===${NC}"
echo

# Fonction de sélection du provider
select_provider() {
    if [ -z "$PROVIDER" ]; then
        echo -e "${YELLOW}Providers disponibles:${NC}"
        echo "1. OVH Cloud (recommandé EU, économique)"
        echo "2. Scaleway (EU focus, developer-friendly)"
        echo "3. AWS (global, enterprise)"
        echo "4. Google Cloud (global, ML/analytics)"
        echo "5. Microsoft Azure (enterprise, hybrid)"
        echo "6. Local (développement/test)"
        echo

        read -p "Choisissez un provider [1-6]: " choice

        case $choice in
            1) PROVIDER="ovh" ;;
            2) PROVIDER="scw" ;;
            3) PROVIDER="aws" ;;
            4) PROVIDER="gcp" ;;
            5) PROVIDER="azure" ;;
            6) PROVIDER="local" ;;
            *) echo -e "${RED}Choix invalide${NC}"; exit 1 ;;
        esac
    fi
}

# Fonction de sélection de région
select_region() {
    if [ -z "$REGION" ]; then
        case $PROVIDER in
            "ovh")
                echo -e "${YELLOW}Régions OVH disponibles:${NC}"
                echo "EU: gra(Gravelines) rbx(Roubaix) sbg(Strasbourg) de(Frankfurt) uk(Londres) waw(Varsovie)"
                echo "CA: bhs(Beauharnois) ca-east-tor(Toronto)"
                echo "APAC: sgp(Singapour) au-syd(Sydney)"
                read -p "Région [gra]: " REGION
                REGION=${REGION:-gra}
                ;;
            "scw")
                echo -e "${YELLOW}Régions Scaleway disponibles:${NC}"
                echo "EU: fr-par(Paris) nl-ams(Amsterdam) pl-waw(Varsovie)"
                read -p "Région [fr-par]: " REGION
                REGION=${REGION:-fr-par}
                ;;
            "aws")
                echo -e "${YELLOW}Régions AWS populaires:${NC}"
                echo "EU: eu-west-3(Paris) eu-central-1(Frankfurt) eu-west-1(Irlande)"
                echo "US: us-east-1(Virginie) us-west-2(Oregon)"
                read -p "Région [eu-west-3]: " REGION
                REGION=${REGION:-eu-west-3}
                ;;
            "gcp")
                echo -e "${YELLOW}Régions GCP populaires:${NC}"
                echo "EU: europe-west1(Belgique) europe-west3(Frankfurt) europe-west2(Londres)"
                echo "US: us-central1 us-east1"
                read -p "Région [europe-west1]: " REGION
                REGION=${REGION:-europe-west1}
                ;;
            "azure")
                echo -e "${YELLOW}Régions Azure populaires:${NC}"
                echo "EU: westeurope francecentral germanywestcentral"
                echo "US: eastus westus"
                read -p "Région [westeurope]: " REGION
                REGION=${REGION:-westeurope}
                ;;
            "local")
                REGION="local"
                ;;
        esac
    fi
}

# Fonction de génération de la configuration
generate_config() {
    local config_file=".env.patchledger"

    echo -e "${YELLOW}Génération de la configuration...${NC}"

    cat > "$config_file" << EOF
# Configuration PatchLedger - Généré le $(date)
# Provider: $PROVIDER | Région: $REGION

# =================================================================
# PROVIDER & RÉGION
# =================================================================
PL_PROVIDER=$PROVIDER
PL_REGION=$REGION

EOF

    case $PROVIDER in
        "ovh")
            cat >> "$config_file" << EOF
# Configuration OVH Cloud
PL_S3_ENDPOINT=https://s3.${REGION}.io.cloud.ovh.net
PL_SWIFT_ENDPOINT=https://auth.cloud.ovh.net/v3
PL_SWIFT_REGION=$REGION
PL_RETENTION_DAYS=90
PL_GLACIER_DAYS=30

# Variables OVH requises (à configurer)
# export OS_AUTH_URL=https://auth.cloud.ovh.net/v3
# export OS_PROJECT_ID=your_project_id
# export OS_USERNAME=your_username
# export OS_PASSWORD=your_password
# export OS_REGION_NAME=$REGION

EOF
            ;;
        "scw")
            cat >> "$config_file" << EOF
# Configuration Scaleway
PL_S3_ENDPOINT=https://s3.${REGION}.scw.cloud
PL_RETENTION_DAYS=60
PL_GLACIER_DAYS=14

# Variables Scaleway requises (à configurer)
# export SCW_ACCESS_KEY=your_access_key
# export SCW_SECRET_KEY=your_secret_key
# export SCW_DEFAULT_PROJECT_ID=your_project_id
# export SCW_DEFAULT_REGION=$REGION

EOF
            ;;
        "aws")
            cat >> "$config_file" << EOF
# Configuration AWS
PL_S3_ENDPOINT=https://s3.${REGION}.amazonaws.com
AWS_DEFAULT_REGION=$REGION
PL_RETENTION_DAYS=365
PL_GLACIER_DAYS=90

# Variables AWS requises (à configurer)
# export AWS_ACCESS_KEY_ID=your_access_key
# export AWS_SECRET_ACCESS_KEY=your_secret_key
# export AWS_DEFAULT_REGION=$REGION

EOF
            ;;
        "gcp")
            cat >> "$config_file" << EOF
# Configuration Google Cloud
PL_S3_ENDPOINT=https://storage.googleapis.com
GOOGLE_CLOUD_PROJECT=\${GCP_PROJECT_ID}
PL_RETENTION_DAYS=180
PL_GLACIER_DAYS=60

# Variables GCP requises (à configurer)
# export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
# export GCP_PROJECT_ID=your_project_id

EOF
            ;;
        "azure")
            cat >> "$config_file" << EOF
# Configuration Microsoft Azure
PL_S3_ENDPOINT=https://\${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net
PL_RETENTION_DAYS=120
PL_GLACIER_DAYS=30

# Variables Azure requises (à configurer)
# export AZURE_STORAGE_ACCOUNT=your_storage_account
# export AZURE_STORAGE_KEY=your_storage_key

EOF
            ;;
        "local")
            cat >> "$config_file" << EOF
# Configuration Stockage Local
PL_S3_ENDPOINT=file:///var/backups/patchledger
PL_RETENTION_DAYS=30
PL_GLACIER_DAYS=0

# Créer le répertoire local
sudo mkdir -p /var/backups/patchledger
sudo chown \$USER:www-data /var/backups/patchledger
sudo chmod 755 /var/backups/patchledger

EOF
            ;;
    esac

    cat >> "$config_file" << EOF
# =================================================================
# CONFIGURATION COMMUNE
# =================================================================
PL_AWS_PROFILE=patchledger-\${PL_REGION}
PL_BUCKET=patchledger-\${PL_PROVIDER}-\${PL_REGION}/\${SITE_SLUG}/

# Chiffrement et sécurité
PL_ENCRYPTION_ENABLED=true
PL_ENCRYPTION_KEY_ID=\${PL_PROVIDER}-kms-\${PL_REGION}

# Tags pour organisation
PL_TAGS="Environment=production,Service=patchledger,Region=\${PL_REGION},Provider=\${PL_PROVIDER}"

# Monitoring
PL_ALERT_STORAGE_THRESHOLD_GB=1000
PL_ALERT_BANDWIDTH_THRESHOLD_GB=500

# =================================================================
# ACTIVATION
# =================================================================
# Pour activer cette configuration:
# source $config_file
# export \$(grep -v '^#' $config_file | xargs)

EOF

    echo -e "${GREEN}✓ Configuration générée: $config_file${NC}"
}

# Fonction de test de connectivité
test_connectivity() {
    echo -e "${YELLOW}Test de connectivité...${NC}"

    case $PROVIDER in
        "ovh")
            if command -v openstack >/dev/null 2>&1; then
                echo "Test OVH OpenStack..."
            else
                echo -e "${YELLOW}Installer openstack client: pip install python-openstackclient${NC}"
            fi
            ;;
        "scw")
            if command -v scw >/dev/null 2>&1; then
                echo "Test Scaleway CLI..."
            else
                echo -e "${YELLOW}Installer scw CLI: curl -s https://raw.githubusercontent.com/scaleway/scaleway-cli/master/scripts/get.sh | sh${NC}"
            fi
            ;;
        "aws")
            if command -v aws >/dev/null 2>&1; then
                aws s3 ls 2>/dev/null && echo -e "${GREEN}✓ AWS connecté${NC}" || echo -e "${RED}✗ AWS non configuré${NC}"
            else
                echo -e "${YELLOW}Installer AWS CLI: pip install awscli${NC}"
            fi
            ;;
        "gcp")
            if command -v gcloud >/dev/null 2>&1; then
                gcloud auth list 2>/dev/null | grep -q "ACTIVE" && echo -e "${GREEN}✓ GCP connecté${NC}" || echo -e "${RED}✗ GCP non configuré${NC}"
            else
                echo -e "${YELLOW}Installer gcloud CLI: https://cloud.google.com/sdk/docs/install${NC}"
            fi
            ;;
        "azure")
            if command -v az >/dev/null 2>&1; then
                az account show >/dev/null 2>&1 && echo -e "${GREEN}✓ Azure connecté${NC}" || echo -e "${RED}✗ Azure non configuré${NC}"
            else
                echo -e "${YELLOW}Installer Azure CLI: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
            fi
            ;;
        "local")
            echo -e "${GREEN}✓ Stockage local configuré${NC}"
            ;;
    esac
}

# Fonction d'affichage des instructions finales
show_instructions() {
    echo
    echo -e "${GREEN}=== Configuration Terminée ===${NC}"
    echo
    echo -e "${YELLOW}Prochaines étapes:${NC}"
    echo "1. Activez la configuration: source .env.patchledger"
    echo "2. Configurez les variables d'authentification (voir le fichier)"
    echo "3. Testez la connectivité avec votre provider"
    echo "4. Créez le bucket/container de stockage"
    echo
    echo -e "${YELLOW}Commandes utiles:${NC}"

    case $PROVIDER in
        "ovh")
            echo "- Lister les containers: openstack container list"
            echo "- Créer un container: openstack container create patchledger-backups"
            ;;
        "scw")
            echo "- Lister les buckets: scw object bucket list"
            echo "- Créer un bucket: scw object bucket create name=patchledger-backups"
            ;;
        "aws")
            echo "- Lister les buckets: aws s3 ls"
            echo "- Créer un bucket: aws s3 mb s3://patchledger-backups-$REGION"
            ;;
        "gcp")
            echo "- Lister les buckets: gsutil ls"
            echo "- Créer un bucket: gsutil mb gs://patchledger-backups-$REGION"
            ;;
        "azure")
            echo "- Lister les containers: az storage container list"
            echo "- Créer un container: az storage container create -n patchledger-backups"
            ;;
    esac
}

# Exécution principale
main() {
    select_provider
    select_region

    echo -e "${BLUE}Configuration sélectionnée:${NC}"
    echo -e "Provider: ${GREEN}$PROVIDER${NC}"
    echo -e "Région: ${GREEN}$REGION${NC}"
    echo

    generate_config
    test_connectivity
    show_instructions
}

main "$@"