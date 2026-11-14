<?php

namespace App\Config;

class Config {
    private static array $env = [];

    public static function load(string $path = __DIR__ . '/../.env'): void {
        if (!file_exists($path)) {
            return;
        }
        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            if (str_contains($line, '=')) {
                [$k, $v] = explode('=', $line, 2);
                $k = trim($k);
                $v = trim($v, " \t\n\r\0\x0B\"'");
                self::$env[$k] = $v;
                putenv("{$k}={$v}");
                $_ENV[$k] = $v;
            }
        }
    }

    public static function get(string $key, mixed $default = null): mixed {
        if (isset(self::$env[$key])) {
            return self::$env[$key];
        }
        $val = getenv($key);
        if ($val !== false) {
            return $val;
        }
        return $default;
    }
}
