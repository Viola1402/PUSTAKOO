import 'konversi_json.dart';

/// MODEL: merepresentasikan satu baris tabel `kategori`.
///
/// ENKAPSULASI: atribut private + final, akses hanya lewat getter.
class Kategori {
  final int _id;
  final String _nama;
  final String? _deskripsi;

  /// CONSTRUCTOR dengan parameter bernama.
  Kategori({
    required int id,
    required String nama,
    String? deskripsi,
  })  : _id = id,
        _nama = nama,
        _deskripsi = deskripsi;

  /// FACTORY CONSTRUCTOR: Map Supabase -> objek [Kategori].
  factory Kategori.dariJson(Map<String, dynamic> json) {
    final deskripsi = keTeks(json['deskripsi']);

    return Kategori(
      id: keInt(json['id']),
      nama: keTeks(json['nama'], bawaan: 'Tanpa nama'),
      deskripsi: deskripsi.isEmpty ? null : deskripsi,
    );
  }

  int get id => _id;
  String get nama => _nama;
  String? get deskripsi => _deskripsi;

  /// Memudahkan pengecekan saat debug (mis. print daftar kategori).
  @override
  String toString() => 'Kategori($_id, $_nama)';
}
