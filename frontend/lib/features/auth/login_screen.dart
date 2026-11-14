import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberUsername = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      final msg = auth.errorMessage ?? 'Gagal masuk ke sistem. Periksa email dan password Anda.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.statusDitolak,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image Kampus Untidar
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_untidar.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: const Color(0xFFF0F4F8)),
            ),
          ),

          // 2. Transparan halus dengan blur ringan di seluruh layar
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),

          // 3. Login Card dengan efek Glassmorphism Transparan + Blur
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white, // Pure Clean White Background
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Logo Untidar (Besar) + Gold Separator + Brand UNTIDAR Fixit (Besar)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/logo_untidar.png',
                                  width: 78,
                                  height: 78,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.school_rounded,
                                    size: 70,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 3,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706), // Gold vertical separator
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        'UNTIDAR ',
                                        style: TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 26,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'Fixit',
                                        style: GoogleFonts.caveat(
                                          color: const Color(0xFF2563EB),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Facility Care Untidar',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
                          const SizedBox(height: 20),

                          // Sign In Title
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Masuk dengan akun civitas akademika Universitas Tidar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username / Email Input Box (Soft Tinted with border)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                              decoration: const InputDecoration(
                                hintText: 'Email atau Username Kampus',
                                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF475569), size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Input Box
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                hintText: 'Kata Sandi',
                                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF475569), size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF475569),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Remember Username & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberUsername,
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberUsername = val ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF3B5BDB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Remember username',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Silakan hubungi Helpdesk UPT TIK Untidar untuk reset sandi.')),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Primary Log in Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B5BDB), // Untidar Royal Blue
                              foregroundColor: Colors.white,
                              elevation: 2,
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: auth.isLoading ? null : _handleLogin,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Log in',
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 14),

                          // Register Link
                          Center(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Daftar Akun Mahasiswa Baru',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Kredensial Resmi Demo dengan Tombol Cepat
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.vpn_key_rounded, size: 14, color: Color(0xFF1E3A8A)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Akun Demo (Klik untuk Isi Otomatis):',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          side: const BorderSide(color: Color(0xFF93C5FD)),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _emailController.text = 'muhammad.asyrof@students.untidar.ac.id';
                                            _passwordController.text = 'UntidarFixit2026!';
                                          });
                                        },
                                        child: const Text(
                                          '👤 Mahasiswa',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          side: const BorderSide(color: Color(0xFFFDBA74)),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _emailController.text = 'admin@untidar.ac.id';
                                            _passwordController.text = 'UntidarFixit2026!';
                                          });
                                        },
                                        child: const Text(
                                          '🛡️ Admin Sarpras',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Follow Us Social Icons
                          const Center(
                            child: Text(
                              'Follow Us',
                              style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialCircle(const Color(0xFF3B5998), Icons.facebook),
                              const SizedBox(width: 8),
                              _buildSocialCircle(const Color(0xFF38A1F3), Icons.alternate_email_rounded),
                              const SizedBox(width: 8),
                              _buildSocialCircle(const Color(0xFF0077B5), Icons.link_rounded),
                              const SizedBox(width: 8),
                              _buildSocialCircle(const Color(0xFF3F729B), Icons.camera_alt_rounded),
                              const SizedBox(width: 8),
                              _buildSocialCircle(const Color(0xFFCD201F), Icons.play_arrow_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCircle(Color color, IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
