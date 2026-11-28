
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kuis_buku.dart';
import 'tema_pustakoo.dart';

// =====================================================
// 1. SUPERCLASS (KELAS INDUK)
// =====================================================
// Menyimpan data dasar sebuah halaman cerita.
// Atribut dibuat private untuk menerapkan encapsulation.

class DataHalaman {
  final int _nomorHalaman;

  DataHalaman({
    required int nomorHalaman,
  }) : _nomorHalaman = nomorHalaman;

  // Getter untuk membaca nomor halaman.
  int get nomorHalaman => _nomorHalaman;
}

// =====================================================
// 2. SUBCLASS (KELAS TURUNAN)
// =====================================================
// HalamanCerita mewarisi DataHalaman menggunakan extends.
// Kelas ini memiliki data isi cerita dan ilustrasi.

class HalamanCerita extends DataHalaman {
  final String _isiHalaman;
  final String? _ilustrasi;

  // Constructor kelas turunan.
  HalamanCerita({
    required int nomorHalaman,
    required String isiHalaman,
    String? ilustrasi,
  })  : _isiHalaman = isiHalaman,
        _ilustrasi = ilustrasi,
        super(nomorHalaman: nomorHalaman);

  // Getter untuk mengakses isi cerita dan ilustrasi.
  String get isiHalaman => _isiHalaman;
  String? get ilustrasi => _ilustrasi;

  // Mengubah data dari Supabase menjadi objek HalamanCerita.
  factory HalamanCerita.fromMap(Map<String, dynamic> data) {
    return HalamanCerita(
      nomorHalaman:
          int.tryParse('${data['nomor_halaman']}') ?? 0,
      isiHalaman: data['isi_halaman']?.toString() ?? '',
      ilustrasi: data['ilustrasi']?.toString(),
    );
  }

  // ===================================================
  // 3. POLYMORPHISM
  // ===================================================
  // Override method toString() dari kelas Object.
  @override
  String toString() {
    return 'Halaman $nomorHalaman: $_isiHalaman';
  }
}

// =====================================================
// 4. CLASS BACA BUKU
// =====================================================
// StatefulWidget merupakan class dari Flutter.
// Constructor menerima identitas anak dan buku.

class BacaBuku extends StatefulWidget {
  final int anakId;
  final int bukuId;
  final String judul;

  const BacaBuku({
    super.key,
    required this.anakId,
    required this.bukuId,
    required this.judul,
  });

  @override
  State<BacaBuku> createState() => _BacaBukuState();
}

// =====================================================
// 5. CLASS STATE BACA BUKU
// =====================================================

class _BacaBukuState extends State<BacaBuku> {
  // ENCAPSULATION:
  // Semua atribut internal menggunakan tanda _.

  final _supabase = Supabase.instance.client;

  bool _memuat = true;
  String? _error;

  List<HalamanCerita> _halaman = [];

  int _indeks = 0;
  bool _sudahSelesai = false;

  Map<String, dynamic>? _kuis;
  String? _sampul;

  final Map<String, Uint8List> _cacheGambar = {};

  // ===================================================
  // 6. INITIALIZATION
  // ===================================================

  @override
  void initState() {
    super.initState();
    _muat();
  }

  // ===================================================
  // 7. MEMUAT DATA DARI SUPABASE
  // ===================================================

  Future<void> _muat() async {
    if (!mounted) return;

    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      // Mengambil halaman berdasarkan ID buku.
      final hasilHalaman = await _supabase
          .from('halaman_buku')
          .select(
            'nomor_halaman, isi_halaman, ilustrasi',
          )
          .eq('buku_id', widget.bukuId);

      // Mengubah data Supabase menjadi objek HalamanCerita.
      final daftar = hasilHalaman
          .map(
            (data) => HalamanCerita.fromMap(
              Map<String, dynamic>.from(data),
            ),
          )
          .toList();

      // Mengurutkan halaman dari nomor terkecil.
      daftar.sort(
        (a, b) => a.nomorHalaman.compareTo(b.nomorHalaman),
      );

      // Menampilkan data halaman pada Debug Console.
      for (final halaman in daftar) {
        debugPrint(halaman.toString());
      }

      // Mengambil progres membaca anak.
      final progres = await _supabase
          .from('progres_membaca')
          .select('halaman_terakhir, status')
          .eq('anak_id', widget.anakId)
          .eq('buku_id', widget.bukuId)
          .limit(1);

      // Mengambil kuis berdasarkan ID buku.
      final kuis = await _supabase
          .from('kuis')
          .select('id, judul')
          .eq('buku_id', widget.bukuId)
          .order('id')
          .limit(1);

      // Mengambil gambar sampul buku.
      String? sampul;

      try {
        final buku = await _supabase
            .from('buku')
            .select('gambar_sampul')
            .eq('id', widget.bukuId)
            .limit(1);

        if (buku.isNotEmpty) {
          sampul = buku.first['gambar_sampul']?.toString();
        }
      } catch (e) {
        debugPrint('Gagal mengambil sampul: $e');
      }

      // Default halaman dimulai dari indeks 0.
      int indeksBaru = 0;

      if (progres.isNotEmpty) {
        final status =
            progres.first['status']?.toString();

        final terakhir = int.tryParse(
              '${progres.first['halaman_terakhir']}',
            ) ??
            1;

        // Jika buku belum selesai, lanjutkan progres.
        // Jika selesai, mulai kembali dari halaman pertama.
        if (status != 'selesai') {
          final posisi = daftar.indexWhere(
            (halaman) =>
                halaman.nomorHalaman == terakhir,
          );

          if (posisi >= 0) {
            indeksBaru = posisi;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _halaman = daftar;
        _indeks = indeksBaru;

        // Reset status selesai saat memulai ulang bacaan.
        _sudahSelesai = false;

        _kuis = kuis.isEmpty
            ? null
            : Map<String, dynamic>.from(kuis.first);

        _sampul = sampul;
        _memuat = false;
      });

      debugPrint('========== DATA BUKU ==========');
      debugPrint('ID Buku: ${widget.bukuId}');
      debugPrint('Jumlah halaman: ${_halaman.length}');
      debugPrint('Indeks awal: $_indeks');
      debugPrint('Nomor halaman aktif: $_nomorAktif');
      debugPrint('================================');

      // Menyimpan posisi awal atau posisi lanjutan.
      if (_halaman.isNotEmpty) {
        await _simpanProgres();
      }
    } catch (e) {
      debugPrint('Gagal memuat buku: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  // ===================================================
  // 8. GETTER HALAMAN AKTIF
  // ===================================================

  int get _nomorAktif {
    if (_halaman.isEmpty) return 0;

    return _halaman[_indeks].nomorHalaman;
  }

  bool get _halamanTerakhir {
    return _halaman.isNotEmpty &&
        _indeks == _halaman.length - 1;
  }

  // ===================================================
  // 9. MENYIMPAN PROGRES MEMBACA
  // ===================================================

  Future<void> _simpanProgres() async {
    if (_halaman.isEmpty) return;

    final nomor = _nomorAktif;

    _sudahSelesai = _halamanTerakhir;

    final status = _sudahSelesai
        ? 'selesai'
        : 'sedang_dibaca';

    final data = {
      'halaman_terakhir': nomor,
      'status': status,
      'terakhir_diperbarui':
          DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final ada = await _supabase
          .from('progres_membaca')
          .select('id')
          .eq('anak_id', widget.anakId)
          .eq('buku_id', widget.bukuId)
          .limit(1);

      if (ada.isEmpty) {
        await _supabase.from('progres_membaca').insert({
          'anak_id': widget.anakId,
          'buku_id': widget.bukuId,
          ...data,
        });
      } else {
        await _supabase
            .from('progres_membaca')
            .update(data)
            .eq('id', ada.first['id']);
      }

      debugPrint(
        'Progres disimpan: halaman $nomor, status $status',
      );
    } catch (e) {
      debugPrint('Gagal menyimpan progres: $e');
    }
  }

  // ===================================================
  // 10. PINDAH HALAMAN
  // ===================================================

  void _pindah(int arah) {
    final baru = _indeks + arah;

    if (baru < 0 || baru >= _halaman.length) {
      return;
    }

    setState(() {
      _indeks = baru;
      _sudahSelesai = false;
    });

    _simpanProgres();
  }

  // ===================================================
  // 11. MEMULAI KUIS
  // ===================================================

  void _mulaiKuis() {
    if (_kuis == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => KuisBuku(
          anakId: widget.anakId,
          kuisId: _kuis!['id'] as int,
          judul: _kuis!['judul'] as String,
        ),
      ),
    );
  }

  // ===================================================
  // 12. INDIKATOR HALAMAN
  // ===================================================

  Widget _penandaHalaman() {
    if (_halaman.length > 12) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 6,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_indeks + 1) / _halaman.length,
            minHeight: 6,
            backgroundColor: Warna.biruTitik,
            color: Warna.emas,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _halaman.length; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(
              horizontal: 3,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _indeks
                  ? Warna.emas
                  : Warna.biruTitik,
            ),
          ),
      ],
    );
  }

  // ===================================================
  // 13. DECODE GAMBAR BASE64
  // ===================================================

  Uint8List? _bytesDariData(
    String? sumber,
    String kunci,
  ) {
    if (sumber == null || !sumber.startsWith('data:')) {
      return null;
    }

    final tersimpan = _cacheGambar[kunci];

    if (tersimpan != null) return tersimpan;

    try {
      final bytes = base64Decode(
        sumber.substring(sumber.indexOf(',') + 1),
      );

      _cacheGambar[kunci] = bytes;

      return bytes;
    } catch (e) {
      debugPrint('Gagal decode gambar: $e');
      return null;
    }
  }

  // ===================================================
  // 14. MENAMPILKAN GAMBAR
  // ===================================================

  Widget? _gambarDari(
    String? sumber,
    String kunci,
    Widget cadangan,
    BoxFit fit,
  ) {
    if (sumber == null || sumber.isEmpty) {
      return null;
    }

    final bytes = _bytesDariData(sumber, kunci);

    if (bytes != null) {
      return Image.memory(
        bytes,
        key: ValueKey(kunci),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => cadangan,
      );
    }

    if (sumber.startsWith('http')) {
      return Image.network(
        sumber,
        key: ValueKey('$kunci-$sumber'),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => cadangan,
      );
    }

    return null;
  }

  // ===================================================
  // 15. ILUSTRASI HALAMAN
  // ===================================================

  Widget _ilustrasi(String? ilustrasi, int nomorHalaman) {
    final huruf = widget.judul.isNotEmpty
        ? widget.judul[0].toUpperCase()
        : '?';

    final penampung = LayoutBuilder(
      builder: (context, kotak) {
        final sisi = (kotak.maxWidth < kotak.maxHeight
                ? kotak.maxWidth
                : kotak.maxHeight) *
            0.62;

        return Center(
          child: Container(
            width: sisi,
            height: sisi,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: sisi * 0.74,
                height: sisi * 0.74,
                decoration: const BoxDecoration(
                  color: Warna.hijauMuda,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    huruf,
                    style: gaya(sisi * 0.42),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final gambar =
        _gambarDari(
          ilustrasi,
          'halaman$nomorHalaman',
          penampung,
          BoxFit.cover,
        ) ??
        _gambarDari(
          _sampul,
          'sampul',
          penampung,
          BoxFit.contain,
        );

    return Container(
      key: ValueKey('ilustrasi-$nomorHalaman'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Warna.hijauMuda,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: gambar ?? penampung,
    );
  }

  // ===================================================
  // 16. TOMBOL HALAMAN KANAN
  // ===================================================

  Widget _tombolKanan() {
    if (!_halamanTerakhir) {
      return TombolPustakoo(
        label: 'Selanjutnya',
        onTap: () => _pindah(1),
      );
    }

    if (_kuis != null) {
      return TombolPustakoo(
        label: 'Mulai Kuis',
        onTap: _mulaiKuis,
        warna: Warna.hijau,
        warnaTeks: Colors.white,
      );
    }

    return TombolPustakoo(
      label: 'Selesai',
      onTap: () => Navigator.pop(context),
      warna: Warna.hijau,
      warnaTeks: Colors.white,
    );
  }

  // ===================================================
  // 17. MENAMPILKAN ISI HALAMAN
  // ===================================================

  Widget _isi() {
    if (_memuat) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return KotakGalat(
        judul: 'Gagal memuat buku.',
        pesan: _error!,
        onUlang: _muat,
      );
    }

    if (_halaman.isEmpty) {
      return Column(
        children: [
          _kepala(),
          const Expanded(
            child: Center(
              child: Text('Buku ini belum punya halaman.'),
            ),
          ),
        ],
      );
    }

    // Mengambil objek halaman berdasarkan indeks aktif.
    final halamanAktif = _halaman[_indeks];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        children: [
          _kepala(),

          _penandaHalaman(),

          const SizedBox(height: 12),

          // Gambar sesuai halaman aktif.
          Expanded(
            flex: 5,
            child: _ilustrasi(
              halamanAktif.ilustrasi,
              halamanAktif.nomorHalaman,
            ),
          ),

          const SizedBox(height: 12),

          // Teks sesuai halaman aktif.
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Warna.krem,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SingleChildScrollView(
                child: Text(
                  halamanAktif.isiHalaman,
                  style: gaya(
                    20,
                    warna: Warna.teksCerita,
                    tinggi: 1.35,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TombolPustakoo(
                  label: 'Sebelumnya',
                  onTap: _indeks == 0
                      ? null
                      : () => _pindah(-1),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _tombolKanan(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 18. HEADER BUKU
  // ===================================================

  Widget _kepala() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Warna.biruTua,
              ),
            ),

            Expanded(
              child: Text(
                widget.judul,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: gaya(16),
              ),
            ),

            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // 19. BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(
      child: _isi(),
    );
  }
}
