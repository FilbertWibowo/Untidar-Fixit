<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Request;
use App\Core\Response;
use App\Core\Security;
use App\Middleware\AuthMiddleware;
use PDO;

class AuthController {
    public function register(Request $request): void {
        $npm = trim($request->input('npm', ''));
        $name = trim($request->input('name', ''));
        $email = strtolower(trim($request->input('email', '')));
        $password = $request->input('password', '');

        $errors = [];
        if (empty($npm)) {
            $errors['npm'] = 'NPM wajib diisi.';
        } elseif (!preg_match('/^[0-9]{9,15}$/', $npm)) {
            $errors['npm'] = 'Format NPM tidak valid (angka 9-15 digit).';
        }

        if (empty($name)) {
            $errors['name'] = 'Nama lengkap wajib diisi.';
        }

        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Alamat email tidak valid.';
        }

        if (strlen($password) < 8) {
            $errors['password'] = 'Password minimal 8 karakter.';
        }

        if (!empty($errors)) {
            Response::error('Validasi gagal.', 422, $errors);
        }

        $pdo = Database::getConnection();

        // Check if email or npm already registered
        $check = $pdo->prepare("SELECT id, npm, email FROM users WHERE email = ? OR npm = ? LIMIT 1");
        $check->execute([$email, $npm]);
        $existing = $check->fetch();

        if ($existing) {
            if ($existing['email'] === $email) {
                Response::error('Email sudah terdaftar.', 409, ['email' => 'Email telah digunakan.']);
            }
            if ($existing['npm'] === $npm) {
                Response::error('NPM sudah terdaftar.', 409, ['npm' => 'NPM telah digunakan.']);
            }
        }

        $passwordHash = Security::hashPassword($password);

        $stmt = $pdo->prepare("
            INSERT INTO users (role, npm, name, email, password_hash, created_at)
            VALUES ('mahasiswa', ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([$npm, Security::sanitize($name), $email, $passwordHash]);
        $userId = (int)$pdo->lastInsertId();

        // Auto login & generate token
        $token = Security::generateToken();
        $tokenHash = Security::hashToken($token);
        $expiredAt = date('Y-m-d H:i:s', time() + (30 * 86400)); // 30 days

        $tokenStmt = $pdo->prepare("INSERT INTO auth_tokens (user_id, token_hash, expired_at) VALUES (?, ?, ?)");
        $tokenStmt->execute([$userId, $tokenHash, $expiredAt]);

        Response::success([
            'token' => $token,
            'user'  => [
                'id'    => $userId,
                'role'  => 'mahasiswa',
                'npm'   => $npm,
                'name'  => $name,
                'email' => $email,
            ]
        ], 'Pendaftaran akun berhasil!', 201);
    }

    public function login(Request $request): void {
        $ip = $request->getIp();
        $identifier = strtolower(trim($request->input('email', '')));
        $password = $request->input('password', '');

        if (empty($identifier) || empty($password)) {
            Response::error('Email/NPM dan password wajib diisi.', 422);
        }

        $pdo = Database::getConnection();

        // Check rate limiting
        if (!Security::checkLoginRateLimit($pdo, $ip, $identifier)) {
            Response::error('Terlalu banyak percobaan login gagal. Akun sementara dikunci selama 10 menit.', 429);
        }

        // Allow login by email or NPM
        $stmt = $pdo->prepare("SELECT id, role, npm, name, email, password_hash FROM users WHERE email = ? OR npm = ? LIMIT 1");
        $stmt->execute([$identifier, $identifier]);
        $user = $stmt->fetch();

        if (!$user || !Security::verifyPassword($password, $user['password_hash'])) {
            Security::recordFailedLogin($pdo, $ip, $identifier);
            Response::error('Email/NPM atau password salah.', 401);
        }

        // Reset rate limit on success
        Security::resetLoginAttempts($pdo, $ip, $identifier);

        // Generate token
        $token = Security::generateToken();
        $tokenHash = Security::hashToken($token);
        $expiredAt = date('Y-m-d H:i:s', time() + (30 * 86400));

        $tokenStmt = $pdo->prepare("INSERT INTO auth_tokens (user_id, token_hash, expired_at) VALUES (?, ?, ?)");
        $tokenStmt->execute([$user['id'], $tokenHash, $expiredAt]);

        Response::success([
            'token' => $token,
            'user'  => [
                'id'    => (int)$user['id'],
                'role'  => $user['role'],
                'npm'   => $user['npm'],
                'name'  => $user['name'],
                'email' => $user['email'],
            ]
        ], 'Login berhasil.');
    }

    public function logout(Request $request): void {
        $token = $request->getBearerToken();
        if ($token) {
            $tokenHash = Security::hashToken($token);
            $pdo = Database::getConnection();
            $stmt = $pdo->prepare("DELETE FROM auth_tokens WHERE token_hash = ?");
            $stmt->execute([$tokenHash]);
        }
        Response::success(null, 'Logout berhasil.');
    }

    public function me(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        Response::success($user, 'Profil pengguna.');
    }

    public function changePassword(Request $request): void {
        $user = AuthMiddleware::authenticate($request);
        $oldPassword = $request->input('old_password', '');
        $newPassword = $request->input('new_password', '');

        if (strlen($newPassword) < 8) {
            Response::error('Password baru minimal 8 karakter.', 422);
        }

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id = ?");
        $stmt->execute([$user['id']]);
        $row = $stmt->fetch();

        if (!Security::verifyPassword($oldPassword, $row['password_hash'])) {
            Response::error('Password lama tidak sesuai.', 400);
        }

        $newHash = Security::hashPassword($newPassword);
        $up = $pdo->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
        $up->execute([$newHash, $user['id']]);

        Response::success(null, 'Password berhasil diperbarui.');
    }
}
