<?php

namespace App\Middleware;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Core\Security;

class AuthMiddleware {
    public static function authenticate(Request $request): array {
        $token = $request->getBearerToken();
        if (!$token) {
            Response::unauthorized("Token otentikasi tidak ditemukan. Silakan login kembali.");
        }

        $tokenHash = Security::hashToken($token);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("
            SELECT u.id, u.role, u.npm, u.name, u.email, t.expired_at 
            FROM auth_tokens t
            JOIN users u ON u.id = t.user_id
            WHERE t.token_hash = ? AND t.expired_at > NOW()
            LIMIT 1
        ");
        $stmt->execute([$tokenHash]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::unauthorized("Sesi telah berakhir atau token tidak valid.");
        }

        $request->setUser($user);
        return $user;
    }

    public static function requireRole(Request $request, string ...$allowedRoles): array {
        $user = self::authenticate($request);
        if (!in_array($user['role'], $allowedRoles, true)) {
            Response::forbidden("Akses ditolak. Anda tidak memiliki izin untuk tindakan ini.");
        }
        return $user;
    }
}
