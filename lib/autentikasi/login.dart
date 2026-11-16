import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'registrasi.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocus = FocusNode();

  bool loading = false;
  bool sembunyikanPassword = true;

  static const biru = Color(0xFF005A8D);
  static const kuning = Color(0xFFFBC333);
  static const latar = Color(0xFFEAF6FD);

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan kata sandi wajib diisi'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final halaman = await halamanPengguna();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => halaman),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> lupaPassword() async {
    final controller = TextEditingController(
      text: emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Lupa Password?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan email akunmu. Kami akan mengirimkan '
                'link untuk mengatur ulang password.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email terdaftar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (email == null || email.isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan reset password berhasil dikirim. '
            'Periksa email kamu.',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    passwordFocus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Widget kolomInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool password = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: biru,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: password ? passwordFocus : null,
          obscureText: password && sembunyikanPassword,
          keyboardType:
              password ? TextInputType.text : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: password
                ? IconButton(
                    icon: Icon(
                      sembunyikanPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: biru,
                    ),
                    onPressed: () {
                      setState(() {
                        sembunyikanPassword = !sembunyikanPassword;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: latar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: PikoInteraktif(
                      tutupMata: passwordFocus.hasFocus,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pustakoo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: biru,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Baca cerita seru bersama si kecil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: biru,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  kolomInput(
                    label: 'Email',
                    hint: 'email@contoh.com',
                    controller: emailController,
                  ),
                  const SizedBox(height: 18),
                  kolomInput(
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi',
                    controller: passwordController,
                    password: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: lupaPassword,
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: biru,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
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
                              'Masuk',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: biru),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrasiPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              color: biru,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Coba email "admin@pustakoo.id" '
                    'untuk tampilan Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: biru,
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

// MASKOT PIKO INTERAKTIF

class PikoInteraktif extends StatefulWidget {
  final bool tutupMata;

  const PikoInteraktif({
    super.key,
    required this.tutupMata,
  });

  @override
  State<PikoInteraktif> createState() => _PikoInteraktifState();
}

class _PikoInteraktifState extends State<PikoInteraktif>
    with SingleTickerProviderStateMixin {
  late AnimationController kedipController;
  Timer? timerKedip;

  Offset arahMata = Offset.zero;
  bool berkedip = false;

  @override
  void initState() {
    super.initState();

    kedipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    timerKedip = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {
        if (!mounted || widget.tutupMata) return;

        setState(() => berkedip = true);

        await Future.delayed(
          const Duration(milliseconds: 160),
        );

        if (mounted) {
          setState(() => berkedip = false);
        }
      },
    );
  }

  void ubahArah(Offset posisi, Size ukuran) {
    setState(() {
      arahMata = Offset(
        ((posisi.dx / ukuran.width) - 0.5) * 2,
        ((posisi.dy / ukuran.height) - 0.5) * 2,
      );
    });
  }

  @override
  void dispose() {
    timerKedip?.cancel();
    kedipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mataTertutup = widget.tutupMata || berkedip;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ukuran = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 160,
          144,
        );

        return MouseRegion(
          onHover: (event) {
            ubahArah(event.localPosition, ukuran);
          },
          onExit: (_) {
            setState(() => arahMata = Offset.zero);
          },
          child: GestureDetector(
            onPanUpdate: (event) {
              ubahArah(event.localPosition, ukuran);
            },
            onPanEnd: (_) {
              setState(() => arahMata = Offset.zero);
            },
            child: SizedBox(
              width: 160,
              height: 144,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/piko.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PikoMataPainter(
                        arah: arahMata,
                        tertutup: mataTertutup,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PikoMataPainter extends CustomPainter {
  final Offset arah;
  final bool tertutup;

  PikoMataPainter({
    required this.arah,
    required this.tertutup,
  });

  static const warnaMata = Color(0xFF1D2B36);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 1000;
    final sy = size.height / 900;

    canvas.save();
    canvas.scale(sx, sy);

    final putih = Paint()..color = Colors.white;
    final gelap = Paint()..color = warnaMata;

    // Menutup mata asli pada gambar.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(338, 460),
        width: 230,
        height: 260,
      ),
      putih,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(670, 460),
        width: 230,
        height: 260,
      ),
      putih,
    );

    if (tertutup) {
      final garis = Paint()
        ..color = warnaMata
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round;

      for (final x in [338.0, 670.0]) {
        final path = Path()
          ..moveTo(x - 65, 465)
          ..quadraticBezierTo(x, 500, x + 65, 465);

        canvas.drawPath(path, garis);
      }
    } else {
      for (final x in [338.0, 670.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, 460),
            width: 205,
            height: 236,
          ),
          gelap,
        );

        canvas.drawCircle(
          Offset(x, 460),
          59,
          putih,
        );

        final gerakX = arah.dx.clamp(-1.0, 1.0) * 16;
        final gerakY = arah.dy.clamp(-1.0, 1.0) * 16;

        canvas.drawCircle(
          Offset(x + gerakX, 460 + gerakY),
          32,
          gelap,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PikoMataPainter oldDelegate) {
    return oldDelegate.arah != arah || oldDelegate.tertutup != tertutup;
  }
}
