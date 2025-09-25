#!/usr/bin/env bash
# Usage: MAGENTO_PATH=/var/www/html ./magento_update.sh package/name 1.2.3
set -euo pipefail

M2=${MAGENTO_PATH:-/var/www/html}
PKG="$1"
VER="$2"

cd "$M2"
php bin/magento maintenance:enable
composer require "$PKG:$VER" --no-plugins --no-scripts -q
php bin/magento setup:upgrade -q
php bin/magento cache:flush -q
php bin/magento maintenance:disable
