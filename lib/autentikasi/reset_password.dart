import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool loading = false;
  bool sembunyikanPassword = true;
  bool sembunyikanKonfirmasi = true;

  static const biru = Color(0xFF005A8D);
  static const kuning = Color(0xFFFBC333);
  static const latar = Color(0xFFEAF6FD);

  Future<void> ubahPassword() async {
    final password = passwordController.text;
    final konfirmasi = konfirmasiController.text;

    if (password.isEmpty || konfirmasi.isEmpty) {
      pesan('Semua kolom wajib diisi');
      return;
    }

    if (password.length < 6) {
      pesan('Password minimal 6 karakter');
      return;
    }

    if (password != konfirmasi) {
      pesan('Konfirmasi password tidak cocok');
      return;
    }

    setState(() => loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diperbarui!'),
        ),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      pesan(e.message);
    } catch (e) {
      if (!mounted) return;
      pesan('Gagal mengubah password: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    size: 85,
                    color: biru,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Buat Password Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: biru,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Masukkan password baru untuk akun Pustakoo kamu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: biru),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: passwordController,
                    obscureText: sembunyikanPassword,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          sembunyikanPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            sembunyikanPassword = !sembunyikanPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: konfirmasiController,
                    obscureText: sembunyikanKonfirmasi,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          sembunyikanKonfirmasi
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            sembunyikanKonfirmasi = !sembunyikanKonfirmasi;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : ubahPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kuning,
                        foregroundColor: biru,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Simpan Password Baru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
