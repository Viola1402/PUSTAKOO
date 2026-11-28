import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

// ==========================================================
// MODEL DATA
// ==========================================================

class ProfilAnak {
  final String nama;
  final int usia;
  final int poin;

  const ProfilAnak({
    required this.nama,
    required this.usia,
    required this.poin,
  });
}

class BarisPengguna {
  final String id;
  final String nama;
  final String email;
  final String bergabung;
  final DateTime? tanggal;
  final List<ProfilAnak> anak;

  const BarisPengguna({
    required this.id,
    required this.nama,
    required this.email,
    required this.bergabung,
    required this.tanggal,
    required this.anak,
  });

  int get koin => anak.fold(0, (total, item) => total + item.poin);

  int get jumlahAnak => anak.length;

  String get inisial {
    final bagian = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase());

    return bagian.isEmpty ? '?' : bagian.join();
  }
}

// ==========================================================
// FORMAT DATA
// ==========================================================

abstract final class FormatPengguna {
  static String angka(int nilai) {
    final teks = nilai.toString();
    final hasil = StringBuffer();

    for (var i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(teks[i]);
    }

    return hasil.toString();
  }

  static String tanggal(dynamic nilai) {
    if (nilai == null) return '-';

    try {
      final date = DateTime.parse(nilai.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')} '
          '${bulan(date.month)} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  static String bulan(int bulan) {
    const namaBulan = [
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

    return namaBulan[bulan - 1];
  }
}

// ==========================================================
// FILTER
// ==========================================================

enum RentangUsia {
  semua('Semua Usia'),
  praSekolah('3 - 5 Tahun'),
  anak('6 - 10 Tahun'),
  besar('11 - 12 Tahun');

  final String label;
  const RentangUsia(this.label);

  bool cocok(int usia) {
    switch (this) {
      case RentangUsia.semua:
        return true;
      case RentangUsia.praSekolah:
        return usia >= 3 && usia <= 5;
      case RentangUsia.anak:
        return usia >= 6 && usia <= 10;
      case RentangUsia.besar:
        return usia >= 11 && usia <= 12;
    }
  }
}

enum UrutanPengguna {
  tanggalTerbaru('Terbaru'),
  namaAZ('Nama A-Z'),
  namaZA('Nama Z-A'),
  koinTerbanyak('Koin Terbanyak');

  final String label;
  const UrutanPengguna(this.label);
}

// ==========================================================
// HALAMAN KELOLA PENGGUNA
// ==========================================================

class KelolaPenggunaPage extends StatefulWidget {
  const KelolaPenggunaPage({super.key});

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController pencarianController = TextEditingController();

  List<BarisPengguna> daftarPengguna = [];

  bool sedangMemuat = true;
  String kataKunci = '';

  RentangUsia filterUsia = RentangUsia.semua;
  UrutanPengguna urutan = UrutanPengguna.tanggalTerbaru;

  @override
  void initState() {
    super.initState();
    ambilData();
  }

  @override
  void dispose() {
    pencarianController.dispose();
    super.dispose();
  }

  // ========================================================
  // AMBIL DATA SUPABASE
  // ========================================================

  Future<void> ambilData() async {
    if (mounted) {
      setState(() => sedangMemuat = true);
    }

    try {
      final hasilPengguna =
          await supabase.from('pengguna').select().eq('peran', 'orang_tua');

      final hasilAnak = await supabase.from('anak').select();

      final dataOrangTua = List<Map<String, dynamic>>.from(hasilPengguna);

      final dataAnak = List<Map<String, dynamic>>.from(hasilAnak);

      final hasil = dataOrangTua.map((pengguna) {
        final anakMilik = dataAnak.where((anak) {
          return anak['pengguna_id']?.toString() == pengguna['id']?.toString();
        }).map((anak) {
          return ProfilAnak(
            nama: anak['nama_panggilan']?.toString() ?? '-',
            usia: (anak['usia'] as num?)?.toInt() ?? 0,
            poin: (anak['poin'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        final tanggal = pengguna['tanggal_dibuat'];

        DateTime? tanggalDate;

        if (tanggal != null) {
          try {
            tanggalDate = DateTime.parse(tanggal.toString());
          } catch (_) {}
        }

        return BarisPengguna(
          id: pengguna['id']?.toString() ?? '',
          nama: pengguna['nama']?.toString() ?? '-',
          email: pengguna['email']?.toString() ?? '-',
          bergabung: FormatPengguna.tanggal(tanggal),
          tanggal: tanggalDate,
          anak: anakMilik,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        daftarPengguna = hasil;
        sedangMemuat = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => sedangMemuat = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data: $e'),
          backgroundColor: GayaAdmin.merah,
        ),
      );
    }
  }

  // ========================================================
  // STATISTIK
  // ========================================================

  int get totalAnak {
    return daftarPengguna.fold(
      0,
      (total, pengguna) => total + pengguna.jumlahAnak,
    );
  }

  int get totalKoin {
    return daftarPengguna.fold(
      0,
      (total, pengguna) => total + pengguna.koin,
    );
  }

  double get rataAnak {
    if (daftarPengguna.isEmpty) return 0;
    return totalAnak / daftarPengguna.length;
  }

  // ========================================================
  // PENCARIAN DAN PENGURUTAN
  // ========================================================

  List<BarisPengguna> get penggunaTampil {
    final hasil = daftarPengguna.where((pengguna) {
      final kunci = kataKunci.toLowerCase().trim();

      final cocokPencarian = pengguna.nama.toLowerCase().contains(kunci) ||
          pengguna.email.toLowerCase().contains(kunci) ||
          pengguna.anak.any(
            (anak) => anak.nama.toLowerCase().contains(kunci),
          );

      final cocokUsia = filterUsia == RentangUsia.semua ||
          pengguna.anak.any(
            (anak) => filterUsia.cocok(anak.usia),
          );

      return cocokPencarian && cocokUsia;
    }).toList();

    switch (urutan) {
      case UrutanPengguna.namaAZ:
        hasil.sort((a, b) => a.nama.compareTo(b.nama));
        break;

      case UrutanPengguna.namaZA:
        hasil.sort((a, b) => b.nama.compareTo(a.nama));
        break;

      case UrutanPengguna.koinTerbanyak:
        hasil.sort((a, b) => b.koin.compareTo(a.koin));
        break;

      case UrutanPengguna.tanggalTerbaru:
        hasil.sort((a, b) {
          return (b.tanggal ?? DateTime(2000))
              .compareTo(a.tanggal ?? DateTime(2000));
        });
        break;
    }

    return hasil;
  }

  // ========================================================
  // DETAIL PENGGUNA
  // ========================================================

  void tampilkanDetail(BarisPengguna pengguna) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: GayaAdmin.biruMuda,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 25,
                            color: GayaAdmin.biru,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Text(
                            'Detail Pengguna',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: GayaAdmin.biruTua,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    detailItem('Nama Orang Tua', pengguna.nama),
                    detailItem('Email', pengguna.email),
                    detailItem(
                      'Tanggal Bergabung',
                      pengguna.bergabung,
                    ),
                    detailItem(
                      'Jumlah Profil Anak',
                      '${pengguna.jumlahAnak}',
                    ),
                    detailItem(
                      'Total Tabungan Koin',
                      '${FormatPengguna.angka(pengguna.koin)} Koin',
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil Anak',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: GayaAdmin.biruTua,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (pengguna.anak.isEmpty)
                      const Text(
                        'Belum memiliki profil anak.',
                        style: TextStyle(
                          fontSize: 14,
                          color: GayaAdmin.teksAbu,
                        ),
                      )
                    else
                      ...pengguna.anak.map((anak) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: GayaAdmin.latar,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: GayaAdmin.garis,
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: GayaAdmin.biruMuda,
                                child: Icon(
                                  Icons.child_care,
                                  size: 24,
                                  color: GayaAdmin.biruTua,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      anak.nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: GayaAdmin.biruTua,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Usia: ${anak.usia} tahun',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: GayaAdmin.teksAbu,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${FormatPengguna.angka(anak.poin)} Koin',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF8A5A13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget detailItem(String judul, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              judul,
              style: const TextStyle(
                fontSize: 13,
                color: GayaAdmin.teksAbu,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: GayaAdmin.teks,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAMPILAN UTAMA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Pengguna',
      child: RefreshIndicator(
        onRefresh: ambilData,
        color: GayaAdmin.biru,
        child: ListView(
          padding: const EdgeInsets.all(26),
          children: [
            const RemahAdmin([
              'Dashboard',
              'Kelola Pengguna',
            ]),

            const JudulBagian(
              ikon: Icons.people_outline,
              judul: 'Kelola Pengguna',
              subjudul: 'Kelola data orang tua dan profil anak Pustakoo.',
            ),

            const SizedBox(height: 28),

            // KARTU STATISTIK
            LayoutBuilder(
              builder: (context, constraints) {
                final lebar = constraints.maxWidth;

                final jumlahKolom = lebar >= 1000 ? 4 : 2;

                final jarak = 16.0;
                final lebarKartu =
                    (lebar - (jarak * (jumlahKolom - 1))) / jumlahKolom;

                return Wrap(
                  spacing: jarak,
                  runSpacing: jarak,
                  children: [
                    SizedBox(
                      width: lebarKartu,
                      child: KartuStatistikPengguna(
                        judul: 'Total Akun Orang Tua',
                        nilai: daftarPengguna.length,
                        satuan: 'Akun',
                        catatan: 'Orang tua terdaftar',
                        jenis: 0,
                      ),
                    ),
                    SizedBox(
                      width: lebarKartu,
                      child: KartuStatistikPengguna(
                        judul: 'Total Profil Anak',
                        nilai: totalAnak,
                        satuan: 'Anak',
                        catatan: 'Profil anak terdaftar',
                        jenis: 1,
                      ),
                    ),
                    SizedBox(
                      width: lebarKartu,
                      child: KartuStatistikPengguna(
                        judul: 'Rata-rata Anak',
                        nilai: rataAnak,
                        satuan: 'Anak / akun',
                        catatan: 'Rata-rata per orang tua',
                        jenis: 2,
                      ),
                    ),
                    SizedBox(
                      width: lebarKartu,
                      child: KartuStatistikPengguna(
                        judul: 'Total Koin Anak',
                        nilai: totalKoin,
                        satuan: 'Koin',
                        catatan: 'Akumulasi seluruh anak',
                        jenis: 3,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // PANEL DAFTAR PENGGUNA
            KartuAdmin(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const JudulBagian(
                    ikon: Icons.manage_accounts_outlined,
                    judul: 'Daftar Pengguna',
                    subjudul:
                        'Informasi orang tua dan profil anak yang terdaftar.',
                  ),

                  const SizedBox(height: 22),

                  // PENCARIAN
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: GayaAdmin.latar,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: GayaAdmin.garis),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          size: 23,
                          color: GayaAdmin.teksAbu,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pencarianController,
                            onChanged: (nilai) {
                              setState(() => kataKunci = nilai);
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText:
                                  'Cari nama orang tua, email, atau nama anak...',
                              hintStyle: TextStyle(fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TAB PENGGUNA
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: GayaAdmin.biruTua,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'Semua Orang Tua (${daftarPengguna.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: GayaAdmin.garis),
                  const SizedBox(height: 16),

                  // FILTER
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 19,
                            color: GayaAdmin.teksAbu,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'FILTER:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GayaAdmin.teksAbu,
                            ),
                          ),
                        ],
                      ),
                      _DropdownPengguna<RentangUsia>(
                        nilai: filterUsia,
                        opsi: RentangUsia.values,
                        label: (item) => item.label,
                        awalan: 'Usia Anak',
                        onPilih: (item) {
                          setState(() => filterUsia = item);
                        },
                      ),
                      _DropdownPengguna<UrutanPengguna>(
                        nilai: urutan,
                        opsi: UrutanPengguna.values,
                        label: (item) => item.label,
                        awalan: 'Urutkan',
                        onPilih: (item) {
                          setState(() => urutan = item);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  const Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 16,
                        color: GayaAdmin.hijau,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Menampilkan data dari database Pustakoo',
                        style: TextStyle(
                          fontSize: 12,
                          color: GayaAdmin.teksAbu,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // MEMUAT
                  if (sedangMemuat)
                    const Padding(
                      padding: EdgeInsets.all(45),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )

                  // DATA KOSONG
                  else if (penggunaTampil.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(35),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 55,
                              color: GayaAdmin.teksAbu,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Tidak ada pengguna yang cocok.',
                              style: TextStyle(
                                fontSize: 14,
                                color: GayaAdmin.teksAbu,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )

                  // TABEL / KARTU
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 750) {
                          return Column(
                            children: [
                              for (final pengguna in penggunaTampil)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 14,
                                  ),
                                  child: KartuPenggunaRingkas(
                                    pengguna: pengguna,
                                    onDetail: tampilkanDetail,
                                  ),
                                ),
                            ],
                          );
                        }

                        return TabelPengguna(
                          daftar: penggunaTampil,
                          onDetail: tampilkanDetail,
                        );
                      },
                    ),

                  const SizedBox(height: 18),

                  FooterPengguna(
                    ditampilkan: penggunaTampil.length,
                    total: daftarPengguna.length,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// KARTU STATISTIK
// ==========================================================

class KartuStatistikPengguna extends StatelessWidget {
  final String judul;
  final num nilai;
  final String satuan;
  final String catatan;
  final int jenis;

  const KartuStatistikPengguna({
    super.key,
    required this.judul,
    required this.nilai,
    required this.satuan,
    required this.catatan,
    required this.jenis,
  });

  @override
  Widget build(BuildContext context) {
    final warnaLatar = [
      const Color(0xFFF4FAFF),
      Colors.white,
      Colors.white,
      const Color(0xFFFAF2E2),
    ][jenis];

    final warnaIkon = [
      GayaAdmin.biruTua,
      const Color(0xFFC0781A),
      GayaAdmin.biru,
      const Color(0xFF8A5A13),
    ][jenis];

    final ikon = [
      Icons.groups_2_outlined,
      Icons.child_care_outlined,
      Icons.family_restroom_outlined,
      Icons.savings_outlined,
    ][jenis];

    final nilaiTampil = nilai is double
        ? nilai.toStringAsFixed(1).replaceAll('.', ',')
        : FormatPengguna.angka(nilai.toInt());

    return Container(
      constraints: const BoxConstraints(minHeight: 155),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  judul.toUpperCase(),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: warnaIkon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  ikon,
                  size: 23,
                  color: warnaIkon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  nilaiTampil,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  satuan,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            catatan,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: GayaAdmin.teksAbu,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// DROPDOWN FILTER
// ==========================================================

class _DropdownPengguna<T> extends StatelessWidget {
  final T nilai;
  final List<T> opsi;
  final String Function(T) label;
  final String awalan;
  final ValueChanged<T> onPilih;

  const _DropdownPengguna({
    required this.nilai,
    required this.opsi,
    required this.label,
    required this.awalan,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: nilai,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(
            Icons.expand_more,
            size: 20,
            color: GayaAdmin.teksAbu,
          ),
          hint: Text(
            awalan,
            style: const TextStyle(fontSize: 12),
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GayaAdmin.teks,
          ),
          items: [
            for (final item in opsi)
              DropdownMenuItem<T>(
                value: item,
                child: Text(label(item)),
              ),
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
// TABEL PENGGUNA DESKTOP
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
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 17,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _KepalaTabel('ORANG TUA / WALI'),
                ),
                Expanded(
                  flex: 3,
                  child: _KepalaTabel('PROFIL ANAK'),
                ),
                Expanded(
                  flex: 2,
                  child: _KepalaTabel('TABUNGAN KOIN'),
                ),
                Expanded(
                  flex: 2,
                  child: _KepalaTabel('TANGGAL BERGABUNG'),
                ),
                SizedBox(
                  width: 70,
                  child: _KepalaTabel('AKSI'),
                ),
              ],
            ),
          ),
          for (var i = 0; i < daftar.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: GayaAdmin.garis,
              ),
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

class _KepalaTabel extends StatelessWidget {
  final String teks;

  const _KepalaTabel(this.teks);

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: GayaAdmin.teksAbu,
        letterSpacing: 0.5,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 18,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SelOrangTua(pengguna),
          ),
          Expanded(
            flex: 3,
            child: _SelAnak(pengguna),
          ),
          Expanded(
            flex: 2,
            child: _SelKoin(pengguna),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pengguna.bergabung,
              style: const TextStyle(
                fontSize: 12,
                color: GayaAdmin.teks,
              ),
            ),
          ),
          SizedBox(
            width: 70,
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

// ==========================================================
// KARTU PENGGUNA MOBILE
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelOrangTua(pengguna),
          const SizedBox(height: 15),
          _SelAnak(pengguna),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SelKoin(pengguna)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pengguna.bergabung,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
              _TombolDetail(
                onPressed: () => onDetail(pengguna),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// SEL ORANG TUA
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
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GayaAdmin.biruMuda,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCFE3F3),
            ),
          ),
          child: Text(
            pengguna.inisial,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pengguna.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pengguna.email,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gabung ${pengguna.bergabung}',
                style: const TextStyle(
                  fontSize: 10,
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

// ==========================================================
// SEL PROFIL ANAK
// ==========================================================

class _SelAnak extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelAnak(this.pengguna);

  @override
  Widget build(BuildContext context) {
    if (pengguna.anak.isEmpty) {
      return const Text(
        'Belum ada profil anak',
        style: TextStyle(
          fontSize: 12,
          color: GayaAdmin.teksAbu,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final anak in pengguna.anak)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.child_care,
                  size: 17,
                  color: GayaAdmin.biru,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        anak.nama,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: GayaAdmin.teks,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${anak.usia} Thn',
                          style: const TextStyle(
                            fontSize: 10,
                            color: GayaAdmin.teksAbu,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==========================================================
// SEL KOIN
// ==========================================================

class _SelKoin extends StatelessWidget {
  final BarisPengguna pengguna;

  const _SelKoin(this.pengguna);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: GayaAdmin.kremMuda,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFF0E3C6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            size: 17,
            color: Color(0xFFC0781A),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              FormatPengguna.angka(pengguna.koin),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A5A13),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Koin',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF8A5A13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// TOMBOL DETAIL
// ==========================================================

class _TombolDetail extends StatelessWidget {
  final VoidCallback onPressed;

  const _TombolDetail({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: GayaAdmin.biru,
        minimumSize: const Size(65, 38),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: const Text('Detail'),
    );
  }
}

// ==========================================================
// FOOTER
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        ditampilkan == 0
            ? 'Tidak ada pengguna untuk ditampilkan'
            : 'Menampilkan $ditampilkan dari $total pengguna terdaftar',
        style: const TextStyle(
          fontSize: 12,
          color: GayaAdmin.teksAbu,
        ),
      ),
    );
  }
}
