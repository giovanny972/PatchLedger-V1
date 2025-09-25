#!/bin/bash

# Script d'installation automatique de l'agent PatchLedger pour WordPress
# Compatible avec toutes les distributions Linux
# Usage: ./install-auto.sh

set -euo pipefail

echo "=== Installation Agent PatchLedger WordPress ==="
echo

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier si on est root ou avec sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
   echo -e "${RED}Ce script nécessite les droits sudo${NC}"
   echo "Usage: sudo $0"
   exit 1
fi

# Fonction de détection WordPress
detect_wordpress() {
    local wp_paths=(
        "/var/www/html"
        "/var/www/wordpress"
        "/usr/share/wordpress"
        "/opt/wordpress"
        "/home/*/public_html"
        "/var/lib/wordpress"
    )

    echo -e "${YELLOW}Recherche de WordPress...${NC}"

    for path in "${wp_paths[@]}"; do
        if [ -f "$path/wp-config.php" ] || [ -f "$path/wp-config-sample.php" ]; then
            echo -e "${GREEN}✓ WordPress trouvé dans: $path${NC}"
            WP_ROOT="$path"
            return 0
        fi
    done

    # Recherche plus approfondie
    local found_wp
    found_wp=$(find /var /usr/share /opt /home -name "wp-config.php" -type f 2>/dev/null | head -1)
    if [ -n "$found_wp" ]; then
        WP_ROOT=$(dirname "$found_wp")
        echo -e "${GREEN}✓ WordPress trouvé dans: $WP_ROOT${NC}"
        return 0
    fi

    return 1
}

# Fonction de détection du répertoire plugins
detect_plugins_dir() {
    local possible_dirs=(
        "$WP_ROOT/wp-content/plugins"
        "/var/lib/wordpress/wp-content/plugins"
        "/usr/share/wordpress/wp-content/plugins"
    )

    echo -e "${YELLOW}Recherche du répertoire plugins...${NC}"

    for dir in "${possible_dirs[@]}"; do
        if [ -d "$dir" ]; then
            PLUGINS_DIR="$dir"
            echo -e "${GREEN}✓ Répertoire plugins: $PLUGINS_DIR${NC}"
            return 0
        fi
    done

    # Créer le répertoire s'il n'existe pas
    PLUGINS_DIR="$WP_ROOT/wp-content/plugins"
    echo -e "${YELLOW}Création du répertoire plugins: $PLUGINS_DIR${NC}"
    mkdir -p "$PLUGINS_DIR"
    return 0
}

# Fonction d'installation du plugin
install_plugin() {
    local plugin_dir="$PLUGINS_DIR/patchledger-agent"

    echo -e "${YELLOW}Installation du plugin...${NC}"

    # Créer le répertoire du plugin
    mkdir -p "$plugin_dir"

    # Copier le fichier PHP
    if [ -f "patchledger-agent-wp.php" ]; then
        cp "patchledger-agent-wp.php" "$plugin_dir/"
        echo -e "${GREEN}✓ Fichier plugin copié${NC}"
    else
        echo -e "${RED}✗ Fichier patchledger-agent-wp.php non trouvé${NC}"
        echo "Assurez-vous d'être dans le bon répertoire"
        exit 1
    fi

    # Déterminer l'utilisateur web
    local web_user=""
    if id "www-data" &>/dev/null; then
        web_user="www-data"
    elif id "apache" &>/dev/null; then
        web_user="apache"
    elif id "nginx" &>/dev/null; then
        web_user="nginx"
    else
        echo -e "${YELLOW}⚠ Utilisateur web non détecté, utilisation de www-data${NC}"
        web_user="www-data"
    fi

    # Définir les permissions
    chown -R "$web_user:$web_user" "$plugin_dir"
    chmod 755 "$plugin_dir"
    chmod 644 "$plugin_dir/patchledger-agent-wp.php"

    echo -e "${GREEN}✓ Permissions définies pour $web_user${NC}"
    echo -e "${GREEN}✓ Plugin installé dans: $plugin_dir${NC}"
}

# Fonction de vérification
verify_installation() {
    local plugin_file="$PLUGINS_DIR/patchledger-agent/patchledger-agent-wp.php"

    echo -e "${YELLOW}Vérification de l'installation...${NC}"

    if [ -f "$plugin_file" ]; then
        if php -l "$plugin_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Syntaxe PHP correcte${NC}"
        else
            echo -e "${RED}✗ Erreur de syntaxe PHP${NC}"
            return 1
        fi

        if grep -q "Plugin Name: PatchLedger Agent" "$plugin_file"; then
            echo -e "${GREEN}✓ En-tête WordPress valide${NC}"
        else
            echo -e "${RED}✗ En-tête WordPress manquant${NC}"
            return 1
        fi

        return 0
    else
        echo -e "${RED}✗ Fichier plugin non trouvé${NC}"
        return 1
    fi
}

# Afficher les instructions finales
show_instructions() {
    echo
    echo "=== Installation terminée ==="
    echo
    echo -e "${GREEN}Prochaines étapes:${NC}"
    echo "1. Connectez-vous à votre admin WordPress (/wp-admin)"
    echo "2. Allez dans Extensions → Extensions installées"
    echo "3. Activez 'PatchLedger Agent'"
    echo "4. Testez l'endpoint: curl \"$WP_URL/wp-json/patchledger/v1/health\""
    echo
    echo -e "${YELLOW}Configuration recommandée:${NC}"
    echo "- Créez un Application Password dans Utilisateurs → Profil"
    echo "- Vérifiez que les permaliens sont configurés"
    echo "- Testez l'API REST: $WP_URL/wp-json/"
    echo
}

# Exécution principale
main() {
    if ! detect_wordpress; then
        echo -e "${RED}✗ WordPress non trouvé${NC}"
        echo "Vérifiez que WordPress est installé sur ce serveur"
        exit 1
    fi

    detect_plugins_dir
    install_plugin

    if verify_installation; then
        # Tenter de détecter l'URL du site
        if [ -f "$WP_ROOT/wp-config.php" ]; then
            WP_URL=$(grep -o "define.*WP_HOME.*'[^']*'" "$WP_ROOT/wp-config.php" 2>/dev/null | cut -d"'" -f4 || echo "http://localhost")
        else
            WP_URL="http://localhost"
        fi

        show_instructions
    else
        echo -e "${RED}✗ Échec de l'installation${NC}"
        exit 1
    fi
}

# Variables globales
WP_ROOT=""
PLUGINS_DIR=""
WP_URL=""

# Lancer l'installation
main "$@"