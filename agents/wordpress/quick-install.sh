#!/bin/bash

# Installation rapide de WordPress + PatchLedger Agent sur Debian
# Usage: ./quick-install.sh

set -euo pipefail

echo "=== Installation Rapide WordPress + PatchLedger ==="
echo

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier les droits sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
   echo -e "${RED}Ce script nécessite sudo${NC}"
   exit 1
fi

# Fonction d'installation WordPress
install_wordpress() {
    echo -e "${YELLOW}Installation de WordPress...${NC}"

    # Mettre à jour les paquets
    sudo apt update

    # Installer WordPress et ses dépendances
    sudo apt install -y wordpress php libapache2-mod-php mysql-server php-mysql

    echo -e "${GREEN}✓ WordPress installé${NC}"

    # Configurer Apache pour WordPress
    if ! [ -f /etc/apache2/conf-available/wordpress.conf ]; then
        sudo ln -sf /usr/share/wordpress /var/www/html/wordpress

        # Créer la configuration Apache
        cat << 'EOF' | sudo tee /etc/apache2/conf-available/wordpress.conf > /dev/null
Alias /wordpress /usr/share/wordpress
<Directory /usr/share/wordpress>
    Options FollowSymLinks
    AllowOverride Limit Options FileInfo
    DirectoryIndex index.php
    Order allow,deny
    Allow from all
</Directory>
<Directory /usr/share/wordpress/wp-content>
    Options FollowSymLinks
    Order allow,deny
    Allow from all
</Directory>
EOF

        # Activer la configuration
        sudo a2enconf wordpress
        sudo systemctl reload apache2

        echo -e "${GREEN}✓ Apache configuré pour WordPress${NC}"
    fi
}

# Fonction de configuration MySQL
setup_mysql() {
    echo -e "${YELLOW}Configuration MySQL...${NC}"

    # Générer un mot de passe aléatoire
    DB_PASSWORD=$(openssl rand -base64 12)

    # Créer la base de données et l'utilisateur
    sudo mysql -e "
        CREATE DATABASE IF NOT EXISTS wordpress;
        CREATE USER IF NOT EXISTS 'wordpress'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';
        FLUSH PRIVILEGES;
    " 2>/dev/null || {
        echo -e "${YELLOW}Configuration MySQL manuelle requise${NC}"
        echo "Créez une base 'wordpress' et configurez /etc/wordpress/config-default.php"
        return 0
    }

    # Configurer WordPress pour utiliser cette base
    if [ ! -f /etc/wordpress/config-default.php ]; then
        sudo cp /usr/share/doc/wordpress/examples/setup-mysql /tmp/
        sudo sed -i "s/wordpress-db/wordpress/g" /tmp/setup-mysql
        sudo sed -i "s/wordpress-user/wordpress/g" /tmp/setup-mysql
        sudo bash /tmp/setup-mysql
    fi

    echo "Base de données: wordpress"
    echo "Utilisateur: wordpress"
    echo "Mot de passe: $DB_PASSWORD"
    echo -e "${GREEN}✓ MySQL configuré${NC}"
}

# Fonction d'installation de l'agent PatchLedger
install_patchledger() {
    echo -e "${YELLOW}Installation de l'agent PatchLedger...${NC}"

    local plugin_dir="/var/lib/wordpress/wp-content/plugins/patchledger-agent"

    # Créer le répertoire
    sudo mkdir -p "$plugin_dir"

    # Copier le plugin
    if [ -f "patchledger-agent-wp.php" ]; then
        sudo cp "patchledger-agent-wp.php" "$plugin_dir/"
    else
        echo -e "${RED}Fichier patchledger-agent-wp.php non trouvé${NC}"
        echo "Assurez-vous d'être dans le bon répertoire"
        return 1
    fi

    # Définir les permissions
    sudo chown -R www-data:www-data "$plugin_dir"
    sudo chmod -R 755 "$plugin_dir"

    echo -e "${GREEN}✓ Agent PatchLedger installé${NC}"
}

# Fonction de détection de l'IP
get_server_ip() {
    # Essayer plusieurs méthodes pour obtenir l'IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipecho.net/plain 2>/dev/null || hostname -I | awk '{print $1}' || echo "localhost")
}

# Fonction d'affichage des instructions finales
show_final_instructions() {
    get_server_ip

    echo
    echo "=== Installation Terminée ==="
    echo
    echo -e "${GREEN}WordPress est maintenant installé !${NC}"
    echo
    echo -e "${YELLOW}URLs d'accès:${NC}"
    echo "- Site: http://$SERVER_IP/wordpress/"
    echo "- Admin: http://$SERVER_IP/wordpress/wp-admin/"
    echo
    echo -e "${YELLOW}Prochaines étapes:${NC}"
    echo "1. Ouvrez http://$SERVER_IP/wordpress/ dans votre navigateur"
    echo "2. Suivez l'assistant d'installation WordPress"
    echo "3. Connectez-vous à l'admin (/wp-admin/)"
    echo "4. Activez le plugin 'PatchLedger Agent'"
    echo "5. Testez: curl \"http://$SERVER_IP/wordpress/wp-json/patchledger/v1/health\""
    echo
    echo -e "${YELLOW}Informations base de données:${NC}"
    echo "- Nom: wordpress"
    echo "- Utilisateur: wordpress"
    echo "- Serveur: localhost"
    echo
    echo -e "${YELLOW}Dépannage:${NC}"
    echo "- Logs Apache: sudo tail -f /var/log/apache2/error.log"
    echo "- Redémarrer Apache: sudo systemctl restart apache2"
    echo "- Vérifier MySQL: sudo systemctl status mysql"
}

# Exécution principale
main() {
    echo "Cette installation va:"
    echo "1. Installer WordPress via apt"
    echo "2. Configurer Apache et MySQL"
    echo "3. Installer l'agent PatchLedger"
    echo
    read -p "Continuer? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation annulée"
        exit 0
    fi

    install_wordpress
    setup_mysql
    install_patchledger
    show_final_instructions
}

main "$@"