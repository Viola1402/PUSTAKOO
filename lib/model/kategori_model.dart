// ==========================================================
// MODEL DATA KELOLA KATEGORI ADMIN PUSTAKOO
// Kelas data murni (tanpa Flutter) agar mudah diuji dan
// dipakai ulang oleh lapisan layanan maupun tampilan.
// ==========================================================

/// Tingkat bacaan yang dipakai untuk distribusi koleksi buku.
enum TingkatBaca {
  pemula('Pemula', 'Usia 3 - 5 Tahun'),
  menengah('Menengah', 'Usia 6 - 10 Tahun'),
  mahir('Mahir', 'Usia 11 - 12 Tahun');

  final String label;
  final String kelompokUsia;

  const TingkatBaca(this.label, this.kelompokUsia);

  /// Menebak tingkat dari isi kolom `tingkat_membaca` pada tabel buku.
  static TingkatBaca dariTeks(String? teks) {
    final n = (teks ?? '').toLowerCase();

    if (n.contains('mahir') || n.contains('lanjut') || n.contains('3')) {
      return mahir;
    }

    if (n.contains('menengah') || n.contains('sedang') || n.contains('2')) {
      return menengah;
    }

    return pemula;
  }
}

/// Kelompok tema yang menentukan ikon dan warna kartu kategori.
enum JenisKategori { dongeng, petualangan, hewan, sains, ceritaRakyat, umum }

/// Satu kategori cerita pada halaman kelola kategori.
class KategoriCerita {
  final int id;
  final String nama;
  final String genre;
  final String deskripsi;
  final int jumlahCerita;
  final JenisKategori jenis;

  const KategoriCerita({
    required this.id,
    required this.nama,
    required this.genre,
    required this.deskripsi,
    required this.jumlahCerita,
    required this.jenis,
  });

  /// Membuat kategori baru dari isian formulir, dipakai saat data
  /// belum tersimpan ke basis data.
  factory KategoriCerita.dariIsian(IsianKategori isian, {int id = 0}) {
    return KategoriCerita(
      id: id,
      nama: isian.nama.trim(),
      genre: isian.genreFinal,
      deskripsi: isian.deskripsi.trim(),
      jumlahCerita: 0,
      jenis: jenisDari(isian.nama),
    );
  }

  KategoriCerita salinDengan({
    String? nama,
    String? genre,
    String? deskripsi,
  }) {
    return KategoriCerita(
      id: id,
      nama: nama ?? this.nama,
      genre: genre ?? this.genre,
      deskripsi: deskripsi ?? this.deskripsi,
      jumlahCerita: jumlahCerita,
      jenis: nama == null ? jenis : jenisDari(nama),
    );
  }

  String get labelJumlah => '$jumlahCerita Cerita terdaftar';

  static JenisKategori jenisDari(String nama) {
    final n = nama.toLowerCase();

    if (n.contains('dongeng') || n.contains('fabel')) {
      return JenisKategori.dongeng;
    }

    if (n.contains('petualangan') || n.contains('petualang')) {
      return JenisKategori.petualangan;
    }

    if (n.contains('hewan') || n.contains('satwa')) {
      return JenisKategori.hewan;
    }

    if (n.contains('sains') || n.contains('stem')) {
      return JenisKategori.sains;
    }

    if (n.contains('rakyat') || n.contains('legenda') || n.contains('budaya')) {
      return JenisKategori.ceritaRakyat;
    }

    return JenisKategori.umum;
  }

  static String genreBawaan(String nama) {
    switch (jenisDari(nama)) {
      case JenisKategori.dongeng:
        return 'Fantasi';
      case JenisKategori.petualangan:
        return 'Eksplorasi';
      case JenisKategori.hewan:
        return 'Fabel Satwa';
      case JenisKategori.sains:
        return 'Edukasi STEM';
      case JenisKategori.ceritaRakyat:
        return 'Budaya Lokal';
      case JenisKategori.umum:
        return 'Kategori Cerita';
    }
  }
}

/// Satu bagian pada diagram distribusi buku per tingkat baca.
class BagianDistribusi {
  final TingkatBaca tingkat;
  final int jumlah;

  const BagianDistribusi({required this.tingkat, required this.jumlah});
}

/// Distribusi koleksi buku berdasarkan tingkat bacaan.
class DistribusiBuku {
  final List<BagianDistribusi> bagian;

  const DistribusiBuku(this.bagian);

  int get total {
    return bagian.fold<int>(0, (jumlah, item) => jumlah + item.jumlah);
  }

  double persentase(BagianDistribusi item) {
    if (total == 0) return 0;
    return (item.jumlah / total) * 100;
  }

  String labelPersentase(BagianDistribusi item) {
    return '${item.tingkat.label}: ${persentase(item).round()}%';
  }
}

/// Seluruh data yang dibutuhkan halaman kelola kategori.
class DataKategori {
  final List<KategoriCerita> kategori;
  final DistribusiBuku distribusi;
  final bool dataContoh;
  final DateTime dimuatPada;

  const DataKategori({
    required this.kategori,
    required this.distribusi,
    required this.dataContoh,
    required this.dimuatPada,
  });

  int get jumlahKategori => kategori.length;

  int get jumlahTingkatBaca => TingkatBaca.values.length;

  int get totalBuku => distribusi.total;

  DataKategori denganKategori(List<KategoriCerita> daftar) {
    return DataKategori(
      kategori: daftar,
      distribusi: distribusi,
      dataContoh: dataContoh,
      dimuatPada: dimuatPada,
    );
  }
}

/// Isian formulir tambah/ubah kategori beserta aturan validasinya.
class IsianKategori {
  final String nama;
  final String genre;
  final String deskripsi;

  const IsianKategori({
    required this.nama,
    this.genre = '',
    this.deskripsi = '',
  });

  bool get valid => nama.trim().isNotEmpty;

  String get genreFinal {
    final teks = genre.trim();
    return teks.isEmpty ? KategoriCerita.genreBawaan(nama) : teks;
  }
}
