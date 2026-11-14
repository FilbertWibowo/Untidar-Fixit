<?php

namespace App\Core;

class Response {
    public static function json(
        mixed $data = null,
        string $message = 'Success',
        int $statusCode = 200,
        bool $success = true,
        mixed $errors = null
    ): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=UTF-8');
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('Referrer-Policy: strict-origin-when-cross-origin');

        $payload = [
            'success' => $success,
            'message' => $message,
            'data'    => $data,
            'errors'  => $errors,
        ];

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success(mixed $data = null, string $message = 'Success', int $statusCode = 200): void {
        self::json($data, $message, $statusCode, true, null);
    }

    public static function error(string $message = 'An error occurred', int $statusCode = 400, mixed $errors = null): void {
        self::json(null, $message, $statusCode, false, $errors);
    }

    public static function unauthorized(string $message = 'Unauthorized'): void {
        self::error($message, 401);
    }

    public static function forbidden(string $message = 'Forbidden'): void {
        self::error($message, 403);
    }

    public static function notFound(string $message = 'Resource not found'): void {
        self::error($message, 404);
    }
}
