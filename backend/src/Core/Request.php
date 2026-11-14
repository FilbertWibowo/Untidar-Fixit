<?php

namespace App\Core;

class Request {
    private string $method;
    private string $uri;
    private array $queryParams;
    private array $body;
    private array $headers;
    private array $files;
    private ?array $user = null;

    public function __construct() {
        $this->method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $parts = parse_url($uri);
        $this->uri = rawurldecode($parts['path'] ?? '/');
        
        $this->queryParams = $_GET;
        $this->files = $_FILES;
        $this->headers = $this->extractHeaders();
        $this->body = $this->parseBody();
    }

    private function extractHeaders(): array {
        $headers = [];
        foreach ($_SERVER as $key => $val) {
            if (str_starts_with($key, 'HTTP_')) {
                $name = str_replace('_', '-', strtolower(substr($key, 5)));
                $headers[$name] = $val;
            } elseif (in_array($key, ['CONTENT_TYPE', 'CONTENT_LENGTH'])) {
                $name = str_replace('_', '-', strtolower($key));
                $headers[$name] = $val;
            }
        }
        return $headers;
    }

    private function parseBody(): array {
        $contentType = $this->getHeader('content-type') ?? '';
        if (str_contains($contentType, 'application/json')) {
            $input = file_get_contents('php://input');
            $data = json_decode($input, true);
            return is_array($data) ? $data : [];
        }
        return $_POST;
    }

    public function getMethod(): string {
        return $this->method;
    }

    public function getUri(): string {
        return $this->uri;
    }

    public function getHeader(string $name): ?string {
        return $this->headers[strtolower($name)] ?? null;
    }

    public function getBearerToken(): ?string {
        $auth = $this->getHeader('authorization');
        if ($auth && preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            return $matches[1];
        }
        return null;
    }

    public function getQuery(string $key, mixed $default = null): mixed {
        return $this->queryParams[$key] ?? $default;
    }

    public function getAllQuery(): array {
        return $this->queryParams;
    }

    public function input(string $key, mixed $default = null): mixed {
        return $this->body[$key] ?? $default;
    }

    public function all(): array {
        return $this->body;
    }

    public function getFile(string $key): ?array {
        return $this->files[$key] ?? null;
    }

    public function getFiles(): array {
        return $this->files;
    }

    public function setUser(array $user): void {
        $this->user = $user;
    }

    public function getUser(): ?array {
        return $this->user;
    }

    public function getIp(): string {
        return $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    }
}
