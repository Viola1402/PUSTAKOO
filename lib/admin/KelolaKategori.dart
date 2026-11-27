import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA KATEGORI & TINGKAT BACA
// ==========================================================

class KelolaKategoriPage extends StatefulWidget {
  const KelolaKategoriPage({super.key});

  @override
  State<KelolaKategoriPage> createState() => _KelolaKategoriPageState();
}

class _KelolaKategoriPageState extends State<KelolaKategoriPage> {
  final supabase = Supabase.instance.client;

  bool sedangMemuat = true;
  bool dataContoh = false;

  List<Map<String, dynamic>> kategori = _contohKategori();
  List<Map<String, dynamic>> tingkat = _contohTingkat();
  List<Map<String, dynamic>> buku = [];

  static const List<List<Color>> palet = [
    [Color(0xFFFDF1DC), Color(0xFFC0781A)],
    [Color(0xFFF1ECFB), Color(0xFF7A5AC4)],
    [Color(0xFFE0F2FE), Color(0xFF0B669B)],
    [Color(0xFFECF6E8), Color(0xFF4A8A3A)],
    [Color(0xFFFDECEC), Color(0xFFC4555A)],
  ];

  @override
  void initState() {
    super.initState();
    muatData();
  }

  static List<Map<String, dynamic>> _contohKategori() {
    return [
      {
        'id': 1,
        'nama': 'Dongeng',
        'jenis': 'Fabel Tradisional',
        'deskripsi': 'Cerita mengandung nilai moral, karakter hewan, '
            'dan latar dunia fantasi.',
        'jumlah': 12,
      },
      {
        'id': 2,
        'nama': 'Petualangan',
        'jenis': 'Fantasi',
        'deskripsi': 'Perjalanan tokoh, tantangan alam, dan penemuan '
            'tempat baru.',
        'jumlah': 12,
      },
      {
        'id': 3,
        'nama': 'Hewan',
        'jenis': 'Fabel Satwa',
        'deskripsi': 'Kisah fabel tentang hewan, sifat, dan interaksi '
            'di alam.',
        'jumlah': 10,
      },
      {
        'id': 4,
        'nama': 'Sains',
        'jenis': 'Edukasi STEM',
        'deskripsi': 'Pengenalan ilmu alam, teknologi, dan eksperimen '
            'sederhana.',
        'jumlah': 8,
      },
      {
        'id': 5,
        'nama': 'Cerita Rakyat',
        'jenis': 'Legenda Nusantara',
        'deskripsi': 'Dongeng dari nusantara, tradisi, dan kearifan '
            'lokal.',
        'jumlah': 8,
      },
    ];
  }

  static List<Map<String, dynamic>> _contohTingkat() {
    return [
      {
        'id': 1,
        'nama': 'Pemula',
        'level': 1,
        'usia': 'Usia 3-5 Tahun',
        'deskripsi': 'Kalimat pendek, buku bergambar, kosa kata maksimal '
            '100-150 kata.',
        'catatan': 'Usia rata-rata 3-5 tahun • 8-12 halaman • 50-100 '
            'kata per halaman',
      },
      {
        'id': 2,
        'nama': 'Menengah',
        'level': 2,
        'usia': 'Usia 6-10 Tahun',
        'deskripsi': 'Paragraf lebih panjang, kosa kata baru diselingi '
            'ilustrasi untuk konteks, durasi baca sampai 20 menit.',
        'catatan': 'Usia rata-rata 6-10 tahun • 20-30 halaman',
      },
      {
        'id': 3,
        'nama': 'Mahir',
        'level': 3,
        'usia': 'Usia 11-12 Tahun',
        'deskripsi': 'Buku cerita bergambar, struktur cerita berlapis, '
            'dengan alur cerita kompleks, pengembangan karakter, '
            'kosakata lebih tinggi dan referensi pemahaman mendalam.',
        'catatan': 'Usia rata-rata 11-12 tahun • 35+ halaman • buku seri',
      },
    ];
  }

  String teks(dynamic nilai, [String nilaiAwal = '-']) {
    if (nilai == null || nilai.toString().trim().isEmpty) return nilaiAwal;
    return nilai.toString();
  }

  int angka(dynamic nilai) {
    if (nilai is num) return nilai.toInt();
    return int.tryParse(nilai?.toString() ?? '') ?? 0;
  }

  Future<void> muatData() async {
    if (!mounted) return;

    setState(() => sedangMemuat = true);

    try {
      final hasilKategori = await supabase
          .from('kategori')
          .select('id, nama, deskripsi')
          .order('nama');

      final hasilBuku = await supabase
          .from('buku')
          .select('id, judul, kategori_id');

      if (!mounted) return;

      final daftarBuku = List<Map<String, dynamic>>.from(hasilBuku);

      setState(() {
        buku = daftarBuku;

        if (hasilKategori.isNotEmpty) {
          kategori = hasilKategori.map((item) {
            final id = item['id'].toString();
            final jumlah = daftarBuku
                .where((row) => row['kategori_id'].toString() == id)
                .length;

            return <String, dynamic>{
              'id': item['id'],
              'nama': item['nama'] ?? 'Tanpa Nama',
              'jenis': _jenisDariNama(teks(item['nama'], '')),
              'deskripsi': item['deskripsi'] ?? '',
              'jumlah': jumlah,
            };
          }).toList();

          dataContoh = false;
        } else {
          dataContoh = true;
        }

        sedangMemuat = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        sedangMemuat = false;
        dataContoh = true;
      });
    }
  }

  String _jenisDariNama(String nama) {
    final n = nama.toLowerCase();

    if (n.contains('dongeng')) return 'Fabel Tradisional';
    if (n.contains('petualangan')) return 'Fantasi';
    if (n.contains('hewan')) return 'Fabel Satwa';
    if (n.contains('sains')) return 'Edukasi STEM';
    if (n.contains('rakyat')) return 'Legenda Nusantara';

    return 'Kategori Cerita';
  }

  IconData _ikonKategori(String nama) {
    final n = nama.toLowerCase();

    if (n.contains('dongeng')) return Icons.auto_stories_outlined;
    if (n.contains('petualangan')) return Icons.explore_outlined;
    if (n.contains('hewan')) return Icons.pets_outlined;
    if (n.contains('sains')) return Icons.science_outlined;
    if (n.contains('rakyat')) return Icons.account_balance_outlined;

    return Icons.menu_book_outlined;
  }

  int get totalBuku {
    final dariKategori = kategori.fold<int>(
      0,
      (jumlah, item) => jumlah + angka(item['jumlah']),
    );

    return dariKategori;
  }

  List<int> get distribusi {
    final total = totalBuku;

    if (total == 0) return [45, 35, 20];

    final pemula = (total * 0.45).round();
    final menengah = (total * 0.35).round();
    final mahir = total - pemula - menengah;

    return [pemula, menengah, mahir];
  }

  // --------------------------------------------------------
  // DIALOG KATEGORI
  // --------------------------------------------------------

  Future<void> _dialogKategori([Map<String, dynamic>? item]) async {
    final baru = item == null;
    final nama = TextEditingController(text: teks(item?['nama'], ''));
    final jenis = TextEditingController(text: teks(item?['jenis'], ''));
    final deskripsi = TextEditingController(
      text: teks(item?['deskripsi'], ''),
    );

    final disimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            baru ? 'Tambah Kategori Baru' : 'Ubah Kategori',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KotakIsian(
                    label: 'Nama Kategori',
                    hint: 'Contoh: Dongeng',
                    controller: nama,
                  ),
                  KotakIsian(
                    label: 'Jenis / Sub Kategori',
                    hint: 'Contoh: Fabel Tradisional',
                    controller: jenis,
                  ),
                  KotakIsian(
                    label: 'Deskripsi',
                    hint: 'Ringkasan isi kategori',
                    controller: deskripsi,
                    keyboard: TextInputType.multiline,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nama.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama kategori harus diisi.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GayaAdmin.biru,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (disimpan == true) {
      final namaBaru = nama.text.trim();
      final jenisBaru = jenis.text.trim();
      final deskripsiBaru = deskripsi.text.trim();

      var tersimpanServer = false;

      try {
        if (baru) {
          await supabase.from('kategori').insert({
            'nama': namaBaru,
            'deskripsi': deskripsiBaru,
          });
        } else {
          await supabase.from('kategori').update({
            'nama': namaBaru,
            'deskripsi': deskripsiBaru,
          }).eq('id', item['id']);
        }

        tersimpanServer = true;
      } catch (_) {
        tersimpanServer = false;
      }

      if (!mounted) return;

      setState(() {
        if (baru) {
          kategori.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'nama': namaBaru,
            'jenis': jenisBaru.isEmpty ? 'Kategori Cerita' : jenisBaru,
            'deskripsi': deskripsiBaru,
            'jumlah': 0,
          });
        } else {
          item['nama'] = namaBaru;
          if (jenisBaru.isNotEmpty) item['jenis'] = jenisBaru;
          item['deskripsi'] = deskripsiBaru;
        }
      });

      if (tersimpanServer) {
        await muatData();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tersimpanServer
                ? 'Kategori berhasil disimpan.'
                : 'Kategori diperbarui pada sesi ini.',
          ),
        ),
      );
    }

    nama.dispose();
    jenis.dispose();
    deskripsi.dispose();
  }

  // --------------------------------------------------------
  // DIALOG TINGKAT BACA
  // --------------------------------------------------------

  Future<void> _dialogTingkat([Map<String, dynamic>? item]) async {
    final baru = item == null;
    final levelBerikut = tingkat.length + 1;

    final nama = TextEditingController(text: teks(item?['nama'], ''));
    final usia = TextEditingController(text: teks(item?['usia'], ''));
    final deskripsi = TextEditingController(
      text: teks(item?['deskripsi'], ''),
    );

    final disimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            baru ? 'Tambah Tingkat Baca Baru' : 'Ubah Tingkat Baca',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KotakIsian(
                    label: 'Nama Tingkat',
                    hint: 'Contoh: Pemula',
                    controller: nama,
                  ),
                  KotakIsian(
                    label: 'Kelompok Usia',
                    hint: 'Contoh: Usia 3-5 Tahun',
                    controller: usia,
                  ),
                  KotakIsian(
                    label: 'Deskripsi',
                    hint: 'Ciri-ciri bacaan pada tingkat ini',
                    controller: deskripsi,
                    keyboard: TextInputType.multiline,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nama.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama tingkat harus diisi.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GayaAdmin.biru,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (disimpan == true && mounted) {
      setState(() {
        if (baru) {
          tingkat.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'nama': nama.text.trim(),
            'level': levelBerikut,
            'usia': usia.text.trim().isEmpty
                ? 'Usia belum diatur'
                : usia.text.trim(),
            'deskripsi': deskripsi.text.trim(),
            'catatan': '',
          });
        } else {
          item['nama'] = nama.text.trim();
          item['usia'] = usia.text.trim().isEmpty
              ? 'Usia belum diatur'
              : usia.text.trim();
          item['deskripsi'] = deskripsi.text.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tingkat baca berhasil disimpan.')),
      );
    }

    nama.dispose();
    usia.dispose();
    deskripsi.dispose();
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Kategori',
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RemahAdmin(['Dashboard', 'Kategori']),
                _judulHalaman(),
                const SizedBox(height: 16),
                if (dataContoh)
                  _keteranganContoh()
                else
                  const SizedBox.shrink(),
                if (lebar > 950)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _kartuKategori()),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: _kartuTingkat()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _kartuKategori(),
                      const SizedBox(height: 14),
                      _kartuTingkat(),
                    ],
                  ),
                const SizedBox(height: 14),
                _kartuDistribusi(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _judulHalaman() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: GayaAdmin.biruMuda,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 19,
                color: GayaAdmin.biruTua,
              ),
            ),
            const Text(
              'Kelola Kategori & Tingkat Baca',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            ChipAdmin('${tingkat.length} Tingkat Baca'),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola taksonomi cerita perpustakaan digital anak, genre '
          'bacaan, dan klasifikasi kelompok usia untuk sinkronisasi '
          'kurikulum bacaan.',
          style: TextStyle(
            fontSize: 11.5,
            color: GayaAdmin.teksAbu,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _keteranganContoh() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: GayaAdmin.oranyeMuda,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFF0DDB6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 15, color: GayaAdmin.oranye),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tabel kategori masih kosong, data contoh ditampilkan agar '
              'tampilan tetap lengkap.',
              style: TextStyle(fontSize: 10, color: GayaAdmin.oranye),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU KATEGORI
  // --------------------------------------------------------

  Widget _kartuKategori() {
    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.folder_outlined,
            judul: 'Kategori Cerita',
            subjudul: 'Kelompokkan buku dalam genre bacaan anak',
            kanan: ChipAdmin('${kategori.length} Kategori'),
          ),
          const SizedBox(height: 12),
          if (sedangMemuat)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (var i = 0; i < kategori.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _tileKategori(kategori[i], i),
              ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: TombolAdmin(
              teks: 'Tambah Kategori Baru',
              ikon: Icons.add,
              onPressed: () => _dialogKategori(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileKategori(Map<String, dynamic> item, int indeks) {
    final warna = palet[indeks % palet.length];
    final nama = teks(item['nama'], 'Tanpa Nama');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: warna[0],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_ikonKategori(nama), size: 17, color: warna[1]),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 3,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GayaAdmin.biruTua,
                      ),
                    ),
                    ChipAdmin(
                      teks(item['jenis'], 'Kategori Cerita'),
                      warna: GayaAdmin.krem,
                      kecil: true,
                      teksWarna: GayaAdmin.oranye,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  teks(item['deskripsi'], 'Belum ada deskripsi kategori.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: GayaAdmin.teksAbu,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 11,
                      color: GayaAdmin.teksAbu,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${angka(item['jumlah'])} Cerita terdaftar',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: GayaAdmin.teksAbu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah kategori',
            onPressed: () => _dialogKategori(item),
            icon: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: GayaAdmin.teksAbu,
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU TINGKAT BACA
  // --------------------------------------------------------

  Widget _kartuTingkat() {
    return KartuAdmin(
      warna: GayaAdmin.krem,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JudulBagian(
            ikon: Icons.signal_cellular_alt,
            judul: 'Tingkat Baca',
            subjudul: 'Tingkatan literasi berdasar usia',
            warnaIkon: Colors.white,
          ),
          const SizedBox(height: 12),
          for (final item in tingkat)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tileTingkat(item),
            ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE7DCC2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: GayaAdmin.oranye,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Peringkat tingkat baca secara otomatis mengkalibrasi '
                    'algoritma rekomendasi bacaan anak, sosok panduan usia, '
                    'dan tingkat kesulitan kuis agar sesuai kemampuan '
                    'literasi anak.',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.5,
                      color: Color(0xFF7C6A45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TombolAdmin(
              teks: 'Tambah Tingkat Baca Baru',
              ikon: Icons.add,
              onPressed: () => _dialogTingkat(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileTingkat(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7DCC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GayaAdmin.biruMuda,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  angka(item['level']).toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teks(item['nama'], 'Tingkat Baru'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GayaAdmin.biruTua,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        ChipAdmin(
                          'Level ${angka(item['level'])}',
                          kecil: true,
                          warna: const Color(0xFFF1F5F9),
                          teksWarna: GayaAdmin.teks,
                        ),
                        ChipAdmin(
                          teks(item['usia'], 'Usia belum diatur'),
                          kecil: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ubah tingkat baca',
                onPressed: () => _dialogTingkat(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: GayaAdmin.teksAbu,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            teks(item['deskripsi'], 'Belum ada deskripsi tingkat baca.'),
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.45,
              color: GayaAdmin.teksAbu,
            ),
          ),
          if (teks(item['catatan'], '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.link,
                  size: 11,
                  color: GayaAdmin.biru,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    teks(item['catatan']),
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: GayaAdmin.biru,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU DISTRIBUSI
  // --------------------------------------------------------

  Widget _kartuDistribusi() {
    final data = distribusi;
    final total = totalBuku;

    return KartuAdmin(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;
          final kiri = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: GayaAdmin.biruMuda,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  size: 20,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Buku Berdasarkan Tingkat',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: GayaAdmin.biruTua,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total $total judul buku telah terdaftar dalam '
                      'koleksi bacaan.',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: GayaAdmin.teksAbu,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Kategori dan tingkat baca ada pada halaman ini.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Kategori',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biru,
                  ),
                ),
              ),
            ],
          );

          final bar = _barDistribusi(data, total);

          if (lebar > 720) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: kiri),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: bar),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kiri,
              const SizedBox(height: 12),
              bar,
            ],
          );
        },
      ),
    );
  }

  Widget _barDistribusi(List<int> data, int total) {
    if (total == 0) total = 1;

    const warna = [
      GayaAdmin.biru,
      Color(0xFF6FA9CB),
      Color(0xFFE3B23C),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (var i = 0; i < tingkat.length && i < 3; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: warna[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${teks(tingkat[i]['nama'], 'Tingkat')} '
                    '${((data[i] / total) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  flex: data[i] == 0 ? 1 : data[i],
                  child: Container(
                    height: 8,
                    color: warna[i],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
