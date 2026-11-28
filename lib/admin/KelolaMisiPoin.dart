import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA MISI & POIN
// ==========================================================

class KelolaMisiPoinPage extends StatefulWidget {
  const KelolaMisiPoinPage({super.key});

  @override
  State<KelolaMisiPoinPage> createState() => _KelolaMisiPoinPageState();
}

class _KelolaMisiPoinPageState extends State<KelolaMisiPoinPage> {
  final supabase = Supabase.instance.client;

  final poinBuku = TextEditingController(text: '20');
  final poinKuis = TextEditingController(text: '10');
  final poinSempurna = TextEditingController(text: '25');
  final poinHarian = TextEditingController(text: '250');

  bool weekendBoost = true;
  bool sedangMemuat = true;
  int tabMisi = 0;
  String cariBuku = '';

  List<Map<String, dynamic>> hargaTukar = _contohHargaTukar();
  List<Map<String, dynamic>> misiHarian = _contohMisiHarian();
  List<Map<String, dynamic>> misiMingguan = _contohMisiMingguan();

  static List<Map<String, dynamic>> _contohHargaTukar() {
    return [
      {
        'judul': 'Petualangan',
        'kategori': 'Dongeng',
        'poin': 80,
        'aktif': true
      },
      {'judul': 'Sains', 'kategori': 'Pengetahuan', 'poin': 120, 'aktif': true},
      {
        'judul': 'Cerita Rakyat',
        'kategori': 'Gratis / 35 Poin',
        'poin': 35,
        'aktif': true
      },
    ];
  }

  static List<Map<String, dynamic>> _contohMisiHarian() {
    return [
      {
        'judul': 'Tamatkan 1 cerita hari ini',
        'label': 'HARIAN',
        'target': 'Target: 1 buku tamat, sampai selesai',
        'poin': 30,
        'selesai': 84,
        'satuan': 'anak selesai hari ini',
        'aktif': true,
      },
      {
        'judul': 'Seleseikan 3 kuis pertama hari ini',
        'label': 'HARIAN',
        'target': 'Target: 3 kuis cerita tamat',
        'poin': 50,
        'selesai': 52,
        'satuan': 'anak selesai hari ini',
        'aktif': true,
      },
    ];
  }

  static List<Map<String, dynamic>> _contohMisiMingguan() {
    return [
      {
        'judul': 'Baca 5 hari berturut-turut',
        'label': 'MINGGUAN',
        'target': 'Target: 5 hari konsisten membaca',
        'poin': 120,
        'selesai': 64,
        'satuan': 'anak selesai hari ini',
        'aktif': true,
      },
      {
        'judul': 'Jelajahi 2 kategori cerita baru',
        'label': 'MINGGUAN',
        'target': 'Target: 2 kategori baru',
        'poin': 70,
        'selesai': 52,
        'satuan': 'anak selesai hari ini',
        'aktif': true,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    muatBuku();
  }

  @override
  void dispose() {
    poinBuku.dispose();
    poinKuis.dispose();
    poinSempurna.dispose();
    poinHarian.dispose();
    super.dispose();
  }

  String teks(dynamic nilai, [String nilaiAwal = '-']) {
    if (nilai == null || nilai.toString().trim().isEmpty) return nilaiAwal;
    return nilai.toString();
  }

  Future<void> muatBuku() async {
    if (!mounted) return;

    setState(() => sedangMemuat = true);

    try {
      final hasilBuku =
          await supabase.from('buku').select('id, judul, kategori_id');

      final hasilMisi = await supabase
          .from('misi')
          .select('id, judul, deskripsi, target, hadiah_poin');

      if (!mounted) return;

      setState(() {
        if (hasilBuku.isNotEmpty) {
          hargaTukar = hasilBuku.take(3).map((item) {
            return <String, dynamic>{
              'id': item['id'],
              'judul': item['judul'] ?? 'Tanpa Judul',
              'kategori': 'Harga tukar poin',
              'poin': 20,
              'aktif': true,
            };
          }).toList();
        }

        if (hasilMisi.isNotEmpty) {
          final harian = <Map<String, dynamic>>[];
          final mingguan = <Map<String, dynamic>>[];

          for (var i = 0; i < hasilMisi.length; i++) {
            final item = hasilMisi[i];
            final data = <String, dynamic>{
              'id': item['id'],
              'judul': item['judul'] ?? 'Misi Baru',
              'label': i.isEven ? 'HARIAN' : 'MINGGUAN',
              'target': item['deskripsi'] != null
                  ? 'Target: ${item['deskripsi']}'
                  : 'Target: ${item['target'] ?? 1}',
              'poin': (item['hadiah_poin'] as num?)?.toInt() ?? 0,
              'selesai': 0,
              'satuan': 'anak selesai hari ini',
              'aktif': true,
            };

            if (i.isEven) {
              harian.add(data);
            } else {
              mingguan.add(data);
            }
          }

          if (harian.isNotEmpty) misiHarian = harian;
          if (mingguan.isNotEmpty) misiMingguan = mingguan;
        }

        sedangMemuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => sedangMemuat = false);
    }
  }

  List<Map<String, dynamic>> get daftarHargaTampil {
    if (cariBuku.trim().isEmpty) return hargaTukar;

    final kunci = cariBuku.toLowerCase();

    return hargaTukar
        .where((item) => teks(item['judul'], '').toLowerCase().contains(kunci))
        .toList();
  }

  List<Map<String, dynamic>> get misiAktif {
    return tabMisi == 0 ? misiHarian : misiMingguan;
  }

  // --------------------------------------------------------
  // DIALOG HARGA TUKAR
  // --------------------------------------------------------

  Future<void> _dialogHarga({Map<String, dynamic>? item, int? indeks}) async {
    final judul = TextEditingController(text: teks(item?['judul'], ''));
    final poin = TextEditingController(
      text: item == null ? '20' : teks(item['poin'], '20'),
    );

    final disimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          item == null ? 'Penukaran Buku Baru' : 'Ubah Harga Tukar',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GayaAdmin.biruTua,
          ),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KotakIsian(
                label: 'Judul Buku',
                hint: 'Contoh: Kancil dan Buaya',
                controller: judul,
              ),
              KotakIsian(
                label: 'Harga Tukar',
                hint: '20',
                controller: poin,
                keyboard: TextInputType.number,
                akhiran: 'Poin',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (judul.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Judul buku harus diisi.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GayaAdmin.biru,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (disimpan == true && mounted) {
      setState(() {
        if (item == null) {
          hargaTukar.add({
            'judul': judul.text.trim(),
            'kategori': 'Harga tukar poin',
            'poin': int.tryParse(poin.text.trim()) ?? 0,
            'aktif': true,
          });
        } else {
          item['judul'] = judul.text.trim();
          item['poin'] = int.tryParse(poin.text.trim()) ?? item['poin'];
        }
      });
    }

    judul.dispose();
    poin.dispose();
  }

  // --------------------------------------------------------
  // DIALOG MISI
  // --------------------------------------------------------

  Future<void> _dialogMisi({Map<String, dynamic>? item}) async {
    final judul = TextEditingController(text: teks(item?['judul'], ''));
    final target = TextEditingController(text: teks(item?['target'], ''));
    final poin = TextEditingController(
      text: item == null ? '30' : teks(item['poin'], '30'),
    );
    var harian = (item?['label'] ?? 'HARIAN') == 'HARIAN';

    final disimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Text(
                item == null ? 'Tambah Misi Baru' : 'Ubah Misi',
                style: const TextStyle(
                  fontSize: 20,
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
                        label: 'Judul Misi',
                        hint: 'Contoh: Tamatkan 1 cerita hari ini',
                        controller: judul,
                      ),
                      KotakIsian(
                        label: 'Target',
                        hint: 'Contoh: 1 buku tamat',
                        controller: target,
                        keyboard: TextInputType.multiline,
                        maxLines: 2,
                      ),
                      KotakIsian(
                        label: 'Hadiah Poin',
                        hint: '30',
                        controller: poin,
                        keyboard: TextInputType.number,
                        akhiran: 'Poin',
                      ),
                      const Text(
                        'Jenis Misi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: GayaAdmin.biruTua,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _pilihanJenis(
                            'Harian',
                            harian,
                            () => setDialogState(() => harian = true),
                          ),
                          const SizedBox(width: 8),
                          _pilihanJenis(
                            'Mingguan',
                            !harian,
                            () => setDialogState(() => harian = false),
                          ),
                        ],
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
                    if (judul.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Judul misi harus diisi.')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GayaAdmin.biru,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (disimpan == true && mounted) {
      final dataMisi = <String, dynamic>{
        'judul': judul.text.trim(),
        'label': harian ? 'HARIAN' : 'MINGGUAN',
        'target': target.text.trim().isEmpty
            ? 'Target: belum diatur'
            : 'Target: ${target.text.trim()}',
        'poin': int.tryParse(poin.text.trim()) ?? 0,
        'selesai': 0,
        'satuan': 'anak selesai hari ini',
        'aktif': true,
      };

      setState(() {
        if (item == null) {
          if (harian) {
            misiHarian.add(dataMisi);
          } else {
            misiMingguan.add(dataMisi);
          }
        } else {
          item['judul'] = dataMisi['judul'];
          item['label'] = dataMisi['label'];
          item['target'] = dataMisi['target'];
          item['poin'] = dataMisi['poin'];
        }
        tabMisi = harian ? 0 : 1;
      });
    }

    judul.dispose();
    target.dispose();
    poin.dispose();
  }

  Widget _pilihanJenis(String teks, bool aktif, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: aktif ? GayaAdmin.biru : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          teks,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: aktif ? Colors.white : GayaAdmin.teks,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Misi & Poin',
      child: LayoutBuilder(
        builder: (context, ukuran) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 20, 26, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _judulHalaman(),
                const SizedBox(height: 24),

                // Susunan dibuat vertikal agar sama seperti referensi:
                // Aturan Poin -> Misi Membaca -> Harga Tukar Cerita.
                _kartuAturanPoin(),
                const SizedBox(height: 26),
                _kartuMisi(),
                const SizedBox(height: 26),
                _kartuHargaTukar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _judulHalaman() {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final tombol = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TombolAdmin(
              teks: 'Riwayat Transaksi Poin',
              ikon: Icons.receipt_long_outlined,
              utama: false,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Riwayat transaksi poin belum tersedia.'),
                  ),
                );
              },
            ),
            TombolAdmin(
              teks: 'Tambah Misi Baru',
              ikon: Icons.add,
              onPressed: () => _dialogMisi(),
            ),
          ],
        );

        final judul = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Misi & Poin',
              style: TextStyle(
                fontSize: 34,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: GayaAdmin.biruTua,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Konfigurasi sistem gamifikasi: perolehan poin baca, katalog '
              'harga penukaran buku, dan misi harian anak.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ],
        );

        if (ukuran.maxWidth > 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: judul),
              const SizedBox(width: 10),
              tombol,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            judul,
            const SizedBox(height: 10),
            tombol,
          ],
        );
      },
    );
  }

  // --------------------------------------------------------
  // KARTU ATURAN POIN
  // --------------------------------------------------------

  Widget _kartuAturanPoin() {
    return KartuAdmin(
      warna: const Color(0xFF80C5ED),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aturan Poin',
            style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: GayaAdmin.biruTua),
          ),
          const SizedBox(height: 4),
          const Text('Parameter koin yang diperoleh anak',
              style: TextStyle(fontSize: 14.5, color: GayaAdmin.biruTua)),
          /* const JudulBagian(
            ikon: Icons.adjust,
            judul: 'Aturan Poin',
            subjudul: 'Parameter poin yang diperoleh anak',
            warnaIkon: Colors.white,
          ), */
          const SizedBox(height: 22),
          KotakIsian(
            label: 'Poin Selesai Membaca',
            bantuan: 'Per buku tamat',
            controller: poinBuku,
            keyboard: TextInputType.number,
            akhiran: 'Poin / buku',
          ),
          KotakIsian(
            label: 'Poin Jawaban Kuis Benar',
            bantuan: 'Per pertanyaan benar',
            controller: poinKuis,
            keyboard: TextInputType.number,
            akhiran: 'Poin / benar',
          ),
          KotakIsian(
            label: 'Bonus Kuis Sempurna',
            bantuan: 'Skor 100%',
            controller: poinSempurna,
            keyboard: TextInputType.number,
            akhiran: 'Poin bonus',
          ),
          KotakIsian(
            label: 'Batas Maksimum Poin Harian',
            bantuan: 'Reset tiap hari',
            controller: poinHarian,
            keyboard: TextInputType.number,
            akhiran: 'Poin / hari',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE7DCC2)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekend Boost (2x Poin)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: GayaAdmin.biruTua,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Otomatis aktif Sabtu & Minggu',
                        style: TextStyle(
                          fontSize: 12,
                          color: GayaAdmin.teksAbu,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: weekendBoost,
                    activeColor: Colors.white,
                    activeTrackColor: GayaAdmin.hijau,
                    onChanged: (value) {
                      setState(() => weekendBoost = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TombolAdmin(
              teks: 'Simpan Aturan Poin',
              ikon: Icons.save_outlined,
              onPressed: _simpanAturan,
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: GayaAdmin.biruTua,
              ),
              SizedBox(width: 6),
              Text(
                'Terakhir diperbarui: Hari ini, 09.30 WIB',
                style: TextStyle(
                  fontSize: 11.5,
                  color: GayaAdmin.biruTua,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _simpanAturan() {
    final nilai = [
      poinBuku.text.trim(),
      poinKuis.text.trim(),
      poinSempurna.text.trim(),
      poinHarian.text.trim(),
    ];

    if (nilai.any((teks) => int.tryParse(teks) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua aturan poin harus berupa angka.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aturan poin berhasil disimpan.')),
    );
  }

  // --------------------------------------------------------
  // KARTU HARGA TUKAR
  // --------------------------------------------------------

  Widget _kartuHargaTukar() {
    final daftar = daftarHargaTampil;

    return KartuAdmin(
      warna: const Color(0xFFF2A6A8),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harga Tukar Cerita',
            style: TextStyle(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: GayaAdmin.biruTua),
          ),
          const SizedBox(height: 4),
          const Text('Biaya koin emas untuk akses buku baru',
              style: TextStyle(fontSize: 14.5, color: GayaAdmin.biruTua)),
          /* const JudulBagian(
            ikon: Icons.shopping_bag_outlined,
            judul: 'Harga Tukar Cerita',
            subjudul: 'Biaya poin untuk membuka akses buku baru',
          ), */
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: GayaAdmin.latar,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: GayaAdmin.garis),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: GayaAdmin.teksAbu,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() => cariBuku = value);
                          },
                          style: const TextStyle(fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: 'Cari judul cerita...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: GayaAdmin.teksAbu,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: GayaAdmin.latar,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: GayaAdmin.garis),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_outlined,
                        size: 16, color: GayaAdmin.biruTua),
                    SizedBox(width: 7),
                    Text('Filter',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: GayaAdmin.biruTua)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < daftar.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _barisHarga(daftar[i], hargaTukar.indexOf(daftar[i])),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TombolAdmin(
              teks: 'Tambah Penukaran Buku Baru',
              ikon: Icons.add,
              utama: false,
              onPressed: () => _dialogHarga(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisHarga(Map<String, dynamic> item, int indeks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D3D7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F1FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book,
              size: 20,
              color: GayaAdmin.biru,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teks(item['judul'], 'Tanpa Judul'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  teks(item['kategori'], '-'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ChipAdmin(
            '${item['poin']} Poin',
            warna: GayaAdmin.oranyeMuda,
            teksWarna: GayaAdmin.oranye,
            kecil: true,
          ),
          SizedBox(
            height: 30,
            width: 44,
            child: Transform.scale(
              scale: 0.82,
              child: Switch(
                value: item['aktif'] == true,
                activeColor: Colors.white,
                activeTrackColor: GayaAdmin.hijau,
                onChanged: (value) {
                  setState(() => item['aktif'] = value);
                },
              ),
            ),
          ),
          InkWell(
            onTap: () => _dialogHarga(item: item, indeks: indeks),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biru,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU MISI MEMBACA
  // --------------------------------------------------------

  Widget _kartuMisi() {
    return KartuAdmin(
      warna: const Color(0xFFF4E9CF),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Misi Membaca',
            style: TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: GayaAdmin.biruTua,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tantangan literasi berkelanjutan anak',
            style: TextStyle(fontSize: 14.5, color: GayaAdmin.biruTua),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, ukuran) {
              final duaKolom = ukuran.maxWidth >= 620;
              if (!duaKolom) {
                return Column(
                  children: [
                    _labelTabMisi('Misi Harian (${misiHarian.length})'),
                    const SizedBox(height: 10),
                    for (final item in misiHarian)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _kartuItemMisi(item),
                      ),
                    const SizedBox(height: 8),
                    _labelTabMisi('Misi Mingguan (${misiMingguan.length})'),
                    const SizedBox(height: 10),
                    for (final item in misiMingguan)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _kartuItemMisi(item),
                      ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _labelTabMisi('Misi Harian (${misiHarian.length})'),
                            const SizedBox(height: 12),
                            for (final item in misiHarian)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _kartuItemMisi(item),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _labelTabMisi(
                                'Misi Mingguan (${misiMingguan.length})'),
                            const SizedBox(height: 12),
                            for (final item in misiMingguan)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _kartuItemMisi(item),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TombolAdmin(
              teks: 'Buat Template Misi Baru',
              ikon: Icons.add_task,
              utama: false,
              onPressed: () => _dialogMisi(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelTabMisi(String teksLabel) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EAF2)),
      ),
      child: Text(
        teksLabel,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: GayaAdmin.biruTua,
        ),
      ),
    );
  }

  Widget _kartuItemMisi(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE7DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: GayaAdmin.oranye,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teks(item['label'], 'HARIAN'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.oranye,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  tooltip: 'Ubah misi',
                  onPressed: () => _dialogMisi(item: item),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: GayaAdmin.teksAbu,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 46,
                height: 32,
                child: Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: item['aktif'] == true,
                    activeColor: Colors.white,
                    activeTrackColor: GayaAdmin.hijau,
                    inactiveThumbColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        item['aktif'] = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            teks(item['judul'], 'Misi Baru'),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teks(item['target'], 'Target: belum diatur'),
            style: const TextStyle(
              fontSize: 12.5,
              color: GayaAdmin.teksAbu,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChipAdmin(
                '+${item['poin']} Poin',
                warna: GayaAdmin.oranyeMuda,
                teksWarna: GayaAdmin.oranye,
                kecil: true,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${item['selesai']} ${teks(item['satuan'], 'anak selesai')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
