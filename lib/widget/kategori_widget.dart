import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';
import '../model/kategori_model.dart';

// ==========================================================
// IKON KATEGORI BERDASARKAN NAMA
// ==========================================================

IconData ikonKategori(String nama) {
  final kategori = nama.toLowerCase();

  if (kategori.contains('hewan')) {
    return Icons.pets;
  } else if (kategori.contains('alam')) {
    return Icons.eco;
  } else if (kategori.contains('dongeng')) {
    return Icons.auto_stories;
  } else if (kategori.contains('sains')) {
    return Icons.science;
  } else if (kategori.contains('sejarah') || kategori.contains('rakyat')) {
    return Icons.account_balance;
  } else if (kategori.contains('petualangan')) {
    return Icons.explore;
  } else if (kategori.contains('persahabatan')) {
    return Icons.people;
  } else if (kategori.contains('pendidikan')) {
    return Icons.school;
  }

  return Icons.menu_book;
}

// ==========================================================
// JUDUL HALAMAN
// ==========================================================

class JudulKategori extends StatelessWidget {
  final VoidCallback onTambah;

  const JudulKategori({
    super.key,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    const judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Kategori',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: GayaAdmin.biruTua,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Kelola kategori cerita, genre bacaan, dan klasifikasi '
          'koleksi buku anak.',
          style: TextStyle(
            fontSize: 13,
            color: GayaAdmin.teksAbu,
            height: 1.5,
          ),
        ),
      ],
    );

    final aksi = TombolAdmin(
      teks: 'Tambah Kategori Baru',
      ikon: Icons.add,
      onPressed: onTambah,
    );

    return LayoutBuilder(
      builder: (context, ukuran) {
        if (ukuran.maxWidth > 780) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: judul),
              const SizedBox(width: 15),
              aksi,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            judul,
            const SizedBox(height: 14),
            aksi,
          ],
        );
      },
    );
  }
}

// ==========================================================
// KEPALA BAGIAN KATEGORI
// ==========================================================

class KepalaBagianKategori extends StatelessWidget {
  final int jumlahKategori;

  const KepalaBagianKategori({
    super.key,
    required this.jumlahKategori,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.account_tree_outlined,
            size: 23,
            color: GayaAdmin.biruTua,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Cerita',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Daftar kategori dan genre buku anak',
                style: TextStyle(
                  fontSize: 12,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ],
          ),
        ),
        ChipAdmin(
          '$jumlahKategori Kategori',
        ),
      ],
    );
  }
}

// ==========================================================
// KISI KATEGORI
// ==========================================================

class KisiKategori extends StatelessWidget {
  final List<KategoriCerita> kategori;
  final ValueChanged<KategoriCerita> onUbah;
  final ValueChanged<KategoriCerita> onHapus;

  const KisiKategori({
    super.key,
    required this.kategori,
    required this.onUbah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    if (kategori.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(45),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: GayaAdmin.garis),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 52,
              color: GayaAdmin.teksAbu,
            ),
            SizedBox(height: 14),
            Text(
              'Belum Ada Kategori',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Tambahkan kategori baru untuk mengelompokkan cerita.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, ukuran) {
        final kolom = ukuran.maxWidth > 1100
            ? 3
            : ukuran.maxWidth > 600
                ? 2
                : 1;

        const celah = 18.0;
        final lebar = (ukuran.maxWidth - celah * (kolom - 1)) / kolom;

        return Wrap(
          spacing: celah,
          runSpacing: celah,
          children: [
            for (final item in kategori)
              SizedBox(
                width: lebar,
                height: 255,
                child: KartuKategoriCerita(
                  kategori: item,
                  onUbah: () => onUbah(item),
                  onHapus: () => onHapus(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ==========================================================
// KARTU KATEGORI
// ==========================================================

class KartuKategoriCerita extends StatelessWidget {
  final KategoriCerita kategori;
  final VoidCallback onUbah;
  final VoidCallback onHapus;

  const KartuKategoriCerita({
    super.key,
    required this.kategori,
    required this.onUbah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final gaya = _GayaKategori.dari(kategori.jenis);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: GayaAdmin.garis,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IKON DAN TOMBOL
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: gaya.latar,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  ikonKategori(kategori.nama),
                  size: 31,
                  color: gaya.warna,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Ubah kategori',
                onPressed: onUbah,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 22,
                  color: GayaAdmin.biru,
                ),
              ),
              IconButton(
                tooltip: 'Hapus kategori',
                onPressed: onHapus,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 22,
                  color: GayaAdmin.merah,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // NAMA KATEGORI
          Text(
            kategori.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),

          const SizedBox(height: 8),

          // GENRE
          ChipAdmin(
            kategori.genre,
            kecil: false,
            warna: gaya.latar,
            teksWarna: gaya.warna,
          ),

          const SizedBox(height: 10),

          // DESKRIPSI
          Expanded(
            child: Text(
              kategori.deskripsi.isEmpty
                  ? 'Belum ada deskripsi kategori.'
                  : kategori.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ),

          const Divider(
            height: 18,
            color: GayaAdmin.garis,
          ),

          // JUMLAH CERITA
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: GayaAdmin.teksAbu,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  kategori.labelJumlah,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onUbah,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                ),
                label: const Text('Ubah'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GayaAdmin.biruTua,
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: GayaAdmin.garis,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              OutlinedButton.icon(
                onPressed: onHapus,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 15,
                ),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GayaAdmin.merah,
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFFF3CACA),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
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

// ==========================================================
// GAYA KATEGORI
// ==========================================================

class _GayaKategori {
  final Color latar;
  final Color warna;
  final IconData ikon;

  const _GayaKategori(
    this.latar,
    this.warna,
    this.ikon,
  );

  static _GayaKategori dari(JenisKategori jenis) {
    switch (jenis) {
      case JenisKategori.dongeng:
        return const _GayaKategori(
          Color(0xFFFDEBEF),
          Color(0xFFD46A7E),
          Icons.auto_stories,
        );

      case JenisKategori.petualangan:
        return const _GayaKategori(
          Color(0xFFFDF3E3),
          Color(0xFFC0781A),
          Icons.explore,
        );

      case JenisKategori.hewan:
        return const _GayaKategori(
          Color(0xFFE9F1FD),
          Color(0xFF4A7BD0),
          Icons.pets,
        );

      case JenisKategori.sains:
        return const _GayaKategori(
          Color(0xFFEAF6EE),
          Color(0xFF4A8A3A),
          Icons.science,
        );

      case JenisKategori.ceritaRakyat:
        return const _GayaKategori(
          Color(0xFFEEEBFB),
          Color(0xFF6C5BC4),
          Icons.account_balance,
        );

      case JenisKategori.umum:
        return const _GayaKategori(
          GayaAdmin.biruMuda,
          GayaAdmin.biru,
          Icons.menu_book,
        );
    }
  }
}
