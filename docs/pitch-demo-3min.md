# Panduan Demo & Pitch Presentasi Juri (3 Menit) — LaporTidar

> **Tema:** Solusi Digital Fasilitas, Mobilitas & Lingkungan Kampus Tuguran Untidar  
> **Target Audience:** Dewan Juri Hackathon Universitas Tidar 2026  
> **Durasi Presentasi:** Maksimal 3 Menit

---

## ⏱️ Timeline Presentasi 3 Menit

```
[00:00 - 00:45] Hook & Problem Statement Mahasiswa Tuguran
[00:45 - 01:30] Demo Mahasiswa: Scan QR Ruangan & Fitur Anti-Spam "Saya Mengalami Hal Serupa"
[01:30 - 02:15] Demo Sarpras: Antrian Skor Prioritas, Penugasan Teknisi & Foto Bukti
[02:15 - 02:45] Live Progress Tracking (Timeline Transparan) & Rating Kepuasan Mahasiswa
[02:45 - 03:00] Closing, Security Hardening & Kesiapan Deploy aaPanel
```

---

## 🎙️ Script & Langkah Demo Langkah demi Langkah

### 1. Menit 00:00 – 00:45: The Hook & Real Campus Problem
> *"Bapak/Ibu Dewan Juri yang terhormat, pernahkah Anda masuk ke ruang kuliah di GKB Lantai 3 dan mendapati AC bocor menetes ke meja kuliah, atau toilet di FT airnya mengucur semalaman?*  
> *Masalah di Kampus Tuguran bukan mahasiswanya tidak mau melapor, melainkan:*
> 1. *Laporan berserakan di WhatsApp tanpa nomor tiket resmi.*
> 2. *Lokasi tidak jelas ('Pak, toilet rusak', toilet yang mana?).*
> 3. *Terjadi laporan ganda (puluhan orang melapor hal yang sama).*
> 4. *Dan yang paling menyebalkan: mahasiswa tidak tahu apakah laporan mereka sedang dikerjakan atau diabaikan oleh Sarpras.*
>
> *Inilah alasan kami membangun **LaporTidar**: platform pengaduan fasilitas kampus berbasis QR, anti-spam, dan live tracking transparan."*

---

### 2. Menit 00:45 – 01:30: Demo Mahasiswa (Quick QR & Anti-Spam)
**Aksi di Layar:**
1. Buka aplikasi, klik tombol **"Demo Mahasiswa"** (Bagas Pratama - NPM 2210501001) lalu klik **Masuk**.
2. Masuk ke menu **Scan QR**:
   - Tunjukkan simulasi stiker pintu ruangan: Klik tombol **"GKB Lt 3 - Ruang 3.02"**.
   - *Sorot ke Juri:* Lokasi langsung terverifikasi dengan tanda tangan digital **HMAC SHA-256** anti-pemalsuan.
3. Klik **Buat Laporan**:
   - Pilih Kategori **AC & Pendingin**.
   - *Sorot ke Juri:* Muncul pop-up pintar **"Laporan Serupa Ditemukan!"**:
     > *"Sistem mendeteksi bahwa AC di GKB 3.02 sudah dilaporkan kemarin. Mahasiswa tidak perlu mengetik laporan baru, cukup klik tombol **'Saya Mengalami Hal Serupa (Upvote)'**!"*
   - Tunjukkan bahwa jumlah dukungan langsung bertambah dan skor prioritas otomatis naik.

---

### 3. Menit 01:30 – 02:15: Demo Sarpras (Antrian Skor Prioritas & Penugasan)
**Aksi di Layar:**
1. Klik **Keluar**, lalu klik tombol **"Demo Admin Sarpras"** (`admin@untidar.ac.id`) dan klik **Masuk**.
2. Tunjukkan **Dashboard Sarpras**:
   - Sorot **Peta Status Kerusakan Gedung Tuguran**: Gedung GKB berwarna merah (3+ masalah aktif), Perpustakaan kuning, Kantin hijau.
   - Sorot metrik: Rata-rata penyelesaian 24.3 jam, indeks kepuasan mahasiswa.
3. Buka menu **Antrian Prioritas**:
   - *Sorot ke Juri:* Urutan laporan tidak acak, melainkan menggunakan rumus:
     $$\text{Skor} = (\text{Upvote} \times 2) + \text{Bobot Kategori} + \text{Hari Terbuka} + \text{Urgensi}$$
   - Klik **Verifikasi** pada tiket laporan AC.
   - Klik **Tugaskan Teknisi**: Pilih teknisi internal Sarpras (*Pak Joko Riyanto - Spesialis Kelistrikan & AC*).
   - Klik **Selesaikan Laporan**: Wajib mengunggah **Foto Bukti Perbaikan (After Photo)** agar tidak ada laporan fiktif yang ditutup tanpa diperbaiki.

---

### 4. Menit 02:15 – 02:45: Live Tracking Transparan & Rating
**Aksi di Layar:**
1. Logout dan kembali login sebagai Mahasiswa.
2. Buka notifikasi atau menu **Laporan Saya**, klik tiket yang baru saja diselesaikan.
3. Tunjukkan ke Juri:
   - **Vertical Timeline**: tercatat rapi detik demi detik siapa petugas yang memverifikasi, teknisi yang bertugas, catatan teknisi, hingga foto perbaikan sesudah.
   - Klik tombol **Beri Rating Kepuasan**: Berikan 5 Bintang dan ulasan *"Terima kasih Sarpras, AC GKB sudah dingin dan tidak bocor lagi!"*.

---

### 5. Menit 02:45 – 03:00: Closing & Kesiapan Produksi
> *"LaporTidar dibangun di atas arsitektur yang solid: Frontend Flutter Web yang responsif untuk HP, tablet, dan laptop, dipadukan dengan REST API PHP 8 native yang ringan, aman dari SQL Injection dan brute-force, serta siap di-deploy langsung di VPS aaPanel Untidar.*  
> *Dengan LaporTidar, fasilitas Kampus Tuguran tertata, Sarpras bekerja terukur, dan mahasiswa belajar dengan nyaman. Terima kasih!"*

---

## 💡 Jawaban Cepat untuk Pertanyaan Juri (FAQ)

1. **Bagaimana jika stiker QR di kelas disobek atau dirusak mahasiswa jahil?**  
   *Jawaban:* Sistem menyediakan fallback manual input kode ruangan (misal `TUG-GKB-302`), dan admin dapat mencetak ulang stiker QR dari menu *Kelola Lokasi & QR* dalam hitungan detik.

2. **Apakah mahasiswa luar atau hacker bisa mengirim ratusan laporan palsu?**  
   *Jawaban:* Kami menerapkan proteksi berlapis: wajib login akun mahasiswa Untidar, rate limiting di level server, validasi MIME asli pada file foto (maks 3MB), serta deteksi duplikasi lokasi berbasis anti-spam.

3. **Bagaimana performa sistem saat digunakan ribuan mahasiswa?**  
   *Jawaban:* Backend PHP native memiliki overhead memori sangat minim (<5 MB per worker), menggunakan connection pooling PDO tanpa framework berat, serta Flutter Web di-build menjadi aset statis yang di-cache di Nginx.
