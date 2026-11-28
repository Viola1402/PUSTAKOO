import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/sampul_cerita.dart';
import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA KUIS
// Tabel yang dipakai:
// - kuis(id, buku_id, judul)
// - pertanyaan(id, kuis_id, isi_pertanyaan, jawaban_benar,
//   jawaban_salah_1, jawaban_salah_2, jawaban_salah_3)
// - riwayat_kuis(id, nilai, anak_id, kuis_id, waktu_selesai, percobaan_ke)
// ==========================================================


class KelolaKuisPage extends StatefulWidget {
  const KelolaKuisPage({super.key});

  @override
  State<KelolaKuisPage> createState() => _KelolaKuisPageState();
}

class _KelolaKuisPageState extends State<KelolaKuisPage> {
  final supabase = Supabase.instance.client;

  bool sedangMemuat = true;
  bool sedangMenyimpan = false;
  String? pesanError;

  int indeksBuku = 0;
  int? kuisId;

  List<Map<String, dynamic>> daftarBuku = [];
  List<Map<String, dynamic>> soal = [];
  Map<String, String> namaKategori = {};

  int rataRata = 0;
  int totalDikerjakan = 0;
  int nilaiTertinggi = 0;
  int jumlahAnak = 0;

  @override
  void initState() {
    super.initState();
    muatData();
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

  Map<String, dynamic> get bukuTerpilih {
    if (daftarBuku.isEmpty) return <String, dynamic>{};
    if (indeksBuku < 0 || indeksBuku >= daftarBuku.length) {
      return daftarBuku.first;
    }
    return daftarBuku[indeksBuku];
  }

  /// Urutan pilihan pada layar anak: jawaban benar + tiga pengecoh.
  List<String> pilihanSoal(Map<String, dynamic> item) {
    return [
      teks(item['jawaban_benar'], ''),
      teks(item['jawaban_salah_1'], ''),
      teks(item['jawaban_salah_2'], ''),
      teks(item['jawaban_salah_3'], ''),
    ].where((pilihan) => pilihan.isNotEmpty).toList();
  }

  // --------------------------------------------------------
  // MUAT DATA
  // --------------------------------------------------------

  Future<void> muatData() async {
    if (!mounted) return;

    setState(() {
      sedangMemuat = true;
      pesanError = null;
    });

    try {
      final hasilBuku = await supabase
          .from('buku')
          .select(
            'id, judul, kategori_id, status, tingkat_membaca, gambar_sampul',
          )
          .order('judul');

      final hasilKategori = await supabase.from('kategori').select('id, nama');

      if (!mounted) return;

      final petaKategori = <String, String>{};

      for (final item in hasilKategori) {
        petaKategori[item['id'].toString()] = teks(item['nama']);
      }

      setState(() {
        namaKategori = petaKategori;
        daftarBuku = hasilBuku.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'judul': item['judul'] ?? 'Tanpa Judul',
            'kategori': petaKategori[item['kategori_id'].toString()] ??
                'Tanpa Kategori',
            'status': teks(item['status'], 'draf'),
            'tingkat_membaca': teks(item['tingkat_membaca'], '-'),
            'sampul': teks(item['gambar_sampul'], ''),
          };
        }).toList();
        indeksBuku = 0;
        sedangMemuat = false;
      });

      await muatKuis();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sedangMemuat = false;
        pesanError = e.toString();
      });
    }
  }

  Future<void> muatKuis() async {
    if (!mounted) return;

    if (daftarBuku.isEmpty) {
      setState(() {
        kuisId = null;
        soal = [];
        rataRata = 0;
        totalDikerjakan = 0;
        nilaiTertinggi = 0;
        jumlahAnak = 0;
      });
      return;
    }

    setState(() {
      sedangMemuat = true;
      pesanError = null;
    });

    try {
      final idBuku = bukuTerpilih['id'];

      final hasilKuis = await supabase
          .from('kuis')
          .select('id, judul')
          .eq('buku_id', idBuku)
          .order('id')
          .limit(1);

      int? idKuis;
      List<Map<String, dynamic>> daftarSoal = [];
      var rata = 0;
      var dikerjakan = 0;
      var tertinggi = 0;
      var anak = 0;

      if (hasilKuis.isNotEmpty) {
        idKuis = angka(hasilKuis.first['id']);

        final hasilSoal = await supabase
            .from('pertanyaan')
            .select(
              'id, kuis_id, isi_pertanyaan, jawaban_benar, '
              'jawaban_salah_1, jawaban_salah_2, jawaban_salah_3',
            )
            .eq('kuis_id', idKuis)
            .order('id');

        daftarSoal = List<Map<String, dynamic>>.from(hasilSoal);

        final hasilRiwayat = await supabase
            .from('riwayat_kuis')
            .select('nilai, anak_id')
            .eq('kuis_id', idKuis);

        if (hasilRiwayat.isNotEmpty) {
          var jumlahNilai = 0.0;
          final daftarAnak = <String>{};

          for (final item in hasilRiwayat) {
            final nilai = double.tryParse(
                  item['nilai']?.toString() ?? '',
                ) ??
                0;

            jumlahNilai += nilai;
            if (nilai > tertinggi) tertinggi = nilai.round();
            if (item['anak_id'] != null) {
              daftarAnak.add(item['anak_id'].toString());
            }
          }

          rata = (jumlahNilai / hasilRiwayat.length).round();
          dikerjakan = hasilRiwayat.length;
          anak = daftarAnak.length;
        }
      }

      if (!mounted) return;

      setState(() {
        kuisId = idKuis;
        soal = daftarSoal;
        rataRata = rata;
        totalDikerjakan = dikerjakan;
        nilaiTertinggi = tertinggi;
        jumlahAnak = anak;
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

  String _pesanGalatKuis(Object e) {
    final pesan = e.toString();
    final kecil = pesan.toLowerCase();

    if (pesan.contains('42501') || kecil.contains('row-level security')) {
      return 'Akses ditolak oleh RLS Supabase. Pastikan policy INSERT/UPDATE/'
          'DELETE untuk tabel kuis dan pertanyaan sudah dibuat untuk admin.';
    }

    if (pesan.contains('23503')) {
      return 'Kuis untuk buku ini tidak ditemukan di database. Tekan Muat '
          'Ulang lalu coba lagi.';
    }

    if (kecil.contains('does not exist')) {
      return 'Kolom atau tabel tidak ditemukan di database. Periksa skema.';
    }

    return pesan;
  }

  Future<int?> pastikanKuis() async {
    if (kuisId != null) return kuisId;

    final idBuku = bukuTerpilih['id'];

    if (idBuku == null) {
      throw 'Buku belum dipilih. Pilih buku pada kartu di atas.';
    }

    final judul = 'Kuis ${teks(bukuTerpilih['judul'], '')}';

    try {
      final hasil = await supabase
          .from('kuis')
          .insert({'buku_id': idBuku, 'judul': judul})
          .select('id')
          .single();

      kuisId = angka(hasil['id']);
      return kuisId;
    } on PostgrestException catch (e) {
      // Bisa jadi kuis sudah ada (unique buku_id) atau select setelah insert
      // dibatasi policy; cek dulu apakah kuis untuk buku ini benar-benar ada.
      final hasil = await supabase
          .from('kuis')
          .select('id')
          .eq('buku_id', idBuku)
          .order('id')
          .limit(1);

      if (hasil.isNotEmpty) {
        kuisId = angka(hasil.first['id']);
        return kuisId;
      }

      throw _pesanGalatKuis(e);
    }
  }

  // --------------------------------------------------------
  // DIALOG SOAL
  // --------------------------------------------------------

  Future<void> _dialogSoal({Map<String, dynamic>? item}) async {
    final baru = item == null;

    final isi = TextEditingController(
      text: teks(item?['isi_pertanyaan'], ''),
    );
    final benar = TextEditingController(
      text: teks(item?['jawaban_benar'], ''),
    );
    final salah1 = TextEditingController(
      text: teks(item?['jawaban_salah_1'], ''),
    );
    final salah2 = TextEditingController(
      text: teks(item?['jawaban_salah_2'], ''),
    );
    final salah3 = TextEditingController(
      text: teks(item?['jawaban_salah_3'], ''),
    );

    if (!mounted) {
      isi.dispose();
      benar.dispose();
      salah1.dispose();
      salah2.dispose();
      salah3.dispose();
      return;
    }

    final disimpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            baru ? 'Tambah Pertanyaan' : 'Ubah Pertanyaan',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KotakIsian(
                    label: 'Pertanyaan',
                    hint: 'Tulis pertanyaan pemahaman cerita',
                    controller: isi,
                    keyboard: TextInputType.multiline,
                    maxLines: 2,
                  ),
                  KotakIsian(
                    label: 'Jawaban Benar',
                    hint: 'Jawaban yang tepat',
                    controller: benar,
                    bantuan: 'Disimpan pada kolom jawaban_benar.',
                  ),
                  KotakIsian(
                    label: 'Pilihan Pengecoh 1',
                    hint: 'Jawaban salah pertama',
                    controller: salah1,
                  ),
                  KotakIsian(
                    label: 'Pilihan Pengecoh 2',
                    hint: 'Jawaban salah kedua',
                    controller: salah2,
                  ),
                  KotakIsian(
                    label: 'Pilihan Pengecoh 3',
                    hint: 'Jawaban salah ketiga',
                    controller: salah3,
                    bantuan: 'Aplikasi anak mengacak 1 jawaban benar + 3 '
                        'pengecoh ini menjadi pilihan A, B, C, D.',
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
                if (isi.text.trim().isEmpty ||
                    benar.text.trim().isEmpty ||
                    salah1.text.trim().isEmpty ||
                    salah2.text.trim().isEmpty ||
                    salah3.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pertanyaan, jawaban benar, dan tiga pengecoh '
                        'harus diisi.',
                      ),
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
      await _simpanSoal(
        baru: baru,
        item: item,
        isi: isi.text.trim(),
        benar: benar.text.trim(),
        salah1: salah1.text.trim(),
        salah2: salah2.text.trim(),
        salah3: salah3.text.trim(),
      );
    }

    isi.dispose();
    benar.dispose();
    salah1.dispose();
    salah2.dispose();
    salah3.dispose();
  }

  Future<void> _simpanSoal({
    required bool baru,
    Map<String, dynamic>? item,
    required String isi,
    required String benar,
    required String salah1,
    required String salah2,
    required String salah3,
  }) async {
    setState(() => sedangMenyimpan = true);

    try {
      final idKuis = await pastikanKuis();
      if (idKuis == null) {
        throw 'Kuis untuk buku ini belum siap. Tekan Muat Ulang lalu coba lagi.';
      }

      final data = {
        'kuis_id': idKuis,
        'isi_pertanyaan': isi,
        'jawaban_benar': benar,
        'jawaban_salah_1': salah1,
        'jawaban_salah_2': salah2,
        'jawaban_salah_3': salah3,
      };

      if (baru) {
        final hasil =
            await supabase.from('pertanyaan').insert(data).select('id');

        if (hasil.isEmpty) {
          throw 'Pertanyaan tidak tersimpan. Kemungkinan policy INSERT pada '
              'tabel pertanyaan belum dibuat di Supabase (RLS).';
        }
      } else {
        final hasil = await supabase
            .from('pertanyaan')
            .update(data)
            .eq('id', item?['id'])
            .select('id');

        if (hasil.isEmpty) {
          throw 'Pertanyaan tidak terupdate. Kemungkinan policy UPDATE pada '
              'tabel pertanyaan belum dibuat di Supabase (RLS).';
        }
      }

      await muatKuis();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            baru
                ? 'Pertanyaan berhasil ditambahkan.'
                : 'Pertanyaan berhasil diperbarui.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pertanyaan: ${_pesanGalatKuis(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => sedangMenyimpan = false);
    }
  }

  Future<void> _hapusSoal(int indeks) async {
    if (indeks < 0 || indeks >= soal.length) return;

    final item = soal[indeks];

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hapus Pertanyaan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Hapus Soal ${indeks + 1} dari kuis ini?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GayaAdmin.merah,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() => sedangMenyimpan = true);

    try {
      final hasil = await supabase
          .from('pertanyaan')
          .delete()
          .eq('id', item['id'])
          .select('id');

      if (hasil.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pertanyaan gagal dihapus: kemungkinan policy DELETE pada tabel '
              'pertanyaan belum dibuat di Supabase (RLS).',
            ),
          ),
        );
        return;
      }

      await muatKuis();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus pertanyaan: ${_pesanGalatKuis(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => sedangMenyimpan = false);
    }
  }

  Future<void> _pilihBuku() async {
    final hasil = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Pilih Buku',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: daftarBuku.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      leading: const Icon(
                        Icons.menu_book,
                        color: GayaAdmin.biru,
                      ),
                      title: Text(
                        teks(daftarBuku[i]['judul'], 'Tanpa Judul'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: i == indeksBuku
                          ? const Icon(Icons.check, color: GayaAdmin.hijau)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, i),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (hasil != null && mounted) {
      setState(() => indeksBuku = hasil);
      await muatKuis();
    }
  }

  // --------------------------------------------------------
  // PRATINJAU KUIS
  // --------------------------------------------------------

  Future<void> _bukaPratinjau() async {
    if (soal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada pertanyaan untuk dipratinjau. Tambahkan pertanyaan '
            'terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DialogPratinjauKuis(
        judul: 'Kuis ${teks(bukuTerpilih['judul'], '')}',
        soal: List<Map<String, dynamic>>.from(soal),
      ),
    );
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Kuis',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RemahAdmin(['Dashboard', 'Kelola Kuis']),
            _judulHalaman(),
            const SizedBox(height: 14),
            if (pesanError != null) ...[
              _kartuError(),
              const SizedBox(height: 12),
            ],
            if (daftarBuku.isEmpty && !sedangMemuat)
              _kosongBuku()
            else ...[
              _kartuBuku(),
              const SizedBox(height: 14),
              if (sedangMemuat)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (soal.isEmpty)
                _kosongSoal()
              else
                for (var i = 0; i < soal.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _kartuSoal(soal[i], i),
                  ),
              const SizedBox(height: 2),
              _kartuTambahSoal(),
              const SizedBox(height: 16),
              _footer(),
            ],
          ],
        ),
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
              teks: 'Pratinjau Kuis',
              ikon: Icons.visibility_outlined,
              utama: false,
              onPressed: _bukaPratinjau,
            ),
            TombolAdmin(
              teks: 'Muat Ulang',
              ikon: Icons.refresh,
              onPressed: sedangMemuat ? null : muatData,
            ),
          ],
        );

        final judul = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 9,
              runSpacing: 6,
              children: [
                Text(
                  'Kelola Kuis ${teks(bukuTerpilih['judul'], '')}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                ChipAdmin(
                  '${soal.length} Pertanyaan',
                  warna: GayaAdmin.biruMuda,
                  ikon: Icons.quiz_outlined,
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Atur pertanyaan pemahaman cerita beserta kunci jawabannya. '
              'Setiap perubahan langsung tersimpan ke database.',
              style: TextStyle(fontSize: 11.5, color: GayaAdmin.teksAbu),
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
  // KARTU INFORMASI BUKU
  // --------------------------------------------------------

  Widget _kartuBuku() {
    final buku = bukuTerpilih;

    return KartuAdmin(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SampulCerita(
                sumber: teks(buku['sampul'], ''),
                lebar: 62,
                tinggi: 82,
                warnaIkon: GayaAdmin.biru,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buku',
                      style: TextStyle(
                        fontSize: 9,
                        color: GayaAdmin.teksAbu,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _pilihBuku,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                teks(buku['judul'], 'Tanpa Judul'),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: GayaAdmin.biruTua,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 17,
                              color: GayaAdmin.biruTua,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${teks(buku['kategori'], 'Tanpa Kategori')} • '
                      '${teks(buku['tingkat_membaca'], '-')}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: GayaAdmin.teksAbu,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final statistik = Row(
            children: [
              _statistik('Rata-rata Skor', '$rataRata/100'),
              _statistik('Total Dikerjakan', '$totalDikerjakan'),
              _statistik('Nilai Tertinggi', '$nilaiTertinggi'),
              _statistik('Anak Mengerjakan', '$jumlahAnak'),
            ],
          );

          if (ukuran.maxWidth > 780) {
            return Row(
              children: [
                Expanded(flex: 3, child: info),
                const SizedBox(width: 10),
                Expanded(flex: 5, child: statistik),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              const SizedBox(height: 14),
              statistik,
            ],
          );
        },
      ),
    );
  }

  Widget _statistik(String label, String nilai) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: GayaAdmin.teksAbu),
          ),
          const SizedBox(height: 3),
          Text(
            nilai,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU SOAL
  // --------------------------------------------------------

  Widget _kartuSoal(Map<String, dynamic> item, int indeks) {
    final daftarPilihan = pilihanSoal(item);

    return KartuAdmin(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChipAdmin(
                'Soal ${indeks + 1}',
                warna: GayaAdmin.biruMuda,
                kecil: true,
              ),
              const SizedBox(width: 8),
              Icon(
                daftarPilihan.length == 4
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 12,
                color: daftarPilihan.length == 4
                    ? GayaAdmin.teksAbu
                    : GayaAdmin.oranye,
              ),
              const SizedBox(width: 3),
              Text(
                daftarPilihan.length == 4
                    ? '4 pilihan jawaban'
                    : 'Pilihan jawaban belum lengkap',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Ubah pertanyaan',
                onPressed:
                    sedangMenyimpan ? null : () => _dialogSoal(item: item),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: GayaAdmin.teksAbu,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(5),
              ),
              IconButton(
                tooltip: 'Hapus pertanyaan',
                onPressed: sedangMenyimpan ? null : () => _hapusSoal(indeks),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: GayaAdmin.teksAbu,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            teks(item['isi_pertanyaan'], 'Pertanyaan belum diisi'),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, ukuran) {
              final duaKolom = ukuran.maxWidth > 620;
              final lebar =
                  duaKolom ? (ukuran.maxWidth - 10) / 2 : ukuran.maxWidth;

              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < daftarPilihan.length; i++)
                    SizedBox(
                      width: lebar,
                      child: _opsiJawaban(daftarPilihan[i], i, i == 0),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _opsiJawaban(String tulisan, int indeks, bool benar) {
    final huruf = String.fromCharCode(65 + indeks);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: benar ? GayaAdmin.hijauMuda : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: benar ? const Color(0xFFB7EBD4) : GayaAdmin.garis,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: benar ? GayaAdmin.hijau : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: benar ? GayaAdmin.hijau : const Color(0xFFCBD5E1),
              ),
            ),
            child: benar
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$huruf. $tulisan',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: benar ? FontWeight.w600 : FontWeight.w400,
                color:
                    benar ? const Color(0xFF0B7A50) : const Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
          if (benar) ...[
            const SizedBox(width: 6),
            const ChipAdmin(
              'Jawaban Benar',
              warna: GayaAdmin.hijau,
              teksWarna: Colors.white,
              kecil: true,
              ikon: Icons.check,
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // TAMBAH SOAL
  // --------------------------------------------------------

  Widget _kartuTambahSoal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9E6F7)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.playlist_add,
              size: 18,
              color: GayaAdmin.biruTua,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambah Pertanyaan Baru',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Buat pertanyaan interaktif untuk melihat seberapa paham anak '
            'membaca ceritanya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: GayaAdmin.teksAbu,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TombolAdmin(
                teks: 'Tambah Pertanyaan',
                ikon: Icons.add,
                onPressed: sedangMenyimpan ? null : () => _dialogSoal(),
              ),
              TombolAdmin(
                teks: 'Impor Soal dari Naskah',
                ikon: Icons.upload_file_outlined,
                utama: false,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur impor soal dari naskah belum tersedia.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kosongSoal() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 40,
            color: GayaAdmin.teksAbu,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada pertanyaan untuk buku ini',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan pertanyaan pemahaman cerita untuk membuat kuis.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: GayaAdmin.teksAbu),
          ),
        ],
      ),
    );
  }

  Widget _kosongBuku() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: GayaAdmin.teksAbu,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada buku di database',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan cerita terlebih dahulu pada halaman Kelola Cerita, '
            'lalu kembali ke sini untuk membuat kuisnya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: GayaAdmin.teksAbu),
          ),
        ],
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
              'Gagal memuat data kuis.\n$pesanError',
              style: const TextStyle(
                fontSize: 10,
                color: GayaAdmin.merah,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: muatData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: GayaAdmin.hijau,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Tersimpan langsung ke tabel pertanyaan.',
            style: TextStyle(fontSize: 9.5, color: GayaAdmin.teksAbu),
          ),
        ),
        TextButton(
          onPressed: sedangMemuat ? null : muatKuis,
          child: const Text(
            'Muat Ulang',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DialogPratinjauKuis extends StatefulWidget {
  const _DialogPratinjauKuis({required this.judul, required this.soal});

  final String judul;
  final List<Map<String, dynamic>> soal;

  @override
  State<_DialogPratinjauKuis> createState() => _DialogPratinjauKuisState();
}

class _DialogPratinjauKuisState extends State<_DialogPratinjauKuis> {
  final acak = Random();

  int indeks = 0;
  int jumlahBenar = 0;
  bool selesai = false;
  String? dipilih;
  List<String> pilihan = [];

  Map<String, dynamic> get soalAktif => widget.soal[indeks];

  String get jawabanBenar =>
      soalAktif['jawaban_benar']?.toString().trim() ?? '';

  @override
  void initState() {
    super.initState();
    _acakPilihan();
  }

  void _acakPilihan() {
    final semua = [
      soalAktif['jawaban_benar'],
      soalAktif['jawaban_salah_1'],
      soalAktif['jawaban_salah_2'],
      soalAktif['jawaban_salah_3'],
    ]
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();

    semua.shuffle(acak);
    pilihan = semua;
    dipilih = null;
  }

  void _pilihJawaban(String jawaban) {
    if (dipilih != null) return;

    setState(() {
      dipilih = jawaban;
      if (jawaban == jawabanBenar) jumlahBenar++;
    });
  }

  void _berikutnya() {
    if (indeks + 1 >= widget.soal.length) {
      setState(() => selesai = true);
      return;
    }

    setState(() {
      indeks++;
      _acakPilihan();
    });
  }

  void _ulangi() {
    setState(() {
      indeks = 0;
      jumlahBenar = 0;
      selesai = false;
      _acakPilihan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Pratinjau ${widget.judul}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: GayaAdmin.biruTua,
        ),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: selesai ? _hasil() : _pertanyaan(),
        ),
      ),
      actions: selesai
          ? [
              TextButton(onPressed: _ulangi, child: const Text('Ulangi')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GayaAdmin.biru,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tutup'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: dipilih == null ? null : _berikutnya,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GayaAdmin.biru,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  indeks + 1 >= widget.soal.length
                      ? 'Lihat Hasil'
                      : 'Soal Berikutnya',
                ),
              ),
            ],
    );
  }

  Widget _pertanyaan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChipAdmin(
              'Soal ${indeks + 1} dari ${widget.soal.length}',
              warna: GayaAdmin.biruMuda,
              kecil: true,
            ),
            const Spacer(),
            Text(
              'Benar: $jumlahBenar',
              style: const TextStyle(
                fontSize: 10,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          soalAktif['isi_pertanyaan']?.toString() ?? 'Pertanyaan belum diisi',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < pilihan.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _opsi(pilihan[i], i),
          ),
        if (dipilih != null) ...[
          const SizedBox(height: 4),
          Text(
            dipilih == jawabanBenar
                ? 'Jawaban benar.'
                : 'Belum tepat. Jawaban benar: $jawabanBenar',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color:
                  dipilih == jawabanBenar ? GayaAdmin.hijau : GayaAdmin.merah,
            ),
          ),
        ],
      ],
    );
  }

  Widget _opsi(String jawaban, int posisi) {
    final sudahMenjawab = dipilih != null;
    final iniJawabanBenar = jawaban == jawabanBenar;
    final iniPilihan = dipilih == jawaban;
    final huruf = String.fromCharCode(65 + posisi);

    Color warnaTepi = GayaAdmin.garis;
    Color warnaLatar = const Color(0xFFF8FAFC);
    Color warnaTeks = const Color(0xFF475569);

    if (sudahMenjawab && iniJawabanBenar) {
      warnaTepi = const Color(0xFFB7EBD4);
      warnaLatar = GayaAdmin.hijauMuda;
      warnaTeks = const Color(0xFF0B7A50);
    } else if (sudahMenjawab && iniPilihan) {
      warnaTepi = const Color(0xFFF6C6C6);
      warnaLatar = GayaAdmin.merahMuda;
      warnaTeks = GayaAdmin.merah;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: sudahMenjawab ? null : () => _pilihJawaban(jawaban),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: warnaLatar,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: warnaTepi),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: GayaAdmin.garis),
              ),
              child: Text(
                huruf,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                jawaban,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sudahMenjawab && iniJawabanBenar
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: warnaTeks,
                  height: 1.35,
                ),
              ),
            ),
            if (sudahMenjawab && iniJawabanBenar)
              const Icon(Icons.check, size: 14, color: GayaAdmin.hijau),
            if (sudahMenjawab && iniPilihan && !iniJawabanBenar)
              const Icon(Icons.close, size: 14, color: GayaAdmin.merah),
          ],
        ),
      ),
    );
  }

  Widget _hasil() {
    final total = widget.soal.length;
    final nilai = total == 0 ? 0 : ((jumlahBenar / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pratinjau selesai',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ChipAdmin(
              '$jumlahBenar / $total benar',
              warna: GayaAdmin.hijauMuda,
              kecil: true,
              ikon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            ChipAdmin(
              'Nilai $nilai',
              warna: GayaAdmin.biruMuda,
              kecil: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Ini hanya pratinjau admin. Pilihan jawaban diacak seperti pada '
          'aplikasi anak, dan hasilnya tidak disimpan.',
          style: TextStyle(
            fontSize: 10,
            color: GayaAdmin.teksAbu,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
