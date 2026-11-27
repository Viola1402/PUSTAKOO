import 'package:flutter/material.dart';

import '../layanan/kategori_layanan.dart';
import '../model/kategori_model.dart';
import '../widget/kategori_widget.dart';
import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA KATEGORI & TINGKAT BACA
// Halaman hanya merangkai widget dan menangani aksi dialog;
// pengambilan serta penyimpanan data diserahkan ke
// KategoriRepository (konsep OOP: pemisahan tanggung jawab).
// ==========================================================

class KelolaKategoriPage extends StatefulWidget {
  final KategoriRepository? repositori;

  const KelolaKategoriPage({super.key, this.repositori});

  @override
  State<KelolaKategoriPage> createState() => _KelolaKategoriPageState();
}

class _KelolaKategoriPageState extends State<KelolaKategoriPage> {
  late final KategoriRepository _repositori =
      widget.repositori ?? SupabaseKategoriRepository();

  DataKategori? _data;
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });

    try {
      final data = await _repositori.muatKategori();

      if (!mounted) return;

      setState(() {
        _data = data;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _memuat = false;
        _galat = 'Data kategori gagal dimuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Kategori',
      child: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _galat != null
              ? _galatTampilan()
              : _isi(_data!),
    );
  }

  Widget _isi(DataKategori data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RemahAdmin(['Dashboard', 'Kategori']),
          JudulKategori(
            jumlahTingkat: data.jumlahTingkatBaca,
            onTambah: () => _dialogKategori(),
            onLihatTingkat: () => _dialogTingkat(data),
          ),
          const SizedBox(height: 16),
          if (data.dataContoh) ...[
            _keteranganContoh(),
            const SizedBox(height: 14),
          ],
          KepalaBagianKategori(jumlahKategori: data.jumlahKategori),
          const SizedBox(height: 10),
          KisiKategori(
            kategori: data.kategori,
            onUbah: (item) => _dialogKategori(item),
            onTambah: () => _dialogKategori(),
          ),
          const SizedBox(height: 14),
          KartuDistribusiKategori(
            distribusi: data.distribusi,
            onLihatKatalog: () => _pesan(
              'Katalog cerita lengkap tersedia di menu Kelola Cerita.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _galatTampilan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 34,
              color: GayaAdmin.teksAbu,
            ),
            const SizedBox(height: 8),
            const Text(
              'Data kategori gagal dimuat.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            const SizedBox(height: 10),
            TombolAdmin(
              teks: 'Coba Lagi',
              ikon: Icons.refresh,
              onPressed: _muat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _keteranganContoh() {
    return Container(
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
  // DIALOG TAMBAH / UBAH KATEGORI
  // --------------------------------------------------------

  Future<void> _dialogKategori([KategoriCerita? item]) async {
    final nama = TextEditingController(text: item?.nama ?? '');
    final genre = TextEditingController(text: item?.genre ?? '');
    final deskripsi = TextEditingController(text: item?.deskripsi ?? '');

    final isian = await showDialog<IsianKategori>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          title: Text(
            item == null ? 'Tambah Kategori Baru' : 'Ubah Kategori',
            style: const TextStyle(
              fontSize: 16,
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
                    hint: 'Contoh: Fantasi',
                    controller: genre,
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final hasil = IsianKategori(
                  nama: nama.text,
                  genre: genre.text,
                  deskripsi: deskripsi.text,
                );

                if (!hasil.valid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama kategori harus diisi.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, hasil);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GayaAdmin.biruTua,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    nama.dispose();
    genre.dispose();
    deskripsi.dispose();

    if (isian == null) return;

    final tersimpan = await _repositori.simpanKategori(
      id: item?.id,
      isian: isian,
    );

    if (tersimpan) {
      await _muat();
    } else if (_data != null) {
      final daftar = List<KategoriCerita>.from(_data!.kategori);

      if (item == null) {
        daftar.add(
          KategoriCerita.dariIsian(
            isian,
            id: -DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        final indeks = daftar.indexWhere((row) => row.id == item.id);

        if (indeks >= 0) {
          daftar[indeks] = item.salinDengan(
            nama: isian.nama.trim(),
            genre: isian.genreFinal,
            deskripsi: isian.deskripsi.trim(),
          );
        }
      }

      setState(() {
        _data = _data!.denganKategori(daftar);
      });
    }

    _pesan(
      tersimpan
          ? 'Kategori berhasil disimpan.'
          : 'Kategori diperbarui pada sesi ini.',
    );
  }

  // --------------------------------------------------------
  // DIALOG TINGKAT BACA
  // --------------------------------------------------------

  Future<void> _dialogTingkat(DataKategori data) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Tingkat Baca Pustakoo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tingkatan literasi dipakai untuk mengkalibrasi '
                  'rekomendasi bacaan dan tingkat kesulitan kuis.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
                const SizedBox(height: 12),
                for (final tingkat in TingkatBaca.values)
                  _BarisTingkat(
                    tingkat: tingkat,
                    bagian: data.distribusi.bagian.firstWhere(
                      (item) => item.tingkat == tingkat,
                      orElse: () => BagianDistribusi(
                        tingkat: tingkat,
                        jumlah: 0,
                      ),
                    ),
                    distribusi: data.distribusi,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }
}

class _BarisTingkat extends StatelessWidget {
  final TingkatBaca tingkat;
  final BagianDistribusi bagian;
  final DistribusiBuku distribusi;

  const _BarisTingkat({
    required this.tingkat,
    required this.bagian,
    required this.distribusi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GayaAdmin.latar,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GayaAdmin.biruMuda,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${TingkatBaca.values.indexOf(tingkat) + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tingkat.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tingkat.kelompokUsia,
                  style: const TextStyle(
                    fontSize: 9,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${bagian.jumlah} buku • '
            '${distribusi.persentase(bagian).round()}%',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: GayaAdmin.teks,
            ),
          ),
        ],
      ),
    );
  }
}
