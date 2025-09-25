#!/usr/bin/env bash
# Usage: WP_PATH=/var/www/html ./wp_autopatch.sh plugin-slug new-version
set -euo pipefail

WP=${WP_PATH:-/var/www/html}
SLUG="$1"
VERSION="$2"

cd "$WP"
wp plugin update "$SLUG" --version="$VERSION" --quiet
wp option update patchledger_last_update "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
