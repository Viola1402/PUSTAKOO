import 'konversi_json.dart';

/// MODEL: merepresentasikan satu baris tabel `anak`.
///
/// ENKAPSULASI:
/// - semua atribut private (diawali `_`) dan `final`,
/// - hanya bisa dibaca lewat getter,
/// - tidak ada setter untuk `poin`, jadi saldo poin tidak mungkin diubah
///   sembarangan dari halaman Beranda.
class Anak {
  final int _id;
  final String _namaPanggilan;
  final String? _namaOrangTua;
  final int? _usia;
  final int _poin;

  /// CONSTRUCTOR: objek hanya dibuat lewat sini (atau lewat factory di bawah).
  Anak({
    required int id,
    required String namaPanggilan,
    String? namaOrangTua,
    int? usia,
    int poin = 0,
  })  : _id = id,
        _namaPanggilan = namaPanggilan,
        _namaOrangTua = namaOrangTua,
        _usia = usia,
        _poin = poin;

  /// FACTORY CONSTRUCTOR: mengubah satu baris Supabase menjadi objek [Anak].
  /// Nilai null dan tipe data yang tidak sesuai ditangani di sini.
  factory Anak.dariJson(Map<String, dynamic> json) {
    // usia -1 dipakai sebagai penanda "tidak diisi".
    final usia = keInt(json['usia'], bawaan: -1);
    final namaOrangTua = keTeks(json['nama_orang_tua']);

    return Anak(
      id: keInt(json['id']),
      namaPanggilan: keTeks(json['nama_panggilan'], bawaan: 'Anak'),
      namaOrangTua: namaOrangTua.isEmpty ? null : namaOrangTua,
      usia: usia < 0 ? null : usia,
      poin: keInt(json['poin']),
    );
  }

  // GETTER: satu-satunya jalan membaca data dari luar class.
  int get id => _id;
  String get namaPanggilan => _namaPanggilan;
  String? get namaOrangTua => _namaOrangTua;
  int? get usia => _usia;
  int get poin => _poin;

  /// Teks siap tampil untuk informasi usia anak.
  String get keteranganUsia =>
      _usia == null ? 'Usia belum diisi' : '$_usia tahun';

  /// Huruf pertama nama, dipakai sebagai avatar sederhana.
  String get hurufAwal => _namaPanggilan.isEmpty
      ? '?'
      : _namaPanggilan.substring(0, 1).toUpperCase();
}
