import 'package:supabase_flutter/supabase_flutter.dart';

import 'konversi_json.dart';
import 'model_anak.dart';
import 'model_buku.dart';
import 'model_kategori.dart';
import 'model_misi.dart';

/// HASIL PEMERIKSAAN jumlah halaman tiap buku.
///
/// Tujuannya memisahkan tiga keadaan yang sering tertukar:
/// - buku punya halaman  -> [untukBuku] mengembalikan angka > 0,
/// - query berhasil tetapi buku tidak punya baris halaman -> 0,
/// - query gagal / hasil belum bisa dipercaya -> null (belum diketahui).
class JumlahHalamanBuku {
  final Map<int, int> _perBuku;
  final bool _terverifikasi;

  const JumlahHalamanBuku._(this._perBuku, this._terverifikasi);

  /// Query gagal: jumlah halaman tidak boleh dianggap 0.
  const JumlahHalamanBuku.tidakDiketahui() : this._(const {}, false);

  /// Query berhasil. Hasil yang benar-benar kosong (tidak ada satu baris pun)
  /// tetap dianggap belum diketahui, karena kosong bisa saja disebabkan RLS
  /// yang menyaring baris tanpa melempar error. Hanya hasil yang berisi data
  /// yang boleh dipakai untuk menyimpulkan bahwa sebuah buku belum berhalaman.
  factory JumlahHalamanBuku.dariBaris(
    Iterable<Map<String, dynamic>> baris,
  ) {
    final perBuku = <int, int>{};
    for (final b in baris) {
      final id = keInt(b['buku_id']);
      perBuku[id] = (perBuku[id] ?? 0) + 1;
    }
    return JumlahHalamanBuku._(perBuku, perBuku.isNotEmpty);
  }

  /// True kalau hasil query boleh dipakai sebagai bukti jumlah halaman.
  bool get terverifikasi => _terverifikasi;

  /// Null = belum diketahui; 0 = terverifikasi belum ada halaman.
  int? untukBuku(int bukuId) => _terverifikasi ? (_perBuku[bukuId] ?? 0) : null;
}

/// LAYANAN: satu-satunya class yang berbicara dengan Supabase untuk Beranda.
///
/// Pemisahan tanggung jawab:
/// - UI tidak menulis query,
/// - hasil query langsung diubah menjadi objek model (bukan Map mentah),
/// - kalau gagal, error dilempar ke pemanggil supaya tiap bagian Beranda bisa
///   menampilkan pesan sendiri.
class LayananBeranda {
  final SupabaseClient _supabase;

  /// CONSTRUCTOR + COMPOSITION: layanan memakai SupabaseClient.
  /// Parameter [supabase] opsional agar mudah diuji, defaultnya client global.
  LayananBeranda({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Mengambil id pengguna yang sedang login lewat Supabase Auth.
  String _idPenggunaAktif() {
    final pengguna = _supabase.auth.currentUser;
    if (pengguna == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return pengguna.id;
  }

  /// Semua profil anak milik pengguna yang sedang login (bisa lebih dari satu).
  Future<List<Anak>> ambilDaftarAnak() async {
    final idPengguna = _idPenggunaAktif();

    final baris = await _supabase
        .from('anak')
        .select('id, nama_panggilan, nama_orang_tua, usia, poin')
        .eq('pengguna_id', idPengguna)
        .order('id');

    // Map dari Supabase diubah menjadi objek Anak lewat factory constructor.
    return baris
        .map((e) => Anak.dariJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Daftar buku yang sudah diterbitkan, dipakai untuk rekomendasi.
  Future<List<Buku>> ambilBukuTerbit() async {
    final baris = await _supabase
        .from('buku')
        .select(
          'id, judul, deskripsi, tingkat_membaca, gambar_sampul, status, kategori_id, kategori(nama)',
        )
        .eq('status', 'diterbitkan')
        .order('judul');

    // Jumlah halaman dipakai untuk teks "Halaman 3 dari 4" pada kartu
    // Lanjutkan Membaca dan untuk menandai buku yang belum berisi. Kalau
    // pemeriksaan ini gagal, daftar buku tetap tampil tanpa total halaman
    // (tidak dianggap kegagalan seluruh bagian).
    final jumlahHalaman = await _periksaJumlahHalaman();

    return baris.map((e) {
      final json = Map<String, dynamic>.from(e);
      return Buku.dariJson(
        json,
        jumlahHalaman: jumlahHalaman.untukBuku(keInt(json['id'])),
      );
    }).toList();
  }

  /// Memeriksa jumlah halaman seluruh buku pada satu query.
  /// Kegagalan query tidak melempar error ke UI, cukup ditandai sebagai
  /// "belum diketahui" agar Beranda tidak menyimpulkan buku tidak berhalaman.
  Future<JumlahHalamanBuku> _periksaJumlahHalaman() async {
    try {
      final halaman = await _supabase.from('halaman_buku').select('buku_id');
      return JumlahHalamanBuku.dariBaris(halaman);
    } catch (_) {
      return const JumlahHalamanBuku.tidakDiketahui();
    }
  }

  /// Progres membaca milik satu anak, terbaru lebih dulu.
  Future<List<ProgresMembaca>> ambilProgresMembaca(int anakId) async {
    final baris = await _supabase
        .from('progres_membaca')
        .select('buku_id, halaman_terakhir, status, terakhir_diperbarui')
        .eq('anak_id', anakId)
        .order('terakhir_diperbarui', ascending: false);

    return baris
        .map((e) => ProgresMembaca.dariJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Semua kategori cerita (untuk daftar kategori di Beranda).
  Future<List<Kategori>> ambilKategori() async {
    final baris = await _supabase
        .from('kategori')
        .select('id, nama, deskripsi')
        .order('nama');

    return baris
        .map((e) => Kategori.dariJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Id kategori minat milik satu anak (tabel `minat_anak`).
  /// Hanya id yang diambil, lalu dicocokkan dengan daftar kategori di UI.
  Future<List<int>> ambilIdMinatAnak(int anakId) async {
    final baris = await _supabase
        .from('minat_anak')
        .select('kategori_id')
        .eq('anak_id', anakId);

    return baris.map((e) => e['kategori_id'] as int).toList();
  }

  /// Ringkasan misi anak: data `misi` digabung dengan `progres_misi`.
  ///
  /// Penggabungan dilakukan di Dart agar tidak bergantung pada nama relasi
  /// foreign key di Supabase. Misi yang belum punya baris progres tetap
  /// ditampilkan dengan progres 0 (tanpa menulis data baru).
  Future<List<MisiAnak>> ambilMisiAnak(int anakId) async {
    final barisMisi = await _supabase
        .from('misi')
        .select('id, judul, deskripsi, target, hadiah_poin')
        .order('id');

    final barisProgres = await _supabase
        .from('progres_misi')
        .select('id, misi_id, progres_saat_ini, status, waktu_selesai')
        .eq('anak_id', anakId);

    final petaProgres = <int, ProgresMisi>{};
    for (final p in barisProgres) {
      final progres = ProgresMisi.dariJson(Map<String, dynamic>.from(p));
      petaProgres[progres.misiId] = progres;
    }

    final daftar = barisMisi.map((m) {
      final misi = Misi.dariJson(Map<String, dynamic>.from(m));
      return MisiAnak(misi, petaProgres[misi.id]);
    }).toList();

    // Misi yang belum selesai tampil lebih dulu.
    daftar.sort((a, b) {
      if (a.selesai != b.selesai) return a.selesai ? 1 : -1;
      return a.misi.id.compareTo(b.misi.id);
    });

    return daftar;
  }
}
