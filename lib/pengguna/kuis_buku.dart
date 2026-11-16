import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Soal {
  final String pertanyaan;
  final String benar;
  final List<String> pilihan; // sudah diacak, isinya 3 pilihan (A, B, C)

  _Soal(this.pertanyaan, this.benar, this.pilihan);
}

class KuisBuku extends StatefulWidget {
  final int anakId;
  final int kuisId;
  final String judul;

  const KuisBuku({
    super.key,
    required this.anakId,
    required this.kuisId,
    required this.judul,
  });

  @override
  State<KuisBuku> createState() => _KuisBukuState();
}

class _KuisBukuState extends State<KuisBuku> {
  final _supabase = Supabase.instance.client;
  final _acak = Random();

  bool _memuat = true;
  String? _error;
  List<_Soal> _soal = [];
  int _indeks = 0;
  int _benar = 0;
  int? _dipilih; // indeks pilihan yang diketuk
  bool _selesai = false;
  double _nilai = 0;
  bool _gagalSimpan = false;

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
      final data = await _supabase
          .from('pertanyaan')
          .select('isi_pertanyaan, jawaban_benar, jawaban_salah_1, jawaban_salah_2')
          .eq('kuis_id', widget.kuisId)
          .order('id');

      // Sesuai desain Figma: 3 pilihan (1 benar + 2 salah), urutannya diacak.
      final soal = data.map<_Soal>((r) {
        final benar = r['jawaban_benar'] as String;
        final pilihan = <String>[
          benar,
          r['jawaban_salah_1'] as String,
          r['jawaban_salah_2'] as String,
        ]..shuffle(_acak);
        return _Soal(r['isi_pertanyaan'] as String, benar, pilihan);
      }).toList();

      setState(() {
        _soal = soal;
        _indeks = 0;
        _benar = 0;
        _dipilih = null;
        _selesai = false;
        _memuat = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  void _pilih(int i) {
    if (_dipilih != null) return; // sudah menjawab
    setState(() {
      _dipilih = i;
      if (_soal[_indeks].pilihan[i] == _soal[_indeks].benar) _benar++;
    });
  }

  Future<void> _lanjut() async {
    if (_indeks < _soal.length - 1) {
      setState(() {
        _indeks++;
        _dipilih = null;
      });
      return;
    }

    final nilai = _soal.isEmpty ? 0.0 : _benar / _soal.length * 100;
    setState(() {
      _nilai = nilai;
      _selesai = true;
    });
    await _simpanNilai(nilai);
  }

  Future<void> _simpanNilai(double nilai) async {
    try {
      final lama = await _supabase
          .from('riwayat_kuis')
          .select('id')
          .eq('anak_id', widget.anakId)
          .eq('kuis_id', widget.kuisId);

      await _supabase.from('riwayat_kuis').insert({
        'anak_id': widget.anakId,
        'kuis_id': widget.kuisId,
        'percobaan_ke': lama.length + 1,
        'nilai': nilai,
      });
    } catch (e) {
      debugPrint('Gagal menyimpan nilai kuis: $e');
      if (mounted) setState(() => _gagalSimpan = true);
    }
  }

  Color? _warnaPilihan(int i) {
    if (_dipilih == null) return null;
    final s = _soal[_indeks];
    if (s.pilihan[i] == s.benar) return Colors.green.shade100;
    if (i == _dipilih) return Colors.red.shade100;
    return null;
  }

  Widget _tampilanSoal() {
    final s = _soal[_indeks];
    const huruf = ['A', 'B', 'C'];
    final terakhir = _indeks == _soal.length - 1;

    return Column(
      children: [
        LinearProgressIndicator(value: (_indeks + 1) / _soal.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Pertanyaan ${_indeks + 1} dari ${_soal.length}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                s.pertanyaan,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < s.pilihan.length; i++)
                Card(
                  color: _warnaPilihan(i),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _pilih(i),
                    leading: CircleAvatar(child: Text(huruf[i])),
                    title: Text(s.pilihan[i], style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dipilih == null ? null : _lanjut,
                child: Text(terakhir ? 'Lihat Hasil' : 'Lanjut'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tampilanHasil() {
    final bulat = _nilai.round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bulat >= 60 ? Icons.emoji_events : Icons.menu_book,
              size: 80,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              bulat >= 60 ? 'Hebat!' : 'Ayo coba lagi!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Benar $_benar dari ${_soal.length} soal',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Nilai: $bulat',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            if (_gagalSimpan) ...[
              const SizedBox(height: 12),
              Text(
                'Nilai belum berhasil disimpan.',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _ulangi, child: const Text('Ulangi Kuis')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }

  void _ulangi() {
    setState(() => _gagalSimpan = false);
    _muat();
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
              const Text('Gagal memuat kuis.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    if (_soal.isEmpty) {
      return const Center(child: Text('Kuis ini belum punya pertanyaan.'));
    }

    return _selesai ? _tampilanHasil() : _tampilanSoal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: _isi(),
    );
  }
}
