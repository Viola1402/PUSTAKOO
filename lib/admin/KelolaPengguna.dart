import 'package:flutter/material.dart';

import '../layanan/pengguna_layanan.dart';
import '../model/pengguna_model.dart';
import '../widget/pengguna_widget.dart';
import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA PENGGUNA & ANAK
// Halaman hanya mengatur status filter dan merangkai widget;
// pengambilan data diserahkan ke PenggunaRepository.
// ==========================================================

class KelolaPenggunaPage extends StatefulWidget {
  final PenggunaRepository repositori;

  const KelolaPenggunaPage({
    super.key,
    this.repositori = const ContohPenggunaRepository(),
  });

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  late Future<DataPengguna> _data;
  final TextEditingController _pencarian = TextEditingController();

  FilterPengguna _filter = const FilterPengguna();

  @override
  void initState() {
    super.initState();
    _data = widget.repositori.muatPengguna();
  }

  @override
  void dispose() {
    _pencarian.dispose();
    super.dispose();
  }

  void _muatUlang() {
    setState(() {
      _data = widget.repositori.muatPengguna();
    });
  }

  void _ubahFilter(FilterPengguna filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Pengguna',
      child: FutureBuilder<DataPengguna>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _galat();
          }

          return _isi(snapshot.data!);
        },
      ),
    );
  }

  Widget _isi(DataPengguna data) {
    final daftar = _filter.terapkan(data.pengguna);

    return LayoutBuilder(
      builder: (context, ukuran) {
        final lebar = ukuran.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RemahAdmin(['Dashboard', 'Kelola Pengguna']),
              _judulHalaman(),
              const SizedBox(height: 12),
              _keteranganContoh(),
              const SizedBox(height: 14),
              _barisStatistik(data.statistik, lebar),
              const SizedBox(height: 14),
              FilterPenggunaBar(
                filter: _filter,
                ringkasan: data.ringkasan,
                pencarian: _pencarian,
                onUbah: _ubahFilter,
              ),
              const SizedBox(height: 14),
              if (lebar > 1000)
                TabelPengguna(
                  daftar: daftar,
                  onDetail: _detailPengguna,
                )
              else
                Column(
                  children: [
                    for (final item in daftar)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: KartuPenggunaRingkas(
                          pengguna: item,
                          onDetail: _detailPengguna,
                        ),
                      ),
                    if (daftar.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Tidak ada pengguna yang cocok dengan filter.',
                          style: TextStyle(
                            fontSize: 11,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              FooterPengguna(
                ditampilkan: daftar.length,
                total: data.ringkasan.totalAkun,
              ),
              const SizedBox(height: 18),
              _barisInformasi(lebar),
            ],
          ),
        );
      },
    );
  }

  Widget _galat() {
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
              'Data pengguna gagal dimuat.',
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
              onPressed: _muatUlang,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // JUDUL HALAMAN
  // --------------------------------------------------------

  Widget _judulHalaman() {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final tombol = TombolAdmin(
          teks: 'Ekspor Data',
          ikon: Icons.file_download_outlined,
          utama: false,
          onPressed: () =>
              _pesan('Ekspor data pengguna belum dihubungkan.'),
        );

        const judul = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Pengguna',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Manajemen data orang tua terdaftar, profil anak, riwayat '
              'koin terkumpul, dan status langganan/keaktifan.',
              style: TextStyle(
                fontSize: 11.5,
                color: GayaAdmin.teksAbu,
                height: 1.45,
              ),
            ),
          ],
        );

        if (ukuran.maxWidth > 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: judul),
              const SizedBox(width: 12),
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
              'Kolom email, usia anak, koin, dan langganan belum tersedia '
              'di database. Data contoh ditampilkan agar tampilan tetap lengkap.',
              style: TextStyle(fontSize: 10, color: GayaAdmin.oranye),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // STATISTIK
  // --------------------------------------------------------

  Widget _barisStatistik(List<StatistikPengguna> statistik, double lebar) {
    final kolom = lebar > 1050
        ? statistik.length
        : lebar > 560
            ? 2
            : 1;
    const celah = 12.0;
    final lebarKartu = (lebar - celah * (kolom - 1)) / kolom;

    return Wrap(
      spacing: celah,
      runSpacing: celah,
      children: [
        for (final item in statistik)
          SizedBox(
            width: lebarKartu,
            height: 132,
            child: KartuStatistikPengguna(statistik: item),
          ),
      ],
    );
  }

  // --------------------------------------------------------
  // INFORMASI BAWAH
  // --------------------------------------------------------

  Widget _barisInformasi(double lebar) {
    final kolom = lebar > 900 ? 3 : 1;
    const celah = 10.0;
    final lebarKartu = (lebar - celah * (kolom - 1)) / kolom;

    return Wrap(
      spacing: celah,
      runSpacing: celah,
      children: [
        SizedBox(
          width: lebarKartu,
          child: const KartuInformasiPengguna(
            judul: 'Pengumuman & Notifikasi Massal',
            isi: 'Kirim pesan pengumuman buku atau tips membaca.',
            ikon: Icons.campaign_outlined,
            warna: GayaAdmin.biruMuda,
            warnaIkon: GayaAdmin.biruTua,
          ),
        ),
        SizedBox(
          width: lebarKartu,
          child: const KartuInformasiPengguna(
            judul: 'Atur Bonus Koin Membaca',
            isi: 'Kelola rate bonus koin untuk periode liburan.',
            ikon: Icons.stars_outlined,
            warna: GayaAdmin.krem,
            warnaIkon: Color(0xFFC0781A),
          ),
        ),
        SizedBox(
          width: lebarKartu,
          child: const KartuInformasiPengguna(
            judul: 'Keamanan & Hak Akses Ortu',
            isi: 'PIN pengaman anak dan kontrol batasan durasi.',
            ikon: Icons.shield_outlined,
            warna: GayaAdmin.biruMuda,
            warnaIkon: GayaAdmin.biruTua,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // AKSI
  // --------------------------------------------------------

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  Future<void> _detailPengguna(BarisPengguna pengguna) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            pengguna.nama,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengguna.email,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                  const Divider(height: 18),
                  _barisDetail('Status akun', pengguna.status.label),
                  _barisDetail('Langganan', pengguna.paket),
                  _barisDetail(
                    'Tabungan koin',
                    '${FormatPengguna.angka(pengguna.koin)} Koin',
                  ),
                  _barisDetail('Bergabung', pengguna.bergabung),
                  const SizedBox(height: 10),
                  const Text(
                    'Profil Anak',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: GayaAdmin.biruTua,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final anak in pengguna.anak)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.child_care,
                            size: 13,
                            color: GayaAdmin.biru,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${anak.label} • ${anak.level}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: GayaAdmin.teks,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: GayaAdmin.latar,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Aktivitas terakhir: ${pengguna.aktivitas} '
                      '(${pengguna.waktuAktivitas})',
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.4,
                        color: GayaAdmin.teksAbu,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _barisDetail(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.teks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
