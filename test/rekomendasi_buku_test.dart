import 'package:flutter_application_1/pengguna/layanan_beranda.dart';
import 'package:flutter_application_1/pengguna/model_buku.dart';
import 'package:flutter_application_1/pengguna/model_kategori.dart';
import 'package:flutter_application_1/pengguna/rekomendasi_buku.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uji logika strategi rekomendasi tanpa memanggil Supabase.
/// File ini hanya menguji class milik fitur Beranda.
Buku _buku(int id, String judul, int? kategoriId,
    {String status = 'diterbitkan', int? jumlahHalaman}) {
  return Buku(
    id: id,
    judul: judul,
    kategori: kategoriId == null
        ? null
        : Kategori(id: kategoriId, nama: 'Kategori $kategoriId'),
    status: status,
    jumlahHalaman: jumlahHalaman,
  );
}

void main() {
  final daftar = <Buku>[
    _buku(1, 'Si Kucing Pemalu', 1),
    _buku(2, 'Hutan Pelangi', 2),
    _buku(3, 'Kancil dan Buaya', 1),
    _buku(4, 'Draf Rahasia', 1, status: 'draf'),
  ];

  group('RekomendasiBuku', () {
    test('RekomendasiMinat mendahulukan kategori minat anak', () {
      final RekomendasiBuku strategi = RekomendasiMinat(daftar, [2]);
      final hasil = strategi.rekomendasikan();

      expect(hasil.first.id, 2);
      expect(hasil.map((b) => b.id), isNot(contains(4)));
    });

    test('RekomendasiMinat tetap terisi walau buku berminat sedikit', () {
      final RekomendasiBuku strategi = RekomendasiMinat(daftar, [2]);
      final hasil = strategi.rekomendasikan();

      expect(hasil.length, 3);
    });

    test('RekomendasiUmum mengabaikan buku yang belum diterbitkan', () {
      final RekomendasiBuku strategi = RekomendasiUmum(daftar);
      final hasil = strategi.rekomendasikan(batas: 2);

      expect(hasil.length, 2);
      expect(hasil.map((b) => b.id), isNot(contains(4)));
    });

    test('batas jumlah rekomendasi dihormati', () {
      final RekomendasiBuku strategi = RekomendasiUmum(daftar);

      expect(strategi.rekomendasikan(batas: 1).length, 1);
    });

    test('buku yang belum punya halaman diletakkan paling akhir', () {
      final beragam = <Buku>[
        _buku(1, 'Awal', 1, jumlahHalaman: 0),
        _buku(2, 'Tengah', 1, jumlahHalaman: 4),
        _buku(3, 'Akhir', 1),
      ];

      final hasil = RekomendasiMinat(beragam, [1]).rekomendasikan();

      expect(hasil.map((b) => b.id).toList(), [2, 3, 1]);
    });
  });

  group('JumlahHalamanBuku', () {
    test('hasil kosong dan kegagalan query bukan berarti 0 halaman', () {
      final kosong = JumlahHalamanBuku.dariBaris(const []);

      expect(kosong.terverifikasi, isFalse);
      expect(kosong.untukBuku(1), isNull);
      expect(const JumlahHalamanBuku.tidakDiketahui().untukBuku(1), isNull);
    });

    test('hasil berisi dihitung per buku, buku tanpa baris bernilai 0', () {
      final ada = JumlahHalamanBuku.dariBaris(const [
        {'buku_id': 1},
        {'buku_id': 1},
        {'buku_id': 2},
      ]);

      expect(ada.terverifikasi, isTrue);
      expect(ada.untukBuku(1), 2);
      expect(ada.untukBuku(2), 1);
      expect(ada.untukBuku(3), 0);
    });

    test('status halaman pada model membedakan 0 dan null', () {
      expect(_buku(1, 'Kosong', 1, jumlahHalaman: 0).tanpaHalaman, isTrue);
      expect(_buku(1, 'Kosong', 1, jumlahHalaman: 0).punyaHalaman, isFalse);
      expect(_buku(1, 'Belum tahu', 1).jumlahHalamanBelumDiketahui, isTrue);
      expect(_buku(1, 'Ada', 1, jumlahHalaman: 3).punyaHalaman, isTrue);
    });
  });
}
