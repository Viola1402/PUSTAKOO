import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'model_belajar.dart';
import 'tema_pustakoo.dart';

/// Layar Progres Belajar (Figma: 10-progres-belajar).
class ProgresBelajar extends StatefulWidget {
  final int anakId;

  // CONSTRUCTOR dengan parameter bernama.
  const ProgresBelajar({super.key, required this.anakId});

  @override
  State<ProgresBelajar> createState() => _ProgresBelajarState();
}

class _ProgresBelajarState extends State<ProgresBelajar> {
  // ENKAPSULASI: semua data layar private.
  final _supabase = Supabase.instance.client;

  bool _memuat = true;
  String? _error;
  String _namaAnak = 'Teman';
  // OOP: data database diubah jadi objek dari kelas di model_belajar.dart.
  List<BukuSelesai> _bukuSelesai = [];
  List<RiwayatKuis> _skor = [];

  static const _warnaBuku = [
    Warna.hijauMuda,
    Warna.persik,
    Warna.biruTitik,
    Color(0xFFF8D7E6),
  ];

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
      final anak = await _supabase
          .from('anak')
          .select('nama_panggilan')
          .eq('id', widget.anakId)
          .limit(1);
      final nama = anak.isNotEmpty ? anak.first['nama_panggilan'] as String : 'Teman';

      // Buku yang sudah selesai dibaca.
      final progres = await _supabase
          .from('progres_membaca')
          .select('buku_id')
          .eq('anak_id', widget.anakId)
          .eq('status', 'selesai');

      final idBuku = progres.map<int>((p) => p['buku_id'] as int).toList();
      final bukuSelesai = <BukuSelesai>[];

      if (idBuku.isNotEmpty) {
        final buku = await _supabase
            .from('buku')
            .select('id, judul, kategori(nama)')
            .inFilter('id', idBuku)
            .order('judul');

        for (final b in buku) {
          // Objek dibuat lewat factory constructor.
          bukuSelesai.add(BukuSelesai.dariJson(b));
        }
      }

      // Nilai kuis per percobaan.
      final riwayat = await _supabase
          .from('riwayat_kuis')
          .select('kuis_id, percobaan_ke, nilai')
          .eq('anak_id', widget.anakId)
          .order('percobaan_ke');

      final perKuis = <int, List<TitikSkor>>{};
      for (final r in riwayat) {
        perKuis
            .putIfAbsent(r['kuis_id'] as int, () => [])
            .add(TitikSkor.dariJson(r)); // named constructor
      }

      final skor = <RiwayatKuis>[];
      if (perKuis.isNotEmpty) {
        final kuis = await _supabase
            .from('kuis')
            .select('id, judul')
            .inFilter('id', perKuis.keys.toList());

        final judulKuis = <int, String>{
          for (final k in kuis) k['id'] as int: k['judul'] as String,
        };

        perKuis.forEach((id, daftarTitik) {
          final rk = RiwayatKuis(judulKuis[id] ?? 'Kuis');
          for (final t in daftarTitik) {
            rk.tambah(t);
          }
          skor.add(rk);
        });
      }

      setState(() {
        _namaAnak = nama;
        _bukuSelesai = bukuSelesai;
        _skor = skor;
        _memuat = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  Widget _kepala() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 22),
      decoration: const BoxDecoration(
        color: Warna.biruMuda,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Warna.biruTua),
          ),
          const Panda(ukuran: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progres Belajar', style: gaya(20)),
                Text('Perkembangan $_namaAnak',
                    style: gaya(13, warna: Warna.biruGelap)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuBuku(BukuSelesai b, int urutan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _warnaBuku[urutan % _warnaBuku.length],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(b.hurufAwal, style: gaya(18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.judul, style: gaya(15)),
                Text(b.keterangan, style: gaya(12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuSkor(RiwayatKuis s) {
    // Tampilkan paling banyak 8 percobaan terakhir supaya grafik tetap rapi.
    final tampil = s.terakhir(8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skor Kuis: ${s.judul}', style: gaya(16)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(painter: _GrafikSkor(tampil)),
              ),
              const SizedBox(height: 6),
              Text(s.keterangan, style: gaya(13)),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _isi() {
    if (_memuat) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return KotakGalat(judul: 'Gagal memuat progres.', pesan: _error!, onUlang: _muat);
    }

    return Column(
      children: [
        _kepala(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _muat,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Buku Selesai Dibaca', style: gaya(16)),
                const SizedBox(height: 10),
                if (_bukuSelesai.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Belum ada buku yang selesai dibaca.', style: gaya(13)),
                  ),
                for (var i = 0; i < _bukuSelesai.length; i++)
                  _kartuBuku(_bukuSelesai[i], i),
                const SizedBox(height: 14),
                if (_skor.isEmpty) Text('Belum ada nilai kuis.', style: gaya(13)),
                for (final s in _skor) _kartuSkor(s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(child: _isi());
  }
}

/// Grafik garis nilai kuis per percobaan (Ke-1, Ke-2, ...).
class _GrafikSkor extends CustomPainter {
  // ENKAPSULASI: data grafik private.
  final List<TitikSkor> _data;

  // CONSTRUCTOR
  _GrafikSkor(this._data);

  void _teks(Canvas canvas, String isi, Offset tengah, double ukuran) {
    final tp = TextPainter(
      text: TextSpan(text: isi, style: gaya(ukuran)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(tengah.dx - tp.width / 2, tengah.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_data.isEmpty) return;

    const padX = 30.0;
    const atas = 28.0;
    const bawah = 26.0;
    final lebar = size.width - padX * 2;
    final tinggi = size.height - atas - bawah;

    Offset posisi(int i) {
      final x = _data.length == 1 ? size.width / 2 : padX + lebar * i / (_data.length - 1);
      final y = atas + tinggi * (1 - _data[i].nilai / 100);
      return Offset(x, y);
    }

    final garis = Paint()
      ..color = Warna.biruTua
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _data.length - 1; i++) {
      canvas.drawLine(posisi(i), posisi(i + 1), garis);
    }

    final isi = Paint()..color = Warna.emas;
    final tepi = Paint()
      ..color = Warna.biruTua
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < _data.length; i++) {
      final p = posisi(i);
      canvas.drawCircle(p, 7, isi);
      canvas.drawCircle(p, 7, tepi);
      _teks(canvas, _data[i].nilai.round().toString(), Offset(p.dx, p.dy - 18), 13);
      _teks(canvas, 'Ke-${_data[i].ke}', Offset(p.dx, size.height - 8), 12);
    }
  }

  @override
  bool shouldRepaint(covariant _GrafikSkor lama) => true;
}