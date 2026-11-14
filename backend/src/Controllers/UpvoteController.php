<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Middleware\AuthMiddleware;
use PDO;

class UpvoteController {
    public function upvote(Request $request, array $params): void {
        $user = AuthMiddleware::authenticate($request);
        $reportId = (int)($params['id'] ?? 0);

        $pdo = Database::getConnection();

        // 1. Fetch report
        $stmt = $pdo->prepare("
            SELECT r.id, r.user_id, r.ticket_number, r.status, r.created_at, r.urgency_level, c.severity_weight
            FROM reports r
            JOIN categories c ON c.id = r.category_id
            WHERE r.id = ?
        ");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        // Cannot upvote own report
        if ((int)$report['user_id'] === (int)$user['id']) {
            Response::error("Anda tidak dapat meng-upvote laporan Anda sendiri.", 400);
        }

        if (in_array($report['status'], ['selesai', 'ditolak'])) {
            Response::error("Laporan sudah ditutup / selesai.", 400);
        }

        $pdo->beginTransaction();
        try {
            // Check existing upvote
            $check = $pdo->prepare("SELECT id FROM report_upvotes WHERE report_id = ? AND user_id = ?");
            $check->execute([$reportId, $user['id']]);
            if ($check->fetch()) {
                $pdo->rollBack();
                Response::error("Anda sudah memberikan dukungan (upvote) pada laporan ini.", 409);
            }

            // Insert upvote
            $ins = $pdo->prepare("INSERT INTO report_upvotes (report_id, user_id, created_at) VALUES (?, ?, NOW())");
            $ins->execute([$reportId, $user['id']]);

            // Count new upvotes
            $cntStmt = $pdo->prepare("SELECT COUNT(*) FROM report_upvotes WHERE report_id = ?");
            $cntStmt->execute([$reportId]);
            $newUpvotes = (int)$cntStmt->fetchColumn();

            // Recalculate priority score
            $newScore = ReportController::calculatePriorityScore(
                $newUpvotes,
                (int)$report['severity_weight'],
                $report['created_at'],
                $report['urgency_level']
            );

            // Update report
            $upd = $pdo->prepare("UPDATE reports SET upvote_count = ?, priority_score = ? WHERE id = ?");
            $upd->execute([$newUpvotes, $newScore, $reportId]);

            // Notify original reporter
            $notif = $pdo->prepare("
                INSERT INTO notifications (user_id, report_id, title, message, is_read, created_at)
                VALUES (?, ?, 'Dukungan Baru!', ?, 0, NOW())
            ");
            $notif->execute([
                $report['user_id'],
                $reportId,
                "Mahasiswa lain juga mengalami hal serupa pada laporan {$report['ticket_number']}. Prioritas penanganan Sarpras ditingkatkan!"
            ]);

            $pdo->commit();

            Response::success([
                'report_id'      => $reportId,
                'upvote_count'   => $newUpvotes,
                'priority_score' => $newScore,
                'has_upvoted'    => true
            ], 'Berhasil mendukung laporan ("Saya Mengalami Hal Serupa")!');
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal upvote: ' . $e->getMessage(), 500);
        }
    }

    public function cancelUpvote(Request $request, array $params): void {
        $user = AuthMiddleware::authenticate($request);
        $reportId = (int)($params['id'] ?? 0);

        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("
            SELECT r.id, r.user_id, r.created_at, r.urgency_level, c.severity_weight
            FROM reports r
            JOIN categories c ON c.id = r.category_id
            WHERE r.id = ?
        ");
        $stmt->execute([$reportId]);
        $report = $stmt->fetch();

        if (!$report) {
            Response::notFound("Laporan tidak ditemukan.");
        }

        $pdo->beginTransaction();
        try {
            $del = $pdo->prepare("DELETE FROM report_upvotes WHERE report_id = ? AND user_id = ?");
            $del->execute([$reportId, $user['id']]);

            $cntStmt = $pdo->prepare("SELECT COUNT(*) FROM report_upvotes WHERE report_id = ?");
            $cntStmt->execute([$reportId]);
            $newUpvotes = (int)$cntStmt->fetchColumn();

            $newScore = ReportController::calculatePriorityScore(
                $newUpvotes,
                (int)$report['severity_weight'],
                $report['created_at'],
                $report['urgency_level']
            );

            $upd = $pdo->prepare("UPDATE reports SET upvote_count = ?, priority_score = ? WHERE id = ?");
            $upd->execute([$newUpvotes, $newScore, $reportId]);

            $pdo->commit();

            Response::success([
                'report_id'      => $reportId,
                'upvote_count'   => $newUpvotes,
                'priority_score' => $newScore,
                'has_upvoted'    => false
            ], 'Dukungan berhasil dibatalkan.');
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Gagal membatalkan upvote: ' . $e->getMessage(), 500);
        }
    }
}
