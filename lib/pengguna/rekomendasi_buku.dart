import 'model_buku.dart';

/// ABSTRACTION: kontrak (blueprint) strategi rekomendasi buku.
///
/// Class ini tidak tahu cara memilih buku. Setiap class turunan wajib
/// mengisi method [rekomendasikan] dengan caranya masing-masing.
abstract class RekomendasiBuku {
  final List<Buku> _daftarBuku;

  const RekomendasiBuku(List<Buku> daftarBuku) : _daftarBuku = daftarBuku;

  /// Daftar buku yang boleh dipakai oleh strategi (atribut private + getter).
  List<Buku> get daftarBuku => _daftarBuku;

  /// ABSTRACT METHOD: tidak punya isi, harus di-@override turunannya.
  List<Buku> rekomendasikan({int batas = 6});

  /// METHOD BERSAMA (dipakai kedua strategi lewat pewarisan):
  /// mengurutkan kandidat supaya buku terbit yang terbukti punya halaman
  /// didahulukan, disusul buku yang jumlah halamannya belum diketahui, dan
  /// buku yang benar-benar belum berisi diletakkan paling akhir.
  List<Buku> urutkanSiapDibaca(List<Buku> kandidat) {
    final hasil = <Buku>[...kandidat];
    hasil.sort((a, b) {
      final beda = a.bobotKetersediaan.compareTo(b.bobotKetersediaan);
      if (beda != 0) return beda;
      return a.judul.toLowerCase().compareTo(b.judul.toLowerCase());
    });
    return hasil;
  }
}

/// INHERITANCE: strategi untuk anak yang sudah punya minat bacaan.
/// Buku dengan kategori yang cocok dengan `minat_anak` didahulukan.
class RekomendasiMinat extends RekomendasiBuku {
  final List<int> _idKategoriMinat;

  const RekomendasiMinat(super.daftarBuku, this._idKategoriMinat);

  @override
  List<Buku> rekomendasikan({int batas = 6}) {
    final cocok = urutkanSiapDibaca(
      daftarBuku
          .where((buku) =>
              buku.status == 'diterbitkan' &&
              buku.termasukKategori(_idKategoriMinat))
          .toList(),
    );

    if (cocok.length >= batas) return cocok.take(batas).toList();

    // Kalau buku berminat belum cukup, lengkapi dengan buku terbit lainnya
    // supaya bagian rekomendasi tidak kosong.
    final pelengkap = urutkanSiapDibaca(
      daftarBuku
          .where(
              (buku) => buku.status == 'diterbitkan' && !cocok.contains(buku))
          .toList(),
    );

    return <Buku>[...cocok, ...pelengkap].take(batas).toList();
  }
}

/// INHERITANCE: strategi cadangan saat anak belum punya minat bacaan.
/// Semua buku berstatus terbit diurutkan berdasarkan judul.
class RekomendasiUmum extends RekomendasiBuku {
  const RekomendasiUmum(super.daftarBuku);

  @override
  List<Buku> rekomendasikan({int batas = 6}) {
    final terbit = urutkanSiapDibaca(
      daftarBuku.where((buku) => buku.status == 'diterbitkan').toList(),
    );

    return terbit.take(batas).toList();
  }
}
