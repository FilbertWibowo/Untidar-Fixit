$ErrorActionPreference = 'Stop'
$rootDir = 'c:\Users\THIN\Documents\Hackthon'
$stageDir = Join-Path $rootDir 'dist_aapanel'
$zipPath = Join-Path $rootDir 'untidar-fixit-full-aapanel.zip'

Write-Host "1. Cleaning staging directory..."
if (Test-Path $stageDir) {
    Remove-Item -Recurse -Force $stageDir
}
New-Item -ItemType Directory -Path $stageDir | Out-Null

Write-Host "2. Copying Flutter Web release files to root..."
Copy-Item -Path "$rootDir\frontend\build\web\*" -Destination $stageDir -Recurse -Force

Write-Host "3. Creating api/index.php proxy forwarder..."
$apiDir = Join-Path $stageDir 'api'
New-Item -ItemType Directory -Path $apiDir | Out-Null
$apiForwarder = @"
<?php
// Direct forwarder to backend/public/index.php
require_once __DIR__ . '/../backend/public/index.php';
"@
Set-Content -Path (Join-Path $apiDir 'index.php') -Value $apiForwarder -Encoding UTF8

Write-Host "4. Copying backend..."
$stageBackend = Join-Path $stageDir 'backend'
New-Item -ItemType Directory -Path $stageBackend | Out-Null
Copy-Item -Path "$rootDir\backend\config" -Destination $stageBackend -Recurse -Force
Copy-Item -Path "$rootDir\backend\database" -Destination $stageBackend -Recurse -Force
Copy-Item -Path "$rootDir\backend\public" -Destination $stageBackend -Recurse -Force
Copy-Item -Path "$rootDir\backend\src" -Destination $stageBackend -Recurse -Force
Copy-Item -Path "$rootDir\backend\test_api.php" -Destination $stageBackend -Force
Copy-Item -Path "$rootDir\backend\test_e2e_flow.php" -Destination $stageBackend -Force

Write-Host "5. Setting up production .env..."
$prodEnv = @"
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
"@
Set-Content -Path (Join-Path $stageBackend '.env') -Value $prodEnv -Encoding UTF8
Set-Content -Path (Join-Path $stageBackend '.env.production') -Value $prodEnv -Encoding UTF8

Write-Host "6. Adding SQL dump, Nginx config and README..."
Copy-Item -Path "$rootDir\untidar_fixit_full_dump.sql" -Destination $stageDir -Force
Copy-Item -Path "$rootDir\nginx-aapanel.conf" -Destination $stageDir -Force

$readme = @"
================================================================================
PANDUAN DEPLOYMENT UNTIDAR FIXIT KE AAPANEL
Domain: untidar-fixit.duckdns.org
Database: untidar-fixit_db | User: untidar-fixit_db | Pass: KMi2Gkmj8rL8kaXW
================================================================================

1. UPLOAD FILE ZIP:
   - Buka aaPanel > Menu "Files".
   - Masuk ke folder direktori website: /www/wwwroot/untidar-fixit.duckdns.org/
   - Upload file `untidar-fixit-full-aapanel.zip` lalu Extract di folder tersebut.

2. DATABASE & SQL (JIKA INGIN RE-IMPORT):
   - Import file `untidar_fixit_full_dump.sql` di phpMyAdmin aaPanel database `untidar-fixit_db`.
   - File SQL ini 100% SUDAH BERSIH dari "CREATE DATABASE" & "USE laportidar" sehingga tidak akan ada Access Denied.

3. KONFIGURASI NGINX DI AAPANEL:
   - Buka menu "Website" > Klik nama situs `untidar-fixit.duckdns.org` > "Configuration".
   - Tambahkan blok rewrite API dan SPA:

     location /api {
         rewrite ^/api/(.*)$ /backend/public/index.php?`$query_string last;
     }

     location / {
         try_files `$uri `$uri/ /index.html;
     }

4. KREDENSIAL LOGIN DEMO:
   - Mahasiswa: muhammad.asyrof@students.untidar.ac.id
   - Admin Sarpras: admin@untidar.ac.id
   - Password: UntidarFixit2026! (atau mahasiswa123)
================================================================================
"@
Set-Content -Path (Join-Path $stageDir 'README_DEPLOY_AAPANEL.txt') -Value $readme -Encoding UTF8

Write-Host "7. Compressing to $zipPath..."
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

# Use Compress-Archive
Compress-Archive -Path "$stageDir\*" -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "8. Cleaning staging directory..."
Remove-Item -Recurse -Force $stageDir

$size = (Get-Item $zipPath).Length / 1MB
Write-Host "SUCCESS: $zipPath created successfully ($([math]::Round($size, 2)) MB)"
