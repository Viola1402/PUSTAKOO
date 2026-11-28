import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/kategori_model.dart';

// ==========================================================
// REPOSITORY KELOLA KATEGORI
// ==========================================================

abstract class KategoriRepository {
  Future<DataKategori> muatKategori();

  Future<bool> simpanKategori({
    int? id,
    required IsianKategori isian,
  });

  Future<bool> hapusKategori(int id);
}

// ==========================================================
// REPOSITORY SUPABASE
// ==========================================================

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

      final hasilBuku = await _klien.from('buku').select('id, kategori_id');

      final buku = List<Map<String, dynamic>>.from(hasilBuku);

      final daftar = List<Map<String, dynamic>>.from(hasilKategori).map((item) {
        final id = item['id'];
        final nama = _teks(item['nama'], 'Tanpa Nama');

        final jumlah = buku.where((row) {
          return row['kategori_id']?.toString() == id.toString();
        }).length;

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
        distribusi: DistribusiBuku([
          for (final tingkat in TingkatBaca.values)
            BagianDistribusi(tingkat: tingkat, jumlah: 0),
        ]),
        dataContoh: false,
        dimuatPada: DateTime.now(),
      );
    } catch (error) {
      debugPrint('Kategori: gagal memuat data ($error)');
      rethrow;
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

  @override
  Future<bool> hapusKategori(int id) async {
    try {
      // Cek apakah kategori masih digunakan oleh buku.
      final bukuTerkait =
          await _klien.from('buku').select('id').eq('kategori_id', id).limit(1);

      if (bukuTerkait.isNotEmpty) {
        debugPrint('Kategori masih digunakan oleh buku.');
        return false;
      }

      await _klien.from('kategori').delete().eq('id', id);

      return true;
    } catch (error) {
      debugPrint('Kategori: gagal menghapus ($error)');
      return false;
    }
  }
}

// ==========================================================
// REPOSITORY DATA CONTOH
// ==========================================================

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

  @override
  Future<bool> hapusKategori(int id) async {
    return false;
  }
}

// ==========================================================
// DATA CONTOH
// ==========================================================

DataKategori contohDataKategori({DateTime? dimuatPada}) {
  const daftar = <KategoriCerita>[
    KategoriCerita(
      id: 1,
      nama: 'Dongeng',
      genre: 'Fantasi',
      deskripsi: 'Cerita imajinatif, fabel, dan kisah klasik nusantara.',
      jumlahCerita: 8,
      jenis: JenisKategori.dongeng,
    ),
    KategoriCerita(
      id: 2,
      nama: 'Petualangan',
      genre: 'Eksplorasi',
      deskripsi: 'Eksplorasi alam, misteri ringan, dan kisah petualangan.',
      jumlahCerita: 12,
      jenis: JenisKategori.petualangan,
    ),
    KategoriCerita(
      id: 3,
      nama: 'Hewan',
      genre: 'Fabel Satwa',
      deskripsi: 'Kisah fabel satwa dengan pesan moral untuk anak.',
      jumlahCerita: 10,
      jenis: JenisKategori.hewan,
    ),
    KategoriCerita(
      id: 4,
      nama: 'Sains',
      genre: 'Edukasi STEM',
      deskripsi: 'Cerita ilmu pengetahuan dan eksperimen sederhana.',
      jumlahCerita: 6,
      jenis: JenisKategori.sains,
    ),
    KategoriCerita(
      id: 5,
      nama: 'Cerita Rakyat',
      genre: 'Budaya Lokal',
      deskripsi: 'Legenda nusantara dan kisah budaya daerah.',
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
// PEMBANTU KONVERSI
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
