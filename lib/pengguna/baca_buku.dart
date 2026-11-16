import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kuis_buku.dart';

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

class _BacaBukuState extends State<BacaBuku> {
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
        // Lanjut dari halaman terakhir, kecuali bukunya sudah selesai
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

  /// Menyimpan progres. Galat sengaja tidak ditampilkan ke anak,
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

  Widget _ilustrasi(String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _isi() {
    if (_memuat) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat buku.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    if (_halaman.isEmpty) {
      return const Center(child: Text('Buku ini belum punya halaman.'));
    }

    final h = _halaman[_indeks];

    return Column(
      children: [
        LinearProgressIndicator(value: (_indeks + 1) / _halaman.length),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ilustrasi(h['ilustrasi'] as String?),
                Text(
                  h['isi_halaman'] as String,
                  style: const TextStyle(fontSize: 22, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _indeks == 0 ? null : () => _pindah(-1),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
                Expanded(
                  child: Text(
                    '${_indeks + 1} / ${_halaman.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!_halamanTerakhir)
                  ElevatedButton.icon(
                    onPressed: () => _pindah(1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Lanjut'),
                  )
                else if (_kuis != null)
                  ElevatedButton.icon(
                    onPressed: _mulaiKuis,
                    icon: const Icon(Icons.quiz),
                    label: const Text('Mulai Kuis'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Selesai'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: _isi(),
    );
  }
}
