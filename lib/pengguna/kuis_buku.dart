import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'progres_belajar.dart';
import 'tema_pustakoo.dart';

/// OOP: satu soal kuis dibungkus menjadi satu objek.
class _Soal {
  // ENKAPSULASI: field private, dibaca lewat getter.
  final String _pertanyaan;
  final String _benar;
  final List<String> _pilihan; // sudah diacak, isinya 3 pilihan (A, B, C)

  // CONSTRUCTOR biasa.
  _Soal(this._pertanyaan, this._benar, this._pilihan);

  // FACTORY CONSTRUCTOR: membuat soal dari satu baris database,
  // sekalian mengacak urutan pilihan (1 benar + 2 salah, sesuai Figma).
  factory _Soal.dariJson(Map<String, dynamic> r, Random acak) {
    final benar = r['jawaban_benar'] as String;
    final pilihan = <String>[
      benar,
      r['jawaban_salah_1'] as String,
      r['jawaban_salah_2'] as String,
    ]..shuffle(acak);
    return _Soal(r['isi_pertanyaan'] as String, benar, pilihan);
  }

  String get pertanyaan => _pertanyaan;
  List<String> get pilihan => List.unmodifiable(_pilihan);

  bool apakahBenar(int indeksPilihan) => _pilihan[indeksPilihan] == _benar;
}

/// Layar Interactive Reading (Figma: 08-kuis dan 09-hasil-kuis).
class KuisBuku extends StatefulWidget {
  final int anakId;
  final int kuisId;
  final String judul;

  // CONSTRUCTOR dengan parameter bernama.
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
  // ENKAPSULASI: semua data layar private.
  final _supabase = Supabase.instance.client;
  final _acak = Random();

  bool _memuat = true;
  String? _error;
  List<_Soal> _soal = [];
  int _indeks = 0;
  int _benar = 0;
  int? _dipilih; // indeks pilihan yang diketuk
  bool _terkirim = false; // sudah menekan Kirim Jawaban
  bool _selesai = false;
  double _nilai = 0;
  bool _gagalSimpan = false;
  String _namaAnak = 'Teman';

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
      // Nama panggilan untuk sapaan di layar hasil. Kalau gagal, pakai "Teman".
      try {
        final anak = await _supabase
            .from('anak')
            .select('nama_panggilan')
            .eq('id', widget.anakId)
            .limit(1);
        if (anak.isNotEmpty) _namaAnak = anak.first['nama_panggilan'] as String;
      } catch (_) {}

      final data = await _supabase
          .from('pertanyaan')
          .select('isi_pertanyaan, jawaban_benar, jawaban_salah_1, jawaban_salah_2')
          .eq('kuis_id', widget.kuisId)
          .order('id');

      // Tiap baris database diubah jadi objek _Soal lewat factory constructor.
      final soal = data.map<_Soal>((r) => _Soal.dariJson(r, _acak)).toList();

      setState(() {
        _soal = soal;
        _indeks = 0;
        _benar = 0;
        _dipilih = null;
        _terkirim = false;
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
    if (_terkirim) return;
    setState(() => _dipilih = i);
  }

  void _kirim() {
    if (_dipilih == null || _terkirim) return;
    setState(() {
      _terkirim = true;
      if (_soal[_indeks].apakahBenar(_dipilih!)) _benar++;
    });
  }

  Future<void> _lanjut() async {
    if (_indeks < _soal.length - 1) {
      setState(() {
        _indeks++;
        _dipilih = null;
        _terkirim = false;
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

  void _ulangi() {
    setState(() => _gagalSimpan = false);
    _muat();
  }

  void _lihatProgres() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgresBelajar(anakId: widget.anakId)),
    );
  }

  void _keBeranda() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // Warna kartu pilihan: biasa, terpilih, atau (setelah dikirim) benar/salah.
  ({Color isi, Color garis}) _warnaPilihan(int i) {
    final s = _soal[_indeks];

    if (_terkirim) {
      if (s.apakahBenar(i)) return (isi: Warna.hijauMuda, garis: Warna.hijau);
      if (i == _dipilih) {
        return (isi: const Color(0xFFFFD6D6), garis: const Color(0xFFE05555));
      }
    } else if (i == _dipilih) {
      return (isi: Warna.kuning, garis: Warna.emas);
    }
    return (isi: Colors.white, garis: Warna.biruMuda);
  }

  Widget _tampilanSoal() {
    final s = _soal[_indeks];
    const huruf = ['A', 'B', 'C'];
    final terakhir = _indeks == _soal.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Warna.kuning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Soal ${_indeks + 1} dari ${_soal.length}', style: gaya(13)),
              ),
              const Spacer(),
              const Panda(ukuran: 44),
            ],
          ),
          const SizedBox(height: 24),
          Text(s.pertanyaan, style: gaya(22, tinggi: 1.35)),
          const SizedBox(height: 22),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < s.pilihan.length; i++)
                  Builder(builder: (context) {
                    final w = _warnaPilihan(i);
                    return GestureDetector(
                      onTap: () => _pilih(i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: w.isi,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: w.garis, width: 3),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Warna.biruMuda,
                                shape: BoxShape.circle,
                              ),
                              child: Text(huruf[i], style: gaya(15)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s.pilihan[i], style: gaya(16))),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!_terkirim)
            TombolPustakoo(
              label: 'Kirim Jawaban',
              onTap: _dipilih == null ? null : _kirim,
              warna: Warna.biruTua,
              warnaTeks: Colors.white,
            )
          else
            TombolPustakoo(
              label: terakhir ? 'Lihat Hasil' : 'Lanjut',
              onTap: _lanjut,
              warna: Warna.biruTua,
              warnaTeks: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _tampilanHasil() {
    final bulat = _nilai.round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Panda(ukuran: 110),
          const SizedBox(height: 24),
          Text(
            bulat >= 60 ? 'Hebat, $_namaAnak!' : 'Ayo semangat, $_namaAnak!',
            textAlign: TextAlign.center,
            style: gaya(28),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('Skormu', style: gaya(14)),
                Text('$bulat', style: gaya(54, tinggi: 1.2)),
                Text('$_benar dari ${_soal.length} benar', style: gaya(14)),
                if (_gagalSimpan) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Nilai belum berhasil disimpan.',
                    style: gaya(13, warna: const Color(0xFFE05555)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          TombolPustakoo(label: 'Lihat Progres', onTap: _lihatProgres),
          const SizedBox(height: 12),
          TombolPustakoo(
            label: 'Ke Beranda',
            onTap: _keBeranda,
            warna: Warna.biruTua,
            warnaTeks: Colors.white,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _ulangi,
            child: Text('Ulangi Kuis', style: gaya(15)),
          ),
        ],
      ),
    );
  }

  Widget _isi() {
    if (_memuat) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return KotakGalat(judul: 'Gagal memuat kuis.', pesan: _error!, onUlang: _muat);
    }

    if (_soal.isEmpty) {
      return const Center(child: Text('Kuis ini belum punya pertanyaan.'));
    }

    return _selesai ? _tampilanHasil() : _tampilanSoal();
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(child: _isi());
  }
}