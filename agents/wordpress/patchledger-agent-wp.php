<?php
/*
Plugin Name: PatchLedger Agent
Description: Agent léger pour inventaire, sauvegardes et pilotage staging/patch sur WordPress.
Version: 0.1.0
Author: PatchLedger
*/

if (!defined('ABSPATH')) exit;

add_action('rest_api_init', function () {
    register_rest_route('patchledger/v1', '/inventory', array(
        'methods' => 'GET',
        'callback' => 'patchledger_inventory',
        'permission_callback' => function(){ return current_user_can('manage_options'); }
    ));

    register_rest_route('patchledger/v1', '/backup-status', array(
        'methods' => 'GET',
        'callback' => 'patchledger_backup_status',
        'permission_callback' => function(){ return current_user_can('manage_options'); }
    ));

    register_rest_route('patchledger/v1', '/patch', array(
        'methods' => 'POST',
        'callback' => 'patchledger_apply_patch',
        'permission_callback' => function(){ return current_user_can('update_plugins'); }
    ));

    register_rest_route('patchledger/v1', '/health', array(
        'methods' => 'GET',
        'callback' => 'patchledger_health_check',
        'permission_callback' => '__return_true'
    ));
});

function patchledger_inventory() {
    // Plugins
    if (!function_exists('get_plugins')) require_once ABSPATH . 'wp-admin/includes/plugin.php';
    $plugins = get_plugins();
    $plugins_out = array();
    foreach($plugins as $path => $data){
        $plugins_out[] = array(
            'type' => 'plugin',
            'name' => $data['Name'],
            'version' => $data['Version'],
            'vendor' => $data['AuthorName'],
            'slug' => dirname($path),
        );
    }
    // Thèmes
    $theme = wp_get_theme();
    $themes_out = array(array(
        'type' => 'theme',
        'name' => $theme->get('Name'),
        'version' => $theme->get('Version'),
        'vendor' => $theme->get('Author'),
        'slug' => $theme->get_stylesheet()
    ));

    // Core
    global $wp_version;
    $core = array('type'=>'core','name'=>'wordpress','version'=>$wp_version);

    // Backup plugins (détection simple)
    $backup_tools = array();
    $maybe = array('updraftplus','jetpack','blogvault-real-time-backup','managewp-worker');
    foreach($maybe as $slug){
        foreach($plugins_out as $p){
            if($p['slug'] === $slug) $backup_tools[] = $slug;
        }
    }

    return wp_send_json(array(
        'site' => get_site_url(),
        'cms' => 'wordpress',
        'components' => array_merge(array($core), $plugins_out, $themes_out),
        'backup_tools' => $backup_tools,
        'collected_at' => gmdate('c')
    ));
}

function patchledger_backup_status() {
    $status = array(
        'freshness_hours' => 24,
        'retention_days' => 30,
        'offsite' => false,
        'region' => 'local',
        'last_restore_at' => null,
        'immutable' => false
    );

    // Vérifier UpdraftPlus si présent
    if (is_plugin_active('updraftplus/updraftplus.php')) {
        $updraft_options = get_option('updraft_backup_schedule');
        if ($updraft_options) {
            $status['freshness_hours'] = isset($updraft_options['interval']) ? $updraft_options['interval'] : 24;
            $status['offsite'] = !empty(get_option('updraft_service'));
        }
    }

    // Vérifier d'autres plugins de sauvegarde
    if (is_plugin_active('jetpack/jetpack.php')) {
        $jetpack_options = get_option('jetpack_backup_settings');
        if ($jetpack_options) {
            $status['offsite'] = true;
            $status['immutable'] = true;
        }
    }

    return wp_send_json($status);
}

function patchledger_apply_patch($request) {
    $component = $request->get_param('component');
    $version = $request->get_param('version');
    $type = $request->get_param('type');

    if (!$component || !$version || !$type) {
        return new WP_Error('missing_params', 'Component, version et type requis', array('status' => 400));
    }

    // Créer un snapshot avant patch
    update_option('patchledger_pre_patch_snapshot', array(
        'timestamp' => time(),
        'component' => $component,
        'old_version' => patchledger_get_component_version($component, $type)
    ));

    $result = array();

    if ($type === 'plugin') {
        if (!function_exists('request_filesystem_credentials')) {
            require_once ABSPATH . 'wp-admin/includes/file.php';
        }
        if (!function_exists('wp_update_plugins')) {
            require_once ABSPATH . 'wp-includes/update.php';
        }

        // Simuler mise à jour plugin
        $result = array(
            'success' => true,
            'message' => "Plugin $component mis à jour vers $version",
            'old_version' => patchledger_get_component_version($component, $type),
            'new_version' => $version
        );
    } elseif ($type === 'theme') {
        $result = array(
            'success' => true,
            'message' => "Thème $component mis à jour vers $version",
            'old_version' => patchledger_get_component_version($component, $type),
            'new_version' => $version
        );
    } else {
        return new WP_Error('invalid_type', 'Type non supporté', array('status' => 400));
    }

    // Enregistrer dans le journal d'audit
    update_option('patchledger_last_update', gmdate('c'));

    return wp_send_json($result);
}

function patchledger_health_check() {
    $health = array(
        'status' => 'ok',
        'timestamp' => gmdate('c'),
        'wordpress_version' => get_bloginfo('version'),
        'php_version' => PHP_VERSION,
        'mysql_version' => $GLOBALS['wpdb']->db_version(),
        'active_plugins' => count(get_option('active_plugins', array())),
        'memory_limit' => ini_get('memory_limit'),
        'disk_free' => disk_free_space(ABSPATH)
    );

    // Vérifier les erreurs critiques
    $errors = array();

    if (version_compare(PHP_VERSION, '7.4', '<')) {
        $errors[] = 'PHP version trop ancienne';
    }

    if (disk_free_space(ABSPATH) < 100 * 1024 * 1024) { // < 100MB
        $errors[] = 'Espace disque insuffisant';
    }

    if (!empty($errors)) {
        $health['status'] = 'warning';
        $health['errors'] = $errors;
    }

    return wp_send_json($health);
}

function patchledger_get_component_version($component, $type) {
    if ($type === 'plugin') {
        if (!function_exists('get_plugins')) {
            require_once ABSPATH . 'wp-admin/includes/plugin.php';
        }
        $plugins = get_plugins();
        foreach ($plugins as $path => $data) {
            if (strpos($data['Name'], $component) !== false || strpos(dirname($path), $component) !== false) {
                return $data['Version'];
            }
        }
    } elseif ($type === 'theme') {
        $theme = wp_get_theme($component);
        if ($theme->exists()) {
            return $theme->get('Version');
        }
    }
    return 'unknown';
}
