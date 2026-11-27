import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/dashboard_model.dart';

// ==========================================================
// LAYANAN DATA DASHBOARD
// Abstraksi DashboardRepository memungkinkan implementasi
// lain (misalnya data tiruan untuk pengujian) tanpa
// mengubah halaman dashboard.
// ==========================================================

abstract class DashboardRepository {
  Future<DataDashboard> muatDashboard();
}

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _klien;

  SupabaseDashboardRepository({SupabaseClient? klien})
      : _klien = klien ?? Supabase.instance.client;

  static const int _hariPekan = 7;
  static const int _batasBaris = 1000;

  @override
  Future<DataDashboard> muatDashboard() async {
    final sekarang = DateTime.now();
    final batasPekan = sekarang.subtract(const Duration(days: _hariPekan));
    final batasDuaPekan =
        sekarang.subtract(const Duration(days: _hariPekan * 2));

    final jumlah = await Future.wait<int>([
      _jumlah('pengguna'),
      _jumlah('anak'),
      _jumlah('buku'),
      _jumlah('riwayat_kuis'),
    ]);

    final tabel = await Future.wait<List<Map<String, dynamic>>>([
      _baris('pengguna', 'id, nama, tanggal_dibuat', urut: 'tanggal_dibuat'),
      _baris('anak', 'id, pengguna_id, nama_panggilan'),
      _baris(
        'buku',
        'id, judul, kategori_id, status, tingkat_membaca, gambar_sampul',
      ),
      _baris('kategori', 'id, nama'),
      _baris('kuis', 'id, buku_id, judul'),
      _baris('misi', 'id, judul'),
      _baris(
        'riwayat_kuis',
        'id, nilai, anak_id, kuis_id, waktu_selesai',
        urut: 'waktu_selesai',
        sejak: batasDuaPekan,
        batas: _batasBaris,
      ),
      _baris(
        'progres_membaca',
        'buku_id, anak_id, status, terakhir_diperbarui',
        urut: 'terakhir_diperbarui',
        batas: _batasBaris,
      ),
      _baris(
        'transaksi_poin',
        'anak_id, jumlah_poin, jenis, keterangan, tanggal_transaksi',
        urut: 'tanggal_transaksi',
        batas: 50,
      ),
      _baris(
        'progres_misi',
        'id, misi_id, anak_id, status, waktu_selesai',
        urut: 'waktu_selesai',
        batas: _batasBaris,
      ),
    ]);

    final pengguna = tabel[0];
    final anak = tabel[1];
    final buku = tabel[2];
    final kategori = tabel[3];
    final kuis = tabel[4];
    final misi = tabel[5];
    final riwayat = tabel[6];
    final progres = tabel[7];
    final transaksi = tabel[8];
    final progresMisi = tabel[9];

    final namaAnak = <String, String>{};
    for (final item in anak) {
      namaAnak[_teks(item['id'], '')] =
          _teks(item['nama_panggilan'], 'Ananda');
    }

    final judulBuku = <String, String>{};
    for (final item in buku) {
      judulBuku[_teks(item['id'], '')] = _teks(item['judul'], 'Tanpa Judul');
    }

    final namaKategori = <String, String>{};
    for (final item in kategori) {
      namaKategori[_teks(item['id'], '')] =
          _teks(item['nama'], 'Tanpa Kategori');
    }

    final bukuKuis = <String, String>{};
    for (final item in kuis) {
      bukuKuis[_teks(item['id'], '')] = _teks(item['buku_id'], '');
    }

    final judulMisi = <String, String>{};
    for (final item in misi) {
      judulMisi[_teks(item['id'], '')] =
          _teks(item['judul'], 'Misi Membaca');
    }

    // ------------------------------------------------------
    // KARTU STATISTIK
    // ------------------------------------------------------

    final penggunaBaru = pengguna.where((item) {
      final waktu = _waktu(item['tanggal_dibuat']);
      return waktu != null && waktu.isAfter(batasPekan);
    }).length;

    final ceritaTerbit = buku.where((item) {
      return _teks(item['status'], '').toLowerCase() == 'diterbitkan';
    }).length;

    final kuisPekanIni = riwayat.where((item) {
      final waktu = _waktu(item['waktu_selesai']);
      return waktu != null && waktu.isAfter(batasPekan);
    }).length;

    final anakAktif = progres
        .where((item) {
          final waktu = _waktu(item['terakhir_diperbarui']);
          return waktu != null && waktu.isAfter(batasPekan);
        })
        .map((item) => _teks(item['anak_id'], ''))
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    final statistik = <StatistikDashboard>[
      StatistikDashboard(
        jenis: JenisStatistik.pengguna,
        judul: 'Total Pengguna',
        nilai: jumlah[0],
        catatan: penggunaBaru == 0
            ? 'Belum ada pengguna baru'
            : '+$penggunaBaru pengguna pekan ini',
      ),
      StatistikDashboard(
        jenis: JenisStatistik.anak,
        judul: 'Total Anak',
        nilai: jumlah[1],
        catatan: anakAktif == 0
            ? 'Belum ada anak aktif pekan ini'
            : '$anakAktif anak aktif pekan ini',
      ),
      StatistikDashboard(
        jenis: JenisStatistik.cerita,
        judul: 'Total Cerita',
        nilai: jumlah[2],
        catatan: '$ceritaTerbit cerita diterbitkan',
      ),
      StatistikDashboard(
        jenis: JenisStatistik.kuis,
        judul: 'Total Kuis Dikerjakan',
        nilai: jumlah[3],
        catatan: '+$kuisPekanIni kuis pekan ini',
      ),
    ];

    // ------------------------------------------------------
    // CERITA POPULER
    // ------------------------------------------------------

    final pembacaBuku = <String, int>{};
    for (final item in progres) {
      final idBuku = _teks(item['buku_id'], '');
      if (idBuku.isEmpty) continue;
      pembacaBuku[idBuku] = (pembacaBuku[idBuku] ?? 0) + 1;
    }

    final nilaiBuku = <String, List<double>>{};
    for (final item in riwayat) {
      final idBuku = bukuKuis[_teks(item['kuis_id'], '')] ?? '';
      if (idBuku.isEmpty) continue;
      nilaiBuku.putIfAbsent(idBuku, () => []).add(_desimal(item['nilai']));
    }

    final daftarCerita = buku.map((item) {
      final id = _teks(item['id'], '');
      final nilai = nilaiBuku[id];
      final rataRata = nilai == null || nilai.isEmpty
          ? null
          : (nilai.reduce((a, b) => a + b) / nilai.length).round();

      return CeritaPopuler(
        judul: judulBuku[id] ?? 'Tanpa Judul',
        kategori:
            namaKategori[_teks(item['kategori_id'], '')] ?? 'Tanpa Kategori',
        level: _teks(item['tingkat_membaca'], 'Belum diatur'),
        pembaca: pembacaBuku[id] ?? 0,
        nilaiKuis: rataRata,
        diterbitkan:
            _teks(item['status'], '').toLowerCase() == 'diterbitkan',
        gambarSampul: _teks(item['gambar_sampul'], ''),
      );
    }).toList()
      ..sort((a, b) => b.pembaca.compareTo(a.pembaca));

    final ceritaPopuler = daftarCerita.take(5).toList();

    // ------------------------------------------------------
    // AKTIVITAS TERBARU
    // ------------------------------------------------------

    final aktivitas = <AktivitasDashboard>[];

    for (final item in progres.take(8)) {
      final idBuku = _teks(item['buku_id'], '');
      if (idBuku.isEmpty) continue;

      aktivitas.add(
        AktivitasMembaca(
          namaAnak: namaAnak[_teks(item['anak_id'], '')] ?? 'Ananda',
          judulBuku: judulBuku[idBuku] ?? 'sebuah cerita',
          selesai: _teks(item['status'], '').toLowerCase() == 'selesai',
          waktu: _waktu(item['terakhir_diperbarui']),
        ),
      );
    }

    for (final item in riwayat.take(8)) {
      aktivitas.add(
        AktivitasKuis(
          namaAnak: namaAnak[_teks(item['anak_id'], '')] ?? 'Ananda',
          nilai: _desimal(item['nilai']).round(),
          waktu: _waktu(item['waktu_selesai']),
        ),
      );
    }

    for (final item in transaksi.take(6)) {
      aktivitas.add(
        AktivitasPoin(
          namaAnak: namaAnak[_teks(item['anak_id'], '')] ?? 'Ananda',
          keterangan: _teks(item['keterangan'], ''),
          waktu: _waktu(item['tanggal_transaksi']),
        ),
      );
    }

    for (final item in progresMisi) {
      if (_teks(item['status'], '').toLowerCase() != 'selesai') continue;

      aktivitas.add(
        AktivitasMisi(
          namaAnak: namaAnak[_teks(item['anak_id'], '')] ?? 'Ananda',
          judulMisi: judulMisi[_teks(item['misi_id'], '')] ?? 'Misi Membaca',
          waktu: _waktu(item['waktu_selesai']),
        ),
      );

      if (aktivitas.whereType<AktivitasMisi>().length >= 4) break;
    }

    for (final item in pengguna.take(3)) {
      aktivitas.add(
        AktivitasPengguna(
          nama: _teks(item['nama'], 'Pengguna'),
          waktu: _waktu(item['tanggal_dibuat']),
        ),
      );
    }

    aktivitas.sort((a, b) {
      if (a.waktu == null) return 1;
      if (b.waktu == null) return -1;
      return b.waktu!.compareTo(a.waktu!);
    });

    final aktivitasTerbaru = aktivitas.take(6).toList();

    // ------------------------------------------------------
    // RINGKASAN LAPORAN PEKAN INI
    // ------------------------------------------------------

    double rataRataAntara(DateTime mulai, DateTime akhir) {
      final nilai = riwayat
          .where((item) {
            final waktu = _waktu(item['waktu_selesai']);
            return waktu != null && waktu.isAfter(mulai) && waktu.isBefore(akhir);
          })
          .map((item) => _desimal(item['nilai']))
          .toList();

      if (nilai.isEmpty) return 0;
      return nilai.reduce((a, b) => a + b) / nilai.length;
    }

    final rataPekanIni = rataRataAntara(
      batasPekan,
      sekarang.add(const Duration(seconds: 1)),
    );
    final rataPekanLalu = rataRataAntara(batasDuaPekan, batasPekan);

    final totalMisi = progresMisi.length;
    final misiSelesai = progresMisi.where((item) {
      return _teks(item['status'], '').toLowerCase() == 'selesai';
    }).length;

    final ringkasan = RingkasanDashboard(
      ceritaTerpopuler: ceritaPopuler.isEmpty
          ? 'Belum ada data'
          : ceritaPopuler.first.judul,
      rataRataKuis: rataPekanIni.round(),
      selisihKuis: (rataPekanIni - rataPekanLalu).round(),
      persentaseMisi:
          totalMisi == 0 ? 0 : ((misiSelesai / totalMisi) * 100).round(),
    );

    return DataDashboard(
      statistik: statistik,
      ceritaPopuler: ceritaPopuler,
      aktivitas: aktivitasTerbaru,
      ringkasan: ringkasan,
      dimuatPada: sekarang,
    );
  }

  // --------------------------------------------------------
  // PEMBANTU AKSES DATA
  // --------------------------------------------------------

  Future<int> _jumlah(String tabel) async {
    try {
      return await _klien.from(tabel).count(CountOption.exact);
    } catch (error) {
      debugPrint('Dashboard: gagal menghitung $tabel ($error)');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _baris(
    String tabel,
    String kolom, {
    String? urut,
    DateTime? sejak,
    int batas = 500,
  }) async {
    try {
      var penyaring = _klien.from(tabel).select(kolom);

      if (sejak != null && urut != null) {
        penyaring = penyaring.gte(urut, sejak.toIso8601String());
      }

      final data = urut == null
          ? await penyaring.limit(batas)
          : await penyaring
              .order(urut, ascending: false)
              .limit(batas);

      return List<Map<String, dynamic>>.from(data);
    } catch (error) {
      debugPrint('Dashboard: gagal membaca $tabel ($error)');
      return [];
    }
  }
}

// ==========================================================
// PEMBANTU KONVERSI NILAI DINAMIS
// ==========================================================

String _teks(dynamic nilai, [String nilaiAwal = '-']) {
  if (nilai == null) return nilaiAwal;
  final hasil = nilai.toString().trim();
  return hasil.isEmpty ? nilaiAwal : hasil;
}

double _desimal(dynamic nilai) {
  if (nilai is num) return nilai.toDouble();
  return double.tryParse(nilai?.toString() ?? '') ?? 0;
}

DateTime? _waktu(dynamic nilai) {
  if (nilai == null) return null;
  return DateTime.tryParse(nilai.toString());
}
