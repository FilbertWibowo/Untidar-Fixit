<?php
// Script to generate seed.sql with official Untidar rooms from data.untidar.ac.id
// plus Tuguran general facilities, demo reports, and students credentials

$secret = 'laportidar_untidar_super_secret_key_2026';
$admin_pw = '$2y$10$nO1GNia0EcbthDMATFQEU.w0gCpBzVEvVZRXs7xzQhbkEOwPcssKG'; // admin12345
$mhs_pw   = '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK'; // mahasiswa123

// Load the 76 official rooms from data.untidar.ac.id
$roomsJsonPath = __DIR__ . '/untidar_rooms.json';
$officialRooms = [];
if (file_exists($roomsJsonPath)) {
    $officialRooms = json_decode(file_get_contents($roomsJsonPath), true) ?? [];
}

$locations = [];
$codeSet = [];

// Helper to standardize building name
function cleanBuilding($b) {
    $b = trim($b);
    if (strpos($b, 'Fakultas Teknik-01') !== false || strpos($b, 'Fakultas Teknik - 01') !== false) {
        return 'Fakultas Teknik (FT-01)';
    }
    if (strpos($b, 'Fakultas Teknik - 02') !== false || strpos($b, 'Fakultas Teknik -  02') !== false) {
        return 'Fakultas Teknik (FT-02)';
    }
    if (strpos($b, 'Gedung Fakultas Teknik 3') !== false) {
        return 'Fakultas Teknik (FT-03)';
    }
    return $b;
}

// 1. Campus Tuguran General Facilities (GKB, Perpus, Lab, Masjid, Parkir, Kantin)
// Placed first so IDs 1-16 remain consistent for testing
$generalFacilities = [
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Ruang Kuliah 1.01', 'TUG-GKB-101'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Ruang Kuliah 1.02', 'TUG-GKB-102'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Toilet Pria Barat', 'TUG-GKB-TOI-1B'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Toilet Wanita Barat', 'TUG-GKB-TOI-1W'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.01', 'TUG-GKB-201'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.02', 'TUG-GKB-202'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.03', 'TUG-GKB-203'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.01', 'TUG-GKB-301'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.02', 'TUG-GKB-302'], // ID 9
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.03', 'TUG-GKB-303'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 4', 'Auditorium GKB Tuguran', 'TUG-GKB-AUD4'],
    ['Gedung Kuliah Bersama (GKB)', 'Lantai 4', 'Lab Komputer GKB 4.02', 'TUG-GKB-LAB402'],
    ['Perpustakaan Pusat Untidar', 'Lantai 1', 'Ruang Sirkulasi & Hotspot Area', 'TUG-PERPUS-101'],
    ['Perpustakaan Pusat Untidar', 'Lantai 2', 'Ruang Referensi & Jurnal Digital', 'TUG-PERPUS-201'],
    ['Masjid Manarul Ilmi Untidar', 'Lantai 1', 'Area Sholat & Tempat Wudhu', 'TUG-MSJ-01'],
    ['Parkiran Belakang Kampus', 'Ground', 'Area Parkir Motor Timur', 'TUG-PARK-MTR-T'],
    ['Parkiran Belakang Kampus', 'Ground', 'Area Parkir Motor Barat', 'TUG-PARK-MTR-B'],
    ['Kantin Mahasiswa Tuguran', 'Ground', 'Area Pujasera & Meja Makan', 'TUG-KNT-01'],

    // Khusus Gedung Fakultas Teknik 3 Lantai 4
    ['Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.4', 'UNT-FT3-344'],
    ['Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.5', 'UNT-FT3-345'],
    ['Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.6', 'UNT-FT3-346'],
    ['Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 1.4.6', 'UNT-FT3-146'],
];

foreach ($generalFacilities as $gf) {
    $codeSet[$gf[3]] = true;
    $locations[] = $gf;
}

// 2. Add all official classroom data from data.untidar.ac.id
foreach ($officialRooms as $r) {
    $b = cleanBuilding($r['gedung']);
    $ltRaw = trim($r['lantai']);
    $f = 'Lantai ' . strtoupper($ltRaw);
    $rm = trim($r['ruang']);
    
    // Generate clean unique code
    $slugB = preg_replace('/[^a-zA-Z0-9]/', '', $b);
    $slugB = substr($slugB, 0, 8);
    $slugR = preg_replace('/[^a-zA-Z0-9]/', '', $rm);
    $slugR = substr($slugR, 0, 10);
    $code = 'UNT-' . strtoupper($slugB) . '-' . strtoupper($slugR);
    
    $idx = 1;
    $origCode = $code;
    while (isset($codeSet[$code])) {
        $code = $origCode . '-' . $idx;
        $idx++;
    }
    $codeSet[$code] = true;

    $locations[] = [$b, $f, $rm, $code];
}

// Generate SQL
$sql = "-- Untidar Fixit Seed Data (Official data.untidar.ac.id + Tuguran Campus)\n";
$sql .= "USE `laportidar`;\n\n";

// Users
$sql .= "-- Users\n";
$sql .= "INSERT INTO `users` (`id`, `role`, `npm`, `name`, `email`, `password_hash`, `created_at`) VALUES\n";
$sql .= "(1, 'admin', NULL, 'Sarpras Untidar (Admin)', 'admin@untidar.ac.id', '{$admin_pw}', NOW()),\n";
$sql .= "(2, 'mahasiswa', '2210501001', 'Bagas Pratama', 'bagas@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(3, 'mahasiswa', '2210501045', 'Siti Nurhaliza', 'siti@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(4, 'mahasiswa', '2310502012', 'Rizky Firmansyah', 'rizky@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(5, 'mahasiswa', '2210501015', 'Muhammad Asyrof', 'muhammad.asyrof@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(6, 'mahasiswa', '2210501020', 'Gayuh Senoaji', 'gayuh.senoaji@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(7, 'mahasiswa', '2210501025', 'Widyadana Hussin Firmansyah', 'widyadanahussinfirmansyah@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(8, 'mahasiswa', '2210501030', 'Satrio Purwoko', 'satriopu150105@students.untidar.ac.id', '{$mhs_pw}', NOW()),\n";
$sql .= "(9, 'mahasiswa', '2210501035', 'Filbert Wibowo', 'filbert.wibowo@students.untidar.ac.id', '{$mhs_pw}', NOW());\n\n";

// Categories
$sql .= "-- Categories\n";
$sql .= "INSERT INTO `categories` (`id`, `name`, `icon`, `severity_weight`) VALUES\n";
$sql .= "(1, 'AC & Pendingin Ruang', 'ac_unit', 3),\n";
$sql .= "(2, 'Listrik, Lampu & Saklar', 'lightbulb', 4),\n";
$sql .= "(3, 'Air, Toilet & Sanitasi', 'water_drop', 5),\n";
$sql .= "(4, 'Jaringan & WiFi Kampus', 'wifi', 3),\n";
$sql .= "(5, 'Furnitur, Meja & Kursi Kuliah', 'chair', 2),\n";
$sql .= "(6, 'Kebersihan & Tempat Sampah', 'cleaning_services', 2),\n";
$sql .= "(7, 'Keamanan & Area Parkir', 'security', 4),\n";
$sql .= "(8, 'Sarana Proyektor, LCD & Audio', 'videocam', 3),\n";
$sql .= "(9, 'Fasilitas Lainnya', 'category', 1);\n\n";

// Technicians
$sql .= "-- Technicians\n";
$sql .= "INSERT INTO `technicians` (`id`, `name`, `phone`, `specialty`, `is_active`) VALUES\n";
$sql .= "(1, 'Pak Joko Riyanto', '081234567890', 'Kelistrikan, AC & Elektronik', 1),\n";
$sql .= "(2, 'Pak Bambang Sutrisno', '081398765432', 'Plumbing, Air & Sanitasi', 1),\n";
$sql .= "(3, 'Mas Hendra Kurniawan', '085678901234', 'Jaringan, WiFi & Proyektor', 1),\n";
$sql .= "(4, 'Pak Slamet Wahyudi', '082134567891', 'Pertukangan, Meja & Kursi', 1);\n\n";

// Locations
$sql .= "-- Locations (" . count($locations) . " Ruang Resmi Untidar)\n";
$sql .= "INSERT INTO `locations` (`id`, `building`, `floor`, `room`, `code`, `qr_signature`, `is_active`) VALUES\n";
$locRows = [];
$locId = 1;
foreach ($locations as $loc) {
    $b = addslashes($loc[0]);
    $f = addslashes($loc[1]);
    $r = addslashes($loc[2]);
    $c = addslashes($loc[3]);
    $sig = hash_hmac('sha256', $loc[3], $secret);
    $locRows[] = "({$locId}, '{$b}', '{$f}', '{$r}', '{$c}', '{$sig}', 1)";
    $locId++;
}
$sql .= implode(",\n", $locRows) . ";\n\n";

// Initial realistic complaints across faculties
$sql .= "-- Reports\n";
$sql .= "INSERT INTO `reports` (`id`, `ticket_number`, `user_id`, `location_id`, `category_id`, `title`, `description`, `urgency_level`, `status`, `rejection_reason`, `priority_score`, `upvote_count`, `created_at`, `resolved_at`) VALUES\n";
$sql .= "(1, 'LAP-202611-A101', 2, 9, 1, 'AC Ruang GKB 3.02 Menetes dan Tidak Dingin', 'Saat perkuliahan pagi AC hanya mengeluarkan angin hangat dan air bocor menetes ke lantai depan baris kedua.', 'tinggi', 'diverifikasi', NULL, 12, 4, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),\n";
$sql .= "(2, 'LAP-202611-A102', 3, 19, 2, 'Lampu Depan Papan Tulis Redup Berkedip di FE A.2b.01', 'Dua lampu TL depan papan tulis berkedip-kedip cepat sangat mengganggu konsentrasi mahasiswa di ruang A.2b.01.', 'sedang', 'ditugaskan', NULL, 9, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), NULL),\n";
$sql .= "(3, 'LAP-202611-A103', 5, 3, 3, 'Kran Air Toilet Pria GKB Lantai 1 Bocor Deras', 'Kran wastafel tidak bisa dimatikan rapat dan air menggenang sampai ke selasar depan pintu.', 'tinggi', 'selesai', NULL, 15, 6, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),\n";
$sql .= "(4, 'LAP-202611-A104', 6, 13, 4, 'Hotspot WiFi Perpustakaan Lemah & Sering Disconnect', 'Akses internet Untidar-WiFi di lantai 1 perpus sinyalnya lemah saat jam siang dan sulit tersambung.', 'sedang', 'terkirim', NULL, 7, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL),\n";
$sql .= "(5, 'LAP-202611-A105', 7, 9, 8, 'Proyektor HDMI GKB 3.02 Warna Kuning Bergaris', 'Kabel port HDMI longgar dan tampilan proyektor berwarna kekuningan bergaris saat dosen presentasi materi.', 'tinggi', 'diverifikasi', NULL, 11, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),\n";
$sql .= "(6, 'LAP-202611-A106', 8, 17, 7, 'Lampu Penerangan Parkir Motor Belakang Mati Total', 'Area parkir motor barat sangat gelap saat malam hari jam kuliah sore, rawan keamanan helm dan kendaraan.', 'tinggi', 'ditugaskan', NULL, 14, 5, DATE_SUB(NOW(), INTERVAL 4 DAY), NULL),\n";
$sql .= "(7, 'LAP-202611-FT301', 5, 19, 1, 'AC Ruang 3.4.4 FT 3 Lantai 4 Mengeluarkan Bunyi Kasar', 'AC split indoor berderak keras dan angin tidak sejuk di Ruang 3.4.4 Gedung Fakultas Teknik 3 Lantai 4 saat perkuliahan.', 'tinggi', 'diverifikasi', NULL, 13, 5, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL);\n\n";

// Upvotes
$sql .= "-- Upvotes\n";
$sql .= "INSERT INTO `report_upvotes` (`report_id`, `user_id`, `created_at`) VALUES\n";
$sql .= "(1, 3, NOW()), (1, 5, NOW()), (1, 6, NOW()), (1, 7, NOW()),\n";
$sql .= "(2, 5, NOW()), (2, 6, NOW()),\n";
$sql .= "(3, 2, NOW()), (3, 3, NOW()), (3, 6, NOW()), (3, 7, NOW()), (3, 8, NOW()), (3, 9, NOW()),\n";
$sql .= "(4, 5, NOW()), (4, 7, NOW()),\n";
$sql .= "(5, 5, NOW()), (5, 6, NOW()), (5, 8, NOW()),\n";
$sql .= "(6, 5, NOW()), (6, 6, NOW()), (6, 7, NOW()), (6, 9, NOW()),\n";
$sql .= "(7, 6, NOW()), (7, 7, NOW()), (7, 8, NOW()), (7, 9, NOW());\n\n";

// Status History
$sql .= "-- Report Status History\n";
$sql .= "INSERT INTO `report_status_history` (`report_id`, `status`, `note`, `photo_path`, `changed_by`, `created_at`) VALUES\n";
$sql .= "(1, 'terkirim', 'Laporan kerusakan AC disampaikan oleh mahasiswa.', NULL, 5, DATE_SUB(NOW(), INTERVAL 2 DAY)),\n";
$sql .= "(1, 'diverifikasi', 'Sarpras telah memverifikasi keluhan AC bocor di FE A.2b.01.', NULL, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),\n";
$sql .= "(2, 'terkirim', 'Laporan lampu berkedip dibuat.', NULL, 6, DATE_SUB(NOW(), INTERVAL 3 DAY)),\n";
$sql .= "(2, 'diverifikasi', 'Verifikasi data lampu TL FT-01 disetujui.', NULL, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),\n";
$sql .= "(2, 'ditugaskan', 'Ditugaskan ke teknisi Pak Joko untuk penggantian ballast & starter.', NULL, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),\n";
$sql .= "(3, 'terkirim', 'Laporan kran toilet bocor.', NULL, 7, DATE_SUB(NOW(), INTERVAL 5 DAY)),\n";
$sql .= "(3, 'diverifikasi', 'Disetujui untuk perbaikan pipa sanitasi.', NULL, 1, DATE_SUB(NOW(), INTERVAL 4 DAY)),\n";
$sql .= "(3, 'ditugaskan', 'Pak Bambang ditugaskan perbaikan seal kran.', NULL, 1, DATE_SUB(NOW(), INTERVAL 3 DAY)),\n";
$sql .= "(3, 'selesai', 'Kran wastafel telah diganti dengan valve kuningan baru.', 'seed_proof_kran.jpg', 1, DATE_SUB(NOW(), INTERVAL 1 DAY));\n\n";

// Assignments
$sql .= "-- Assignments\n";
$sql .= "INSERT INTO `report_assignments` (`report_id`, `technician_id`, `assigned_by`, `notes`, `assigned_at`) VALUES\n";
$sql .= "(2, 1, 1, 'Periksa starter dan ganti lampu TL ruang E.01.01 FT', NOW()),\n";
$sql .= "(3, 2, 1, 'Ganti valve kran wastafel toilet pria GKB Lt 1', NOW()),\n";
$sql .= "(6, 1, 1, 'Ganti bohlam LED sorot tiang parkiran barat', NOW());\n\n";

// Rating
$sql .= "-- Ratings\n";
$sql .= "INSERT INTO `ratings` (`report_id`, `user_id`, `rating`, `review`, `created_at`) VALUES\n";
$sql .= "(3, 7, 5, 'Perbaikan sangat cepat tanggap dari Sarpras, air tidak lagi menggenangi selasar.', NOW());\n\n";

// Notifications
$sql .= "-- Notifications\n";
$sql .= "INSERT INTO `notifications` (`user_id`, `report_id`, `title`, `message`, `is_read`, `created_at`) VALUES\n";
$sql .= "(5, 1, 'Laporan Diverifikasi', 'Laporan Anda untuk AC Ruang A.2b.01 telah diverifikasi tim Sarpras.', 0, NOW()),\n";
$sql .= "(6, 2, 'Teknisi Ditugaskan', 'Teknisi Pak Joko telah ditugaskan menangani lampu di FT-01.', 0, NOW()),\n";
$sql .= "(7, 3, 'Perbaikan Selesai!', 'Kerusakan kran wastafel toilet GKB telah selesai diperbaiki.', 1, NOW());\n";

file_put_contents(__DIR__ . '/seed.sql', $sql);
echo "seed.sql generated with " . count($locations) . " official Untidar rooms and locations.\n";
