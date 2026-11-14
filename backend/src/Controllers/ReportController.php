<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Core\Security;
use App\Middleware\AuthMiddleware;
use PDO;

class ReportController {
    /**
     * Centralized Priority Score Calculation Formula
     * Formula: (Upvote Count * 2) + Category Severity Weight + (Days Open * 1) + Urgency Weight
     */
    public static function calculatePriorityScore(int $upvotes, int $categoryWeight, string $createdAt, string $urgencyLevel): int {
        $daysOpen = max(0, (int)floor((time() - strtotime($createdAt)) / 86400));
        
        $urgencyWeight = match ($urgencyLevel) {
            'tinggi' => 5,
            'sedang' => 2,
            default  => 0,
        };

        return ($upvotes * 2) + $categoryWeight + $daysOpen + $urgencyWeight;
    }

    public function index(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $building   = $request->getQuery('building');
        $categoryId = $request->getQuery('category_id');
        $status     = $request->getQuery('status');
        $search     = $request->getQuery('search');
        $sortBy     = $request->getQuery('sort_by', 'priority'); // 'priority' or 'latest'
        $page       = max(1, (int)$request->getQuery('page', 1));
        $perPage    = min(50, max(1, (int)$request->getQuery('per_page', 15)));
        $offset     = ($page - 1) * $perPage;

        $where = ['1=1'];
        $params = [];

        if (!empty($building)) {
            $where[] = "l.building = ?";
            $params[] = $building;
        }

        if (!empty($categoryId)) {
            $where[] = "r.category_id = ?";
            $params[] = (int)$categoryId;
        }

        if (!empty($status)) {
            $where[] = "r.status = ?";
            $params[] = $status;
        }

        if (!empty($search)) {
            $where[] = "(r.ticket_number LIKE ? OR r.title LIKE ? OR r.description LIKE ? OR l.room LIKE ?)";
            $term = "%{$search}%";
            $params[] = $term;
            $params[] = $term;
            $params[] = $term;
            $params[] = $term;
        }

        $whereClause = implode(' AND ', $where);
        $orderClause = $sortBy === 'latest' ? "r.created_at DESC" : "r.priority_score DESC, r.created_at DESC";

        // Count total
        $countStmt = $pdo->prepare("
            SELECT COUNT(*) 
            FROM reports r
            JOIN locations l ON l.id = r.location_id
            WHERE {$whereClause}
        ");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        // Fetch reports
        $query = "
            SELECT 
                r.id, r.ticket_number, r.user_id, r.title, r.description, r.urgency_level,
                r.status, r.priority_score, r.upvote_count, r.created_at, r.resolved_at,
                u.name AS reporter_name,
                l.building, l.floor, l.room, l.code AS location_code,
                c.id AS category_id, c.name AS category_name, c.icon AS category_icon, c.severity_weight,
                (SELECT COUNT(*) FROM report_upvotes u2 WHERE u2.report_id = r.id AND u2.user_id = ?) AS user_has_upvoted,
                (SELECT file_path FROM report_photos p WHERE p.report_id = r.id ORDER BY p.id ASC LIMIT 1) AS thumbnail_path
            FROM reports r
            JOIN users u ON u.id = r.user_id
            JOIN locations l ON l.id = r.location_id
            JOIN categories c ON c.id = r.category_id
            WHERE {$whereClause}
            ORDER BY {$orderClause}
            LIMIT {$perPage} OFFSET {$offset}
        ";

        $execParams = array_merge([$user['id']], $params);
        $stmt = $pdo->prepare($query);
        $stmt->execute($execParams);
        $items = $stmt->fetchAll();

        // Convert user_has_upvoted to boolean
        foreach ($items as &$item) {
            $item['user_has_upvoted'] = (bool)$item['user_has_upvoted'];
            $item['id'] = (int)$item['id'];
            $item['user_id'] = (int)$item['user_id'];
            $item['priority_score'] = (int)$item['priority_score'];
            $item['upvote_count'] = (int)$item['upvote_count'];
        }

        Response::success([
            'items'        => $items,
            'total'        => $total,
            'page'         => $page,
            'per_page'     => $perPage,
            'total_pages'  => (int)ceil($total / $perPage),
        ], 'Daftar pengaduan fasilitas.');
    }

    public function mine(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("
            SELECT 
                r.id, r.ticket_number, r.title, r.description, r.urgency_level,
                r.status, r.priority_score, r.upvote_count, r.created_at, r.resolved_at,
                l.building, l.floor, l.room, l.code AS location_code,
                c.name AS category_name, c.icon AS category_icon,
                (SELECT file_path FROM report_photos p WHERE p.report_id = r.id ORDER BY p.id ASC LIMIT 1) AS thumbnail_path
            FROM reports r
            JOIN locations l ON l.id = r.location_id
            JOIN categories c ON c.id = r.category_id
            WHERE r.user_id = ?
            ORDER BY r.created_at DESC
        ");
        $stmt->execute([$user['id']]);
        $reports = $stmt->fetchAll();

        Response::success($reports, 'Laporan saya.');
    }

    public function findSimilar(Request $request): void {
        AuthMiddleware::authenticate($request);

        $locationId = (int)$request->getQuery('location_id', 0);
        $categoryId = (int)$request->getQuery('category_id', 0);

        if (!$locationId || !$categoryId) {
            Response::error('location_id dan category_id diperlukan.', 422);
        }

        $pdo = Database::getConnection();

        // Find reports in same location & category that are NOT yet resolved or rejected
        $stmt = $pdo->prepare("
            SELECT 
                r.id, r.ticket_number, r.title, r.description, r.status, r.priority_score, 
                r.upvote_count, r.created_at,
                l.building, l.floor, l.room,
                c.name AS category_name,
                (SELECT file_path FROM report_photos p WHERE p.report_id = r.id LIMIT 1) AS photo_path
            FROM reports r
            JOIN locations l ON l.id = r.location_id
            JOIN categories c ON c.id = r.category_id
            WHERE r.location_id = ? 
              AND r.category_id = ? 
              AND r.status IN ('terkirim', 'diverifikasi', 'ditugaskan')
            ORDER BY r.priority_score DESC, r.created_at DESC
        ");
        $stmt->execute([$locationId, $categoryId]);
        $similar = $stmt->fetchAll();

        Response::success([
            'count' => count($similar),
            'has_similar' => count($similar) > 0,
            'similar_reports' => $similar
        ], 'Pencarian laporan serupa di lokasi ini.');
    }

    public function show(Request $request, array $params): void {
        $user = AuthMiddleware::authenticate($request);
        $id = (int)($params['id'] ?? 0);

        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("
            SELECT 
                r.*,
                u.name AS reporter_name, u.email AS reporter_email, u.npm AS reporter_npm,
                l.building, l.floor, l.room, l.code AS location_code,
                c.name AS category_name, c.icon AS category_icon, c.severity_weight,
                (SELECT COUNT(*) FROM report_upvotes u2 WHERE u2.report_id = r.id AND u2.user_id = ?) AS user_has_upvoted
            FROM reports r
            JOIN users u ON u.id = r.user_id
            JOIN locations l ON l.id = r.location_id
            JOIN categories c ON c.id = r.category_id
            WHERE r.id = ?
            LIMIT 1
        ");
        $stmt->execute([$user['id'], $id]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        $report['user_has_upvoted'] = (bool)$report['user_has_upvoted'];

        // Photos
        $photoStmt = $pdo->prepare("SELECT id, file_path, type, uploaded_at FROM report_photos WHERE report_id = ? ORDER BY id ASC");
        $photoStmt->execute([$id]);
        $report['photos'] = $photoStmt->fetchAll();

        // Timeline History
        $histStmt = $pdo->prepare("
            SELECT h.id, h.status, h.note, h.photo_path, h.created_at, u.name AS changed_by_name, u.role AS changed_by_role
            FROM report_status_history h
            JOIN users u ON u.id = h.changed_by
            WHERE h.report_id = ?
            ORDER BY h.created_at ASC
        ");
        $histStmt->execute([$id]);
        $report['timeline'] = $histStmt->fetchAll();

        // Assignment if any
        $assignStmt = $pdo->prepare("
            SELECT a.notes, a.assigned_at, t.name AS technician_name, t.phone AS technician_phone, t.specialty
            FROM report_assignments a
            JOIN technicians t ON t.id = a.technician_id
            WHERE a.report_id = ?
            LIMIT 1
        ");
        $assignStmt->execute([$id]);
        $report['assignment'] = $assignStmt->fetch() ?: null;

        // Rating if any
        $rateStmt = $pdo->prepare("SELECT rating, review, created_at FROM ratings WHERE report_id = ? LIMIT 1");
        $rateStmt->execute([$id]);
        $report['rating'] = $rateStmt->fetch() ?: null;

        Response::success($report, 'Detail laporan fasilitas.');
    }

    public function store(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $locationId = (int)$request->input('location_id', 0);
        $categoryId = (int)$request->input('category_id', 0);
        $title       = trim($request->input('title', ''));
        $description = trim($request->input('description', ''));
        $urgency     = strtolower(trim($request->input('urgency_level', 'rendah')));

        if (!in_array($urgency, ['rendah', 'sedang', 'tinggi'])) {
            $urgency = 'rendah';
        }

        $errors = [];
        if (!$locationId) {
            $errors['location_id'] = 'Lokasi ruangan wajib dipilih.';
        }
        if (!$categoryId) {
            $errors['category_id'] = 'Kategori kerusakan wajib dipilih.';
        }
        if (empty($title)) {
            $errors['title'] = 'Judul laporan singkat wajib diisi.';
        }
        if (empty($description)) {
            $errors['description'] = 'Deskripsi detail kerusakan fasilitas wajib diisi.';
        }

        if (!empty($errors)) {
            Response::error('Validasi gagal.', 422, $errors);
        }

        // Fetch category severity weight
        $catStmt = $pdo->prepare("SELECT severity_weight FROM categories WHERE id = ?");
        $catStmt->execute([$categoryId]);
        $catWeight = (int)$catStmt->fetchColumn() ?: 1;

        // Initial priority score
        $createdAt = date('Y-m-d H:i:s');
        $priorityScore = self::calculatePriorityScore(0, $catWeight, $createdAt, $urgency);

        // Generate Ticket LAP-YYYYMM-XXXX
        $ticket = 'LAP-' . date('Ym') . '-' . strtoupper(bin2hex(random_bytes(2)));

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("
                INSERT INTO reports 
                (ticket_number, user_id, location_id, category_id, title, description, urgency_level, status, priority_score, upvote_count, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'terkirim', ?, 0, ?)
            ");
            $stmt->execute([
                $ticket,
                $user['id'],
                $locationId,
                $categoryId,
                Security::sanitize($title),
                Security::sanitize($description),
                $urgency,
                $priorityScore,
                $createdAt
            ]);
            $reportId = (int)$pdo->lastInsertId();

            // Insert initial timeline event
            $hist = $pdo->prepare("
                INSERT INTO report_status_history (report_id, status, note, changed_by, created_at)
                VALUES (?, 'terkirim', 'Laporan berhasil dibuat dan dikirim ke sistem Sarpras.', ?, ?)
            ");
            $hist->execute([$reportId, $user['id'], $createdAt]);

            // Handle Photo Uploads (1-3 photos)
            $files = $request->getFiles();
            $targetDir = __DIR__ . '/../../public/uploads/photos';

            // Check if photos uploaded as single or multiple
            if (isset($files['photos'])) {
                $p = $files['photos'];
                if (is_array($p['name'])) {
                    $count = count($p['name']);
                    for ($i = 0; $i < min(3, $count); $i++) {
                        if ($p['error'][$i] === UPLOAD_ERR_OK) {
                            $singleFile = [
                                'name'     => $p['name'][$i],
                                'type'     => $p['type'][$i],
                                'tmp_name' => $p['tmp_name'][$i],
                                'error'    => $p['error'][$i],
                                'size'     => $p['size'][$i],
                            ];
                            $storedName = Security::validateAndStoreUpload($singleFile, $targetDir);
                            $photoPath = 'uploads/photos/' . $storedName;

                            $pStmt = $pdo->prepare("INSERT INTO report_photos (report_id, file_path, type, uploaded_at) VALUES (?, ?, 'before', NOW())");
                            $pStmt->execute([$reportId, $photoPath]);
                        }
                    }
                } else {
                    if ($p['error'] === UPLOAD_ERR_OK) {
                        $storedName = Security::validateAndStoreUpload($p, $targetDir);
                        $photoPath = 'uploads/photos/' . $storedName;
                        $pStmt = $pdo->prepare("INSERT INTO report_photos (report_id, file_path, type, uploaded_at) VALUES (?, ?, 'before', NOW())");
                        $pStmt->execute([$reportId, $photoPath]);
                    }
                }
            }

            // Notification for student
            $notif = $pdo->prepare("
                INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at)
                VALUES (?, ?, 'Laporan Terkirim', ?, 0, NOW())
            ");
            $notif->execute([$user['id'], $reportId, "Laporan {$ticket} telah terkirim. Anda dapat memantau progresnya di sini."]);

            $pdo->commit();

            Response::success([
                'id'            => $reportId,
                'ticket_number' => $ticket,
                'title'         => $title,
                'status'        => 'terkirim',
                'priority_score'=> $priorityScore
            ], 'Laporan fasilitas berhasil dikirim!', 201);
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal mengirim laporan: ' . $e->getMessage(), 500);
        }
    }

    public function submitRating(Request $request, array $params): void {
        $user = AuthMiddleware::authenticate($request);
        $reportId = (int)($params['id'] ?? 0);
        $rating = (int)$request->input('rating', 0);
        $review = trim($request->input('review', ''));

        if ($rating < 1 || $rating > 5) {
            Response::error('Nilai rating harus berada di antara 1 dan 5 bintang.', 422);
        }

        $pdo = Database::getConnection();

        // Verify report exists, belongs to user, and is 'selesai'
        $stmt = $pdo->prepare("SELECT id, user_id, status FROM reports WHERE id = ?");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        if ((int)$report['user_id'] !== (int)$user['id']) {
            Response::forbidden("Hanya pelapor yang dapat memberikan penilaian kepuasan.");
        }

        if ($report['status'] !== 'selesai') {
            Response::error("Penilaian hanya dapat diberikan setelah perbaikan selesai.", 400);
        }

        // Upsert rating
        $rateStmt = $pdo->prepare("
            INSERT INTO ratings (report_id, user_id, rating, review, created_at)
            VALUES (?, ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE rating = VALUES(rating), review = VALUES(review), created_at = NOW()
        ");
        $rateStmt->execute([$reportId, $user['id'], $rating, Security::sanitize($review)]);

        Response::success(null, 'Terima kasih atas penilaian dan ulasan kepuasan Anda!');
    }
}
