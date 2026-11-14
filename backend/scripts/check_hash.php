<?php
$hash = '$2y$10$9q93oWQPaSZkwvUXnSjZsuO4qZwuVRV4QSewzyY5V3mwKqy6jGlDK';
echo "mahasiswa123: " . (password_verify('mahasiswa123', $hash) ? 'TRUE' : 'FALSE') . "\n";
echo "UntidarFixit2026!: " . (password_verify('UntidarFixit2026!', $hash) ? 'TRUE' : 'FALSE') . "\n";

$adminHash = '$2y$10$nO1GNia0EcbthDMATFQEU.w0gCpBzVEvVZRXs7xzQhbkEOwPcssKG';
echo "admin admin123: " . (password_verify('admin123', $adminHash) ? 'TRUE' : 'FALSE') . "\n";
echo "admin UntidarFixit2026!: " . (password_verify('UntidarFixit2026!', $adminHash) ? 'TRUE' : 'FALSE') . "\n";
