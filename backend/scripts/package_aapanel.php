<?php
// Packaging script for aaPanel Deployment
declare(strict_types=1);

$rootDir = realpath(__DIR__ . '/../../');
$webBuildDir = $rootDir . '/frontend/build/web';
$zipFile = $rootDir . '/untidar-fixit-full-aapanel.zip';

if (!is_dir($webBuildDir)) {
    die("Error: Web build directory not found at $webBuildDir\n");
}

if (file_exists($zipFile)) {
    unlink($zipFile);
}

$zip = new ZipArchive();
if ($zip->open($zipFile, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
    die("Error: Cannot create zip file at $zipFile\n");
}

echo "1. Adding Flutter Web release files to ZIP root...\n";
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($webBuildDir, RecursiveDirectoryIterator::SKIP_DOTS),
    RecursiveIteratorIterator::SELF_FIRST
);

foreach ($iterator as $file) {
    $filePath = $file->getRealPath();
    $relativePath = substr($filePath, strlen($webBuildDir) + 1);
    $relativePath = str_replace('\\', '/', $relativePath);
    
    if ($file->isDir()) {
        $zip->addEmptyDir($relativePath);
    } else {
        $zip->addFile($filePath, $relativePath);
    }
}

echo "2. Adding API front controller helper (api/index.php)...\n";
$apiIndex = <<<'PHP'
<?php
// Forward /api requests to backend/public/index.php
require_once __DIR__ . '/../backend/public/index.php';
PHP;
$zip->addFromString('api/index.php', $apiIndex);

echo "3. Adding backend source and configuration...\n";
$backendDir = $rootDir . '/backend';
$backendFiles = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($backendDir, RecursiveDirectoryIterator::SKIP_DOTS),
    RecursiveIteratorIterator::SELF_FIRST
);

$excludeDirs = ['node_modules', '.git', 'vendor', 'cache'];
foreach ($backendFiles as $file) {
    $filePath = $file->getRealPath();
    $relativePath = 'backend/' . str_replace('\\', '/', substr($filePath, strlen($backendDir) + 1));

    $skip = false;
    foreach ($excludeDirs as $ex) {
        if (str_contains($relativePath, '/' . $ex . '/') || str_ends_with($relativePath, '/' . $ex)) {
            $skip = true;
            break;
        }
    }
    if ($skip) continue;

    if ($file->isDir()) {
        $zip->addEmptyDir($relativePath);
    } else {
        $zip->addFile($filePath, $relativePath);
    }
}

echo "4. Setting up production .env...\n";
$prodEnv = <<<ENV
APP_NAME="Untidar Fixit"
APP_ENV=production
APP_DEBUG=false
APP_URL="https://untidar-fixit.duckdns.org"

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=untidar-fixit_db
DB_USER=untidar-fixit_db
DB_PASS=KMi2Gkmj8rL8kaXW

APP_SECRET="untidar_fixit_super_secret_key_2026_tuguran_sidotopo"
JWT_SECRET="untidar_fixit_jwt_signature_secret_untidar_2026"
CORS_ALLOWED_ORIGINS="https://untidar-fixit.duckdns.org,http://untidar-fixit.duckdns.org,http://localhost:5000,http://127.0.0.1:5000,*"
ENV;

$zip->addFromString('backend/.env', $prodEnv);
$zip->addFromString('backend/.env.production', $prodEnv);

echo "5. Adding SQL files & Nginx configuration...\n";
if (file_exists($rootDir . '/untidar_fixit_full_dump.sql')) {
    $zip->addFile($rootDir . '/untidar_fixit_full_dump.sql', 'untidar_fixit_full_dump.sql');
}

$nginxConf = <<<'NGINX'
# Nginx Configuration for Untidar Fixit on aaPanel
# Domain: untidar-fixit.duckdns.org
# Root: /www/wwwroot/untidar-fixit.duckdns.org

server {
    listen 80;
    listen 443 ssl http2;
    server_name untidar-fixit.duckdns.org;
    index index.html index.php;
    root /www/wwwroot/untidar-fixit.duckdns.org;

    # API Proxy to PHP Backend
    location /api {
        rewrite ^/api/(.*)$ /backend/public/index.php?$query_string last;
    }

    # Uploads storage
    location /uploads {
        alias /www/wwwroot/untidar-fixit.duckdns.org/backend/public/uploads;
        expires 30d;
        access_log off;
    }

    # PHP FastCGI execution for backend
    location ~ \.php$ {
        include fastcgi_params;
        # Sesuaikan dengan versi PHP aaPanel Anda (misal php-cgi-83.sock, php-cgi-82.sock, php-cgi-81.sock, atau php-cgi-80.sock)
        fastcgi_pass unix:/tmp/php-cgi-83.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Flutter Web Single Page App fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Protect sensitive backend folders
    location ~ ^/backend/(src|config|database|\.env) {
        deny all;
        return 404;
    }
}
NGINX;
$zip->addFromString('nginx-aapanel.conf', $nginxConf);

$readme = <<<'TXT'
================================================================================
PANDUAN DEPLOYMENT UNTIDAR FIXIT KE AAPANEL
Domain: untidar-fixit.duckdns.org
Database: untidar-fixit_db | User: untidar-fixit_db | Pass: KMi2Gkmj8rL8kaXW
================================================================================

1. UPLOAD FILE ZIP:
   - Buka aaPanel > Menu "Files".
   - Masuk ke direktori website: /www/wwwroot/untidar-fixit.duckdns.org/
   - Upload file `untidar-fixit-full-aapanel.zip` lalu Extract di folder tersebut.

2. DATABASE & SQL (JIKA PERLU RE-IMPORT):
   - Buka phpMyAdmin di aaPanel atau langsung import file `untidar_fixit_full_dump.sql`.
   - File SQL ini 100% BEBAS DARI ERROR "CREATE DATABASE / Access Denied".

3. KONFIGURASI NGINX DI AAPANEL:
   - Buka menu "Website" > Klik domain `untidar-fixit.duckdns.org` > "Configuration".
   - Pastikan block `location /api` dan `location /` sudah ditambahkan sesuai `nginx-aapanel.conf`:

     location /api {
         rewrite ^/api/(.*)$ /backend/public/index.php?$query_string last;
     }

     location / {
         try_files $uri $uri/ /index.html;
     }

4. KREDENSIAL DEMO APLIKASI:
   - Mahasiswa: muhammad.asyrof@students.untidar.ac.id
   - Admin Sarpras: admin@untidar.ac.id
   - Password: UntidarFixit2026! (atau mahasiswa123)
================================================================================
TXT;
$zip->addFromString('README_DEPLOY_AAPANEL.txt', $readme);

$zip->close();
echo "aaPanel ZIP created successfully at: $zipFile (" . round(filesize($zipFile) / (1024 * 1024), 2) . " MB)\n";
