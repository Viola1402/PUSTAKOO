// ==========================================================
// MODEL DATA KELOLA PENGGUNA ADMIN PUSTAKOO
// Kelas data murni (tanpa Flutter) agar mudah diuji dan
// dipakai ulang oleh lapisan layanan maupun tampilan.
// ==========================================================

/// Status keaktifan akun orang tua.
enum StatusAkun {
  aktif('Aktif'),
  nonaktif('Nonaktif');

  final String label;

  const StatusAkun(this.label);
}

/// Kelompok tab penyaring pada halaman kelola pengguna.
enum KelompokPengguna {
  semua('Semua Pengguna'),
  aktif('Orang Tua Aktif'),
  baruPekanIni('Akun Baru Pekan Ini'),
  nonaktif('Akun Nonaktif');

  final String label;

  const KelompokPengguna(this.label);
}

/// Rentang usia anak untuk dropdown filter.
enum RentangUsia {
  semua('Semua Usia', 0, null),
  praSekolah('3 - 5 Tahun', 3, 5),
  anak('6 - 10 Tahun', 6, 10),
  besar('11 - 12 Tahun', 11, 12);

  final String label;
  final int minimum;
  final int? maksimum;

  const RentangUsia(this.label, this.minimum, this.maksimum);

  bool cocok(int usia) {
    final batas = maksimum;
    return usia >= minimum && (batas == null || usia <= batas);
  }
}

/// Penyaring status langganan.
enum FilterLangganan {
  semua('Semua Status'),
  premium('Premium'),
  gratis('Gratis');

  final String label;

  const FilterLangganan(this.label);
}

/// Urutan daftar pengguna.
enum UrutanPengguna {
  aktivitasTerbaru('Aktivitas Terbaru'),
  namaAZ('Nama A-Z'),
  koinTerbanyak('Koin Terbanyak');

  final String label;

  const UrutanPengguna(this.label);
}

/// Jenis kartu statistik pada bagian atas halaman.
enum JenisStatistikPengguna { akunOrangTua, profilAnak, akunMembaca, totalKoin }

/// Profil anak yang terdaftar pada satu akun orang tua.
class ProfilAnak {
  final String nama;
  final int usia;
  final String level;

  const ProfilAnak({
    required this.nama,
    required this.usia,
    required this.level,
  });

  String get label => '$nama ($usia Thn)';

  bool beradaPada(RentangUsia rentang) => rentang.cocok(usia);
}

/// Satu baris pengguna pada tabel kelola pengguna.
class BarisPengguna {
  final String nama;
  final String email;
  final String bergabung;
  final List<ProfilAnak> anak;
  final int koin;
  final String aktivitas;
  final String waktuAktivitas;
  final StatusAkun status;
  final String paket;
  final bool terdaftarPekanIni;

  /// Perkiraan umur aktivitas dalam menit, dipakai untuk pengurutan.
  final int menitAktivitas;

  const BarisPengguna({
    required this.nama,
    required this.email,
    required this.bergabung,
    required this.anak,
    required this.koin,
    required this.aktivitas,
    required this.waktuAktivitas,
    required this.status,
    required this.paket,
    this.terdaftarPekanIni = false,
    this.menitAktivitas = 0,
  });

  /// Inisial nama tanpa sapaan, mis. "Bunda Sari Pertiwi" -> "SP".
  String get inisial {
    final bagian = nama
        .replaceAll(RegExp(r'^(Bunda|Ayah|Ibu)\s+'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((teks) => teks.isNotEmpty)
        .take(2)
        .map((teks) => teks[0].toUpperCase());

    return bagian.isEmpty ? '?' : bagian.join();
  }

  int get jumlahAnak => anak.length;

  String get ringkasanAnak {
    if (anak.isEmpty) return 'Belum ada profil anak';
    return anak.map((item) => item.label).join(' • ');
  }

  bool get premium => paket.toLowerCase().contains('premium');

  bool get gratis => paket.toLowerCase().contains('gratis');

  bool cocokPencarian(String kunci) {
    if (kunci.isEmpty) return true;

    final teks = kunci.toLowerCase();
    if (nama.toLowerCase().contains(teks)) return true;
    if (email.toLowerCase().contains(teks)) return true;

    return anak.any((item) => item.nama.toLowerCase().contains(teks));
  }
}

/// Kumpulan kriteria penyaringan yang diterapkan sekaligus.
class FilterPengguna {
  final String pencarian;
  final KelompokPengguna kelompok;
  final RentangUsia usia;
  final FilterLangganan langganan;
  final UrutanPengguna urutan;

  const FilterPengguna({
    this.pencarian = '',
    this.kelompok = KelompokPengguna.semua,
    this.usia = RentangUsia.semua,
    this.langganan = FilterLangganan.semua,
    this.urutan = UrutanPengguna.aktivitasTerbaru,
  });

  FilterPengguna salin({
    String? pencarian,
    KelompokPengguna? kelompok,
    RentangUsia? usia,
    FilterLangganan? langganan,
    UrutanPengguna? urutan,
  }) {
    return FilterPengguna(
      pencarian: pencarian ?? this.pencarian,
      kelompok: kelompok ?? this.kelompok,
      usia: usia ?? this.usia,
      langganan: langganan ?? this.langganan,
      urutan: urutan ?? this.urutan,
    );
  }

  List<BarisPengguna> terapkan(List<BarisPengguna> data) {
    final hasil = data.where(_cocok).toList();

    switch (urutan) {
      case UrutanPengguna.namaAZ:
        hasil.sort((a, b) => a.nama.compareTo(b.nama));
      case UrutanPengguna.koinTerbanyak:
        hasil.sort((a, b) => b.koin.compareTo(a.koin));
      case UrutanPengguna.aktivitasTerbaru:
        hasil.sort((a, b) => a.menitAktivitas.compareTo(b.menitAktivitas));
    }

    return hasil;
  }

  bool _cocok(BarisPengguna item) {
    if (!item.cocokPencarian(pencarian.trim())) return false;

    final cocokKelompok = switch (kelompok) {
      KelompokPengguna.semua => true,
      KelompokPengguna.aktif => item.status == StatusAkun.aktif,
      KelompokPengguna.baruPekanIni => item.terdaftarPekanIni,
      KelompokPengguna.nonaktif => item.status == StatusAkun.nonaktif,
    };
    if (!cocokKelompok) return false;

    if (usia != RentangUsia.semua &&
        !item.anak.any((anak) => anak.beradaPada(usia))) {
      return false;
    }

    return switch (langganan) {
      FilterLangganan.semua => true,
      FilterLangganan.premium => item.premium,
      FilterLangganan.gratis => item.gratis,
    };
  }
}

/// Angka ringkasan yang tampil pada kartu statistik dan tab.
class RingkasanPengguna {
  final int totalAkun;
  final int akunAktif;
  final int akunBaruPekanIni;
  final int akunNonaktif;
  final int profilAnak;
  final int akunMembaca;
  final int totalKoin;

  /// Persentase akun yang membaca cerita pekan ini.
  final double persenMembaca;

  /// Pertumbuhan akun dibanding bulan lalu, dalam persen.
  final int persenPertumbuhan;

  const RingkasanPengguna({
    required this.totalAkun,
    required this.akunAktif,
    required this.akunBaruPekanIni,
    required this.akunNonaktif,
    required this.profilAnak,
    required this.akunMembaca,
    required this.totalKoin,
    required this.persenMembaca,
    required this.persenPertumbuhan,
  });

  int hitung(KelompokPengguna kelompok) {
    return switch (kelompok) {
      KelompokPengguna.semua => totalAkun,
      KelompokPengguna.aktif => akunAktif,
      KelompokPengguna.baruPekanIni => akunBaruPekanIni,
      KelompokPengguna.nonaktif => akunNonaktif,
    };
  }

  double get rataAnakPerKeluarga =>
      totalAkun == 0 ? 0 : profilAnak / totalAkun;
}

/// Satu kartu statistik pada halaman kelola pengguna.
class StatistikPengguna {
  final JenisStatistikPengguna jenis;
  final String judul;
  final int nilai;
  final String satuan;
  final String catatan;

  /// Label kecil berwarna hijau, mis. "+12%".
  final String? penanda;

  /// Nilai progres 0..1 bila kartu menampilkan bilah kemajuan.
  final double? progres;

  const StatistikPengguna({
    required this.jenis,
    required this.judul,
    required this.nilai,
    required this.satuan,
    required this.catatan,
    this.penanda,
    this.progres,
  });
}

/// Seluruh data yang dibutuhkan halaman kelola pengguna.
class DataPengguna {
  final List<BarisPengguna> pengguna;
  final RingkasanPengguna ringkasan;
  final DateTime dimuatPada;

  const DataPengguna({
    required this.pengguna,
    required this.ringkasan,
    required this.dimuatPada,
  });

  List<StatistikPengguna> get statistik {
    final r = ringkasan;

    return [
      StatistikPengguna(
        jenis: JenisStatistikPengguna.akunOrangTua,
        judul: 'Total Akun Orang Tua',
        nilai: r.totalAkun,
        satuan: 'Akun',
        catatan: 'dibandingkan bulan lalu',
        penanda: '+${r.persenPertumbuhan}%',
      ),
      StatistikPengguna(
        jenis: JenisStatistikPengguna.profilAnak,
        judul: 'Total Profil Anak Aktif',
        nilai: r.profilAnak,
        satuan: 'Anak',
        catatan:
            'Rata-rata ${r.rataAnakPerKeluarga.toStringAsFixed(1).replaceAll('.', ',')} anak per keluarga',
      ),
      StatistikPengguna(
        jenis: JenisStatistikPengguna.akunMembaca,
        judul: 'Akun Membaca Aktif',
        nilai: r.akunMembaca,
        satuan: 'Akun',
        catatan:
            '${r.persenMembaca.toStringAsFixed(1).replaceAll('.', ',')}% pekan ini',
        progres: r.persenMembaca / 100,
      ),
      StatistikPengguna(
        jenis: JenisStatistikPengguna.totalKoin,
        judul: 'Total Koin Beredar',
        nilai: r.totalKoin,
        satuan: 'Koin',
        catatan: 'Tabungan hadiah anak: Misi & Kuis',
      ),
    ];
  }
}
