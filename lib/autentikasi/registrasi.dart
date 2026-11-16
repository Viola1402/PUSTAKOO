import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  State<RegistrasiPage> createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool sedangMemuat = false;
  bool sembunyikanPassword = true;
  bool sembunyikanKonfirmasi = true;

  final biru = const Color(0xFF2878D0);
  final kuning = const Color(0xFFFFD54F);

  Future<void> daftar() async {
    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final konfirmasi = konfirmasiController.text.trim();

    if (nama.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      tampilkanPesan('Semua kolom wajib diisi!');
      return;
    }

    if (password.length < 6) {
      tampilkanPesan('Password minimal 6 karakter!');
      return;
    }

    if (password != konfirmasi) {
      tampilkanPesan('Konfirmasi password tidak cocok!');
      return;
    }

    setState(() => sedangMemuat = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'nama': nama},
      );

      if (!mounted) return;

      if (response.user != null && response.session != null) {
        tampilkanPesan('Registrasi berhasil! Silakan login.');
        Navigator.pop(context);
      } else if (response.user != null) {
        tampilkanPesan(
          'Akun berhasil dibuat. Silakan periksa email untuk konfirmasi.',
        );
      } else {
        tampilkanPesan('Registrasi belum berhasil.');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      tampilkanPesan(e.message);
    } catch (e) {
      if (!mounted) return;
      tampilkanPesan('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => sedangMemuat = false);
      }
    }
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget kolomInput({
    required String label,
    required String hint,
    required IconData ikon,
    required TextEditingController controller,
    bool password = false,
    bool sembunyi = false,
    VoidCallback? toggle,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF34445A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: password && sembunyi,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(ikon, color: biru),
            suffixIcon: password
                ? IconButton(
                    onPressed: toggle,
                    icon: Icon(
                      sembunyi ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF5F8FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE4EAF2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: biru,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF2878D0),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // MASKOT PIKO
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kuning,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/piko.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Gabung Bersama Pustakoo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2468B5),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Buat akun dan mulai petualangan membaca.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: biru.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34445A),
                      ),
                    ),
                    const SizedBox(height: 22),
                    kolomInput(
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      ikon: Icons.person_outline,
                      controller: namaController,
                    ),
                    const SizedBox(height: 18),
                    kolomInput(
                      label: 'Email',
                      hint: 'Masukkan alamat email',
                      ikon: Icons.email_outlined,
                      controller: emailController,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    kolomInput(
                      label: 'Password',
                      hint: 'Minimal 6 karakter',
                      ikon: Icons.lock_outline,
                      controller: passwordController,
                      password: true,
                      sembunyi: sembunyikanPassword,
                      toggle: () {
                        setState(() {
                          sembunyikanPassword = !sembunyikanPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    kolomInput(
                      label: 'Konfirmasi Password',
                      hint: 'Masukkan ulang password',
                      ikon: Icons.lock_reset_outlined,
                      controller: konfirmasiController,
                      password: true,
                      sembunyi: sembunyikanKonfirmasi,
                      toggle: () {
                        setState(() {
                          sembunyikanKonfirmasi = !sembunyikanKonfirmasi;
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: sedangMemuat ? null : daftar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kuning,
                          foregroundColor: const Color(0xFF34445A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: sedangMemuat
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(
                      color: Color(0xFF718096),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: biru,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
