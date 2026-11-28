import 'package:flutter/material.dart';

import '../layanan/kategori_layanan.dart';
import '../model/kategori_model.dart';
import '../widget/kategori_widget.dart';
import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA KATEGORI
// ==========================================================

class KelolaKategoriPage extends StatefulWidget {
  final KategoriRepository? repositori;

  const KelolaKategoriPage({
    super.key,
    this.repositori,
  });

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

  // ========================================================
  // MEMUAT DATA KATEGORI
  // ========================================================

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
    } catch (error) {
      debugPrint('Gagal memuat kategori: $error');

      if (!mounted) return;

      setState(() {
        _memuat = false;
        _galat = 'Data kategori gagal dimuat.';
      });
    }
  }

  // ========================================================
  // TAMPILAN UTAMA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Kategori',
      child: _memuat
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
          const RemahAdmin([
            'Dashboard',
            'Kategori',
          ]),
          JudulKategori(
            onTambah: () => _dialogKategori(),
          ),
          const SizedBox(height: 20),
          KepalaBagianKategori(
            jumlahKategori: data.jumlahKategori,
          ),
          const SizedBox(height: 12),
          KisiKategori(
            kategori: data.kategori,
            onUbah: (item) => _dialogKategori(item),
            onHapus: (item) => _konfirmasiHapus(item),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAMPILAN GAGAL MEMUAT DATA
  // ========================================================

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

  // ========================================================
  // DIALOG TAMBAH / UBAH KATEGORI
  // ========================================================

  Future<void> _dialogKategori([
    KategoriCerita? item,
  ]) async {
    final nama = TextEditingController(
      text: item?.nama ?? '',
    );

    final genre = TextEditingController(
      text: item?.genre ?? '',
    );

    final deskripsi = TextEditingController(
      text: item?.deskripsi ?? '',
    );

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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nama kategori harus diisi.',
                      ),
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

    if (!mounted) return;

    if (tersimpan) {
      await _muat();

      if (!mounted) return;

      _pesan(
        item == null
            ? 'Kategori berhasil ditambahkan.'
            : 'Kategori berhasil diperbarui.',
      );
    } else {
      _pesan('Kategori gagal disimpan. Periksa koneksi database.');
    }
  }

  // ========================================================
  // KONFIRMASI HAPUS KATEGORI
  // ========================================================

  Future<void> _konfirmasiHapus(
    KategoriCerita item,
  ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Hapus Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus kategori '
            '"${item.nama}"?',
            style: const TextStyle(
              fontSize: 12,
              color: GayaAdmin.teks,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) return;

    final berhasil = await _repositori.hapusKategori(item.id);

    if (!mounted) return;

    if (berhasil) {
      await _muat();

      if (!mounted) return;

      _pesan('Kategori berhasil dihapus.');
    } else {
      _pesan(
        'Kategori gagal dihapus. Pastikan kategori tidak '
        'sedang digunakan oleh buku.',
      );
    }
  }

  // ========================================================
  // PESAN
  // ========================================================

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
      ),
    );
  }
}
