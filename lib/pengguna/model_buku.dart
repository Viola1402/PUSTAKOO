import 'konversi_json.dart';
import 'model_kategori.dart';

/// MODEL: merepresentasikan satu baris tabel `buku` beserta kategorinya.
///
/// ENKAPSULASI: semua atribut private + final, dibaca lewat getter.
class Buku {
  final int _id;
  final String _judul;
  final String? _deskripsi;
  final String? _tingkatMembaca;
  final String? _gambarSampul;
  final Kategori? _kategori;
  final String _status;
  final int? _jumlahHalaman;

  Buku({
    required int id,
    required String judul,
    String? deskripsi,
    String? tingkatMembaca,
    String? gambarSampul,
    Kategori? kategori,
    String status = 'diterbitkan',
    int? jumlahHalaman,
  })  : _id = id,
        _judul = judul,
        _deskripsi = deskripsi,
        _tingkatMembaca = tingkatMembaca,
        _gambarSampul = gambarSampul,
        _kategori = kategori,
        _status = status,
        _jumlahHalaman = jumlahHalaman;

  /// FACTORY CONSTRUCTOR: Map Supabase -> objek [Buku].
  /// Relasi `kategori(nama)` dari Supabase bisa null, jadi diperiksa dulu.
  factory Buku.dariJson(Map<String, dynamic> json, {int? jumlahHalaman}) {
    final dataKategori = json['kategori'];
    final kategori = dataKategori is Map
        ? Kategori.dariJson(Map<String, dynamic>.from(dataKategori))
        : null;

    final deskripsi = keTeks(json['deskripsi']);
    final tingkat = keTeks(json['tingkat_membaca']);
    final sampul = keTeks(json['gambar_sampul']);

    return Buku(
      id: keInt(json['id']),
      judul: keTeks(json['judul'], bawaan: 'Tanpa judul'),
      deskripsi: deskripsi.isEmpty ? null : deskripsi,
      tingkatMembaca: tingkat.isEmpty ? null : tingkat,
      gambarSampul: sampul.isEmpty ? null : sampul,
      kategori: kategori,
      status: keTeks(json['status'], bawaan: 'diterbitkan'),
      jumlahHalaman: jumlahHalaman,
    );
  }

  int get id => _id;
  String get judul => _judul;
  String? get deskripsi => _deskripsi;
  String? get tingkatMembaca => _tingkatMembaca;
  String? get gambarSampul => _gambarSampul;
  Kategori? get kategori => _kategori;
  String get status => _status;

  /// Jumlah halaman buku (dihitung dari tabel `halaman_buku`).
  /// Null berarti belum diketahui / gagal dimuat, bukan berarti 0 halaman.
  int? get jumlahHalaman => _jumlahHalaman;

  /// True kalau pemeriksaan berhasil dan buku memang belum punya halaman.
  bool get tanpaHalaman => _jumlahHalaman != null && _jumlahHalaman <= 0;

  /// True kalau jumlah halaman belum pasti (query gagal / hasil belum jelas).
  /// Kondisi ini tidak boleh dianggap sama dengan "tidak punya halaman".
  bool get jumlahHalamanBelumDiketahui => _jumlahHalaman == null;

  /// True kalau buku terbukti punya halaman cerita sehingga bisa dibaca.
  bool get punyaHalaman => (_jumlahHalaman ?? 0) > 0;

  /// Bobot untuk mengurutkan rekomendasi: yang terbukti bisa dibaca lebih
  /// dulu, lalu yang belum diketahui, terakhir yang belum ada isinya.
  int get bobotKetersediaan =>
      punyaHalaman ? 0 : (jumlahHalamanBelumDiketahui ? 1 : 2);

  /// Apakah buku milik salah satu kategori minat anak.
  bool termasukKategori(List<int> idKategori) =>
      idKategori.contains(_kategori?.id);

  /// Teks pendek "Kategori • Tingkat" untuk kartu buku.
  String get keteranganSingkat {
    final bagian = <String>[
      if (_kategori != null) _kategori.nama,
      if (_tingkatMembaca != null) _tingkatMembaca,
    ];
    return bagian.join(' • ');
  }

  /// Huruf pertama judul untuk pengganti sampul bila gambar tidak ada.
  String get hurufAwal =>
      _judul.isEmpty ? '?' : _judul.substring(0, 1).toUpperCase();
}

/// MODEL: progres membaca anak pada satu buku (tabel `progres_membaca`).
class ProgresMembaca {
  final int _bukuId;
  final int _halamanTerakhir;
  final String _status;

  ProgresMembaca({
    required int bukuId,
    required int halamanTerakhir,
    String status = 'sedang_dibaca',
  })  : _bukuId = bukuId,
        _halamanTerakhir = halamanTerakhir,
        _status = status;

  factory ProgresMembaca.dariJson(Map<String, dynamic> json) {
    return ProgresMembaca(
      bukuId: keInt(json['buku_id']),
      halamanTerakhir: keInt(json['halaman_terakhir']),
      status: keTeks(json['status'], bawaan: 'sedang_dibaca'),
    );
  }

  int get bukuId => _bukuId;
  int get halamanTerakhir => _halamanTerakhir;

  /// Halaman terakhir yang aman ditampilkan untuk total halaman tertentu.
  /// [total] null atau 0 diperlakukan sebagai "belum diketahui".
  int halamanTampil(int? total) {
    if (total == null || total <= 0) return _halamanTerakhir;
    return _halamanTerakhir.clamp(0, total);
  }

  String get status => _status;

  bool get selesai => _status == 'selesai';
  String get label =>
      selesai ? 'Selesai dibaca' : 'Terakhir di halaman $_halamanTerakhir';
}

/// COMPOSITION: menggabungkan objek [Buku] dengan [ProgresMembaca] menjadi
/// satu bacaan yang bisa dilanjutkan. Dipakai kartu "Lanjutkan Membaca".
class BacaanBerjalan {
  final Buku _buku;
  final ProgresMembaca _progres;

  const BacaanBerjalan(this._buku, this._progres);

  Buku get buku => _buku;
  ProgresMembaca get progres => _progres;
}
