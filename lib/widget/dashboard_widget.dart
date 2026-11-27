import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';
import '../model/dashboard_model.dart';
import '../widgets/sampul_cerita.dart';

// ==========================================================
// KOMPONEN TAMPILAN DASHBOARD ADMIN PUSTAKOO
// ==========================================================

abstract final class FormatDashboard {
  static const List<String> _bulan = [
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

  static String angka(int nilai) {
    final teks = nilai.abs().toString();
    final hasil = StringBuffer();

    for (var i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(teks[i]);
    }

    return '${nilai < 0 ? '-' : ''}$hasil';
  }

  static String tanggalRingkas(DateTime tanggal) {
    return '${tanggal.day} ${_bulan[tanggal.month - 1]} ${tanggal.year}';
  }

  static String waktuRelatif(DateTime? waktu) {
    if (waktu == null) return 'Waktu tidak tersedia';

    final selisih = DateTime.now().difference(waktu);

    if (selisih.isNegative || selisih.inMinutes < 1) {
      return 'Baru saja';
    }
    if (selisih.inMinutes < 60) {
      return '${selisih.inMinutes} menit lalu';
    }
    if (selisih.inHours < 24) {
      return '${selisih.inHours} jam lalu';
    }
    if (selisih.inDays < 7) {
      return '${selisih.inDays} hari lalu';
    }

    return tanggalRingkas(waktu);
  }
}

// ==========================================================
// PALET WARNA DASHBOARD
// ==========================================================

abstract final class PaletDashboard {
  static const Color teksKartu = Color(0xFF0E3C5C);
  static const Color kremTabel = Color(0xFFFBF6EA);

  static const Color kartuPengguna = Color(0xFFBFDCF2);
  static const Color kartuAnak = Color(0xFFF2EAA8);
  static const Color kartuCerita = Color(0xFFF6C25B);
  static const Color kartuKuis = Color(0xFFEFE7D5);
}

// ==========================================================
// GAYA KATEGORI CERITA
// ==========================================================

class _GayaKategori {
  final Color latar;
  final Color teks;
  final IconData ikon;

  const _GayaKategori(this.latar, this.teks, this.ikon);

  static const _GayaKategori bawaan = _GayaKategori(
    Color(0xFFE0F2FE),
    Color(0xFF006B9F),
    Icons.auto_stories_outlined,
  );

  static _GayaKategori dari(String nama) {
    final teks = nama.toLowerCase();

    if (teks.contains('dongeng') || teks.contains('fantasi')) {
      return const _GayaKategori(
        Color(0xFFFBE4EF),
        Color(0xFFC2185B),
        Icons.castle_outlined,
      );
    }

    if (teks.contains('petualangan') || teks.contains('eksplorasi')) {
      return const _GayaKategori(
        Color(0xFFFDF1DC),
        Color(0xFFB7791F),
        Icons.terrain_outlined,
      );
    }

    if (teks.contains('hewan') ||
        teks.contains('fabel') ||
        teks.contains('satwa')) {
      return const _GayaKategori(
        Color(0xFFE7F7EC),
        Color(0xFF2E7D32),
        Icons.pets_outlined,
      );
    }

    if (teks.contains('sains') ||
        teks.contains('edukasi') ||
        teks.contains('stem')) {
      return const _GayaKategori(
        Color(0xFFE9E9FD),
        Color(0xFF4F46B8),
        Icons.lightbulb_outline,
      );
    }

    if (teks.contains('rakyat') || teks.contains('budaya')) {
      return const _GayaKategori(
        Color(0xFFE0F2FE),
        Color(0xFF006B9F),
        Icons.menu_book_outlined,
      );
    }

    return bawaan;
  }
}

// ==========================================================
// GAYA TEKS PANEL
// ==========================================================

const TextStyle _gayaJudulPanel = TextStyle(
  fontSize: 23,
  height: 1.2,
  fontWeight: FontWeight.bold,
  color: GayaAdmin.biru,
);

const TextStyle _gayaSubJudulPanel = TextStyle(
  fontSize: 12,
  height: 1.4,
  color: GayaAdmin.teksAbu,
);

// ==========================================================
// KARTU STATISTIK
// ==========================================================

class KartuStatistikDashboard extends StatelessWidget {
  final StatistikDashboard statistik;

  const KartuStatistikDashboard({
    super.key,
    required this.statistik,
  });

  Color get _warna {
    switch (statistik.jenis) {
      case JenisStatistik.pengguna:
        return PaletDashboard.kartuPengguna;
      case JenisStatistik.anak:
        return PaletDashboard.kartuAnak;
      case JenisStatistik.cerita:
        return PaletDashboard.kartuCerita;
      case JenisStatistik.kuis:
        return PaletDashboard.kartuKuis;
    }
  }

  IconData get _ikon {
    switch (statistik.jenis) {
      case JenisStatistik.pengguna:
        return Icons.groups_2_outlined;
      case JenisStatistik.anak:
        return Icons.child_care_outlined;
      case JenisStatistik.cerita:
        return Icons.menu_book_outlined;
      case JenisStatistik.kuis:
        return Icons.fact_check_outlined;
    }
  }

  IconData get _ikonCatatan {
    switch (statistik.jenis) {
      case JenisStatistik.pengguna:
      case JenisStatistik.cerita:
        return Icons.trending_up;
      case JenisStatistik.anak:
        return Icons.circle;
      case JenisStatistik.kuis:
        return Icons.arrow_upward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warnaIkonCatatan = statistik.jenis == JenisStatistik.anak
        ? PaletDashboard.teksKartu
        : GayaAdmin.hijau;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _warna,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  statistik.judul.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w800,
                    color: PaletDashboard.teksKartu,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _ikon,
                  size: 23,
                  color: PaletDashboard.teksKartu,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FormatDashboard.angka(statistik.nilai),
              style: const TextStyle(
                fontSize: 42,
                height: 1,
                fontWeight: FontWeight.bold,
                color: PaletDashboard.teksKartu,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ikonCatatan,
                  size: statistik.jenis == JenisStatistik.anak ? 8 : 13,
                  color: warnaIkonCatatan,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statistik.catatan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: PaletDashboard.teksKartu,
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
}

// ==========================================================
// PANEL CERITA POPULER
// ==========================================================

class PanelCeritaPopuler extends StatelessWidget {
  final List<CeritaPopuler> cerita;
  final bool memuat;
  final VoidCallback? onLihatSemua;

  const PanelCeritaPopuler({
    super.key,
    required this.cerita,
    this.memuat = false,
    this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cerita Populer', style: _gayaJudulPanel),
                    SizedBox(height: 5),
                    Text(
                      'Buku cerita yang paling sering dibaca pekan ini',
                      style: _gayaSubJudulPanel,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onLihatSemua,
                style: TextButton.styleFrom(
                  foregroundColor: GayaAdmin.biru,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua ›',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (memuat)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cerita.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Belum ada cerita yang dibaca pekan ini.',
                style: TextStyle(
                  fontSize: 12,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, batasan) {
                if (batasan.maxWidth < 620) {
                  return Column(
                    children: [
                      for (final item in cerita)
                        _BarisCerita(item: item, ringkas: true),
                    ],
                  );
                }

                return Column(
                  children: [
                    const _KepalaTabelCerita(),
                    for (final item in cerita) _BarisCerita(item: item),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KepalaTabelCerita extends StatelessWidget {
  const _KepalaTabelCerita();

  @override
  Widget build(BuildContext context) {
    const gaya = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
      color: GayaAdmin.teksAbu,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: PaletDashboard.kremTabel,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(flex: 9, child: Text('BUKU & JUDUL', style: gaya)),
          Expanded(flex: 4, child: Text('KATEGORI', style: gaya)),
          Expanded(flex: 4, child: Text('PEMBACA', style: gaya)),
          Expanded(flex: 4, child: Text('SKOR KUIS', style: gaya)),
          Expanded(flex: 3, child: Text('STATUS', style: gaya)),
        ],
      ),
    );
  }
}

class _BarisCerita extends StatelessWidget {
  final CeritaPopuler item;
  final bool ringkas;

  const _BarisCerita({
    required this.item,
    this.ringkas = false,
  });

  Widget get _detail {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.judul,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.subjudul,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: GayaAdmin.teksAbu,
          ),
        ),
      ],
    );
  }

  Widget get _kategori {
    final gaya = _GayaKategori.dari(item.kategori);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: gaya.latar,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          item.kategori,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: gaya.teks,
          ),
        ),
      ),
    );
  }

  Widget get _pembaca {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${FormatDashboard.angka(item.pembaca)} Kali',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Dibaca',
          style: TextStyle(
            fontSize: 11,
            color: GayaAdmin.teksAbu,
          ),
        ),
      ],
    );
  }

  Widget get _skor {
    if (item.nilaiKuis == null) {
      return const Text(
        '-',
        style: TextStyle(
          fontSize: 12,
          color: GayaAdmin.teksAbu,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.nilaiLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: item.lulus ? GayaAdmin.hijau : GayaAdmin.oranye,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                item.lulus ? 'Lulus' : 'Perlu Ulang',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.lulus ? GayaAdmin.hijau : GayaAdmin.oranye,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget get _status {
    final warna = item.diterbitkan ? GayaAdmin.hijau : GayaAdmin.oranye;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: warna,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            item.statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ringkas) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: GayaAdmin.garis),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SampulBuku(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail,
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _kategori,
                      _pembaca,
                      _skor,
                      _status,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: GayaAdmin.garis),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 9,
            child: Row(
              children: [
                _SampulBuku(item: item),
                const SizedBox(width: 12),
                Expanded(child: _detail),
              ],
            ),
          ),
          Expanded(flex: 4, child: _kategori),
          Expanded(flex: 4, child: _pembaca),
          Expanded(flex: 4, child: _skor),
          Expanded(flex: 3, child: _status),
        ],
      ),
    );
  }
}

class _SampulBuku extends StatelessWidget {
  final CeritaPopuler item;

  const _SampulBuku({required this.item});

  @override
  Widget build(BuildContext context) {
    final gaya = _GayaKategori.dari(item.kategori);
    final gambar = item.gambarSampul?.trim() ?? '';

    if (gambar.isNotEmpty) {
      return SampulCerita(
        sumber: gambar,
        lebar: 42,
        tinggi: 54,
        radius: BorderRadius.circular(8),
        warnaLatar: gaya.latar,
        warnaIkon: gaya.teks,
      );
    }

    return Container(
      width: 42,
      height: 54,
      decoration: BoxDecoration(
        color: gaya.latar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        gaya.ikon,
        size: 21,
        color: gaya.teks,
      ),
    );
  }
}

// ==========================================================
// PANEL AKTIVITAS TERBARU
// ==========================================================

class PanelAktivitasTerbaru extends StatelessWidget {
  final List<AktivitasDashboard> aktivitas;
  final bool memuat;
  final VoidCallback? onLihatSemua;

  const PanelAktivitasTerbaru({
    super.key,
    required this.aktivitas,
    this.memuat = false,
    this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: GayaAdmin.krem,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aktivitas Terbaru', style: _gayaJudulPanel),
          const SizedBox(height: 5),
          const Text(
            'Log aktivitas real-time orang tua & anak',
            style: _gayaSubJudulPanel,
          ),
          const SizedBox(height: 16),
          if (memuat)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (aktivitas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Belum ada aktivitas.',
                style: TextStyle(
                  fontSize: 12,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            )
          else
            for (final item in aktivitas) _ItemAktivitas(item: item),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: onLihatSemua,
              style: TextButton.styleFrom(
                foregroundColor: GayaAdmin.biruTua,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat Semua Log Aktivitas →',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemAktivitas extends StatelessWidget {
  final AktivitasDashboard item;

  const _ItemAktivitas({required this.item});

  IconData get _ikon {
    switch (item.jenis) {
      case JenisAktivitas.membaca:
        return Icons.menu_book_outlined;
      case JenisAktivitas.kuis:
        return Icons.quiz_outlined;
      case JenisAktivitas.poin:
        return Icons.stars_outlined;
      case JenisAktivitas.misi:
        return Icons.emoji_events_outlined;
      case JenisAktivitas.pengguna:
        return Icons.person_add_alt_1_outlined;
    }
  }

  Color get _warna {
    switch (item.jenis) {
      case JenisAktivitas.membaca:
        return GayaAdmin.biru;
      case JenisAktivitas.kuis:
        return const Color(0xFF7C5CBF);
      case JenisAktivitas.poin:
        return GayaAdmin.oranye;
      case JenisAktivitas.misi:
        return GayaAdmin.hijau;
      case JenisAktivitas.pengguna:
        return GayaAdmin.biruTua;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _warna.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _ikon,
              size: 21,
              color: _warna,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: GayaAdmin.teks,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        FormatDashboard.waktuRelatif(item.waktu),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: GayaAdmin.teksAbu,
                        ),
                      ),
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _warna,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// KARTU RINGKASAN LAPORAN PEKAN INI
// ==========================================================

class KartuRingkasanDashboard extends StatelessWidget {
  final RingkasanDashboard ringkasan;
  final VoidCallback? onLihatLaporan;

  const KartuRingkasanDashboard({
    super.key,
    required this.ringkasan,
    this.onLihatLaporan,
  });

  Widget get _kiri {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ChipAdmin(
          'Rangkuman Mingguan',
          ikon: Icons.insights_outlined,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ringkasan Laporan Pekan Ini',
          style: TextStyle(
            fontSize: 21,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: GayaAdmin.biruTua,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cerita terpopuler, rata-rata skor kuis, dan misi selesai',
          style: TextStyle(
            fontSize: 11,
            height: 1.3,
            color: GayaAdmin.teksAbu,
          ),
        ),
        const SizedBox(height: 10),
        TombolAdmin(
          teks: 'Lihat Laporan',
          ikon: Icons.arrow_forward,
          onPressed: onLihatLaporan,
        ),
      ],
    );
  }

  Widget get _kanan {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BarisRingkasan(
          ikon: Icons.local_fire_department_outlined,
          label: 'Terpopuler',
          warnaIkon: GayaAdmin.oranye,
          kanan: Text(
            ringkasan.ceritaTerpopuler,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _BarisRingkasan(
          ikon: Icons.fact_check_outlined,
          label: 'Rata-rata skor kuis',
          warnaIkon: GayaAdmin.biru,
          kanan: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ringkasan.rataRataKuis} / 100',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              if (ringkasan.selisihKuis != 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: GayaAdmin.hijauMuda,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ringkasan.selisihLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: GayaAdmin.hijau,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        _BarisRingkasan(
          ikon: Icons.check_circle_outline,
          label: 'Misi selesai',
          warnaIkon: GayaAdmin.hijau,
          kanan: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 65,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (ringkasan.persentaseMisi / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: GayaAdmin.garis,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      GayaAdmin.hijau,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${ringkasan.persentaseMisi}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GayaAdmin.krem,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, batasan) {
          if (batasan.maxWidth > 620) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: _kiri),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: _kanan),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kiri,
              const SizedBox(height: 10),
              _kanan,
            ],
          );
        },
      ),
    );
  }
}

// ==========================================================
// BARIS RINGKASAN
// ==========================================================

class _BarisRingkasan extends StatelessWidget {
  final IconData ikon;
  final String label;
  final Widget kanan;
  final Color warnaIkon;

  const _BarisRingkasan({
    required this.ikon,
    required this.label,
    required this.kanan,
    required this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: warnaIkon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ikon,
              size: 15,
              color: warnaIkon,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: GayaAdmin.teks,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: kanan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
