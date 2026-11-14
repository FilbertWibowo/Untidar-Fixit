-- Untidar Fixit Database Schema
-- UTF8mb4, InnoDB, Foreign Keys & Proper Indexes

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `login_attempts`;
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `ratings`;
DROP TABLE IF EXISTS `report_status_history`;
DROP TABLE IF EXISTS `report_assignments`;
DROP TABLE IF EXISTS `report_upvotes`;
DROP TABLE IF EXISTS `report_photos`;
DROP TABLE IF EXISTS `reports`;
DROP TABLE IF EXISTS `technicians`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `locations`;
DROP TABLE IF EXISTS `auth_tokens`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- Users table (mahasiswa & admin)
CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `role` ENUM('mahasiswa', 'admin') NOT NULL DEFAULT 'mahasiswa',
    `npm` VARCHAR(20) NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_role` (`role`),
    INDEX `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Auth tokens for session management
CREATE TABLE `auth_tokens` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `token_hash` VARCHAR(64) NOT NULL UNIQUE,
    `expired_at` DATETIME NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_tokens_hash` (`token_hash`),
    INDEX `idx_tokens_expired` (`expired_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Locations in Kampus Tuguran
CREATE TABLE `locations` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `building` VARCHAR(100) NOT NULL,
    `floor` VARCHAR(20) NOT NULL,
    `room` VARCHAR(100) NOT NULL,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `qr_signature` VARCHAR(64) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_locations_building` (`building`),
    INDEX `idx_locations_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Facility Categories with baseline severity weight
CREATE TABLE `categories` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `icon` VARCHAR(50) NOT NULL DEFAULT 'build',
    `severity_weight` INT NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Technicians for Sarpras
CREATE TABLE `technicians` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(25) NOT NULL,
    `specialty` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reports table
CREATE TABLE `reports` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `ticket_number` VARCHAR(32) NOT NULL UNIQUE,
    `user_id` INT UNSIGNED NOT NULL,
    `location_id` INT UNSIGNED NOT NULL,
    `category_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NOT NULL,
    `urgency_level` ENUM('rendah', 'sedang', 'tinggi') NOT NULL DEFAULT 'rendah',
    `status` ENUM('terkirim', 'diverifikasi', 'ditugaskan', 'selesai', 'ditolak') NOT NULL DEFAULT 'terkirim',
    `rejection_reason` TEXT NULL,
    `priority_score` INT NOT NULL DEFAULT 0,
    `upvote_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `resolved_at` DATETIME NULL,
    CONSTRAINT `fk_reports_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_reports_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
    CONSTRAINT `fk_reports_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
    INDEX `idx_reports_status` (`status`),
    INDEX `idx_reports_priority` (`priority_score`),
    INDEX `idx_reports_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Report photos (before & after repair)
CREATE TABLE `report_photos` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `file_path` VARCHAR(255) NOT NULL,
    `type` ENUM('before', 'after') NOT NULL DEFAULT 'before',
    `uploaded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_photos_report` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
    INDEX `idx_photos_report` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Upvotes ("Saya Mengalami Hal Serupa")
CREATE TABLE `report_upvotes` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `user_id` INT UNSIGNED NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_report_user_upvote` (`report_id`, `user_id`),
    CONSTRAINT `fk_upvotes_report` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_upvotes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Assignments of report to technician
CREATE TABLE `report_assignments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `technician_id` INT UNSIGNED NOT NULL,
    `assigned_by` INT UNSIGNED NOT NULL,
    `notes` TEXT NULL,
    `assigned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_assign_report` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_assign_tech` FOREIGN KEY (`technician_id`) REFERENCES `technicians` (`id`),
    CONSTRAINT `fk_assign_by` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`),
    INDEX `idx_assign_report` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Full historical tracking for vertical timeline
CREATE TABLE `report_status_history` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL,
    `status` ENUM('terkirim', 'diverifikasi', 'ditugaskan', 'selesai', 'ditolak') NOT NULL,
    `note` TEXT NULL,
    `photo_path` VARCHAR(255) NULL,
    `changed_by` INT UNSIGNED NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_history_report` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_history_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`),
    INDEX `idx_history_report` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ratings from student after resolution
CREATE TABLE `ratings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT UNSIGNED NOT NULL UNIQUE,
    `user_id` INT UNSIGNED NOT NULL,
    `rating` TINYINT NOT NULL,
    `review` TEXT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_ratings_report` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ratings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- In-app notifications
CREATE TABLE `notifications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `report_id` INT UNSIGNED NULL,
    `title` VARCHAR(150) NOT NULL,
    `message` TEXT NOT NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_notif_user` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit logs for admin actions
CREATE TABLE `audit_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NULL,
    `action` VARCHAR(100) NOT NULL,
    `resource_type` VARCHAR(50) NOT NULL,
    `resource_id` INT UNSIGNED NULL,
    `details` TEXT NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    INDEX `idx_audit_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Login attempts for brute-force rate limiting
CREATE TABLE `login_attempts` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `ip_address` VARCHAR(45) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `attempts` INT NOT NULL DEFAULT 1,
    `locked_until` DATETIME NULL,
    `last_attempt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_login_ip_email` (`ip_address`, `email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================
-- SEED DATA
-- =========================================

-- Untidar Fixit Seed Data (Official data.untidar.ac.id + Tuguran Campus)

-- Users
INSERT INTO `users` (`id`, `role`, `npm`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'admin', NULL, 'Sarpras Untidar (Admin)', 'admin@untidar.ac.id', '$2y$10$nO1GNia0EcbthDMATFQEU.w0gCpBzVEvVZRXs7xzQhbkEOwPcssKG', NOW()),
(2, 'mahasiswa', '2210501001', 'Bagas Pratama', 'bagas@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(3, 'mahasiswa', '2210501045', 'Siti Nurhaliza', 'siti@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(4, 'mahasiswa', '2310502012', 'Rizky Firmansyah', 'rizky@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(5, 'mahasiswa', '2210501015', 'Muhammad Asyrof', 'muhammad.asyrof@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(6, 'mahasiswa', '2210501020', 'Gayuh Senoaji', 'gayuh.senoaji@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(7, 'mahasiswa', '2210501025', 'Widyadana Hussin Firmansyah', 'widyadanahussinfirmansyah@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(8, 'mahasiswa', '2210501030', 'Satrio Purwoko', 'satriopu150105@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW()),
(9, 'mahasiswa', '2210501035', 'Filbert Wibowo', 'filbert.wibowo@students.untidar.ac.id', '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK', NOW());

-- Categories
INSERT INTO `categories` (`id`, `name`, `icon`, `severity_weight`) VALUES
(1, 'AC & Pendingin Ruang', 'ac_unit', 3),
(2, 'Listrik, Lampu & Saklar', 'lightbulb', 4),
(3, 'Air, Toilet & Sanitasi', 'water_drop', 5),
(4, 'Jaringan & WiFi Kampus', 'wifi', 3),
(5, 'Furnitur, Meja & Kursi Kuliah', 'chair', 2),
(6, 'Kebersihan & Tempat Sampah', 'cleaning_services', 2),
(7, 'Keamanan & Area Parkir', 'security', 4),
(8, 'Sarana Proyektor, LCD & Audio', 'videocam', 3),
(9, 'Fasilitas Lainnya', 'category', 1);

-- Technicians
INSERT INTO `technicians` (`id`, `name`, `phone`, `specialty`, `is_active`) VALUES
(1, 'Pak Joko Riyanto', '081234567890', 'Kelistrikan, AC & Elektronik', 1),
(2, 'Pak Bambang Sutrisno', '081398765432', 'Plumbing, Air & Sanitasi', 1),
(3, 'Mas Hendra Kurniawan', '085678901234', 'Jaringan, WiFi & Proyektor', 1),
(4, 'Pak Slamet Wahyudi', '082134567891', 'Pertukangan, Meja & Kursi', 1);

-- Locations (98 Ruang Resmi Untidar)
INSERT INTO `locations` (`id`, `building`, `floor`, `room`, `code`, `qr_signature`, `is_active`) VALUES
(1, 'Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Ruang Kuliah 1.01', 'TUG-GKB-101', '42bf778c4e78f684e224d4e4217ef2f0a364f1735f62fee22e4f42910c9f3246', 1),
(2, 'Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Ruang Kuliah 1.02', 'TUG-GKB-102', '9c454c3a900a427aa004f8e7e31208e126d3173da39bf7cd495796e2a4af0dae', 1),
(3, 'Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Toilet Pria Barat', 'TUG-GKB-TOI-1B', '2a4bdf26aeda94ce237ea83859fd2a1035cb587193f2dec04c83b20905d9281e', 1),
(4, 'Gedung Kuliah Bersama (GKB)', 'Lantai 1', 'Toilet Wanita Barat', 'TUG-GKB-TOI-1W', '1cd109d0a8bca391ab4ad1353ed960e53847e332bd4506b4701f0d10b71d963a', 1),
(5, 'Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.01', 'TUG-GKB-201', '988219740465756a90bcad511b633dc96401e184ea25171e2ba8ea454e1428dc', 1),
(6, 'Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.02', 'TUG-GKB-202', '339aae66f64985dd02b9469951c983bf119149be254c69ac8552741f32c30228', 1),
(7, 'Gedung Kuliah Bersama (GKB)', 'Lantai 2', 'Ruang Kuliah 2.03', 'TUG-GKB-203', '8aeb5e7836aa114925b76b2b88c14715c36616cd8382e319ad14f42c4cca9466', 1),
(8, 'Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.01', 'TUG-GKB-301', 'e47527556d9d17c58cd5b002477a20124c7220676f5a8c8ad23fd9e50dc1a376', 1),
(9, 'Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.02', 'TUG-GKB-302', '57421508da53e56be1f463498890a52f6545e11ee2f3458f53f925e49771ffb9', 1),
(10, 'Gedung Kuliah Bersama (GKB)', 'Lantai 3', 'Ruang Kuliah 3.03', 'TUG-GKB-303', '36f03bcd0e006e59ea687e189bb5ed555d30a475f46c6e3b30a9489fe34ac1dd', 1),
(11, 'Gedung Kuliah Bersama (GKB)', 'Lantai 4', 'Auditorium GKB Tuguran', 'TUG-GKB-AUD4', 'afd29e3e1bb8a38ba931b05444d8d3c978c6e1b2b0fc156dea6d0634bdec48d4', 1),
(12, 'Gedung Kuliah Bersama (GKB)', 'Lantai 4', 'Lab Komputer GKB 4.02', 'TUG-GKB-LAB402', '6fd9398f9b4acdaf6b324d10b448e8418326af39b059151cc0c543dd6da303bc', 1),
(13, 'Perpustakaan Pusat Untidar', 'Lantai 1', 'Ruang Sirkulasi & Hotspot Area', 'TUG-PERPUS-101', '1ecdf427b8c7c46f29549259926338f11fa1f483b5b678f3a5cb4d049bf33296', 1),
(14, 'Perpustakaan Pusat Untidar', 'Lantai 2', 'Ruang Referensi & Jurnal Digital', 'TUG-PERPUS-201', '418c0f7f9c68b5b46c77ce05931aad919df5eecc063900c82c58fd9820a85edc', 1),
(15, 'Masjid Manarul Ilmi Untidar', 'Lantai 1', 'Area Sholat & Tempat Wudhu', 'TUG-MSJ-01', '4e8014d008713fc8e4d9e6ed2d64d022506591929673c1547dd8d51d05d3926b', 1),
(16, 'Parkiran Belakang Kampus', 'Ground', 'Area Parkir Motor Timur', 'TUG-PARK-MTR-T', '348ce4cefeb7ccfc81bb9ccae7ba6e1737b3e4abac5744f9f85bfb469af4f01d', 1),
(17, 'Parkiran Belakang Kampus', 'Ground', 'Area Parkir Motor Barat', 'TUG-PARK-MTR-B', 'c34e4ed1e45b9e9b6d419ff7bc39c45f70067a0853ca6b2adb9c57407b9adf37', 1),
(18, 'Kantin Mahasiswa Tuguran', 'Ground', 'Area Pujasera & Meja Makan', 'TUG-KNT-01', 'dbca033456b628df6c0993987da8c846ba07364086f30dc7162deb8b2ec5a3bb', 1),
(19, 'Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.4', 'UNT-FT3-344', '6dffd1760b3425bb913af42d980fb18e793ddd1949b0c4046a774cb4e647725f', 1),
(20, 'Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.5', 'UNT-FT3-345', '224146dd81e2f0c8bbcd44fa03c788c45742c35843a9f26ebd64b028c0a21f44', 1),
(21, 'Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 3.4.6', 'UNT-FT3-346', 'bcc68d6d744d6dce9a63d4595c238b0383f9b68d8dcb35eaa5503d145485563c', 1),
(22, 'Gedung Fakultas Teknik 3', 'Lantai 4', 'Ruang Kuliah 1.4.6', 'UNT-FT3-146', 'f2d557dfafc5b9405e061947e94ca6a3d4915fc59697c30b4143f391c42dcac6', 1),
(23, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.01', 'UNT-FAKULTAS-A2B01', 'a9121bfa41f86bb24d7e904a90e859922a1f0dca2ed8d830a4b3bd019a97577d', 1),
(24, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.02', 'UNT-FAKULTAS-A2B02', '66c85fdbc6c38437c55f0c5c7f1c183d3c74ded6e5ac08766a21eca97ff152f0', 1),
(25, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.03', 'UNT-FAKULTAS-A2B03', 'f006a35aca6b8dfd2a667e859f21c4a0ec68321e7f6f156bfc05b9ade93d3f97', 1),
(26, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.04', 'UNT-FAKULTAS-A2B04', 'fbd73e6d7d6ff42fd6ec8d95d3d928e1645198b4d1b88f019faff2b423f864dc', 1),
(27, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.05', 'UNT-FAKULTAS-A2B05', '2e794f4b996cfc7244c8c5aa0cbcb4d7ddcaa78e03b6050b95eacf091d233e40', 1),
(28, 'Fakultas Ekonomi', 'Lantai 2B', 'A.2b.06', 'UNT-FAKULTAS-A2B06', '2b688bf0c3932fa451cfabb2a9480034be2bdcca34e5f52ae089bad953efc963', 1),
(29, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.01', 'UNT-FAKULTAS-A3B01', '843dea655d781984382750a633344726d709abc70af238421039ceeec899a82c', 1),
(30, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.02', 'UNT-FAKULTAS-A3B02', '9ae8279b8fa535f1d9839d6b8ba624054cc2be4a8287fe5bdf6b38e673172a7e', 1),
(31, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.03', 'UNT-FAKULTAS-A3B03', '3075f421231e430a7936fac77309b9f1a22c678781bc7fe600212a1a182b7d2a', 1),
(32, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.04', 'UNT-FAKULTAS-A3B04', '621404cd58ba136cf8c323b024d6521f6d7469266d3e60fff53b2dbd57f6302f', 1),
(33, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.05', 'UNT-FAKULTAS-A3B05', '83a1347e4e6f57340a79f3347bea9509af8aab122d19a6e672e47e9283aeb13b', 1),
(34, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.06', 'UNT-FAKULTAS-A3B06', '7ffa195834c7bc812934b4a1626ccceaffc63bd6fc718adac33222359e28f008', 1),
(35, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.07 (Lab. Komputer)', 'UNT-FAKULTAS-A3B07LABKO', '7412994cd70c8f678d3716d9fe81111c21723e5867cece54663d317dd1ec04a7', 1),
(36, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.08 (ruang kuliah pusat bahasa)', 'UNT-FAKULTAS-A3B08RUANG', '8ed2ad0f8f114051afb48fdd386f91ef5d7b45168f582c763049fcc124d9511b', 1),
(37, 'Fakultas Ekonomi', 'Lantai 3B', 'A.3b.09', 'UNT-FAKULTAS-A3B09', 'e12d3bb2e4cc7d043c04ca7225db8016a78562854a8f39396ab5e572c3bec2d0', 1),
(38, 'Fakultas Ekonomi', 'Lantai 4A', 'A.4a.01', 'UNT-FAKULTAS-A4A01', '4e96e45d03442845ef448c7197d2cb26c37dd2c29f1f616c14ec57d7ad31ba4d', 1),
(39, 'Fakultas Ekonomi', 'Lantai 4A', 'A.4a.02', 'UNT-FAKULTAS-A4A02', 'cc532fa995e3980c823ae217c863c5ddbd4e6f4a11310fc5333570ee13316108', 1),
(40, 'Fakultas Ekonomi', 'Lantai 4A', 'A.4a.03', 'UNT-FAKULTAS-A4A03', '4772c526078d16958e3b63d4c5603a158cc1be2539350d2162161615644805a4', 1),
(41, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.01', 'UNT-FAKULTAS-A4B01', '1f1978dbb80b2534c1c11b3c5c8795bff1ac4d210d65b88aa32c99292e84485f', 1),
(42, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.02', 'UNT-FAKULTAS-A4B02', 'f1340f4c9d4dffe10894a8a907310bd72f649b4e031424667a072636ffc93abf', 1),
(43, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.03', 'UNT-FAKULTAS-A4B03', '2e21a9fc65221bcdadba19c72d69dbcc7c8002c74a22cede8281d7350730ba85', 1),
(44, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.04', 'UNT-FAKULTAS-A4B04', '071c1da59c582e81b07bd35c65a9a15235195da6327b1642329653174882958a', 1),
(45, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.05', 'UNT-FAKULTAS-A4B05', '04fe12a24541cd7c4fcf1110ff2d52dddcdbdcb9a88b49d650bfa9a006e150d6', 1),
(46, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.06', 'UNT-FAKULTAS-A4B06', 'debcbbe777ff15563b94435e1f3c7d88bd3b179df1fae9d0bc85c44e13fe7a83', 1),
(47, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.07 (Lab. Komputer)', 'UNT-FAKULTAS-A4B07LABKO', 'a0ec2f4607e96eca95d9ff0bc40ea1d84718808d95c54d093988f4b87ad19f9a', 1),
(48, 'Fakultas Ekonomi', 'Lantai 4B', 'A.4b.08 (ruang akuakultur)', 'UNT-FAKULTAS-A4B08RUANG', 'e0308993f22ea4d509426a0e3bc4c5e3e65accb3737fc1859041de77a964b651', 1),
(49, 'Fakultas Teknik (FT-01)', 'Lantai 1', 'E.01.1.09 (Lab.Komputer)', 'UNT-FAKULTAS-E01109LABK', '42c07589c96b7fbb47c0fe080bb69f580b0ba0863e3431d22c314cbf08872bd7', 1),
(50, 'Fakultas Teknik (FT-01)', 'Lantai 2', 'E.01.2.06', 'UNT-FAKULTAS-E01206', '58be984c8af49d99e5d4b28245afdadee659416f37589f071b2a468f2739e40c', 1),
(51, 'Fakultas Teknik (FT-01)', 'Lantai 3', 'E.01.3.05 (Lab. Komputer)', 'UNT-FAKULTAS-E01305LABK', '8a439bc1c31eb73b6d6e9d971746db52a070d22269e67091dbfeae7682e6982c', 1),
(52, 'Fakultas Teknik (FT-01)', 'Lantai 3', 'E.01.3.06 (Lab. Digital)', 'UNT-FAKULTAS-E01306LABD', '428ec5ee432bf2bc74400aa37016005a0b8702896dc01688f6b38b86bf79ab07', 1),
(53, 'Fakultas Teknik (FT-01)', 'Lantai 3', 'E.01.3.07 (Lab. Fisika &amp; Elektronika)', 'UNT-FAKULTAS-E01307LABF', '6be7638f3990680b4949e02c3954bbba16d78ba11288d859a32e934f831a917f', 1),
(54, 'Fakultas Teknik (FT-01)', 'Lantai 3', 'E.01.3.08 (Lab. Teknik Tenaga Listrik)', 'UNT-FAKULTAS-E01308LABT', '9065ecf920df2436d3b30f9d37c6fc18ac07c84fab1eba9fa94c513fef4d3208', 1),
(55, 'Fakultas Teknik (FT-01)', 'Lantai 3', 'E.01.3.09', 'UNT-FAKULTAS-E01309', '6ebf26da77f7884377ae30e628388864aea7af5a06ad9edd6acd33a90544acbf', 1),
(56, 'Fakultas Teknik (FT-01)', 'Lantai 4', 'E.01.4.05', 'UNT-FAKULTAS-E01405', 'fc6c2e734e3f9861eaaf2c94fa6d5abeab922a02e18bf23584501920cb21826b', 1),
(57, 'Fakultas Teknik (FT-01)', 'Lantai 4', 'E.01.4.06', 'UNT-FAKULTAS-E01406', '2a2a3797e2d0c0170acde4f92a9c3e36cdd06f80d8d259265696f5820803325f', 1),
(58, 'Fakultas Teknik (FT-01)', 'Lantai 4', 'E.01.4.07', 'UNT-FAKULTAS-E01407', '857f09275bb606593d98cb99b85a2103a5e251f7a733494c644a76a1907b777d', 1),
(59, 'Fakultas Teknik (FT-01)', 'Lantai 4', 'E.01.4.08', 'UNT-FAKULTAS-E01408', '5525cb189e67c300bb6a9bd902450595f9d807ede2ff3bece08fb5c3a824bf5c', 1),
(60, 'Fakultas Teknik (FT-01)', 'Lantai 4', 'E.01.4.09', 'UNT-FAKULTAS-E01409', 'd9a7a64b7cbb0470dbfd9f8467cbbaa27910b455442ee3debb3944754ebad6dd', 1),
(61, 'Fakultas Teknik (FT-02)', 'Lantai 1', 'E.02.1.01 ( Lab. Mesin S1 )', 'UNT-FAKULTAS-E02101LABM', 'a7cbb9e202189c2e375bd23f4de52de067ee9f6cbb4de5a8f9f98dfb03fa708c', 1),
(62, 'Fakultas Teknik (FT-02)', 'Lantai 1', 'E.02.1.02 ( Lab. Mesin S1 )', 'UNT-FAKULTAS-E02102LABM', '08a5755efdfbe89ff2205a7fa0f04a1c904e0b80eb95fb070cd3dfa311877ca8', 1),
(63, 'Fakultas Teknik (FT-02)', 'Lantai 1', 'E.02.1.03 ( Lab. Mesin D3 )', 'UNT-FAKULTAS-E02103LABM', 'e6dd31fc5b41fd470e2918f94c9b2b352ecbb60d256e430456b6b2eae2b5f9ff', 1),
(64, 'Fakultas Teknik (FT-02)', 'Lantai 1', 'E.02.1.04 ( Lab. Mesin D3 )', 'UNT-FAKULTAS-E02104LABM', 'b9d743451e58e6ee24dc4b5f29b28e8c66169ac84359b21430e9ba303deae2d1', 1),
(65, 'Fakultas Teknik (FT-02)', 'Lantai 1', 'E.02.1.05 ( Lab. Teknik Sipil )', 'UNT-FAKULTAS-E02105LABT', '50a41a022a3d5b4f10c96a4a67ff301ded63c87097b10d0f19a1065cafbdf8ce', 1),
(66, 'Fakultas Teknik (FT-02)', 'Lantai 2', 'E.02.2.06', 'UNT-FAKULTAS-E02206', 'f40abe1442cb95c11cb1878afab82a28f68c19f734611cb91f362add06db0f7e', 1),
(67, 'Fakultas Teknik (FT-02)', 'Lantai 2', 'E.02.2.08', 'UNT-FAKULTAS-E02208', '9742268b1e7c86203731ee6a541b71636df5f84b73c7dcdb1e07b4508e89e38e', 1),
(68, 'Fakultas Teknik (FT-02)', 'Lantai 2', 'E.02.2.09', 'UNT-FAKULTAS-E02209', 'd891c4bf34827786ae8018115fed60cfbf24573470e33f986a92ac7c99af2315', 1),
(69, 'Fakultas Teknik (FT-02)', 'Lantai 2', 'E.02.2.10', 'UNT-FAKULTAS-E02210', 'f35b13546acb9032724c8e937e6181baa6e884c401c453156713b0d81864fd51', 1),
(70, 'Fakultas Teknik (FT-02)', 'Lantai 3', 'E.02.3.06', 'UNT-FAKULTAS-E02306', 'd86ba7ed0e8f4d589e591e73721b390be717b9ad8113b59e961586d72ebe7d07', 1),
(71, 'Fakultas Teknik (FT-02)', 'Lantai 3', 'E.02.3.08', 'UNT-FAKULTAS-E02308', '59a233aac043a2b355f4a1f002bb76f7e39f93168aaed548f597beacda1aa551', 1),
(72, 'Fakultas Teknik (FT-02)', 'Lantai 3', 'E.02.3.09', 'UNT-FAKULTAS-E02309', '0f108032d45b4ed001dd32a6f96bb31550be8567995c9208148b74dc7027f0ea', 1),
(73, 'Fakultas Teknik (FT-02)', 'Lantai 4', 'E.02.4.06', 'UNT-FAKULTAS-E02406', 'a0085b3bbc4057e86b2d938548ef9456d41cf35e1a3e124a186ced04325f638b', 1),
(74, 'Fakultas Teknik (FT-02)', 'Lantai 4', 'E.02.4.07', 'UNT-FAKULTAS-E02407', 'bd2ec377f2b9a30f055b597f12a4b90ee26f01bc5d7a98b5c37e214aad6d4746', 1),
(75, 'Fakultas Teknik (FT-02)', 'Lantai 4', 'E.02.4.08', 'UNT-FAKULTAS-E02408', 'a167f2cdf5bb1f94342d390a0335ceed11e9833b5f9cdd1d6178d093a28bac24', 1),
(76, 'Fakultas Teknik (FT-02)', 'Lantai 4', 'E.02.4.09', 'UNT-FAKULTAS-E02409', 'de63b84c4998aecb4a1e97800f8e7665ae10d4dc35ea048472cb369f09252f06', 1),
(77, 'Fakultas Teknik (FT-02)', 'Lantai 4', 'E.02.4.10', 'UNT-FAKULTAS-E02410', '61a932fcd72267cc66e1b1fb0ee28d57edb52fbbe385f0b4b561007b71847b1e', 1),
(78, 'Fakultas Teknik (FT-03)', 'Lantai 4', 'E03.3.03', 'UNT-FAKULTAS-E03303', 'e80db42eeea8d72df931d3a05692b272cc1d3509169c08232b8b3cf856a0b53c', 1),
(79, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 1', 'I.1.09.A(Lab. Microteaching-1)', 'UNT-FAKULTAS-I109ALABMI', 'f0e899241b5d631afdd1888f02c9f99de559bffb9ba1ffa8985dfd92321673bf', 1),
(80, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 1', 'I.1.09.B(Lab. Microteaching-2)', 'UNT-FAKULTAS-I109BLABMI', '6f6e4cb23f83ef29bf62c6a22cbfbe49cd9da04c54005fa5627961030580a231', 1),
(81, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 1', 'I.1.8 (Lab. Bahasa FKIP)', 'UNT-FAKULTAS-I18LABBAHA', '0de9444ffe93a8a3f64722746bf581e4a9e90f6973d9fab0f6c9b2946af1c030', 1),
(82, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I.2.08', 'UNT-FAKULTAS-I208', 'f22e02f310314e87144d5177cc4c6d78b1085279a488772c4ebeeeeeb406a058', 1),
(83, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 1', 'I1.06', 'UNT-FAKULTAS-I106', '9fe9bc0e0b0e96af3b3725a37393e14fd37c64d7505d11dd64dc13b3aa7d2543', 1),
(84, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.01', 'UNT-FAKULTAS-I201', 'ba1e7bf06a1d78bc3f11943e31445af8d0cd6f026a938f5d00451ee8393886b2', 1),
(85, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.02', 'UNT-FAKULTAS-I202', '37e89aaf9c8db75a20475729cc4d3ea000259c64db15dbaa04f1f642553b095f', 1),
(86, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.03', 'UNT-FAKULTAS-I203', 'd6e076aa2a1c6afbcc6c8e19513239f54f92aa5654ecf3e0f0900765e2ae4efd', 1),
(87, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.04', 'UNT-FAKULTAS-I204', '3090a82c2284150731822450d4a14efe5af7ad6de0eb5d03d2799aadba20c4ec', 1),
(88, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.05', 'UNT-FAKULTAS-I205', '41e68f92986b074bf81ebc628610aab41343d3b10af7099b9f2f0726dbf0d278', 1),
(89, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.06 (Lab. MIPA)', 'UNT-FAKULTAS-I206LABMIP', '50ff4eaeed3eaaf73a5cae2d90b28b2f8b6fb94e00025b0e9e6049cfe8254348', 1),
(90, 'Fakultas Keguruan dan Ilmu Pendidikan', 'Lantai 2', 'I2.07', 'UNT-FAKULTAS-I207', '9a119998f896cc54115bd07dd10916e66264ff93dda03412aca33f49f6150f1b', 1),
(91, 'Fakultas Ilmu Sosial dan Ilmu Politik', 'Lantai 1', 'J.1.04', 'UNT-FAKULTAS-J104', 'bcbd5830436df4054c5c8ffd19ec36f708de5f1aed5799229f1e6b2c67550fd2', 1),
(92, 'Fakultas Ilmu Sosial dan Ilmu Politik', 'Lantai 2', 'J.2.01', 'UNT-FAKULTAS-J201', 'bf4ba9d269fc9ef966e9d4a3c521ef4ea129c3ca52b5acd0fcc10d64cb5e55a6', 1),
(93, 'Fakultas Ilmu Sosial dan Ilmu Politik', 'Lantai 2', 'J.2.02', 'UNT-FAKULTAS-J202', 'f7efd7c1a0abffd617b08b7eec7108196170eace379a50aa7bd308abde8579b3', 1),
(94, 'Fakultas Ilmu Sosial dan Ilmu Politik', 'Lantai 2', 'J.2.03', 'UNT-FAKULTAS-J203', '2c4e76d791d499886f6d578f6dbbb1d468ecf8cb875dc995683771e5fe8fce1f', 1),
(95, 'Fakultas Pertanian', 'Lantai 2', 'L.2.03', 'UNT-FAKULTAS-L203', 'b3a13d59ecf9365144f6fecfbbe5b801cd5560e12a39430dfd76079e6572f5e2', 1),
(96, 'Fakultas Pertanian', 'Lantai 2', 'P.2.01 (Lab. Pertanian)', 'UNT-FAKULTAS-P201LABPER', 'ec5373f38ee47993e2f9a960f4e9bcfa951979c8fd3e1aed9ab8542a30a4cfaa', 1),
(97, 'Fakultas Pertanian', 'Lantai 2', 'P.2.02 (Lab. Tanah)', 'UNT-FAKULTAS-P202LABTAN', 'd8aff7904e16af55ea29561bb1a049e084fadbd68b99fa683a409b47a3d1e99c', 1),
(98, 'Fakultas Pertanian', 'Lantai 2', 'P.2.03 (Lab. Hama)', 'UNT-FAKULTAS-P203LABHAM', '3c9c4283be2bafe7f77f604e201da2633fc72f25d9c7b02906238b897ee2e1f5', 1);

-- Reports
INSERT INTO `reports` (`id`, `ticket_number`, `user_id`, `location_id`, `category_id`, `title`, `description`, `urgency_level`, `status`, `rejection_reason`, `priority_score`, `upvote_count`, `created_at`, `resolved_at`) VALUES
(1, 'LAP-202611-A101', 2, 9, 1, 'AC Ruang GKB 3.02 Menetes dan Tidak Dingin', 'Saat perkuliahan pagi AC hanya mengeluarkan angin hangat dan air bocor menetes ke lantai depan baris kedua.', 'tinggi', 'diverifikasi', NULL, 12, 4, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(2, 'LAP-202611-A102', 3, 19, 2, 'Lampu Depan Papan Tulis Redup Berkedip di FE A.2b.01', 'Dua lampu TL depan papan tulis berkedip-kedip cepat sangat mengganggu konsentrasi mahasiswa di ruang A.2b.01.', 'sedang', 'ditugaskan', NULL, 9, 2, DATE_SUB(NOW(), INTERVAL 3 DAY), NULL),
(3, 'LAP-202611-A103', 5, 3, 3, 'Kran Air Toilet Pria GKB Lantai 1 Bocor Deras', 'Kran wastafel tidak bisa dimatikan rapat dan air menggenang sampai ke selasar depan pintu.', 'tinggi', 'selesai', NULL, 15, 6, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, 'LAP-202611-A104', 6, 13, 4, 'Hotspot WiFi Perpustakaan Lemah & Sering Disconnect', 'Akses internet Untidar-WiFi di lantai 1 perpus sinyalnya lemah saat jam siang dan sulit tersambung.', 'sedang', 'terkirim', NULL, 7, 2, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL),
(5, 'LAP-202611-A105', 7, 9, 8, 'Proyektor HDMI GKB 3.02 Warna Kuning Bergaris', 'Kabel port HDMI longgar dan tampilan proyektor berwarna kekuningan bergaris saat dosen presentasi materi.', 'tinggi', 'diverifikasi', NULL, 11, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(6, 'LAP-202611-A106', 8, 17, 7, 'Lampu Penerangan Parkir Motor Belakang Mati Total', 'Area parkir motor barat sangat gelap saat malam hari jam kuliah sore, rawan keamanan helm dan kendaraan.', 'tinggi', 'ditugaskan', NULL, 14, 5, DATE_SUB(NOW(), INTERVAL 4 DAY), NULL),
(7, 'LAP-202611-FT301', 5, 19, 1, 'AC Ruang 3.4.4 FT 3 Lantai 4 Mengeluarkan Bunyi Kasar', 'AC split indoor berderak keras dan angin tidak sejuk di Ruang 3.4.4 Gedung Fakultas Teknik 3 Lantai 4 saat perkuliahan.', 'tinggi', 'diverifikasi', NULL, 13, 5, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL);

-- Upvotes
INSERT INTO `report_upvotes` (`report_id`, `user_id`, `created_at`) VALUES
(1, 3, NOW()), (1, 5, NOW()), (1, 6, NOW()), (1, 7, NOW()),
(2, 5, NOW()), (2, 6, NOW()),
(3, 2, NOW()), (3, 3, NOW()), (3, 6, NOW()), (3, 7, NOW()), (3, 8, NOW()), (3, 9, NOW()),
(4, 5, NOW()), (4, 7, NOW()),
(5, 5, NOW()), (5, 6, NOW()), (5, 8, NOW()),
(6, 5, NOW()), (6, 6, NOW()), (6, 7, NOW()), (6, 9, NOW()),
(7, 6, NOW()), (7, 7, NOW()), (7, 8, NOW()), (7, 9, NOW());

-- Report Photos (Before & After Documentation)
INSERT INTO `report_photos` (`id`, `report_id`, `file_path`, `type`, `uploaded_at`) VALUES
(1, 1, 'uploads/photos/demo_ac_leak.jpg', 'before', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 2, 'uploads/photos/demo_chair_broken.jpg', 'before', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(3, 3, 'uploads/photos/demo_projector_bad.jpg', 'before', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(4, 3, 'uploads/photos/demo_after_projector.jpg', 'after', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(5, 4, 'uploads/photos/demo_water_tap.jpg', 'before', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(6, 5, 'uploads/photos/demo_chair_broken.jpg', 'before', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(7, 6, 'uploads/photos/demo_ac_leak.jpg', 'before', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Report Status History
INSERT INTO `report_status_history` (`report_id`, `status`, `note`, `photo_path`, `changed_by`, `created_at`) VALUES
(1, 'terkirim', 'Laporan kerusakan AC disampaikan oleh mahasiswa.', NULL, 5, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 'diverifikasi', 'Sarpras telah memverifikasi keluhan AC bocor di FE A.2b.01.', NULL, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 'terkirim', 'Laporan lampu berkedip dibuat.', NULL, 6, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, 'diverifikasi', 'Verifikasi data lampu TL FT-01 disetujui.', NULL, 1, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 'ditugaskan', 'Ditugaskan ke teknisi Pak Joko untuk penggantian ballast & starter.', NULL, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 'terkirim', 'Laporan kran toilet bocor.', NULL, 7, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(3, 'diverifikasi', 'Disetujui untuk perbaikan pipa sanitasi.', NULL, 1, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(3, 'ditugaskan', 'Pak Bambang ditugaskan perbaikan seal kran.', NULL, 1, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(3, 'selesai', 'Kran wastafel telah diganti dengan valve kuningan baru.', 'seed_proof_kran.jpg', 1, DATE_SUB(NOW(), INTERVAL 1 DAY));

-- Assignments
INSERT INTO `report_assignments` (`report_id`, `technician_id`, `assigned_by`, `notes`, `assigned_at`) VALUES
(2, 1, 1, 'Periksa starter dan ganti lampu TL ruang E.01.01 FT', NOW()),
(3, 2, 1, 'Ganti valve kran wastafel toilet pria GKB Lt 1', NOW()),
(6, 1, 1, 'Ganti bohlam LED sorot tiang parkiran barat', NOW());

-- Ratings
INSERT INTO `ratings` (`report_id`, `user_id`, `rating`, `review`, `created_at`) VALUES
(3, 7, 5, 'Perbaikan sangat cepat tanggap dari Sarpras, air tidak lagi menggenangi selasar.', NOW());

-- Notifications
INSERT INTO `notifications` (`user_id`, `report_id`, `title`, `message`, `is_read`, `created_at`) VALUES
(5, 1, 'Laporan Diverifikasi', 'Laporan Anda untuk AC Ruang A.2b.01 telah diverifikasi tim Sarpras.', 0, NOW()),
(6, 2, 'Teknisi Ditugaskan', 'Teknisi Pak Joko telah ditugaskan menangani lampu di FT-01.', 0, NOW()),
(7, 3, 'Perbaikan Selesai!', 'Kerusakan kran wastafel toilet GKB telah selesai diperbaiki.', 1, NOW());
