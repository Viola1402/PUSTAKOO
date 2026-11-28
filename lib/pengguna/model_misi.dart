import 'konversi_json.dart';

/// MODEL: merepresentasikan satu baris tabel `misi`.
class Misi {
  final int _id;
  final String _judul;
  final String? _deskripsi;
  final int _target;
  final int _hadiahPoin;

  Misi({
    required int id,
    required String judul,
    String? deskripsi,
    required int target,
    required int hadiahPoin,
  })  : _id = id,
        _judul = judul,
        _deskripsi = deskripsi,
        _target = target,
        _hadiahPoin = hadiahPoin;

  /// FACTORY CONSTRUCTOR: Map Supabase -> objek [Misi].
  factory Misi.dariJson(Map<String, dynamic> json) {
    final deskripsi = keTeks(json['deskripsi']);

    return Misi(
      id: keInt(json['id']),
      judul: keTeks(json['judul'], bawaan: 'Misi Membaca'),
      deskripsi: deskripsi.isEmpty ? null : deskripsi,
      target: keInt(json['target']),
      hadiahPoin: keInt(json['hadiah_poin']),
    );
  }

  int get id => _id;
  String get judul => _judul;
  String? get deskripsi => _deskripsi;
  int get target => _target;
  int get hadiahPoin => _hadiahPoin;
}

/// MODEL: progres anak pada satu misi (tabel `progres_misi`).
class ProgresMisi {
  final int _id;
  final int _misiId;
  final int _progresSaatIni;
  final String _status;
  final DateTime? _waktuSelesai;

  ProgresMisi({
    required int id,
    required int misiId,
    required int progresSaatIni,
    String status = 'berlangsung',
    DateTime? waktuSelesai,
  })  : _id = id,
        _misiId = misiId,
        _progresSaatIni = progresSaatIni,
        _status = status,
        _waktuSelesai = waktuSelesai;

  factory ProgresMisi.dariJson(Map<String, dynamic> json) {
    return ProgresMisi(
      id: keInt(json['id']),
      misiId: keInt(json['misi_id']),
      progresSaatIni: keInt(json['progres_saat_ini']),
      status: keTeks(json['status'], bawaan: 'berlangsung'),
      waktuSelesai: keTanggal(json['waktu_selesai']),
    );
  }

  int get id => _id;
  int get misiId => _misiId;
  int get progresSaatIni => _progresSaatIni;
  String get status => _status;
  DateTime? get waktuSelesai => _waktuSelesai;

  bool get selesai => _status == 'selesai';
}

/// COMPOSITION: satu misi + progres milik anak pada misi tersebut.
/// Kalau anak belum punya baris `progres_misi`, [progres] bernilai null dan
/// progres dianggap 0 tanpa membuat data baru di database.
class MisiAnak {
  final Misi _misi;
  final ProgresMisi? _progres;

  const MisiAnak(this._misi, [this._progres]);

  Misi get misi => _misi;
  ProgresMisi? get progres => _progres;

  int get progresSaatIni => _progres?.progresSaatIni ?? 0;
  String get status => _progres?.status ?? 'berlangsung';
  bool get selesai => status == 'selesai';

  /// Persentase kemajuan 0..1.
  /// Target 0 ditangani khusus supaya tidak terjadi pembagian dengan nol.
  double get kemajuan {
    if (_misi.target <= 0) return selesai ? 1 : 0;
    final nilai = progresSaatIni / _misi.target;
    return nilai.clamp(0.0, 1.0).toDouble();
  }

  String get keteranganStatus => selesai ? 'Selesai' : 'Berlangsung';
}
