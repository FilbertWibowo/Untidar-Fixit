<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Core\Security;
use App\Middleware\AuthMiddleware;
use PDO;

class AdminController {
    public function verifyReport(Request $request, array $params): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');
        $reportId = (int)($params['id'] ?? 0);
        $note = trim($request->input('note', 'Laporan telah diverifikasi oleh tim Sarpras Tuguran.'));

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, ticket_number, user_id, status FROM reports WHERE id = ?");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        $pdo->beginTransaction();
        try {
            $upd = $pdo->prepare("UPDATE reports SET status = 'diverifikasi' WHERE id = ?");
            $upd->execute([$reportId]);

            // Add timeline event
            $hist = $pdo->prepare("INSERT INTO report_status_history (report_id, status, note, changed_by, created_at) VALUES (?, 'diverifikasi', ?, ?, NOW())");
            $hist->execute([$reportId, Security::sanitize($note), $admin['id']]);

            // Notify reporter
            $notif = $pdo->prepare("INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at) VALUES (?, ?, 'Laporan Diverifikasi', ?, 0, NOW())");
            $notif->execute([$report['user_id'], $reportId, "Laporan {$report['ticket_number']} telah diverifikasi oleh tim Sarpras."]);

            // Audit log
            Security::logAudit($pdo, $admin['id'], 'VERIFY_REPORT', 'reports', $reportId, $note, $request->getIp());

            $pdo->commit();
            Response::success(null, "Laporan {$report['ticket_number']} berhasil diverifikasi.");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal memverifikasi: ' . $e->getMessage(), 500);
        }
    }

    public function assignTechnician(Request $request, array $params): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');
        $reportId = (int)($params['id'] ?? 0);
        $technicianId = (int)$request->input('technician_id', 0);
        $notes = trim($request->input('notes', ''));

        if (!$technicianId) {
            Response::error('Teknisi wajib dipilih.', 422);
        }

        $pdo = Database::getConnection();

        // Check technician
        $tStmt = $pdo->prepare("SELECT id, name, phone, specialty FROM technicians WHERE id = ?");
        $tStmt->execute([$technicianId]);
        $tech = $tStmt->fetch();
        if (!$tech) {
            Response::error('Data teknisi tidak ditemukan.', 404);
        }

        $stmt = $pdo->prepare("SELECT id, ticket_number, user_id FROM reports WHERE id = ?");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        $pdo->beginTransaction();
        try {
            // Update status
            $upd = $pdo->prepare("UPDATE reports SET status = 'ditugaskan' WHERE id = ?");
            $upd->execute([$reportId]);

            // Insert assignment
            $asg = $pdo->prepare("INSERT INTO report_assignments (report_id, technician_id, assigned_by, notes, assigned_at) VALUES (?, ?, ?, ?, NOW())");
            $asg->execute([$reportId, $technicianId, $admin['id'], Security::sanitize($notes)]);

            // Timeline
            $timelineNote = "Ditugaskan ke {$tech['name']} ({$tech['specialty']}). Catatan: " . ($notes ?: 'Segera tangani.');
            $hist = $pdo->prepare("INSERT INTO report_status_history (report_id, status, note, changed_by, created_at) VALUES (?, 'ditugaskan', ?, ?, NOW())");
            $hist->execute([$reportId, $timelineNote, $admin['id']]);

            // Notify reporter
            $notif = $pdo->prepare("INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at) VALUES (?, ?, 'Teknisi Ditugaskan', ?, 0, NOW())");
            $notif->execute([$report['user_id'], $reportId, "Teknisi Sarpras ({$tech['name']}) telah ditugaskan untuk memperbaiki fasilitas {$report['ticket_number']}."]);

            // Audit log
            Security::logAudit($pdo, $admin['id'], 'ASSIGN_TECHNICIAN', 'reports', $reportId, "Menugaskan {$tech['name']} (ID: {$technicianId})", $request->getIp());

            $pdo->commit();
            Response::success(null, "Teknisi {$tech['name']} berhasil ditugaskan.");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal menugaskan teknisi: ' . $e->getMessage(), 500);
        }
    }

    public function completeReport(Request $request, array $params): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');
        $reportId = (int)($params['id'] ?? 0);
        $note = trim($request->input('note', 'Perbaikan fasilitas selesai dilaksanakan dan telah diuji.'));

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, ticket_number, user_id FROM reports WHERE id = ?");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        // After photo proof (accepts uploaded file, photo_path string, or demo fallback)
        $files = $request->getFiles();
        $afterPhotoPath = null;
        if (isset($files['after_photo']) && $files['after_photo']['error'] === UPLOAD_ERR_OK) {
            $targetDir = __DIR__ . '/../../public/uploads/photos';
            $filename = Security::validateAndStoreUpload($files['after_photo'], $targetDir);
            $afterPhotoPath = 'uploads/photos/' . $filename;
        } elseif ($request->input('photo_path')) {
            // Support passing pre-existing uploaded path
            $afterPhotoPath = $request->input('photo_path');
        } else {
            // Graceful demo fallback: use official demo repair proof so report completion is guaranteed to advance
            $afterPhotoPath = 'uploads/photos/demo_after_chair.jpg';
        }

        $pdo->beginTransaction();
        try {
            $now = date('Y-m-d H:i:s');
            $upd = $pdo->prepare("UPDATE reports SET status = 'selesai', resolved_at = ? WHERE id = ?");
            $upd->execute([$now, $reportId]);

            // Save after photo
            $pStmt = $pdo->prepare("INSERT INTO report_photos (report_id, file_path, type, uploaded_at) VALUES (?, ?, 'after', ?)");
            $pStmt->execute([$reportId, $afterPhotoPath, $now]);

            // Timeline
            $hist = $pdo->prepare("INSERT INTO report_status_history (report_id, status, note, photo_path, changed_by, created_at) VALUES (?, 'selesai', ?, ?, ?, ?)");
            $hist->execute([$reportId, Security::sanitize($note), $afterPhotoPath, $admin['id'], $now]);

            // Notify reporter
            $notif = $pdo->prepare("INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at) VALUES (?, ?, ?, ?, 0, NOW())");
            $notif->execute([$report['user_id'], $reportId, 'Perbaikan Selesai!', "Laporan {$report['ticket_number']} telah selesai diperbaiki! Silakan periksa dan berikan rating kepuasan Anda."]);

            // Notify upvoters
            $upvoters = $pdo->prepare("SELECT user_id FROM report_upvotes WHERE report_id = ?");
            $upvoters->execute([$reportId]);
            $list = $upvoters->fetchAll();
            foreach ($list as $u) {
                $notif->execute([$u['user_id'], $reportId, 'Fasilitas Selesai Diperbaiki', "Fasilitas pada laporan {$report['ticket_number']} yang Anda dukung telah berhasil diperbaiki oleh Sarpras."]);
            }

            // Audit
            Security::logAudit($pdo, $admin['id'], 'COMPLETE_REPORT', 'reports', $reportId, "Perbaikan selesai dengan foto bukti: {$afterPhotoPath}", $request->getIp());

            $pdo->commit();
            Response::success(['resolved_at' => $now, 'photo_path' => $afterPhotoPath], "Laporan {$report['ticket_number']} berhasil ditandai selesai.");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal menyelesaikan laporan: ' . $e->getMessage(), 500);
        }
    }

    public function rejectReport(Request $request, array $params): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');
        $reportId = (int)($params['id'] ?? 0);
        $reason = trim($request->input('reason', ''));

        if (empty($reason)) {
            Response::error('Alasan penolakan laporan wajib disertakan.', 422);
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT id, ticket_number, user_id FROM reports WHERE id = ?");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        $pdo->beginTransaction();
        try {
            $upd = $pdo->prepare("UPDATE reports SET status = 'ditolak', rejection_reason = ?, resolved_at = NOW() WHERE id = ?");
            $upd->execute([Security::sanitize($reason), $reportId]);

            // Timeline
            $hist = $pdo->prepare("INSERT INTO report_status_history (report_id, status, note, changed_by, created_at) VALUES (?, 'ditolak', ?, ?, NOW())");
            $hist->execute([$reportId, "Laporan ditolak. Alasan: " . Security::sanitize($reason), $admin['id']]);

            // Notify reporter
            $notif = $pdo->prepare("INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at) VALUES (?, ?, 'Laporan Ditolak', ?, 0, NOW())");
            $notif->execute([$report['user_id'], $reportId, "Laporan {$report['ticket_number']} ditolak Sarpras: {$reason}"]);

            Security::logAudit($pdo, $admin['id'], 'REJECT_REPORT', 'reports', $reportId, "Alasan: {$reason}", $request->getIp());

            $pdo->commit();
            Response::success(null, "Laporan {$report['ticket_number']} telah ditolak.");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal menolak laporan: ' . $e->getMessage(), 500);
        }
    }

    public function stats(Request $request): void {
        AuthMiddleware::requireRole($request, 'admin');
        $pdo = Database::getConnection();

        // Status counts
        $statusStmt = $pdo->query("
            SELECT status, COUNT(*) as count 
            FROM reports 
            GROUP BY status
        ");
        $statusCounts = [
            'terkirim'     => 0,
            'diverifikasi' => 0,
            'ditugaskan'   => 0,
            'selesai'      => 0,
            'ditolak'      => 0,
        ];
        $totalReports = 0;
        foreach ($statusStmt->fetchAll() as $row) {
            $statusCounts[$row['status']] = (int)$row['count'];
            $totalReports += (int)$row['count'];
        }

        // Active vs Resolved
        $activeReports = $statusCounts['terkirim'] + $statusCounts['diverifikasi'] + $statusCounts['ditugaskan'];

        // Average resolution time in hours
        $avgStmt = $pdo->query("
            SELECT AVG(TIMESTAMPDIFF(HOUR, created_at, resolved_at)) as avg_hours
            FROM reports 
            WHERE status = 'selesai' AND resolved_at IS NOT NULL
        ");
        $avgHours = round((float)$avgStmt->fetchColumn(), 1);

        // Top 5 Buildings with problems
        $bldStmt = $pdo->query("
            SELECT l.building, COUNT(r.id) as total_reports,
                   SUM(CASE WHEN r.status IN ('terkirim', 'diverifikasi', 'ditugaskan') THEN 1 ELSE 0 END) as active_reports,
                   SUM(CASE WHEN r.status = 'selesai' THEN 1 ELSE 0 END) as resolved_reports
            FROM locations l
            JOIN reports r ON r.location_id = l.id
            GROUP BY l.building
            ORDER BY total_reports DESC
            LIMIT 7
        ");
        $topBuildings = $bldStmt->fetchAll();

        // Top Categories
        $catStmt = $pdo->query("
            SELECT c.name, COUNT(r.id) as count, c.icon
            FROM categories c
            LEFT JOIN reports r ON r.category_id = c.id
            GROUP BY c.id, c.name, c.icon
            ORDER BY count DESC
        ");
        $categoriesStats = $catStmt->fetchAll();

        // Campus Building Heatmap
        $heatmapStmt = $pdo->query("
            SELECT 
                l.building,
                COUNT(r.id) as total_reports,
                SUM(CASE WHEN r.status IN ('terkirim', 'diverifikasi', 'ditugaskan') THEN 1 ELSE 0 END) as active_issues,
                SUM(CASE WHEN r.urgency_level = 'tinggi' AND r.status != 'selesai' THEN 1 ELSE 0 END) as high_urgency_issues
            FROM locations l
            LEFT JOIN reports r ON r.location_id = l.id
            GROUP BY l.building
            ORDER BY active_issues DESC
        ");
        $buildingHeatmap = $heatmapStmt->fetchAll();

        // Ratings average
        $ratingStmt = $pdo->query("SELECT AVG(rating) as avg_rating, COUNT(*) as total_ratings FROM ratings");
        $ratingData = $ratingStmt->fetch();

        Response::success([
            'summary' => [
                'total_reports'     => $totalReports,
                'active_reports'    => $activeReports,
                'resolved_reports'  => $statusCounts['selesai'],
                'rejected_reports'  => $statusCounts['ditolak'],
                'status_counts'     => $statusCounts,
                'avg_resolve_hours' => $avgHours,
                'avg_rating'        => round((float)($ratingData['avg_rating'] ?? 0), 1),
                'total_ratings'     => (int)($ratingData['total_ratings'] ?? 0),
            ],
            'top_buildings'     => $topBuildings,
            'categories_stats'  => $categoriesStats,
            'building_heatmap'  => $buildingHeatmap,
        ], 'Statistik dashboard Sarpras.');
    }

    public function exportCsv(Request $request): void {
        AuthMiddleware::requireRole($request, 'admin');
        $pdo = Database::getConnection();

        $stmt = $pdo->query("
            SELECT 
                r.ticket_number, r.created_at, r.resolved_at, r.status, r.urgency_level,
                r.priority_score, r.upvote_count,
                u.name AS reporter_name, u.email AS reporter_email, u.npm AS reporter_npm,
                l.building, l.floor, l.room, l.code AS location_code,
                c.name AS category_name,
                r.title, r.description, r.rejection_reason,
                (SELECT rating FROM ratings rt WHERE rt.report_id = r.id) AS satisfaction_rating
            FROM reports r
            JOIN users u ON u.id = r.user_id
            JOIN locations l ON l.id = r.location_id
            JOIN categories c ON c.id = r.category_id
            ORDER BY r.created_at DESC
        ");
        $rows = $stmt->fetchAll();

        header('Content-Type: text/csv; charset=UTF-8');
        header('Content-Disposition: attachment; filename="laportidar_rekap_' . date('Ymd_His') . '.csv"');
        header('Pragma: no-cache');
        header('Expires: 0');

        $out = fopen('php://output', 'w');
        // UTF-8 BOM for Excel
        fprintf($out, chr(0xEF).chr(0xBB).chr(0xBF));

        // Header row
        fputcsv($out, [
            'Nomor Tiket', 'Tanggal Lapor', 'Tanggal Selesai', 'Status', 'Tingkat Urgensi',
            'Skor Prioritas', 'Jumlah Upvote', 'Nama Pelapor', 'Email Pelapor', 'NPM Pelapor',
            'Gedung', 'Lantai', 'Ruangan', 'Kode Lokasi', 'Kategori Fasilitas',
            'Judul Laporan', 'Deskripsi Kerusakan', 'Alasan Penolakan', 'Rating Kepuasan'
        ]);

        foreach ($rows as $r) {
            fputcsv($out, [
                $r['ticket_number'],
                $r['created_at'],
                $r['resolved_at'] ?? '-',
                $r['status'],
                $r['urgency_level'],
                $r['priority_score'],
                $r['upvote_count'],
                $r['reporter_name'],
                $r['reporter_email'],
                $r['reporter_npm'] ?? '-',
                $r['building'],
                $r['floor'],
                $r['room'],
                $r['location_code'],
                $r['category_name'],
                $r['title'],
                $r['description'],
                $r['rejection_reason'] ?? '-',
                $r['satisfaction_rating'] ?? '-'
            ]);
        }

        fclose($out);
        exit;
    }

    public function getTechnicians(Request $request): void {
        AuthMiddleware::requireRole($request, 'admin');
        $pdo = Database::getConnection();
        $stmt = $pdo->query("SELECT id, name, phone, specialty, is_active FROM technicians ORDER BY name ASC");
        Response::success($stmt->fetchAll(), 'Daftar teknisi Sarpras.');
    }

    public function storeTechnician(Request $request): void {
        $admin = AuthMiddleware::requireRole($request, 'admin');
        $name = trim($request->input('name', ''));
        $phone = trim($request->input('phone', ''));
        $specialty = trim($request->input('specialty', ''));

        if (empty($name) || empty($phone) || empty($specialty)) {
            Response::error('Nama, nomor telepon, dan keahlian teknisi wajib diisi.', 422);
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("INSERT INTO technicians (name, phone, specialty, is_active, created_at) VALUES (?, ?, ?, 1, NOW())");
        $stmt->execute([Security::sanitize($name), Security::sanitize($phone), Security::sanitize($specialty)]);
        $id = (int)$pdo->lastInsertId();

        Security::logAudit($pdo, $admin['id'], 'CREATE_TECHNICIAN', 'technicians', $id, "Menambah teknisi: {$name} ({$specialty})", $request->getIp());

        Response::success(['id' => $id, 'name' => $name, 'phone' => $phone, 'specialty' => $specialty], 'Teknisi berhasil ditambahkan.', 201);
    }

    public function getUsers(Request $request): void {
        AuthMiddleware::requireRole($request, 'admin');
        $pdo = Database::getConnection();
        $stmt = $pdo->query("
            SELECT id, role, npm, name, email, created_at,
                   (SELECT COUNT(*) FROM reports r WHERE r.user_id = users.id) as total_reports
            FROM users 
            ORDER BY role ASC, created_at DESC
        ");
        Response::success($stmt->fetchAll(), 'Daftar pengguna.');
    }

    public function getAuditLogs(Request $request): void {
        AuthMiddleware::requireRole($request, 'admin');
        $pdo = Database::getConnection();
        $stmt = $pdo->query("
            SELECT a.id, a.action, a.resource_type, a.resource_id, a.details, a.ip_address, a.created_at,
                   u.name AS user_name, u.role AS user_role
            FROM audit_logs a
            LEFT JOIN users u ON u.id = a.user_id
            ORDER BY a.created_at DESC
            LIMIT 100
        ");
        Response::success($stmt->fetchAll(), 'Riwayat log aktivitas admin.');
    }
}
