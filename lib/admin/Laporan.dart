import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

// ==========================================================
// HALAMAN LAPORAN & ANALITIK
// Sumber data:
// - buku(id, judul, kategori_id, status, tingkat_membaca)
// - kategori(id, nama)
// - kuis(id, buku_id, judul)
// - pertanyaan(id, kuis_id, ...)
// - riwayat_kuis(id, nilai, anak_id, kuis_id, waktu_selesai, percobaan_ke)
// - anak(id, pengguna_id, nama_panggilan, usia)
// - misi(id, judul, deskripsi, target, hadiah_poin)
// ==========================================================

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final supabase = Supabase.instance.client;

  String periode = '7 Hari Terakhir';
  bool urutTertinggi = true;

  bool sedangMemuat = true;
  String? pesanError;

  List<Map<String, dynamic>> _ringkasan = [];
  List<Map<String, dynamic>> _ceritaPopuler = [];
  List<Map<String, dynamic>> _skorKuis = [];
  List<Map<String, dynamic>> _misi = [];
  List<Map<String, dynamic>> _aktivitas = [];
  List<double> _distribusiHarian = List<double>.filled(7, 0);
  List<String> _labelHari = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  // --------------------------------------------------------
  // PEMBANTU
  // --------------------------------------------------------

  String teks(dynamic nilai, [String nilaiAwal = '-']) {
    if (nilai == null || nilai.toString().trim().isEmpty) return nilaiAwal;
    return nilai.toString();
  }

  int angka(dynamic nilai) {
    if (nilai is num) return nilai.toInt();
    return int.tryParse(nilai?.toString() ?? '') ?? 0;
  }

  double desimal(dynamic nilai) {
    if (nilai is num) return nilai.toDouble();
    return double.tryParse(nilai?.toString() ?? '') ?? 0;
  }

  DateTime get _batasPeriode {
    final sekarang = DateTime.now();

    return switch (periode) {
      '30 Hari Terakhir' => sekarang.subtract(const Duration(days: 30)),
      'Semua Waktu' => DateTime(2000),
      _ => sekarang.subtract(const Duration(days: 7)),
    };
  }

  // --------------------------------------------------------
  // MUAT DATA
  // --------------------------------------------------------

  Future<void> _muat() async {
    if (!mounted) return;

    setState(() {
      sedangMemuat = true;
      pesanError = null;
    });

    try {
      final hasilBuku = await supabase
          .from('buku')
          .select('id, judul, kategori_id, status, tingkat_membaca');

      final hasilKategori = await supabase.from('kategori').select('id, nama');

      final hasilKuis = await supabase
          .from('kuis')
          .select('id, buku_id, judul');

      final hasilAnak = await supabase.from('anak').select('id');

      final hasilMisi = await supabase
          .from('misi')
          .select('id, judul, target, hadiah_poin')
          .order('id');

      var kueriRiwayat = supabase
          .from('riwayat_kuis')
          .select('nilai, anak_id, kuis_id, waktu_selesai');

      if (periode != 'Semua Waktu') {
        kueriRiwayat = kueriRiwayat.gte(
          'waktu_selesai',
          _batasPeriode.toIso8601String(),
        );
      }

      final hasilRiwayat = await kueriRiwayat
          .order('waktu_selesai', ascending: false)
          .limit(2000);

      if (!mounted) return;

      final petaBuku = <String, Map<String, dynamic>>{};
      for (final item in hasilBuku) {
        petaBuku[item['id'].toString()] = item;
      }

      final petaKuis = <String, String>{};
      for (final item in hasilKuis) {
        petaKuis[item['id'].toString()] = item['buku_id'].toString();
      }

      final petaKategori = <String, String>{};
      for (final item in hasilKategori) {
        petaKategori[item['id'].toString()] = teks(item['nama']);
      }

      final riwayat = List<Map<String, dynamic>>.from(hasilRiwayat);

      // Kelompokkan riwayat kuis per buku.
      final perBuku = <String, List<Map<String, dynamic>>>{};
      final anakAktif = <String>{};
      var totalNilai = 0.0;
      var nilaiTertinggi = 0.0;
      var nilaiTerendah = 0.0;

      for (var i = 0; i < riwayat.length; i++) {
        final baris = riwayat[i];
        final nilai = desimal(baris['nilai']);

        totalNilai += nilai;
        if (i == 0 || nilai > nilaiTertinggi) nilaiTertinggi = nilai;
        if (i == 0 || nilai < nilaiTerendah) nilaiTerendah = nilai;

        if (baris['anak_id'] != null) {
          anakAktif.add(baris['anak_id'].toString());
        }

        final idBuku =
            petaKuis[baris['kuis_id']?.toString()] ?? '';

        if (idBuku.isEmpty) continue;

        perBuku.putIfAbsent(idBuku, () => []).add(baris);
      }

      final rataRata = riwayat.isEmpty ? 0 : (totalNilai / riwayat.length).round();

      final jumlahDiterbitkan = hasilBuku
          .where((item) => item['status']?.toString() == 'diterbitkan')
          .length;

      // Cerita terpopuler berdasarkan jumlah riwayat kuis per buku.
      final daftarPopuler = perBuku.entries.map((entri) {
        final buku = petaBuku[entri.key] ?? <String, dynamic>{};
        final idKategori = buku['kategori_id']?.toString() ?? '';

        return <String, dynamic>{
          'judul': teks(buku['judul'], 'Tanpa Judul'),
          'kategori': petaKategori[idKategori] ?? 'Tanpa Kategori',
          'level': teks(buku['tingkat_membaca'], 'Belum diatur'),
          'dibaca': entri.value.length,
          'persen': 0.0,
        };
      }).toList()
        ..sort(
          (a, b) => (b['dibaca'] as int).compareTo(a['dibaca'] as int),
        );

      final puncak = daftarPopuler.isEmpty
          ? 1
          : daftarPopuler.first['dibaca'] as int;

      for (final item in daftarPopuler) {
        item['persen'] = (item['dibaca'] as int) / puncak;
      }

      // Rata-rata skor kuis per buku.
      final daftarSkor = perBuku.entries.map((entri) {
        final buku = petaBuku[entri.key] ?? <String, dynamic>{};
        final idKategori = buku['kategori_id']?.toString() ?? '';
        final nilai = entri.value.map((baris) => desimal(baris['nilai'])).toList();
        final rata = nilai.isEmpty
            ? 0.0
            : nilai.reduce((a, b) => a + b) / nilai.length;
        final lulus = nilai.isEmpty
            ? 0.0
            : nilai.where((n) => n >= 75).length / nilai.length * 100;
        final jumlahAnak = entri.value
            .map((baris) => baris['anak_id']?.toString())
            .whereType<String>()
            .toSet()
            .length;

        return <String, dynamic>{
          'judul': teks(buku['judul'], 'Tanpa Judul'),
          'kategori': petaKategori[idKategori] ?? 'Tanpa Kategori',
          'skor': rata.round(),
          'lulus': lulus.round(),
          'siswa': jumlahAnak,
        };
      }).toList()
        ..sort(
          (a, b) => (b['skor'] as int).compareTo(a['skor'] as int),
        );

      // Distribusi aktivitas 7 hari terakhir.
      final hitungHarian = List<int>.filled(7, 0);
      final sekarang = DateTime.now();
      final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);

      for (final baris in riwayat) {
        final waktu = DateTime.tryParse(
          baris['waktu_selesai']?.toString() ?? '',
        );
        if (waktu == null) continue;

        final tanggal = DateTime(waktu.year, waktu.month, waktu.day);
        final selisih = hariIni.difference(tanggal).inDays;

        if (selisih < 0 || selisih > 6) continue;

        hitungHarian[6 - selisih] += 1;
      }

      final tertinggiHarian = hitungHarian.fold<int>(0, (a, b) => a > b ? a : b);

      final labelHari = List<String>.generate(7, (i) {
        final tanggal = hariIni.subtract(Duration(days: 6 - i));
        return const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][
            tanggal.weekday - 1];
      });

      setState(() {
        _ringkasan = [
          {
            'judul': 'TOTAL KUIS DIKERJAKAN',
            'nilai': '${riwayat.length}',
            'satuan': 'Percobaan',
            'catatan': periode,
            'ikon': Icons.quiz_outlined,
            'warna': GayaAdmin.biruMuda,
          },
          {
            'judul': 'RATA-RATA SKOR KUIS',
            'nilai': '$rataRata',
            'satuan': '/ 100',
            'catatan': 'Ambang kelulusan 75',
            'ikon': Icons.insights_outlined,
            'warna': Colors.white,
          },
          {
            'judul': 'BUKU DITERBITKAN',
            'nilai': '$jumlahDiterbitkan',
            'satuan': 'Buku',
            'catatan': '${hasilBuku.length} buku di database',
            'ikon': Icons.menu_book_outlined,
            'warna': Colors.white,
          },
          {
            'judul': 'ANAK TERDAFTAR',
            'nilai': '${hasilAnak.length}',
            'satuan': 'Anak',
            'catatan': '${anakAktif.length} aktif di periode ini',
            'ikon': Icons.child_care_outlined,
            'warna': GayaAdmin.krem,
          },
        ];

        _ceritaPopuler = daftarPopuler.take(5).toList();
        _skorKuis = daftarSkor;

        _aktivitas = [
          {
            'judul': 'Kuis Dikerjakan',
            'nilai': '${riwayat.length}',
            'satuan': 'Percobaan',
          },
          {
            'judul': 'Rata-rata Nilai',
            'nilai': '$rataRata',
            'satuan': '/ 100',
          },
          {
            'judul': 'Anak Aktif',
            'nilai': '${anakAktif.length}',
            'satuan': 'Anak',
          },
          {
            'judul': 'Buku Dikerjakan',
            'nilai': '${perBuku.length}',
            'satuan': 'Buku',
          },
          {
            'judul': 'Nilai Tertinggi',
            'nilai': '${nilaiTertinggi.round()}',
            'satuan': 'Poin',
          },
          {
            'judul': 'Nilai Terendah',
            'nilai': '${nilaiTerendah.round()}',
            'satuan': 'Poin',
          },
        ];

        _distribusiHarian = tertinggiHarian == 0
            ? List<double>.filled(7, 0)
            : hitungHarian
                .map((jumlah) => jumlah / tertinggiHarian)
                .toList();
        _labelHari = labelHari;

        _misi = hasilMisi.map<Map<String, dynamic>>((item) {
          return {
            'judul': teks(item['judul'], 'Misi'),
            'persen': 0.0,
            'catatan':
                'Target ${angka(item['target'])} • '
                '${angka(item['hadiah_poin'])} poin',
          };
        }).toList();

        sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangMemuat = false;
        pesanError = e.toString();
      });
    }
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Laporan',
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RemahAdmin(['Dashboard', 'Laporan']),
                _judulHalaman(),
                const SizedBox(height: 14),
                if (sedangMemuat)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                if (pesanError != null) ...[
                  _kartuError(),
                  const SizedBox(height: 12),
                ],
                _barisStatistik(lebar),
                const SizedBox(height: 14),
                if (lebar > 1050)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _kartuCeritaPopuler()),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: _kartuSkorKuis()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _kartuCeritaPopuler(),
                      const SizedBox(height: 12),
                      _kartuSkorKuis(),
                    ],
                  ),
                const SizedBox(height: 12),
                if (lebar > 1050)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _kartuAktivitas()),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: _kartuMisi()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _kartuAktivitas(),
                      const SizedBox(height: 12),
                      _kartuMisi(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------
  // JUDUL HALAMAN
  // --------------------------------------------------------

  Widget _judulHalaman() {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final kontrol = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GayaAdmin.garis),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: periode,
                  isDense: true,
                  borderRadius: BorderRadius.circular(9),
                  icon: const Icon(
                    Icons.expand_more,
                    size: 15,
                    color: GayaAdmin.teksAbu,
                  ),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: GayaAdmin.teks,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '7 Hari Terakhir',
                      child: Text('7 Hari Terakhir'),
                    ),
                    DropdownMenuItem(
                      value: '30 Hari Terakhir',
                      child: Text('30 Hari Terakhir'),
                    ),
                    DropdownMenuItem(
                      value: 'Semua Waktu',
                      child: Text('Semua Waktu'),
                    ),
                  ],
                  onChanged: (nilai) {
                    if (nilai == null || nilai == periode) return;
                    setState(() => periode = nilai);
                    _muat();
                  },
                ),
              ),
            ),
            TombolAdmin(
              teks: 'Unduh CSV / PDF',
              ikon: Icons.download_outlined,
              utama: false,
              onPressed: () => _pesan('Unduhan laporan belum dihubungkan.'),
            ),
            TombolAdmin(
              teks: 'Buat Laporan Khusus',
              ikon: Icons.add_chart,
              onPressed: () => _pesan(
                'Pembuatan laporan khusus belum dihubungkan.',
              ),
            ),
          ],
        );

        final judul = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: GayaAdmin.biruMuda,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.insert_chart_outlined,
                    size: 19,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Laporan & Analitik',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GayaAdmin.biruTua,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Ringkasan hasil kuis anak, buku paling sering dikerjakan, '
              'keaktifan pengguna, dan daftar misi gamifikasi.',
              style: TextStyle(
                fontSize: 11.5,
                color: GayaAdmin.teksAbu,
                height: 1.45,
              ),
            ),
          ],
        );

        if (ukuran.maxWidth > 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: judul),
              const SizedBox(width: 12),
              kontrol,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            judul,
            const SizedBox(height: 10),
            kontrol,
          ],
        );
      },
    );
  }

  // --------------------------------------------------------
  // STATISTIK
  // --------------------------------------------------------

  Widget _barisStatistik(double lebar) {
    final kolom = lebar > 1050
        ? 4
        : lebar > 560
            ? 2
            : 1;
    final celah = 12.0;
    final lebarKartu = (lebar - celah * (kolom - 1)) / kolom;

    return Wrap(
      spacing: celah,
      runSpacing: celah,
      children: [
        for (final item in _ringkasan)
          SizedBox(
            width: lebarKartu,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item['warna'] as Color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GayaAdmin.garis),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['judul'] as String,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: GayaAdmin.teksAbu,
                            letterSpacing: 0.4,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Icon(
                        item['ikon'] as IconData,
                        size: 17,
                        color: GayaAdmin.biruTua,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['nilai'] as String,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: GayaAdmin.biruTua,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          item['satuan'] as String,
                          style: const TextStyle(
                            fontSize: 9,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item['catatan'] as String,
                    style: const TextStyle(
                      fontSize: 8.5,
                      height: 1.3,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------
  // CERITA TERPOPULER
  // --------------------------------------------------------

  Widget _kartuCeritaPopuler() {
    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.local_fire_department_outlined,
            judul: 'Cerita Terpopuler',
            subjudul: 'Buku yang paling sering dikerjakan kuisnya',
            kanan: ChipAdmin(periode, kecil: true),
          ),
          const SizedBox(height: 12),
          if (_ceritaPopuler.isEmpty)
            _teksKosong(
              'Belum ada riwayat kuis pada periode ini.',
            )
          else
            for (var i = 0; i < _ceritaPopuler.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _barisCerita(_ceritaPopuler[i], i + 1),
              ),
          const Divider(height: 1, color: GayaAdmin.garis),
          const SizedBox(height: 8),
          Text(
            'Menampilkan ${_ceritaPopuler.length} buku teratas',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biru,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisCerita(Map<String, dynamic> item, int peringkat) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: peringkat == 1
                ? GayaAdmin.krem
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '$peringkat',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: peringkat == 1
                  ? const Color(0xFFC0781A)
                  : GayaAdmin.teksAbu,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(
            Icons.menu_book,
            size: 14,
            color: GayaAdmin.biruTua,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['judul'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${item['kategori']} • ${item['level']}',
                style: const TextStyle(
                  fontSize: 8,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item['persen'] as double).clamp(0.0, 1.0),
                  minHeight: 3.5,
                  backgroundColor: const Color(0xFFEDF2F8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    peringkat == 1
                        ? const Color(0xFFC0781A)
                        : GayaAdmin.biru,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item['dibaca']}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            const Text(
              'dikerjakan',
              style: TextStyle(
                fontSize: 7.5,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // SKOR KUIS
  // --------------------------------------------------------

  Widget _kartuSkorKuis() {
    final daftar = List<Map<String, dynamic>>.from(_skorKuis)
      ..sort((a, b) => urutTertinggi
          ? (b['skor'] as int).compareTo(a['skor'] as int)
          : (a['skor'] as int).compareTo(b['skor'] as int));

    final skorTerendah = _skorKuis.isEmpty
        ? null
        : _skorKuis
            .map((item) => item['skor'] as int)
            .reduce((a, b) => a < b ? a : b);

    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.insights_outlined,
            judul: 'Rata-rata Skor Kuis per Buku',
            subjudul: 'Tingkat pemahaman anak berdasarkan hasil kuis',
            kanan: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  _tombolUrut('Tertinggi', urutTertinggi, () {
                    setState(() => urutTertinggi = true);
                  }),
                  _tombolUrut('Rendah', !urutTertinggi, () {
                    setState(() => urutTertinggi = false);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (daftar.isEmpty)
            _teksKosong('Belum ada nilai kuis yang tercatat.')
          else
            for (final item in daftar)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _barisSkor(item, item['skor'] == skorTerendah),
              ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GayaAdmin.garis),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: GayaAdmin.teksAbu,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Skor di atas 75 menandakan naskah mudah dipahami anak '
                    'sesuai jenjang usia.',
                    style: TextStyle(
                      fontSize: 8.5,
                      height: 1.4,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolUrut(String teks, bool aktif, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: aktif ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: aktif ? GayaAdmin.garis : Colors.transparent,
          ),
        ),
        child: Text(
          teks,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: aktif ? GayaAdmin.biruTua : GayaAdmin.teksAbu,
          ),
        ),
      ),
    );
  }

  Widget _barisSkor(Map<String, dynamic> item, bool terendah) {
    final skor = item['skor'] as int;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 5,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item['judul'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: GayaAdmin.biruTua,
                    ),
                  ),
                  if (terendah)
                    const ChipAdmin(
                      'Terendah',
                      kecil: true,
                      warna: GayaAdmin.oranyeMuda,
                      teksWarna: GayaAdmin.oranye,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Kelulusan ${item['lulus']}%',
                style: const TextStyle(
                  fontSize: 8,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: skor / 100,
                  minHeight: 3.5,
                  backgroundColor: const Color(0xFFEDF2F8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    skor >= 85
                        ? GayaAdmin.biru
                        : skor >= 80
                            ? const Color(0xFF5B9BC9)
                            : const Color(0xFFC7D7E8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$skor / 100',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${item['siswa']} anak',
              style: const TextStyle(
                fontSize: 7.5,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // AKTIVITAS
  // --------------------------------------------------------

  Widget _kartuAktivitas() {
    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.bolt_outlined,
            judul: 'Aktivitas & Keterlibatan',
            subjudul: 'Ringkasan metrik keterlibatan anak pada periode ini',
            kanan: ChipAdmin(periode, kecil: true),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _aktivitas)
                SizedBox(
                  width: 132,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: GayaAdmin.garis),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['judul'] as String,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['nilai'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: GayaAdmin.biruTua,
                          ),
                        ),
                        Text(
                          item['satuan'] as String,
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Distribusi Aktivitas Harian',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const Spacer(),
              const Text(
                '7 hari terakhir',
                style: TextStyle(
                  fontSize: 8,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _distribusiHarian.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 58 * _distribusiHarian[i],
                            decoration: BoxDecoration(
                              color: _distribusiHarian[i] >= 0.9
                                  ? GayaAdmin.biruTua
                                  : _distribusiHarian[i] >= 0.7
                                      ? GayaAdmin.biru
                                      : const Color(0xFFBEDCF0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labelHari[i],
                            style: const TextStyle(
                              fontSize: 7.5,
                              color: GayaAdmin.teksAbu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // MISI
  // --------------------------------------------------------

  Widget _kartuMisi() {
    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.emoji_events_outlined,
            judul: 'Daftar Misi',
            subjudul: 'Misi gamifikasi yang tersedia di database',
            kanan: const ChipAdmin(
              'Gamifikasi',
              kecil: true,
              warna: GayaAdmin.krem,
              teksWarna: GayaAdmin.oranye,
            ),
          ),
          const SizedBox(height: 14),
          if (_misi.isEmpty)
            _teksKosong('Belum ada misi pada tabel misi.')
          else
            for (final item in _misi)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['judul'] as String,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: GayaAdmin.teks,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['catatan'] as String,
                          style: const TextStyle(
                            fontSize: 8,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item['persen'] as double,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFEDF2F8),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          GayaAdmin.biru,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GayaAdmin.biruMuda,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: GayaAdmin.biruTua,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Progres penyelesaian misi belum bisa dihitung karena '
                    'database belum memiliki tabel riwayat penyelesaian misi.',
                    style: TextStyle(
                      fontSize: 8.5,
                      height: 1.45,
                      color: GayaAdmin.biruTua,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // AKSI
  // --------------------------------------------------------

  Widget _teksKosong(String pesan) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          pesan,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: GayaAdmin.teksAbu,
          ),
        ),
      ),
    );
  }

  Widget _kartuError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GayaAdmin.merahMuda,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: GayaAdmin.merah,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gagal memuat laporan.\n$pesanError',
              style: const TextStyle(
                fontSize: 10,
                color: GayaAdmin.merah,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: _muat,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }
}
