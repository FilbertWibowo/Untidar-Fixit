# Panduan Deployment LaporTidar ke VPS aaPanel (Nginx + PHP 8 + MariaDB)

Panduan teknis ini menjelaskan cara mendeploy aplikasi **LaporTidar** ke VPS berbasis control panel **aaPanel** untuk domain kampus (misal: `laportidar.untidar.ac.id`).

---

## 1. Persiapan Server di aaPanel

Pastikan software berikut telah terinstal dari menu **App Store** di aaPanel:
1. **Nginx** (versi 1.22+ atau 1.24)
2. **PHP 8.2** atau **PHP 8.3**
3. **MySQL / MariaDB** (versi 10.4+)
4. Ekstensi PHP yang wajib dicentang di menu *PHP Manager -> Install extensions*:
   - `fileinfo` (untuk validasi MIME foto asli)
   - `gd` (untuk rendering image manipulasi)
   - `pdo_mysql` (koneksi database)

---

## 2. Struktur Folder di Server VPS

Buat direktori proyek di path standar aaPanel:
```bash
mkdir -p /www/wwwroot/laportidar
cd /www/wwwroot/laportidar
```

Upload dan ekstrak source code proyek:
```
/www/wwwroot/laportidar/
├── backend/          # Backend PHP Native REST API
│   ├── public/       # Entry point Nginx untuk /api
│   ├── src/
│   ├── config/
│   └── database/
└── frontend/
    └── build/web/    # Hasil build static Flutter Web
```

---

## 3. Setup Database MariaDB di aaPanel

1. Masuk ke menu **Databases** di aaPanel, klik **Add Database**:
   - Database Name: `laportidar`
   - DB Username: `laportidar_user`
   - Password: `[PasswordKuatMySQL]`
2. Import skema dan seed data:
   ```bash
   mysql -u laportidar_user -p laportidar < /www/wwwroot/laportidar/backend/database/schema.sql
   mysql -u laportidar_user -p laportidar < /www/wwwroot/laportidar/backend/database/seed.sql
   ```

---

## 4. Konfigurasi Environment Backend (`.env`)

Salin `.env.example` ke `.env` pada folder backend:
```bash
cd /www/wwwroot/laportidar/backend
cp .env.example .env
nano .env
```

Sesuaikan nilai variabel produksi:
```ini
APP_NAME="LaporTidar Untidar"
APP_ENV=production
APP_DEBUG=false
APP_URL="https://laportidar.untidar.ac.id"

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=laportidar
DB_USER=laportidar_user
DB_PASS=[PasswordKuatMySQL]

APP_SECRET="generate_secret_acak_panjang_untuk_hmac_untidar"
CORS_ALLOWED_ORIGINS="https://laportidar.untidar.ac.id"
```

---

## 5. Build Flutter Web ke Static Production

Di mesin lokal pengembang, jalankan:
```bash
cd frontend
flutter build web --release
```
Unggah seluruh isi folder `frontend/build/web/` ke `/www/wwwroot/laportidar/frontend/build/web/`.

---

## 6. Konfigurasi Virtual Host Nginx di aaPanel

Buka menu **Website** -> Klik nama domain -> **Configuration**:
Ganti blok server Nginx dengan konfigurasi berikut:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name laportidar.untidar.ac.id;
    index index.html index.php;
    root /www/wwwroot/laportidar/frontend/build/web;

    # SSL Let's Encrypt (dapat diaktifkan 1-klik di tab SSL aaPanel)
    # ssl_certificate ...
    # ssl_certificate_key ...

    # Header Keamanan Produksi
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=*, microphone=*" always;

    # 1. Frontend Flutter Web (Single Page Application Router)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 2. Backend REST API (/api)
    location /api {
        root /www/wwwroot/laportidar/backend/public;
        rewrite ^/api/(.*)$ /index.php?/$1 last;
    }

    # 3. Static Uploads (Foto Bukti Sarpras) dengan Proteksi Eksekusi Script
    location /uploads {
        alias /www/wwwroot/laportidar/backend/public/uploads;
        expires 7d;
        add_header Cache-Control "public, no-transform";

        # BLOCK eksekusi file PHP di folder upload foto!
        location ~ \.(php|php5|phtml|phar|sh|pl|cgi)$ {
            deny all;
            return 403;
        }
    }

    # 4. PHP FastCGI Handler untuk Backend
    location ~ \.php$ {
        root /www/wwwroot/laportidar/backend/public;
        fastcgi_pass unix:/tmp/php-cgi-83.sock; # Sesuaikan versi PHP aaPanel
        fastcgi_index index.php;
        include fastcgi.conf;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # 5. Blok akses file sensitif
    location ~ /\.(ht|env|git|svn) {
        deny all;
    }
}
```

---

## 7. Hardening Hak Akses & PHP Security

Atur kepemilikan user `www:www` standar aaPanel:
```bash
chown -R www:www /www/wwwroot/laportidar
chmod -R 755 /www/wwwroot/laportidar
chmod -R 775 /www/wwwroot/laportidar/backend/public/uploads
```

Di menu *PHP Manager -> Security*:
Tambahkan fungsi-fungsi berbahaya ke dalam `disable_functions`:
```
exec,shell_exec,system,passthru,popen,proc_open,show_source
```

---

## 8. Verifikasi Deployment

1. Buka `https://laportidar.untidar.ac.id/api/health` ➔ Harus merespons `{ "success": true, "message": "API LaporTidar berjalan dengan normal." }`.
2. Buka `https://laportidar.untidar.ac.id` ➔ Halaman login Flutter Web muncul mulus dan siap diuji.
