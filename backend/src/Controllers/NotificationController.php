<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Middleware\AuthMiddleware;
use PDO;

class NotificationController {
    public function index(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("
            SELECT id, report_id, title, message, is_read, created_at 
            FROM notifications 
            WHERE user_id = ? 
            ORDER BY created_at DESC 
            LIMIT 50
        ");
        $stmt->execute([$user['id']]);
        $list = $stmt->fetchAll();

        $unreadCountStmt = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        $unreadCountStmt->execute([$user['id']]);
        $unreadCount = (int)$unreadCountStmt->fetchColumn();

        Response::success([
            'unread_count'  => $unreadCount,
            'notifications' => $list,
        ], 'Daftar notifikasi.');
    }

    public function markAsRead(Request $request, array $params): void {
        $user = AuthMiddleware::authenticate($request);
        $id = (int)($params['id'] ?? 0);

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user['id']]);

        Response::success(null, 'Notifikasi telah ditandai dibaca.');
    }

    public function markAllAsRead(Request $request): void {
        $user = AuthMiddleware::authenticate($request);

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
        $stmt->execute([$user['id']]);

        Response::success(null, 'Semua notifikasi telah ditandai dibaca.');
    }
}
