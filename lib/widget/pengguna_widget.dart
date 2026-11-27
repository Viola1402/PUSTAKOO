import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';
import '../model/pengguna_model.dart';

// ==========================================================
// KOMPONEN TAMPILAN KELOLA PENGGUNA
// Setiap bagian halaman dibuat sebagai kelas widget sendiri
// agar halaman utama tetap ringkas dan mudah dirawat.
// ==========================================================

abstract final class FormatPengguna {
  static String angka(int nilai) {
    final teks = nilai.abs().toString();
    final hasil = StringBuffer();

    for (var i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) hasil.write('.');
      hasil.write(teks[i]);
    }

    return '${nilai < 0 ? '-' : ''}$hasil';
  }
}

// ==========================================================
// KARTU STATISTIK
// ==========================================================

class KartuStatistikPengguna extends StatelessWidget {
  final StatistikPengguna statistik;

  const KartuStatistikPengguna({super.key, required this.statistik});

  Color get _latar {
    return switch (statistik.jenis) {
      JenisStatistikPengguna.akunOrangTua => const Color(0xFFF4FAFF),
      JenisStatistikPengguna.profilAnak => Colors.white,
      JenisStatistikPengguna.akunMembaca => Colors.white,
      JenisStatistikPengguna.totalKoin => const Color(0xFFFAF2E2),
    };
  }

  Color get _latarIkon {
    return switch (statistik.jenis) {
      JenisStatistikPengguna.akunOrangTua => const Color(0xFFD8ECFB),
      JenisStatistikPengguna.profilAnak => const Color(0xFFFDF0D9),
      JenisStatistikPengguna.akunMembaca => const Color(0xFFDCEEFA),
      JenisStatistikPengguna.totalKoin => const Color(0xFFF3E7CE),
    };
  }

  Color get _warnaIkon {
    return switch (statistik.jenis) {
      JenisStatistikPengguna.akunOrangTua => GayaAdmin.biruTua,
      JenisStatistikPengguna.profilAnak => const Color(0xFFC0781A),
      JenisStatistikPengguna.akunMembaca => GayaAdmin.biru,
      JenisStatistikPengguna.totalKoin => const Color(0xFF8A5A13),
    };
  }

  IconData get _ikon {
    return switch (statistik.jenis) {
      JenisStatistikPengguna.akunOrangTua => Icons.groups_2_outlined,
      JenisStatistikPengguna.profilAnak => Icons.child_care_outlined,
      JenisStatistikPengguna.akunMembaca => Icons.menu_book_outlined,
      JenisStatistikPengguna.totalKoin => Icons.savings_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final progres = statistik.progres;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _latar,
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
                  statistik.judul.toUpperCase(),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 8.5,
                    height: 1.3,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _latarIkon,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_ikon, size: 16, color: _warnaIkon),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatPengguna.angka(statistik.nilai),
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  statistik.satuan,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (progres != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progres.clamp(0, 1),
                minHeight: 5,
                backgroundColor: GayaAdmin.garis,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  GayaAdmin.biruTua,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (statistik.penanda != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GayaAdmin.hijauMuda,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 9,
                        color: GayaAdmin.hijau,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        statistik.penanda!,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: GayaAdmin.hijau,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  statistik.catatan,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 8.5,
                    height: 1.3,
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

// ==========================================================
// PANEL PENCARIAN DAN FILTER
// ==========================================================

class FilterPenggunaBar extends StatelessWidget {
  final FilterPengguna filter;
  final RingkasanPengguna ringkasan;
  final TextEditingController pencarian;
  final ValueChanged<FilterPengguna> onUbah;

  const FilterPenggunaBar({
    super.key,
    required this.filter,
    required this.ringkasan,
    required this.pencarian,
    required this.onUbah,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GayaAdmin.latar,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: GayaAdmin.garis),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 16,
                  color: GayaAdmin.teksAbu,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: pencarian,
                    onChanged: (nilai) =>
                        onUbah(filter.salin(pencarian: nilai)),
                    style: const TextStyle(
                      fontSize: 11,
                      color: GayaAdmin.teks,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari nama orang tua, email, atau nama anak...',
                      hintStyle: TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in KelompokPengguna.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabPengguna(
                      label: '${item.label} (${ringkasan.hitung(item)})',
                      aktif: filter.kelompok == item,
                      onTap: () => onUbah(filter.salin(kelompok: item)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const Divider(height: 1, color: GayaAdmin.garis),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 13,
                    color: GayaAdmin.teksAbu,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'FILTER:',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: GayaAdmin.teksAbu,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              _DropdownAdmin<RentangUsia>(
                nilai: filter.usia,
                opsi: RentangUsia.values,
                label: (item) => item.label,
                awalan: 'Tingkat Usia Anak',
                onPilih: (item) => onUbah(filter.salin(usia: item)),
              ),
              _DropdownAdmin<FilterLangganan>(
                nilai: filter.langganan,
                opsi: FilterLangganan.values,
                label: (item) => item.label,
                awalan: 'Status Berlangganan',
                onPilih: (item) => onUbah(filter.salin(langganan: item)),
              ),
              _DropdownAdmin<UrutanPengguna>(
                nilai: filter.urutan,
                opsi: UrutanPengguna.values,
                label: (item) => item.label,
                awalan: 'Urutan',
                onPilih: (item) => onUbah(filter.salin(urutan: item)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              Icon(Icons.sync, size: 11, color: GayaAdmin.hijau),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Menampilkan data terverifikasi Pustakoo Sync',
                  style: TextStyle(fontSize: 8.5, color: GayaAdmin.teksAbu),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabPengguna extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _TabPengguna({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: aktif ? GayaAdmin.biruTua : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: aktif ? GayaAdmin.biruTua : GayaAdmin.garis,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: aktif ? Colors.white : GayaAdmin.teksAbu,
          ),
        ),
      ),
    );
  }
}

class _DropdownAdmin<T> extends StatelessWidget {
  final T nilai;
  final List<T> opsi;
  final String Function(T) label;
  final String awalan;
  final ValueChanged<T> onPilih;

  const _DropdownAdmin({
    required this.nilai,
    required this.opsi,
    required this.label,
    required this.awalan,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: nilai,
          isDense: true,
          borderRadius: BorderRadius.circular(9),
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: GayaAdmin.teksAbu,
          ),
          hint: Text(awalan, style: const TextStyle(fontSize: 9.5)),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: GayaAdmin.teks,
          ),
          items: [
            for (final item in opsi)
              DropdownMenuItem<T>(value: item, child: Text(label(item))),
          ],
          onChanged: (baru) {
            if (baru != null) onPilih(baru);
          },
        ),
      ),
    );
  }
}

// ==========================================================
// TABEL PENGGUNA (LAYAR LEBAR)
// ==========================================================

class TabelPengguna extends StatelessWidget {
  final List<BarisPengguna> daftar;
  final ValueChanged<BarisPengguna> onDetail;

  const TabelPengguna({
    super.key,
    required this.daftar,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _KepalaTabel('ORANG TUA / WALI')),
                Expanded(
                  flex: 3,
                  child: _KepalaTabel('PROFIL ANAK TERDAFTAR'),
                ),
                Expanded(flex: 2, child: _KepalaTabel('TABUNGAN KOIN')),
                Expanded(flex: 2, child: _KepalaTabel('AKTIVITAS TERAKHIR')),
                Expanded(flex: 2, child: _KepalaTabel('STATUS AKUN')),
                SizedBox(width: 58, child: _KepalaTabel('AKSI')),
              ],
            ),
          ),
          if (daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Tidak ada pengguna yang cocok dengan filter.',
                style: TextStyle(fontSize: 11, color: GayaAdmin.teksAbu),
              ),
            )
          else
            for (var i = 0; i < daftar.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: GayaAdmin.garis),
              _BarisTabelPengguna(
                pengguna: daftar[i],
                onDetail: onDetail,
              ),
            ],
        ],
      ),
    );
  }
}

class _BarisTabelPengguna extends StatelessWidget {
  final BarisPengguna pengguna;
  final ValueChanged<BarisPengguna> onDetail;

  const _BarisTabelPengguna({
    required this.pengguna,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(flex: 3, child: _SelOrangTua(pengguna)),
          Expanded(flex: 3, child: _SelAnak(pengguna)),
          Expanded(flex: 2, child: _SelKoin(pengguna)),
          Expanded(flex: 2, child: _SelAktivitas(pengguna)),
          Expanded(flex: 2, child: _SelStatus(pengguna)),
          SizedBox(
            width: 58,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TombolDetail(
                onPressed: () => onDetail(pengguna),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KepalaTabel extends StatelessWidget {
  final String teks;

  const _KepalaTabel(this.teks);

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: GayaAdmin.teksAbu,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ==========================================================
// KARTU PENGGUNA (LAYAR SEMPIT)
// ==========================================================

class KartuPenggunaRingkas extends StatelessWidget {
  final BarisPengguna pengguna;
  final ValueChanged<BarisPengguna> onDetail;

  const KartuPenggunaRingkas({
    super.key,
    required this.pengguna,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return KartuAdmin(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SelOrangTua(pengguna)),
              const SizedBox(width: 8),
              SizedBox(width: 88, child: _SelStatus(pengguna)),
            ],
          ),
          const SizedBox(height: 8),
          _SelAnak(pengguna),
          const SizedBox(height: 6),
          Row(
            children: [
              _SelKoin(pengguna),
              const SizedBox(width: 8),
              Expanded(child: _SelAktivitas(pengguna)),
              const SizedBox(width: 4),
              _TombolDetail(onPressed: () => onDetail(pengguna)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// SEL TABEL
// ==========================================================

class _SelOrangTua extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelOrangTua(this.pengguna);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCFE3F3)),
          ),
          child: Text(
            pengguna.inisial,
            style: const TextStyle(
              fontSize: 9.5,
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
                pengguna.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                pengguna.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gabung ${pengguna.bergabung}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelAnak extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelAnak(this.pengguna);

  @override
  Widget build(BuildContext context) {
    if (pengguna.anak.isEmpty) {
      return const Text(
        'Belum ada profil anak',
        style: TextStyle(fontSize: 9, color: GayaAdmin.teksAbu),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final anak in pengguna.anak)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.child_care,
                      size: 12,
                      color: GayaAdmin.biru,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          anak.label,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: GayaAdmin.teks,
                          ),
                        ),
                        ChipAdmin(
                          anak.level,
                          kecil: true,
                          warna: const Color(0xFFF1F5F9),
                          teksWarna: GayaAdmin.teksAbu,
                        ),
                      ],
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

class _SelKoin extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelKoin(this.pengguna);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: GayaAdmin.kremMuda,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFF0E3C6)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 11,
              color: Color(0xFFC0781A),
            ),
            const SizedBox(width: 4),
            Text(
              FormatPengguna.angka(pengguna.koin),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A5A13),
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              'Koin',
              style: TextStyle(fontSize: 8, color: Color(0xFF8A5A13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelAktivitas extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelAktivitas(this.pengguna);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.circle, size: 5, color: GayaAdmin.biru),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  pengguna.aktivitas,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.35,
                    color: GayaAdmin.teks,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            pengguna.waktuAktivitas,
            style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _SelStatus extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelStatus(this.pengguna);

  @override
  Widget build(BuildContext context) {
    final aktif = pengguna.status == StatusAkun.aktif;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipAdmin(
          pengguna.status.label,
          kecil: true,
          warna: aktif ? GayaAdmin.hijauMuda : GayaAdmin.merahMuda,
          teksWarna: aktif ? GayaAdmin.hijau : GayaAdmin.merah,
          ikon: Icons.circle,
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              pengguna.premium
                  ? Icons.workspace_premium_outlined
                  : Icons.verified_outlined,
              size: 10,
              color: GayaAdmin.teksAbu,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                pengguna.paket,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 8,
                  height: 1.3,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TombolDetail extends StatelessWidget {
  final VoidCallback onPressed;

  const _TombolDetail({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: GayaAdmin.biru,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
      child: const Text('Detail'),
    );
  }
}

// ==========================================================
// FOOTER TABEL DAN PAGINASI
// ==========================================================

class FooterPengguna extends StatelessWidget {
  final int ditampilkan;
  final int total;

  const FooterPengguna({
    super.key,
    required this.ditampilkan,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final halaman = total <= 6 ? 1 : (total / 6).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ditampilkan == 0
                  ? 'Tidak ada pengguna untuk ditampilkan'
                  : 'Menampilkan 1 - $ditampilkan dari $total pengguna terdaftar',
              style: const TextStyle(
                fontSize: 9,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ),
          Row(
            children: [
              const _TombolHalaman(
                ikon: Icons.chevron_left,
                aktif: false,
              ),
              const SizedBox(width: 3),
              for (var i = 1; i <= (halaman < 3 ? halaman : 3); i++) ...[
                _TombolHalaman(
                  teks: '$i',
                  aktif: i == 1,
                  onTap: () {},
                ),
                const SizedBox(width: 3),
              ],
              if (halaman > 4) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '...',
                    style: TextStyle(fontSize: 9, color: GayaAdmin.teksAbu),
                  ),
                ),
                _TombolHalaman(teks: '$halaman', aktif: false, onTap: () {}),
                const SizedBox(width: 3),
              ],
              const _TombolHalaman(
                ikon: Icons.chevron_right,
                aktif: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TombolHalaman extends StatelessWidget {
  final String? teks;
  final IconData? ikon;
  final bool aktif;
  final VoidCallback? onTap;

  const _TombolHalaman({
    this.teks,
    this.ikon,
    required this.aktif,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? GayaAdmin.biruTua : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: aktif ? GayaAdmin.biruTua : GayaAdmin.garis,
          ),
        ),
        child: ikon != null
            ? Icon(
                ikon,
                size: 13,
                color: aktif ? Colors.white : GayaAdmin.teksAbu,
              )
            : Text(
                teks ?? '',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: aktif ? Colors.white : GayaAdmin.teksAbu,
                ),
              ),
      ),
    );
  }
}

// ==========================================================
// KARTU INFORMASI BAWAH
// ==========================================================

class KartuInformasiPengguna extends StatelessWidget {
  final String judul;
  final String isi;
  final IconData ikon;
  final Color warna;
  final Color warnaIkon;

  const KartuInformasiPengguna({
    super.key,
    required this.judul,
    required this.isi,
    required this.ikon,
    required this.warna,
    required this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(ikon, size: 14, color: warnaIkon),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isi,
                  style: const TextStyle(
                    fontSize: 8.5,
                    height: 1.35,
                    color: GayaAdmin.teksAbu,
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
