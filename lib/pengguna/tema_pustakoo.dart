import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Warna sesuai desain Figma Pustakoo.
class Warna {
  static const latar = Color(0xFFEAF6FD);
  static const biruTua = Color(0xFF005A8D);
  static const biruGelap = Color(0xFF003A5A);
  static const biruMuda = Color(0xFF84C7F2);
  static const biruTitik = Color(0xFFBCDFF5);
  static const kuning = Color(0xFFF3E76B);
  static const emas = Color(0xFFFBC333);
  static const hijau = Color(0xFF2E9E5B);
  static const hijauMuda = Color(0xFFBFE6C8);
  static const krem = Color(0xFFFFF6DD);
  static const teksCerita = Color(0xFF3B3020);
  static const persik = Color(0xFFFFE3B3);
  static const gelap = Color(0xFF1D2B36);
  static const abuGelap = Color(0xFF3A4A58);
}

/// Gaya teks Figma: Nunito, tebal (w700).
/// Kalau font Nunito belum dipasang di proyek, Flutter otomatis
/// memakai font bawaan, jadi aman.
TextStyle gaya(double ukuran, {Color warna = Warna.biruTua, double? tinggi}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w700,
    fontSize: ukuran,
    color: warna,
    height: tinggi,
  );
}

/// Kerangka layar bergaya HP: latar biru muda, isi dibatasi lebarnya
/// supaya tetap terlihat seperti HP waktu dibuka di browser.
class KerangkaSeluler extends StatelessWidget {
  final Widget child;
  const KerangkaSeluler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.latar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tombol bulat besar sesuai desain.
class TombolPustakoo extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color warna;
  final Color warnaTeks;

  const TombolPustakoo({
    super.key,
    required this.label,
    required this.onTap,
    this.warna = Warna.kuning,
    this.warnaTeks = Warna.biruTua,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: warna,
          foregroundColor: warnaTeks,
          disabledBackgroundColor: warna.withAlpha(120),
          disabledForegroundColor: warnaTeks.withAlpha(120),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: gaya(16, warna: warnaTeks)),
      ),
    );
  }
}

/// Tampilan galat dengan tombol coba lagi.
class KotakGalat extends StatelessWidget {
  final String judul;
  final String pesan;
  final VoidCallback onUlang;

  const KotakGalat({
    super.key,
    required this.judul,
    required this.pesan,
    required this.onUlang,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(judul, style: gaya(18)),
            const SizedBox(height: 8),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: TombolPustakoo(label: 'Coba lagi', onTap: onUlang),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maskot panda sesuai Figma (grup "Kepala").
/// ENKAPSULASI: ukuran private, semua bagian digambar di satu tempat.
class Panda extends StatelessWidget {
  final double _ukuran; // lebar panda

  // CONSTRUCTOR dengan parameter bernama dan nilai bawaan.
  const Panda({super.key, double ukuran = 48}) : _ukuran = ukuran;

  // Ukuran asli di Figma: sekitar 70 x 57.
  static const double _lebarAsli = 70;
  static const double _tinggiAsli = 57.3;

  static const _gelap = Warna.gelap;
  static const _abu = Warna.abuGelap;
  static const _biru = Warna.biruTua;
  static const _pipi = Color(0x99FBC333);

  Widget _bagian(
    double s,
    double x,
    double y,
    double w,
    double h,
    Color warna, {
    double derajat = 0,
    Border? garis,
  }) {
    return Positioned(
      left: x * s,
      top: y * s,
      child: Transform.rotate(
        angle: derajat * math.pi / 180,
        child: Container(
          width: w * s,
          height: h * s,
          decoration: BoxDecoration(
            color: warna,
            border: garis,
            borderRadius: BorderRadius.all(Radius.elliptical(w * s, h * s)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _ukuran / _lebarAsli; // skala

    return SizedBox(
      width: _ukuran,
      height: _tinggiAsli * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Telinga
          _bagian(s, 0, 0, 18, 18, _gelap),
          _bagian(s, 51.8, 0, 18, 18, _gelap),
          _bagian(s, 5.1, 5.8, 8, 8, _abu),
          _bagian(s, 56.9, 5.8, 8, 8, _abu),

          // Wajah
          _bagian(s, 2.4, 4.9, 65, 52.4, Colors.white,
              garis: Border.all(color: _biru, width: 0.9 * s + 0.4)),

          // Bercak mata
          _bagian(s, 12.2, 19.5, 15, 18.6, _gelap, derajat: 20),
          _bagian(s, 37.3, 19.5, 15, 18.6, _gelap, derajat: -20),

          // Mata putih
          _bagian(s, 18.6, 26.6, 7.3, 7.5, Colors.white),
          _bagian(s, 44.1, 26.6, 7.0, 7.5, Colors.white),

          // Pupil (di tengah bola mata)
          _bagian(s, 20.1, 28.4, 4.3, 4.0, _gelap),
          _bagian(s, 45.6, 28.4, 4.0, 4.0, _gelap),

          // Kilau mata (di pojok kanan atas pupil)
          _bagian(s, 22.0, 28.7, 1.4, 1.3, Colors.white),
          _bagian(s, 47.4, 28.7, 1.4, 1.3, Colors.white),

          // Kilau mata
          _bagian(s, 23.2, 30.2, 1.4, 1.3, Colors.white),
          _bagian(s, 46.4, 30.2, 1.4, 1.3, Colors.white),

          // Hidung
          _bagian(s, 31.1, 37.3, 7.8, 5.3, _gelap),

          // Pipi
          _bagian(s, 9.5, 38.7, 7.8, 7.5, _pipi),
          _bagian(s, 52.7, 38.7, 7.8, 7.5, _pipi),

          // Mulut (senyum)
          Positioned(
            left: 30.8 * s,
            top: 44.2 * s,
            child: CustomPaint(
              size: Size(8.4 * s, 3.6 * s),
              painter: _Senyum(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis senyum kecil di bawah hidung.
class _Senyum extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final garis = Paint()
      ..color = Warna.gelap
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width / 8).clamp(1.0, 3.0).toDouble()
      ..strokeCap = StrokeCap.round;

    final jalur = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height * 1.6, size.width, 0);
    canvas.drawPath(jalur, garis);
  }

  @override
  bool shouldRepaint(covariant _Senyum lama) => false;
}