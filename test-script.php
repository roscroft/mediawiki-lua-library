<?php
// test-script.php - CLI script for testing Lua modules with Scribunto
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set up fake web environment for MediaWiki
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['HTTP_USER_AGENT'] = 'ScribuntoTestRunner';
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['SERVER_NAME'] = 'localhost';
$_SERVER['SERVER_PORT'] = '80';
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['REQUEST_URI'] = '/index.php';
$_SERVER['SERVER_PROTOCOL'] = 'HTTP/1.1';

// Define maintenance mode to bypass some checks
define('MW_PHPUNIT_TEST', true);
putenv('MW_INSTALL_PATH=/var/www/html');

try {
    // Load MediaWiki
    require_once "/var/www/html/includes/WebStart.php";
    
    // Get file path to test
    $script = isset($argv[1]) ? $argv[1] : "/var/www/html/modules/custom/test.lua";
    if (!file_exists($script)) {
        echo "ERROR: Script file not found: $script\n";
        exit(1);
    }

    // Make sure we have a data directory
    if (!file_exists('/var/www/html/data')) {
        mkdir('/var/www/html/data', 0777, true);
    }
    
    // Create a fake user context
    $user = User::newSystemUser('ScribuntoTester', ['steal' => true]);
    RequestContext::getMain()->setUser($user);

    // Initialize parser
    $parser = new Parser();
    $options = ParserOptions::newFromUser($user);
    $parser->startExternalParse(Title::newMainPage(), $options, Parser::OT_HTML, true);

    // Initialize Scribunto
    $engine = new Scribunto_LuaStandaloneEngine([
        'parser' => $parser,
        'title' => Title::newFromText('Module:Test')
    ]);
    
    // Load and execute the module
    echo "Testing module: " . basename($script) . "\n";
    $code = file_get_contents($script);
    
    // Initialize the Lua interpreter
    $engine->setupInterface();
    $interpreter = $engine->getInterpreter();
    
    // Load the module and get its exports
    $result = $interpreter->loadString($code, 'test');
    echo "Module loaded successfully!\n";
    
    // Show module exports if available
    if (isset($result[0]) && is_array($result[0])) {
        $exports = $result[0];
        echo "Module exports " . count($exports) . " functions/values:\n";
        
        foreach ($exports as $key => $value) {
            echo "  - $key: " . gettype($value) . "\n";
        }
    } else {
        echo "Module loaded but returned no exports.\n";
    }
    
} catch (Exception $e) {
    echo "ERROR: " . get_class($e) . ": " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . " on line " . $e->getLine() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}

exit(0);
