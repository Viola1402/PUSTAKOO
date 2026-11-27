import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/kategori_model.dart';

// ==========================================================
// LAYANAN DATA KELOLA KATEGORI
// Abstraksi KategoriRepository memungkinkan data diambil dari
// Supabase, data contoh, atau sumber lain tanpa mengubah
// halaman maupun widget.
// ==========================================================

abstract class KategoriRepository {
  Future<DataKategori> muatKategori();

  /// Mengembalikan `true` bila data berhasil disimpan ke basis data.
  Future<bool> simpanKategori({int? id, required IsianKategori isian});
}

class SupabaseKategoriRepository implements KategoriRepository {
  final SupabaseClient _klien;

  SupabaseKategoriRepository({SupabaseClient? klien})
      : _klien = klien ?? Supabase.instance.client;

  @override
  Future<DataKategori> muatKategori() async {
    try {
      final hasilKategori = await _klien
          .from('kategori')
          .select('id, nama, deskripsi')
          .order('nama');

      final hasilBuku = await _klien
          .from('buku')
          .select('id, kategori_id, tingkat_membaca');

      final buku = List<Map<String, dynamic>>.from(hasilBuku);

      if (hasilKategori.isEmpty) {
        return contohDataKategori(dimuatPada: DateTime.now());
      }

      final daftar = hasilKategori.map((item) {
        final id = item['id'];
        final nama = _teks(item['nama'], 'Tanpa Nama');
        final jumlah = buku
            .where((row) => row['kategori_id'].toString() == id.toString())
            .length;

        return KategoriCerita(
          id: _angka(id),
          nama: nama,
          genre: KategoriCerita.genreBawaan(nama),
          deskripsi: _teks(item['deskripsi'], ''),
          jumlahCerita: jumlah,
          jenis: KategoriCerita.jenisDari(nama),
        );
      }).toList();

      return DataKategori(
        kategori: daftar,
        distribusi: _distribusi(buku),
        dataContoh: false,
        dimuatPada: DateTime.now(),
      );
    } catch (error) {
      debugPrint('Kategori: gagal memuat data ($error)');
      return contohDataKategori(dimuatPada: DateTime.now());
    }
  }

  @override
  Future<bool> simpanKategori({
    int? id,
    required IsianKategori isian,
  }) async {
    try {
      final data = {
        'nama': isian.nama.trim(),
        'deskripsi': isian.deskripsi.trim(),
      };

      if (id == null) {
        await _klien.from('kategori').insert(data);
      } else {
        await _klien.from('kategori').update(data).eq('id', id);
      }

      return true;
    } catch (error) {
      debugPrint('Kategori: gagal menyimpan ($error)');
      return false;
    }
  }

  DistribusiBuku _distribusi(List<Map<String, dynamic>> buku) {
    final jumlah = <TingkatBaca, int>{
      for (final tingkat in TingkatBaca.values) tingkat: 0,
    };

    for (final item in buku) {
      final tingkat = TingkatBaca.dariTeks(
        item['tingkat_membaca']?.toString(),
      );
      jumlah[tingkat] = (jumlah[tingkat] ?? 0) + 1;
    }

    return DistribusiBuku([
      for (final tingkat in TingkatBaca.values)
        BagianDistribusi(tingkat: tingkat, jumlah: jumlah[tingkat] ?? 0),
    ]);
  }
}

/// Data contoh dipakai saat tabel kategori masih kosong atau
/// koneksi basis data gagal.
class ContohKategoriRepository implements KategoriRepository {
  const ContohKategoriRepository();

  @override
  Future<DataKategori> muatKategori() async {
    return contohDataKategori(dimuatPada: DateTime.now());
  }

  @override
  Future<bool> simpanKategori({
    int? id,
    required IsianKategori isian,
  }) async {
    return false;
  }
}

DataKategori contohDataKategori({DateTime? dimuatPada}) {
  const daftar = <KategoriCerita>[
    KategoriCerita(
      id: 1,
      nama: 'Dongeng',
      genre: 'Fantasi',
      deskripsi:
          'Cerita imajinatif, fabel, dan kisah klasik nusantara untuk '
          'membangun daya khayal serta kreativitas anak.',
      jumlahCerita: 8,
      jenis: JenisKategori.dongeng,
    ),
    KategoriCerita(
      id: 2,
      nama: 'Petualangan',
      genre: 'Eksplorasi',
      deskripsi:
          'Eksplorasi alam, misteri ringan, dan kisah ketangguhan karakter '
          'yang melatih keberanian pembaca muda.',
      jumlahCerita: 12,
      jenis: JenisKategori.petualangan,
    ),
    KategoriCerita(
      id: 3,
      nama: 'Hewan',
      genre: 'Fabel Satwa',
      deskripsi:
          'Kisah fabel satwa lucu dengan pesan moral, empati, dan budi '
          'pekerti ramah anak untuk bacaan sehari-hari.',
      jumlahCerita: 10,
      jenis: JenisKategori.hewan,
    ),
    KategoriCerita(
      id: 4,
      nama: 'Sains',
      genre: 'Edukasi STEM',
      deskripsi:
          'Eksplorasi ilmu alam, eksperimen sederhana, dan pemahaman '
          'fenomena dunia sekitar yang memicu rasa ingin tahu.',
      jumlahCerita: 6,
      jenis: JenisKategori.sains,
    ),
    KategoriCerita(
      id: 5,
      nama: 'Cerita Rakyat',
      genre: 'Budaya Lokal',
      deskripsi:
          'Dongeng legenda nusantara, kearifan budaya daerah, dan kisah '
          'keteladanan leluhur dari berbagai penjuru Indonesia.',
      jumlahCerita: 14,
      jenis: JenisKategori.ceritaRakyat,
    ),
  ];

  const distribusi = DistribusiBuku([
    BagianDistribusi(tingkat: TingkatBaca.pemula, jumlah: 23),
    BagianDistribusi(tingkat: TingkatBaca.menengah, jumlah: 17),
    BagianDistribusi(tingkat: TingkatBaca.mahir, jumlah: 10),
  ]);

  return DataKategori(
    kategori: daftar,
    distribusi: distribusi,
    dataContoh: true,
    dimuatPada: dimuatPada ?? DateTime.now(),
  );
}

// ==========================================================
// PEMBANTU KONVERSI NILAI DINAMIS
// ==========================================================

String _teks(dynamic nilai, [String nilaiAwal = '-']) {
  if (nilai == null) return nilaiAwal;
  final hasil = nilai.toString().trim();
  return hasil.isEmpty ? nilaiAwal : hasil;
}

int _angka(dynamic nilai) {
  if (nilai is num) return nilai.toInt();
  return int.tryParse(nilai?.toString() ?? '') ?? 0;
}
