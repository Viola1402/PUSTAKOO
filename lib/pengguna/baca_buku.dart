import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kuis_buku.dart';
import 'tema_pustakoo.dart';

/// Layar Baca Cerita (Figma: 07-baca-cerita dan 07b-halaman-terakhir).
class BacaBuku extends StatefulWidget {
  final int anakId;
  final int bukuId;
  final String judul;

  // CONSTRUCTOR dengan parameter bernama.
  const BacaBuku({
    super.key,
    required this.anakId,
    required this.bukuId,
    required this.judul,
  });

  @override
  State<BacaBuku> createState() => _BacaBukuState();
}

class _BacaBukuState extends State<BacaBuku> {
  // ENKAPSULASI: semua data layar disimpan private (diawali _),
  // hanya diubah lewat method di kelas ini.
  final _supabase = Supabase.instance.client;

  bool _memuat = true;
  String? _error;
  List<Map<String, dynamic>> _halaman = [];
  int _indeks = 0;
  bool _sudahSelesai = false;
  Map<String, dynamic>? _kuis;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      final halaman = await _supabase
          .from('halaman_buku')
          .select('nomor_halaman, isi_halaman, ilustrasi')
          .eq('buku_id', widget.bukuId)
          .order('nomor_halaman');

      final progres = await _supabase
          .from('progres_membaca')
          .select('halaman_terakhir, status')
          .eq('anak_id', widget.anakId)
          .eq('buku_id', widget.bukuId)
          .limit(1);

      final kuis = await _supabase
          .from('kuis')
          .select('id, judul')
          .eq('buku_id', widget.bukuId)
          .order('id')
          .limit(1);

      final daftar = List<Map<String, dynamic>>.from(halaman);
      var indeks = 0;
      var selesai = false;

      if (progres.isNotEmpty) {
        selesai = progres.first['status'] == 'selesai';
        final terakhir = progres.first['halaman_terakhir'] as int;
        // Lanjut dari halaman terakhir, kecuali buku sudah selesai
        // (baca ulang dari awal).
        if (!selesai) {
          final i = daftar.indexWhere((h) => h['nomor_halaman'] == terakhir);
          if (i >= 0) indeks = i;
        }
      }

      setState(() {
        _halaman = daftar;
        _indeks = indeks;
        _sudahSelesai = selesai;
        _kuis = kuis.isEmpty ? null : Map<String, dynamic>.from(kuis.first);
        _memuat = false;
      });

      if (daftar.isNotEmpty) _simpanProgres();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  bool get _halamanTerakhir => _indeks == _halaman.length - 1;

  /// Menyimpan progres. Galat tidak ditampilkan ke anak,
  /// tapi dicetak ke konsol supaya mudah dicek saat pengembangan.
  Future<void> _simpanProgres() async {
    if (_halaman.isEmpty) return;

    final nomor = _halaman[_indeks]['nomor_halaman'] as int;
    if (_halamanTerakhir) _sudahSelesai = true;
    final status = _sudahSelesai ? 'selesai' : 'sedang_dibaca';

    final data = {
      'halaman_terakhir': nomor,
      'status': status,
      'terakhir_diperbarui': DateTime.now().toUtc().toIso8601String(),
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
    } catch (e) {
      debugPrint('Gagal menyimpan progres: $e');
    }
  }

  void _pindah(int arah) {
    final baru = _indeks + arah;
    if (baru < 0 || baru >= _halaman.length) return;
    setState(() => _indeks = baru);
    _simpanProgres();
  }

  void _mulaiKuis() {
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

  // Titik penanda halaman di bawah judul.
  Widget _penandaHalaman() {
    if (_halaman.length > 12) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
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
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _indeks ? Warna.emas : Warna.biruTitik,
            ),
          ),
      ],
    );
  }

  // Kotak ilustrasi: pakai gambar kalau ada, kalau tidak pakai huruf awal judul.
  Widget _ilustrasi(String? url) {
    final huruf = widget.judul.isNotEmpty ? widget.judul[0].toUpperCase() : '?';

    final penampung = LayoutBuilder(
      builder: (context, kotak) {
        final sisi = (kotak.maxWidth < kotak.maxHeight ? kotak.maxWidth : kotak.maxHeight) * 0.62;
        return Center(
          child: Container(
            width: sisi,
            height: sisi,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: sisi * 0.74,
                height: sisi * 0.74,
                decoration: const BoxDecoration(
                  color: Warna.hijauMuda,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(huruf, style: gaya(sisi * 0.42)),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Warna.hijauMuda,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url.isEmpty)
          ? penampung
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => penampung,
            ),
    );
  }

  Widget _tombolKanan() {
    if (!_halamanTerakhir) {
      return TombolPustakoo(label: 'Selanjutnya', onTap: () => _pindah(1));
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

  Widget _isi() {
    if (_memuat) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return KotakGalat(judul: 'Gagal memuat buku.', pesan: _error!, onUlang: _muat);
    }

    if (_halaman.isEmpty) {
      return Column(
        children: [
          _kepala(),
          const Expanded(child: Center(child: Text('Buku ini belum punya halaman.'))),
        ],
      );
    }

    final h = _halaman[_indeks];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        children: [
          _kepala(),
          _penandaHalaman(),
          const SizedBox(height: 12),
          Expanded(flex: 5, child: _ilustrasi(h['ilustrasi'] as String?)),
          const SizedBox(height: 12),
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
                  h['isi_halaman'] as String,
                  style: gaya(20, warna: Warna.teksCerita, tinggi: 1.35),
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
                  onTap: _indeks == 0 ? null : () => _pindah(-1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _tombolKanan()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kepala() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Warna.biruTua),
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

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(child: _isi());
  }
}