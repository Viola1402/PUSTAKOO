import 'package:flutter/material.dart';

import '../layanan/dashboard_layanan.dart';
import '../model/dashboard_model.dart';
import '../widget/dashboard_widget.dart';
import 'admin_shell.dart';

// ==========================================================
// HALAMAN DASHBOARD ADMIN PUSTAKOO
// ==========================================================

class DashboardAdmin extends StatefulWidget {
  final DashboardRepository? repositori;

  const DashboardAdmin({super.key, this.repositori});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  late final DashboardRepository _repositori =
      widget.repositori ?? SupabaseDashboardRepository();

  late Future<DataDashboard> _data;

  @override
  void initState() {
    super.initState();
    _data = _repositori.muatDashboard();
  }

  void _muatUlang() {
    setState(() {
      _data = _repositori.muatDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Dashboard',
      child: FutureBuilder<DataDashboard>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _galat();
          }

          return _isi(snapshot.data!);
        },
      ),
    );
  }

  // ========================================================
  // KONTEN UTAMA DASHBOARD
  // ========================================================

  Widget _isi(DataDashboard data) {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final lebar = ukuran.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kepala(),

              const SizedBox(height: 24),

              // Empat kartu statistik sejajar
              _statistik(data, lebar),

              const SizedBox(height: 24),

              // Konten dashboard
              if (lebar > 1000)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          PanelCeritaPopuler(
                            cerita: data.ceritaPopuler,
                            onLihatSemua: () {
                              _bukaMenu('Kelola Cerita');
                            },
                          ),
                          const SizedBox(height: 16),
                          KartuRingkasanDashboard(
                            ringkasan: data.ringkasan,
                            onLihatLaporan: () {
                              _bukaMenu('Laporan');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: PanelAktivitasTerbaru(
                        aktivitas: data.aktivitas,
                        onLihatSemua: () {
                          _pesan(
                            'Log aktivitas lengkap tersedia di menu Laporan.',
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    PanelCeritaPopuler(
                      cerita: data.ceritaPopuler,
                      onLihatSemua: () {
                        _bukaMenu('Kelola Cerita');
                      },
                    ),
                    const SizedBox(height: 16),
                    PanelAktivitasTerbaru(
                      aktivitas: data.aktivitas,
                      onLihatSemua: () {
                        _pesan(
                          'Log aktivitas lengkap tersedia di menu Laporan.',
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    KartuRingkasanDashboard(
                      ringkasan: data.ringkasan,
                      onLihatLaporan: () {
                        _bukaMenu('Laporan');
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ========================================================
  // HEADER DASHBOARD
  // ========================================================

  Widget _kepala() {
    const judul = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 36,
            height: 1.2,
            fontWeight: FontWeight.bold,
            color: GayaAdmin.biruTua,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Selamat datang kembali! Berikut ringkasan performa '
          'perpustakaan digital anak Pustakoo hari ini.',
          style: TextStyle(
            fontSize: 14,
            color: GayaAdmin.teksAbu,
            height: 1.5,
          ),
        ),
      ],
    );

    final pekan = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: GayaAdmin.kremMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: GayaAdmin.biruTua,
          ),
          const SizedBox(width: 9),
          Text(
            'Pekan Ini: ${_labelPekan(DateTime.now())}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: GayaAdmin.biruTua,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, ukuran) {
        if (ukuran.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: judul),
              const SizedBox(width: 16),
              pekan,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            judul,
            const SizedBox(height: 14),
            pekan,
          ],
        );
      },
    );
  }

  // ========================================================
  // EMPAT KARTU STATISTIK SEJAJAR
  // ========================================================

  Widget _statistik(DataDashboard data, double lebar) {
    const celah = 16.0;
    const jumlahKolom = 4;
    const lebarMinimum = 220.0;

    final lebarKartu = ((lebar - (celah * 3)) / jumlahKolom)
        .clamp(lebarMinimum, double.infinity)
        .toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < data.statistik.length; i++) ...[
            SizedBox(
              width: lebarKartu,
              height: 160,
              child: KartuStatistikDashboard(
                statistik: data.statistik[i],
              ),
            ),
            if (i < data.statistik.length - 1) const SizedBox(width: celah),
          ],
        ],
      ),
    );
  }

  // ========================================================
  // PESAN KETIKA DATA GAGAL DIMUAT
  // ========================================================

  Widget _galat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: GayaAdmin.teksAbu,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data dashboard gagal dimuat.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: GayaAdmin.biruTua,
              ),
            ),
            const SizedBox(height: 14),
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

  // ========================================================
  // NAVIGASI DAN NOTIFIKASI
  // ========================================================

  void _bukaMenu(String menu) {
    bukaMenuAdmin(context, menu);
  }

  void _pesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  // ========================================================
  // FORMAT TANGGAL PEKAN
  // ========================================================

  static String _labelPekan(DateTime sekarang) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final akhir = DateTime(
      sekarang.year,
      sekarang.month,
      sekarang.day,
    );

    final awal = akhir.subtract(
      const Duration(days: 6),
    );

    if (awal.month == akhir.month) {
      return '${awal.day} - ${akhir.day} '
          '${bulan[akhir.month - 1]} ${akhir.year}';
    }

    return '${awal.day} ${bulan[awal.month - 1]} - '
        '${akhir.day} ${bulan[akhir.month - 1]} ${akhir.year}';
  }
}
