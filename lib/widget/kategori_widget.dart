import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';
import '../model/kategori_model.dart';

// ==========================================================
// KOMPONEN TAMPILAN KELOLA KATEGORI
// Setiap bagian halaman dibuat sebagai kelas widget sendiri
// agar halaman utama tetap ringkas dan mudah dirawat.
// ==========================================================

// ==========================================================
// JUDUL HALAMAN
// ==========================================================

class JudulKategori extends StatelessWidget {
  final int jumlahTingkat;
  final VoidCallback onTambah;
  final VoidCallback onLihatTingkat;

  const JudulKategori({
    super.key,
    required this.jumlahTingkat,
    required this.onTambah,
    required this.onLihatTingkat,
  });

  @override
  Widget build(BuildContext context) {
    const judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Kategori',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: GayaAdmin.biruTua,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Kelola taksonomi cerita perpustakaan digital anak, genre '
          'bacaan, dan klasifikasi kelompok usia untuk sinkronisasi '
          'kurikulum bacaan.',
          style: TextStyle(
            fontSize: 11,
            color: GayaAdmin.teksAbu,
            height: 1.45,
          ),
        ),
      ],
    );

    final aksi = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChipTingkat(
          jumlah: jumlahTingkat,
          onTap: onLihatTingkat,
        ),
        const SizedBox(width: 8),
        TombolAdmin(
          teks: 'Tambah Kategori Baru',
          ikon: Icons.add,
          onPressed: onTambah,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, ukuran) {
        if (ukuran.maxWidth > 780) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: judul),
              const SizedBox(width: 12),
              aksi,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            judul,
            const SizedBox(height: 10),
            aksi,
          ],
        );
      },
    );
  }
}

class _ChipTingkat extends StatelessWidget {
  final int jumlah;
  final VoidCallback onTap;

  const _ChipTingkat({required this.jumlah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GayaAdmin.garis),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: GayaAdmin.biru,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$jumlah Tingkat Baca',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// KEPALA BAGIAN KATEGORI
// ==========================================================

class KepalaBagianKategori extends StatelessWidget {
  final int jumlahKategori;

  const KepalaBagianKategori({super.key, required this.jumlahKategori});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: GayaAdmin.biruTua,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Cerita',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Klasifikasi tema dan genre buku anak',
                style: TextStyle(
                  fontSize: 9.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ],
          ),
        ),
        ChipAdmin('$jumlahKategori Kategori'),
      ],
    );
  }
}

// ==========================================================
// KISI KARTU KATEGORI
// ==========================================================

class KisiKategori extends StatelessWidget {
  final List<KategoriCerita> kategori;
  final ValueChanged<KategoriCerita> onUbah;
  final VoidCallback onTambah;

  const KisiKategori({
    super.key,
    required this.kategori,
    required this.onUbah,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final kolom = ukuran.maxWidth > 740 ? 2 : 1;
        const celah = 12.0;
        final lebar = (ukuran.maxWidth - celah * (kolom - 1)) / kolom;

        return Wrap(
          spacing: celah,
          runSpacing: celah,
          children: [
            for (final item in kategori)
              SizedBox(
                width: lebar,
                height: 188,
                child: KartuKategoriCerita(
                  kategori: item,
                  onUbah: () => onUbah(item),
                ),
              ),
            SizedBox(
              width: lebar,
              height: 188,
              child: KartuTambahKategori(onTap: onTambah),
            ),
          ],
        );
      },
    );
  }
}

class KartuKategoriCerita extends StatelessWidget {
  final KategoriCerita kategori;
  final VoidCallback onUbah;

  const KartuKategoriCerita({
    super.key,
    required this.kategori,
    required this.onUbah,
  });

  @override
  Widget build(BuildContext context) {
    final gaya = _GayaKategori.dari(kategori.jenis);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: gaya.latar,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(gaya.ikon, size: 18, color: gaya.warna),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kategori.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: GayaAdmin.biruTua,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ChipAdmin(
                      kategori.genre,
                      kecil: true,
                      warna: gaya.latar,
                      teksWarna: gaya.warna,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            kategori.deskripsi.isEmpty
                ? 'Belum ada deskripsi kategori.'
                : kategori.deskripsi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              color: GayaAdmin.teksAbu,
            ),
          ),
          const Spacer(),
          const Divider(height: 1, color: GayaAdmin.garis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 12,
                color: GayaAdmin.teksAbu,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  kategori.labelJumlah,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onUbah,
                icon: const Icon(Icons.edit_outlined, size: 12),
                label: const Text('Ubah'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GayaAdmin.biruTua,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: GayaAdmin.garis),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KartuTambahKategori extends StatelessWidget {
  final VoidCallback onTap;

  const KartuTambahKategori({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBFCFE),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: onTap,
        child: const CustomPaint(
          painter: _GarisPutusPainter(Color(0xFFCBD5E1)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 26,
                  color: GayaAdmin.biruTua,
                ),
                SizedBox(height: 8),
                Text(
                  'Tambah Kategori Baru',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Buat klasifikasi genre atau tema bacaan baru',
                  style: TextStyle(
                    fontSize: 9,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  final Color warna;

  const _GarisPutusPainter(this.warna);

  @override
  void paint(Canvas canvas, Size size) {
    final kuas = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final jalur = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
          const Radius.circular(11),
        ),
      );

    const panjangGaris = 5.0;
    const jarak = 4.0;

    for (final ukur in jalur.computeMetrics()) {
      var posisi = 0.0;

      while (posisi < ukur.length) {
        final akhir = math.min(posisi + panjangGaris, ukur.length);
        canvas.drawPath(ukur.extractPath(posisi, akhir), kuas);
        posisi += panjangGaris + jarak;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GarisPutusPainter oldDelegate) {
    return oldDelegate.warna != warna;
  }
}

class _GayaKategori {
  final Color latar;
  final Color warna;
  final IconData ikon;

  const _GayaKategori(this.latar, this.warna, this.ikon);

  static _GayaKategori dari(JenisKategori jenis) {
    switch (jenis) {
      case JenisKategori.dongeng:
        return const _GayaKategori(
          Color(0xFFFDEBEF),
          Color(0xFFD46A7E),
          Icons.auto_awesome_outlined,
        );
      case JenisKategori.petualangan:
        return const _GayaKategori(
          Color(0xFFFDF3E3),
          Color(0xFFC0781A),
          Icons.explore_outlined,
        );
      case JenisKategori.hewan:
        return const _GayaKategori(
          Color(0xFFE9F1FD),
          Color(0xFF4A7BD0),
          Icons.pets_outlined,
        );
      case JenisKategori.sains:
        return const _GayaKategori(
          Color(0xFFEAF6EE),
          Color(0xFF4A8A3A),
          Icons.science_outlined,
        );
      case JenisKategori.ceritaRakyat:
        return const _GayaKategori(
          Color(0xFFEEEBFB),
          Color(0xFF6C5BC4),
          Icons.account_balance_outlined,
        );
      case JenisKategori.umum:
        return const _GayaKategori(
          GayaAdmin.biruMuda,
          GayaAdmin.biru,
          Icons.menu_book_outlined,
        );
    }
  }
}

// ==========================================================
// KARTU DISTRIBUSI BUKU
// ==========================================================

class KartuDistribusiKategori extends StatelessWidget {
  final DistribusiBuku distribusi;
  final VoidCallback onLihatKatalog;

  const KartuDistribusiKategori({
    super.key,
    required this.distribusi,
    required this.onLihatKatalog,
  });

  static const List<Color> _warna = [
    Color(0xFF4B9FD4),
    Color(0xFF2E6B96),
    Color(0xFFE9BD62),
  ];

  @override
  Widget build(BuildContext context) {
    final kiri = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bar_chart,
            size: 20,
            color: GayaAdmin.biruTua,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Buku Berdasarkan Tingkat',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Total ${distribusi.total} judul buku aktif terdaftar '
                'dalam sistem katalog saat ini.',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;
          final grafik = _grafik();

          final katalog = TextButton(
            onPressed: onLihatKatalog,
            style: TextButton.styleFrom(
              foregroundColor: GayaAdmin.biruTua,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Lihat Katalog →'),
          );

          if (lebar > 780) {
            return Row(
              children: [
                Expanded(flex: 4, child: kiri),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: grafik),
                const SizedBox(width: 6),
                katalog,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kiri,
              const SizedBox(height: 12),
              grafik,
              Align(alignment: Alignment.centerRight, child: katalog),
            ],
          );
        },
      ),
    );
  }

  Widget _grafik() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (var i = 0; i < distribusi.bagian.length; i++)
              _Legenda(
                warna: _warna[i % _warna.length],
                teks: distribusi.labelPersentase(distribusi.bagian[i]),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (var i = 0; i < distribusi.bagian.length; i++)
                  Expanded(
                    flex: distribusi.bagian[i].jumlah == 0
                        ? 1
                        : distribusi.bagian[i].jumlah,
                    child: Container(color: _warna[i % _warna.length]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color warna;
  final String teks;

  const _Legenda({required this.warna, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          teks,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: GayaAdmin.teksAbu,
          ),
        ),
      ],
    );
  }
}
