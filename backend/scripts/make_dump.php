<?php
$schema = file_get_contents(__DIR__ . '/../database/schema.sql');
$seed = file_get_contents(__DIR__ . '/../database/seed.sql');
$combined = $schema . "\n\n-- =========================================\n-- SEED DATA\n-- =========================================\n\n" . $seed;

file_put_contents(__DIR__ . '/../database/untidar_fixit_full_dump.sql', $combined);
file_put_contents(__DIR__ . '/../../untidar_fixit_full_dump.sql', $combined);
echo "Full SQL dump generated successfully: " . strlen($combined) . " bytes\n";
