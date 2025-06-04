<?php
// A simpler test script that avoids database operations

// Basic environment setup
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Get file path to test
$script = isset($argv[1]) ? $argv[1] : "/var/www/html/modules/custom/test.lua";
if (!file_exists($script)) {
    echo "ERROR: Script file not found: $script\n";
    exit(1);
}

echo "\nTesting module: " . basename($script) . "\n";

// Copy environment files to expected locations
$moduleLoader = '/var/www/html/module-loader.lua';
$wikiEnvFile = '/var/www/html/wiki-lua-env.lua';

// Create the module loader if it doesn't exist
if (!file_exists($moduleLoader)) {
    echo "Setting up test environment...\n";
    if (file_exists('/var/www/html/modules/custom/module-loader.lua')) {
        copy('/var/www/html/modules/custom/module-loader.lua', $moduleLoader);
    }
}

// Create the wiki environment if it doesn't exist
if (!file_exists($wikiEnvFile) && file_exists('/var/www/html/modules/custom/wiki-lua-env.lua')) {
    copy('/var/www/html/modules/custom/wiki-lua-env.lua', $wikiEnvFile);
}

// Execute with lua directly using the module loader
$command = "/usr/bin/lua5.1 -l module-loader " . escapeshellarg($script);
passthru($command, $returnCode);
exit($returnCode);
