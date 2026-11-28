
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'model_belajar.dart';
import 'tema_pustakoo.dart';

/// Layar Progres Belajar.
class ProgresBelajar extends StatefulWidget {
  final int anakId;

  // CONSTRUCTOR
  const ProgresBelajar({super.key, required this.anakId});

  @override
  State<ProgresBelajar> createState() => _ProgresBelajarState();
}

class _ProgresBelajarState extends State<ProgresBelajar> {
  // ENKAPSULASI
  final _supabase = Supabase.instance.client;

  bool _memuat = true;
  String? _error;
  String _namaAnak = 'Teman';

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
    if (!mounted) return;

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

      final nama = anak.isNotEmpty
          ? anak.first['nama_panggilan'] as String
          : 'Teman';

      // Mengambil buku yang sudah selesai dibaca.
      final progres = await _supabase
          .from('progres_membaca')
          .select('buku_id')
          .eq('anak_id', widget.anakId)
          .eq('status', 'selesai');

      final idBuku = progres
          .map<int>((p) => p['buku_id'] as int)
          .toList();

      final bukuSelesai = <BukuSelesai>[];

      if (idBuku.isNotEmpty) {
        final buku = await _supabase
            .from('buku')
            .select('id, judul, kategori(nama)')
            .inFilter('id', idBuku)
            .order('judul');

        for (final b in buku) {
          bukuSelesai.add(BukuSelesai.dariJson(b));
        }
      }

      // Mengambil nilai kuis setiap percobaan.
      final riwayat = await _supabase
          .from('riwayat_kuis')
          .select('kuis_id, percobaan_ke, nilai')
          .eq('anak_id', widget.anakId)
          .order('percobaan_ke');

      final perKuis = <int, List<TitikSkor>>{};

      for (final r in riwayat) {
        perKuis
            .putIfAbsent(r['kuis_id'] as int, () => [])
            .add(TitikSkor.dariJson(r));
      }

      final skor = <RiwayatKuis>[];

      if (perKuis.isNotEmpty) {
        final kuis = await _supabase
            .from('kuis')
            .select('id, judul')
            .inFilter('id', perKuis.keys.toList());

        final judulKuis = <int, String>{
          for (final k in kuis)
            k['id'] as int: k['judul'] as String,
        };

        perKuis.forEach((id, daftarTitik) {
          final rk = RiwayatKuis(judulKuis[id] ?? 'Kuis');

          for (final t in daftarTitik) {
            rk.tambah(t);
          }

          skor.add(rk);
        });
      }

      if (!mounted) return;

      setState(() {
        _namaAnak = nama;
        _bukuSelesai = bukuSelesai;
        _skor = skor;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  // HEADER HALAMAN
  Widget _kepala() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 22),
      decoration: const BoxDecoration(
        color: Warna.biruMuda,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Warna.biruTua,
            ),
          ),
          const Panda(ukuran: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progres Belajar', style: gaya(20)),
                Text(
                  'Perkembangan $_namaAnak',
                  style: gaya(13, warna: Warna.biruGelap),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // JUDUL BAGIAN
  Widget _judulBagian(String judul, IconData ikon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            ikon,
            color: Warna.biruTua,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(judul, style: gaya(17)),
          ),
        ],
      ),
    );
  }

  // KARTU BUKU SELESAI
  Widget _kartuBuku(BukuSelesai b, int urutan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFEDF1F5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _warnaBuku[urutan % _warnaBuku.length],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              b.hurufAwal,
              style: gaya(18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.judul,
                  style: gaya(13),
                ),
                const SizedBox(height: 3),
                Text(
                  b.keterangan,
                  style: gaya(11, warna: Warna.biruGelap),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF20B28C),
            size: 23,
          ),
        ],
      ),
    );
  }

  // DAFTAR BUKU SELESAI DALAM SATU KARTU
  Widget _kartuDaftarBuku() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9F0F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BUKU YANG SUDAH DITAMATKAN',
                  style: gaya(
                    12,
                    warna: const Color(0xFF718096),
                  ),
                ),
              ),
              Text(
                '${_bukuSelesai.length} Buku',
                style: gaya(
                  11,
                  warna: Warna.biruTua,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (_bukuSelesai.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: Colors.grey.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada buku yang ditamatkan.',
                      style: gaya(
                        12,
                        warna: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < _bukuSelesai.length; i++)
            _kartuBuku(_bukuSelesai[i], i),
        ],
      ),
    );
  }

  // KARTU GRAFIK SKOR KUIS
  Widget _kartuSkor(RiwayatKuis s) {
    final tampil = s.terakhir(8);

    final nilaiTertinggi = tampil.isEmpty
        ? 0
        : tampil
            .map((t) => t.nilai)
            .reduce((a, b) => a > b ? a : b)
            .round();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9F0F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JUDUL DAN NILAI TERTINGGI
          Row(
            children: [
              Expanded(
                child: Text(
                  'Skor Kuis: ${s.judul}',
                  style: gaya(14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF5DF91),
                  ),
                ),
                child: Text(
                  '☆ Nilai $nilaiTertinggi',
                  style: gaya(
                    11,
                    warna: const Color(0xFFB58A18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Makin sering membaca, pemahaman $_namaAnak makin keren!',
            style: gaya(
              12,
              warna: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 13),

          // AREA GRAFIK
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SizedBox(
              height: 165,
              width: double.infinity,
              child: CustomPaint(
                painter: _GrafikSkor(tampil),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.keterangan,
            style: gaya(
              12,
              warna: Warna.biruGelap,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(
            color: Color(0xFFEDF1F5),
            height: 1,
          ),
          const SizedBox(height: 14),
          _kartuDaftarBuku(),
        ],
      ),
    );
  }

  // KONTEN HALAMAN
  Widget _isi() {
    if (_memuat) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return KotakGalat(
        judul: 'Gagal memuat progres.',
        pesan: _error!,
        onUlang: _muat,
      );
    }

    return Column(
      children: [
        _kepala(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _muat,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                // BAGIAN PERKEMBANGAN KUIS
                _judulBagian(
                  'Perkembangan Kuis $_namaAnak',
                  Icons.insights,
                ),

                if (_skor.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ada nilai kuis.',
                        style: gaya(13),
                      ),
                    ),
                  ),

                for (final s in _skor) _kartuSkor(s),

                const SizedBox(height: 5),

                // BAGIAN BUKU SELESAI
                _judulBagian(
                  'Buku Selesai Dibaca',
                  Icons.menu_book_rounded,
                ),

                _kartuDaftarBuku(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(
      child: _isi(),
    );
  }
}

/// Grafik garis nilai kuis per percobaan.
class _GrafikSkor extends CustomPainter {
  // ENKAPSULASI
  final List<TitikSkor> _data;

  // CONSTRUCTOR
  _GrafikSkor(this._data);

  void _teks(
    Canvas canvas,
    String isi,
    Offset tengah,
    double ukuran,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: isi,
        style: gaya(ukuran),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        tengah.dx - tp.width / 2,
        tengah.dy - tp.height / 2,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_data.isEmpty) return;

    const padX = 30.0;
    const atas = 32.0;
    const bawah = 30.0;

    final lebar = size.width - padX * 2;
    final tinggi = size.height - atas - bawah;

    Offset posisi(int i) {
      final x = _data.length == 1
          ? size.width / 2
          : padX + lebar * i / (_data.length - 1);

      final nilai = _data[i].nilai.clamp(0, 100);
      final y = atas + tinggi * (1 - nilai / 100);

      return Offset(x, y);
    }

    // GARIS GRAFIK
    final garis = Paint()
      ..color = Warna.biruTua
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // GARIS PANDU
    final garisPanduan = Paint()
      ..color = const Color(0xFFDCE8F0)
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      final y = atas + tinggi * i / 2;

      canvas.drawLine(
        Offset(padX, y),
        Offset(size.width - padX, y),
        garisPanduan,
      );
    }

    // MENGGAMBAR GARIS ANTAR TITIK
    for (var i = 0; i < _data.length - 1; i++) {
      canvas.drawLine(
        posisi(i),
        posisi(i + 1),
        garis,
      );
    }

    final isi = Paint()
      ..color = Warna.emas;

    final tepi = Paint()
      ..color = Warna.biruTua
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // TITIK DAN LABEL NILAI
    for (var i = 0; i < _data.length; i++) {
      final p = posisi(i);

      canvas.drawCircle(p, 7, isi);
      canvas.drawCircle(p, 7, tepi);

      _teks(
        canvas,
        _data[i].nilai.round().toString(),
        Offset(p.dx, p.dy - 19),
        12,
      );

      _teks(
        canvas,
        'Ke-${_data[i].ke}',
        Offset(p.dx, size.height - 9),
        11,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrafikSkor lama) {
    return true;
  }
}
