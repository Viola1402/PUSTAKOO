/// Kelas data untuk fitur Progres Belajar.
/// Materi yang ditunjukkan: OOP, enkapsulasi, dan constructor.

/// OOP: satu titik nilai kuis dibungkus menjadi satu objek
/// (percobaan ke-berapa dan nilainya).
class TitikSkor {
  // ENKAPSULASI: field dibuat private (diawali _), hanya bisa dibaca
  // lewat getter, jadi nilainya tidak bisa diubah sembarangan dari luar.
  final int _ke;
  final double _nilai;

  // CONSTRUCTOR biasa, sekalian memvalidasi nilai supaya selalu 0 sampai 100.
  TitikSkor(this._ke, double nilai)
      : _nilai = nilai < 0 ? 0.0 : (nilai > 100 ? 100.0 : nilai);

  // NAMED CONSTRUCTOR: membuat objek langsung dari satu baris database.
  TitikSkor.dariJson(Map<String, dynamic> json)
      : this(json['percobaan_ke'] as int, (json['nilai'] as num).toDouble());

  int get ke => _ke;
  double get nilai => _nilai;
}

/// OOP: satu buku yang sudah selesai dibaca.
class BukuSelesai {
  // ENKAPSULASI: field private.
  final String _judul;
  final String _kategori;

  // CONSTRUCTOR biasa.
  BukuSelesai(this._judul, this._kategori);

  // FACTORY CONSTRUCTOR: membangun objek dari data database
  // (termasuk data kategori yang bersarang di dalamnya).
  factory BukuSelesai.dariJson(Map<String, dynamic> json) {
    final kategori = json['kategori'];
    final nama = kategori is Map ? (kategori['nama'] as String? ?? '') : '';
    return BukuSelesai(json['judul'] as String, nama);
  }

  String get judul => _judul;
  String get hurufAwal => _judul.isEmpty ? '?' : _judul[0].toUpperCase();
  String get keterangan => _kategori.isEmpty ? 'Selesai dibaca' : _kategori;
}

/// OOP: riwayat nilai satu kuis dari beberapa percobaan.
class RiwayatKuis {
  // ENKAPSULASI: judul dan daftar nilai private. Daftar nilai hanya bisa
  // ditambah lewat method tambah(), tidak bisa diubah langsung dari luar.
  final String _judul;
  final List<TitikSkor> _titik = [];

  // CONSTRUCTOR: judul dibersihkan dulu dari awalan "Kuis ".
  RiwayatKuis(String judulKuis)
      : _judul = judulKuis.replaceFirst(RegExp(r'^Kuis\s+'), '');

  String get judul => _judul;

  /// Menambah satu percobaan, lalu mengurutkan berdasarkan nomor percobaan.
  void tambah(TitikSkor titik) {
    _titik.add(titik);
    _titik.sort((a, b) => a.ke.compareTo(b.ke));
  }

  // Yang keluar hanya salinan yang tidak bisa diubah.
  List<TitikSkor> get titik => List.unmodifiable(_titik);

  List<TitikSkor> terakhir(int jumlah) {
    if (_titik.length <= jumlah) return titik;
    return List.unmodifiable(_titik.sublist(_titik.length - jumlah));
  }

  int get selisih {
    if (_titik.length < 2) return 0;
    return (_titik.last.nilai - _titik.first.nilai).round();
  }

  String get keterangan {
    if (_titik.length < 2) return 'Baru satu kali percobaan.';
    final s = selisih;
    if (s > 0) return 'Nilai naik $s dari percobaan pertama.';
    if (s < 0) return 'Nilai turun ${-s} dari percobaan pertama.';
    return 'Nilai sama dengan percobaan pertama.';
  }
}