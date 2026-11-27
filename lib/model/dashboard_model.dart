// ==========================================================
// MODEL DATA DASHBOARD ADMIN PUSTAKOO
// Berisi kelas data murni (tanpa Flutter) agar mudah diuji
// dan dipakai ulang oleh lapisan layanan maupun tampilan.
// ==========================================================

/// Jenis kartu ringkasan pada bagian atas dashboard.
enum JenisStatistik { pengguna, anak, cerita, kuis }

/// Jenis aktivitas yang tampil pada panel "Aktivitas Terbaru".
enum JenisAktivitas { membaca, kuis, poin, misi, pengguna }

/// Satu kartu statistik pada dashboard.
class StatistikDashboard {
  final JenisStatistik jenis;
  final String judul;
  final int nilai;
  final String catatan;

  const StatistikDashboard({
    required this.jenis,
    required this.judul,
    required this.nilai,
    required this.catatan,
  });
}

/// Satu baris pada tabel "Cerita Populer".
class CeritaPopuler {
  final String judul;
  final String kategori;
  final String level;
  final int pembaca;
  final int? nilaiKuis;
  final bool diterbitkan;
  final String? gambarSampul;

  const CeritaPopuler({
    required this.judul,
    required this.kategori,
    required this.level,
    required this.pembaca,
    required this.nilaiKuis,
    required this.diterbitkan,
    this.gambarSampul,
  });

  bool get lulus => (nilaiKuis ?? 0) >= 75;

  String get nilaiLabel => nilaiKuis == null ? '-' : '$nilaiKuis%';

  String get statusLabel => diterbitkan ? 'Diterbitkan' : 'Draf';

  String get subjudul => '$kategori • $level';
}

/// Kelas dasar aktivitas. Subclass wajib menyediakan judul,
/// label, dan jenisnya sendiri (polimorfisme).
abstract class AktivitasDashboard {
  final DateTime? waktu;

  const AktivitasDashboard({this.waktu});

  String get judul;

  String get label;

  JenisAktivitas get jenis;
}

class AktivitasMembaca extends AktivitasDashboard {
  final String namaAnak;
  final String judulBuku;
  final bool selesai;

  const AktivitasMembaca({
    required this.namaAnak,
    required this.judulBuku,
    required this.selesai,
    super.waktu,
  });

  @override
  String get judul =>
      '$namaAnak ${selesai ? 'menyelesaikan' : 'sedang membaca'} "$judulBuku"';

  @override
  String get label => selesai ? 'Selesai' : 'Membaca';

  @override
  JenisAktivitas get jenis => JenisAktivitas.membaca;
}

class AktivitasKuis extends AktivitasDashboard {
  final String namaAnak;
  final int nilai;

  const AktivitasKuis({
    required this.namaAnak,
    required this.nilai,
    super.waktu,
  });

  @override
  String get judul => '$namaAnak menyelesaikan kuis dengan nilai $nilai';

  @override
  String get label => 'Kuis';

  @override
  JenisAktivitas get jenis => JenisAktivitas.kuis;
}

class AktivitasPoin extends AktivitasDashboard {
  final String namaAnak;
  final String keterangan;

  const AktivitasPoin({
    required this.namaAnak,
    required this.keterangan,
    super.waktu,
  });

  @override
  String get judul =>
      keterangan.isEmpty ? '$namaAnak melakukan transaksi poin' : keterangan;

  @override
  String get label => 'Poin';

  @override
  JenisAktivitas get jenis => JenisAktivitas.poin;
}

class AktivitasMisi extends AktivitasDashboard {
  final String namaAnak;
  final String judulMisi;

  const AktivitasMisi({
    required this.namaAnak,
    required this.judulMisi,
    super.waktu,
  });

  @override
  String get judul => '$namaAnak menyelesaikan misi "$judulMisi"';

  @override
  String get label => 'Misi';

  @override
  JenisAktivitas get jenis => JenisAktivitas.misi;
}

class AktivitasPengguna extends AktivitasDashboard {
  final String nama;

  const AktivitasPengguna({required this.nama, super.waktu});

  @override
  String get judul => '$nama mendaftar sebagai orang tua';

  @override
  String get label => 'Registrasi';

  @override
  JenisAktivitas get jenis => JenisAktivitas.pengguna;
}

/// Ringkasan laporan pekan ini.
class RingkasanDashboard {
  final String ceritaTerpopuler;
  final int rataRataKuis;
  final int selisihKuis;
  final int persentaseMisi;

  const RingkasanDashboard({
    required this.ceritaTerpopuler,
    required this.rataRataKuis,
    required this.selisihKuis,
    required this.persentaseMisi,
  });

  String get selisihLabel {
    if (selisihKuis == 0) return 'stabil dari pekan lalu';
    final tanda = selisihKuis > 0 ? '+' : '';
    return '$tanda$selisihKuis poin dari pekan lalu';
  }
}

/// Kumpulan seluruh data yang dibutuhkan dashboard.
class DataDashboard {
  final List<StatistikDashboard> statistik;
  final List<CeritaPopuler> ceritaPopuler;
  final List<AktivitasDashboard> aktivitas;
  final RingkasanDashboard ringkasan;
  final DateTime dimuatPada;

  const DataDashboard({
    required this.statistik,
    required this.ceritaPopuler,
    required this.aktivitas,
    required this.ringkasan,
    required this.dimuatPada,
  });

  int nilaiStatistik(JenisStatistik jenis) {
    for (final item in statistik) {
      if (item.jenis == jenis) return item.nilai;
    }
    return 0;
  }
}
