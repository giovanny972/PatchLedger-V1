#!/bin/bash

# Script pour trouver votre installation WordPress sur Debian/Ubuntu
# Usage: ./find-wordpress.sh

echo "=== Recherche de WordPress sur votre système ==="
echo

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier si WordPress est installé via paquet
echo -e "${YELLOW}1. Vérification des paquets WordPress installés...${NC}"

if dpkg -l | grep -q wordpress; then
    echo -e "${GREEN}✓ Paquet WordPress trouvé:${NC}"
    dpkg -l | grep wordpress
    echo

    # Chemins typiques Debian
    echo -e "${YELLOW}Chemins WordPress sur Debian:${NC}"
    echo "- Fichiers core: /usr/share/wordpress/"
    echo "- Configuration: /etc/wordpress/"
    echo "- Plugins/thèmes: /var/lib/wordpress/wp-content/"
    echo "- Logs: /var/log/wordpress/"
    echo
else
    echo -e "${RED}✗ Aucun paquet WordPress trouvé${NC}"
fi

# Recherche de fichiers WordPress
echo -e "${YELLOW}2. Recherche des fichiers wp-config.php...${NC}"
wp_configs=$(find /var /usr /opt /home -name "wp-config.php" 2>/dev/null | head -10)

if [ -n "$wp_configs" ]; then
    echo -e "${GREEN}✓ Fichiers wp-config.php trouvés:${NC}"
    echo "$wp_configs"
    echo
else
    echo -e "${RED}✗ Aucun wp-config.php trouvé${NC}"
fi

# Recherche de répertoires wp-content
echo -e "${YELLOW}3. Recherche des répertoires wp-content...${NC}"
wp_contents=$(find /var /usr -name "wp-content" -type d 2>/dev/null | head -10)

if [ -n "$wp_contents" ]; then
    echo -e "${GREEN}✓ Répertoires wp-content trouvés:${NC}"
    echo "$wp_contents"
    echo
else
    echo -e "${RED}✗ Aucun répertoire wp-content trouvé${NC}"
fi

# Vérifier les services web
echo -e "${YELLOW}4. Vérification des services web...${NC}"

if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Apache2 actif${NC}"
    echo "  Document root probable: /var/www/html/"
elif systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx actif${NC}"
    echo "  Document root à vérifier dans: /etc/nginx/sites-enabled/"
else
    echo -e "${RED}✗ Aucun service web détecté${NC}"
fi

# Recherche dans les sites Nginx/Apache
echo -e "${YELLOW}5. Recherche dans les configurations web...${NC}"

# Configuration Apache
if [ -d "/etc/apache2/sites-enabled" ]; then
    echo "Sites Apache actifs:"
    grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | grep -v "#" || echo "  Aucune configuration trouvée"
fi

# Configuration Nginx
if [ -d "/etc/nginx/sites-enabled" ]; then
    echo "Sites Nginx actifs:"
    grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "#" | head -5 || echo "  Aucune configuration trouvée"
fi

echo
echo "=== Diagnostic ==="

# Si paquet Debian installé
if dpkg -l | grep -q wordpress; then
    echo -e "${GREEN}WordPress installé via paquet Debian${NC}"
    echo -e "${YELLOW}Pour installer le plugin PatchLedger:${NC}"
    echo "sudo mkdir -p /var/lib/wordpress/wp-content/plugins/patchledger-agent"
    echo "sudo cp patchledger-agent-wp.php /var/lib/wordpress/wp-content/plugins/patchledger-agent/"
    echo "sudo chown -R www-data:www-data /var/lib/wordpress/wp-content/plugins/patchledger-agent/"
    echo
    echo -e "${YELLOW}Configuration typique:${NC}"
    echo "- URL admin: http://votre-ip/wordpress/wp-admin"
    echo "- Fichiers dans: /usr/share/wordpress/"
    echo "- Plugins dans: /var/lib/wordpress/wp-content/plugins/"

elif [ -n "$wp_configs" ]; then
    wp_root=$(dirname $(echo "$wp_configs" | head -1))
    echo -e "${GREEN}WordPress trouvé dans: $wp_root${NC}"

    if [ -d "$wp_root/wp-content/plugins" ]; then
        echo -e "${YELLOW}Pour installer le plugin PatchLedger:${NC}"
        echo "sudo mkdir -p $wp_root/wp-content/plugins/patchledger-agent"
        echo "sudo cp patchledger-agent-wp.php $wp_root/wp-content/plugins/patchledger-agent/"
        echo "sudo chown -R www-data:www-data $wp_root/wp-content/plugins/patchledger-agent/"
    fi

else
    echo -e "${RED}WordPress non trouvé sur ce système${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "1. Installer WordPress: sudo apt install wordpress"
    echo "2. Télécharger WordPress manuellement dans /var/www/html/"
    echo "3. Utiliser Docker: docker run -p 8080:80 wordpress"
fi

echo
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "- Voir les paquets installés: dpkg -l | grep -i web"
echo "- Voir les services actifs: systemctl list-units --type=service --state=active | grep -E 'apache|nginx'"
echo "- Voir les ports ouverts: sudo netstat -tlnp | grep -E ':80|:443'"