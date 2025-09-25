<?php
/**
 * Script de test pour l'agent WordPress PatchLedger
 * Usage: php test-agent.php
 */

// Simuler l'environnement WordPress minimal
define('ABSPATH', '/var/www/html/');
define('WP_CONTENT_DIR', ABSPATH . 'wp-content');

// Simuler les fonctions WordPress nécessaires
function get_site_url() { return 'https://test-site.local'; }
function get_bloginfo($what = '') {
    if ($what === 'version') return '6.5.3';
    return 'Test Site';
}
function current_user_can($capability) { return true; }
function wp_send_json($data) {
    echo json_encode($data, JSON_PRETTY_PRINT) . "\n";
    return $data;
}
function get_option($option, $default = false) {
    $options = [
        'active_plugins' => ['woocommerce/woocommerce.php', 'jetpack/jetpack.php'],
        'updraft_backup_schedule' => ['interval' => 12],
        'updraft_service' => 's3'
    ];
    return isset($options[$option]) ? $options[$option] : $default;
}
function update_option($option, $value) { return true; }
function is_plugin_active($plugin) {
    $active = ['updraftplus/updraftplus.php', 'jetpack/jetpack.php'];
    return in_array($plugin, $active);
}
function wp_get_theme($stylesheet = null) {
    return new MockTheme();
}
function gmdate($format) { return date($format); }
function get_plugins() {
    return [
        'woocommerce/woocommerce.php' => [
            'Name' => 'WooCommerce',
            'Version' => '8.7.0',
            'AuthorName' => 'Automattic'
        ],
        'jetpack/jetpack.php' => [
            'Name' => 'Jetpack',
            'Version' => '12.5',
            'AuthorName' => 'Automattic'
        ]
    ];
}

class WP_Error {
    public $message;
    public function __construct($code, $message, $data = []) {
        $this->message = $message;
        echo "ERROR [$code]: $message\n";
    }
}

class MockTheme {
    public function get($what) {
        $data = [
            'Name' => 'Test Theme',
            'Version' => '1.0.0',
            'Author' => 'Test Author'
        ];
        return $data[$what] ?? '';
    }
    public function get_stylesheet() { return 'test-theme'; }
    public function exists() { return true; }
}

class MockRequest {
    private $params = [];
    public function __construct($params = []) { $this->params = $params; }
    public function get_param($key) { return $this->params[$key] ?? null; }
}

// Variables globales simulées
global $wp_version, $wpdb;
$wp_version = '6.5.3';
$wpdb = new stdClass();
$wpdb->db_version = function() { return '8.0.34'; };

// Charger l'agent
require_once 'patchledger-agent-wp.php';

echo "=== Test Agent WordPress PatchLedger ===\n\n";

// Test 1: Inventaire
echo "1. Test inventaire:\n";
patchledger_inventory();
echo "\n";

// Test 2: Statut des sauvegardes
echo "2. Test statut sauvegardes:\n";
patchledger_backup_status();
echo "\n";

// Test 3: Health check
echo "3. Test health check:\n";
patchledger_health_check();
echo "\n";

// Test 4: Application de patch
echo "4. Test application patch:\n";
$patch_request = new MockRequest([
    'component' => 'woocommerce',
    'version' => '8.9.0',
    'type' => 'plugin'
]);
patchledger_apply_patch($patch_request);
echo "\n";

// Test 5: Test avec paramètres manquants
echo "5. Test patch avec paramètres manquants:\n";
$bad_request = new MockRequest(['component' => 'test']);
patchledger_apply_patch($bad_request);
echo "\n";

echo "=== Tests terminés ===\n";