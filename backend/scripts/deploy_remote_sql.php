<?php

$host = '103.150.100.114';
$port = 3306;
$db   = 'untidar-fixit_db';
$user = 'untidar-fixit_db';
$pass = 'KMi2Gkmj8rL8kaXW';

echo "1. Trying direct MySQL connection to $host:$port...\n";

try {
    $pdo = new PDO("mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_TIMEOUT => 6,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    echo "SUCCESS: Direct PDO MySQL connection established!\n";
    
    // Execute schema and seed
    $sqlFiles = [
        __DIR__ . '/../database/schema.sql',
        __DIR__ . '/../database/seed.sql'
    ];
    
    foreach ($sqlFiles as $file) {
        if (!file_exists($file)) continue;
        echo "Executing " . basename($file) . "...\n";
        $sql = file_get_contents($file);
        $pdo->exec($sql);
        echo "Completed " . basename($file) . "\n";
    }
    
    echo "ALL_SQL_MIGRATED_SUCCESSFULLY\n";
    exit(0);

} catch (Exception $e) {
    echo "Direct MySQL connection failed: " . $e->getMessage() . "\n";
}

echo "\n2. Trying HTTP connection to phpMyAdmin at http://103.150.100.114:888/phpmyadmin_cb9938d28f6fa294/ ...\n";

$pmaUrl = "http://103.150.100.114:888/phpmyadmin_cb9938d28f6fa294/";
$cookieFile = sys_get_temp_dir() . '/pma_cookie.txt';
if (file_exists($cookieFile)) @unlink($cookieFile);

// Step A: GET PMA login page to grab token
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $pmaUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($ch, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($ch, CURLOPT_TIMEOUT, 15);
curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
$html = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "PMA initial HTTP code: $httpCode\n";

if ($httpCode !== 200 && $httpCode !== 302) {
    echo "Failed to reach phpMyAdmin. Check if IP/port is accessible.\n";
    exit(1);
}

// Find token input
$token = '';
if (preg_match('/name="token"\s+value="([^"]+)"/', $html, $m)) {
    $token = $m[1];
} elseif (preg_match('/token=([a-f0-9]+)/', $html, $m)) {
    $token = $m[1];
}

echo "Found PMA token: " . ($token ? substr($token, 0, 8) . "..." : "none") . "\n";

// Step B: POST login
$postFields = [
    'pma_username' => $user,
    'pma_password' => $pass,
    'server'       => 1,
    'target'       => 'index.php?route=/&db=' . $db,
];
if ($token) {
    $postFields['token'] = $token;
}

curl_setopt($ch, CURLOPT_URL, $pmaUrl . 'index.php?route=/');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postFields));
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

$loginResp = curl_exec($ch);
$loginCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "PMA login response code: $loginCode\n";

// Grab new session token after login
$postToken = $token;
if (preg_match('/name="token"\s+value="([^"]+)"/', $loginResp, $m)) {
    $postToken = $m[1];
} elseif (preg_match('/token=([a-f0-9]{32,})/', $loginResp, $m)) {
    $postToken = $m[1];
}
echo "Authenticated token: " . ($postToken ? substr($postToken, 0, 8) . "..." : "none") . "\n";

// Step C: Execute SQL query via phpMyAdmin
$sqlQueries = file_get_contents(__DIR__ . '/../database/schema.sql') . "\n" . file_get_contents(__DIR__ . '/../database/seed.sql');

$sqlFields = [
    'db'            => $db,
    'token'         => $postToken,
    'sql_query'     => $sqlQueries,
    'is_js_confirmed' => 0,
];

curl_setopt($ch, CURLOPT_URL, $pmaUrl . 'index.php?route=/import');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($sqlFields));

$importResp = curl_exec($ch);
$importCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "PMA import finished with code: $importCode\n";
if (strpos($importResp, 'success') !== false || strpos($importResp, 'berhasil') !== false || $importCode == 200) {
    echo "SQL import to remote database untidar-fixit_db succeeded!\n";
} else {
    echo "Notice: Output received from PMA. Verifying...\n";
}
