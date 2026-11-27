import 'package:flutter/material.dart';

import 'admin_shell.dart';

// ==========================================================
// HALAMAN KELOLA PENGGUNA & ANAK
// ==========================================================

class KelolaPenggunaPage extends StatefulWidget {
  const KelolaPenggunaPage({super.key});

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  static const List<Map<String, dynamic>> _contohPengguna = [
    {
      'nama': 'Bunda Sari Pertiwi',
      'email': 'sari.pertiwi@gmail.com',
      'bergabung': '12 Jan 2024',
      'anak': [
        {
          'nama': 'Rayyan',
          'tahun': 5,
          'usia': '5 Thn',
          'level': 'Level 1 - Pra-Membaca',
        },
      ],
      'koin': 1450,
      'aktivitas': 'Membaca "Kancil dan Buaya"',
      'waktu': '10 menit lalu',
      'status': 'Aktif',
      'paket': 'Premium Family',
      'baru': false,
    },
    {
      'nama': 'Ayah Budi Pratama',
      'email': 'budi.pratama@office.id',
      'bergabung': '04 Feb 2024',
      'anak': [
        {
          'nama': 'Kiki',
          'tahun': 7,
          'usia': '7 Thn',
          'level': 'Level 2 - Pemula Lancar',
        },
      ],
      'koin': 890,
      'aktivitas': 'Selesai Kuis "Hutan Pelangi"',
      'waktu': '1 jam lalu',
      'status': 'Aktif',
      'paket': 'Gratis (Premium)',
      'baru': false,
    },
    {
      'nama': 'Bunda Hana Lestari',
      'email': 'hana.lestari@yahoo.com',
      'bergabung': '18 Nov 2023',
      'anak': [
        {
          'nama': 'Aifi',
          'tahun': 4,
          'usia': '4 Thn',
          'level': 'Level 1 - Pra-Membaca',
        },
        {
          'nama': 'Nia',
          'tahun': 9,
          'usia': '9 Thn',
          'level': 'Level 2 - Lancar Membaca',
        },
      ],
      'koin': 2340,
      'aktivitas': 'Klaim Misi Mingguan',
      'waktu': '3 jam lalu',
      'status': 'Aktif',
      'paket': 'Premium Family',
      'baru': false,
    },
    {
      'nama': 'Bunda Rina Melati',
      'email': 'rina.melati@gmail.com',
      'bergabung': 'Hari ini',
      'anak': [
        {
          'nama': 'Dimas',
          'tahun': 6,
          'usia': '6 Thn',
          'level': 'Level 2 - Transisi Membaca',
        },
      ],
      'koin': 320,
      'aktivitas': 'Registrasi & Verifikasi Akun',
      'waktu': 'Hari ini, 08:00',
      'status': 'Aktif',
      'paket': 'Akun Baru (Premium Akses)',
      'baru': true,
    },
    {
      'nama': 'Ayah Hendra Wijaya',
      'email': 'hendra.wijaya@outlook.com',
      'bergabung': '09 Mar 2023',
      'anak': [
        {
          'nama': 'Sabahila',
          'tahun': 10,
          'usia': '10 Thn',
          'level': 'Level 3 - Pembaca Mandiri',
        },
      ],
      'koin': 1850,
      'aktivitas': 'Membaca "Mulan Kandung"',
      'waktu': 'Kemarin, 19:40',
      'status': 'Aktif',
      'paket': 'Premium Family',
      'baru': false,
    },
    {
      'nama': 'Ibu Citra Dewi',
      'email': 'citra.dewi@gmail.com',
      'bergabung': '15 Jan 2024',
      'anak': [
        {
          'nama': 'Kenzo',
          'tahun': 5,
          'usia': '5 Thn',
          'level': 'Level 1 - Belajar Lancar',
        },
      ],
      'koin': 770,
      'aktivitas': 'Membaca "Putri & Naga Kecil"',
      'waktu': '2 hari lalu',
      'status': 'Aktif',
      'paket': 'Gratis (Premium)',
      'baru': false,
    },
  ];

  late List<Map<String, dynamic>> pengguna =
      List<Map<String, dynamic>>.from(
    _contohPengguna.map((item) => Map<String, dynamic>.from(item)),
  );

  String pencarian = '';
  String tabTerpilih = 'Semua Pengguna';
  String usiaTerpilih = 'Semua Usia';
  String statusTerpilih = 'Semua Status';
  String urutanTerpilih = 'Aktivitas Terbaru';

  static const List<Map<String, String>> _tab = [
    {'judul': 'Semua Pengguna', 'jumlah': '123'},
    {'judul': 'Orang Tua Aktif', 'jumlah': '108'},
    {'judul': 'Akun Baru Pekan Ini', 'jumlah': '15'},
    {'judul': 'Akun Nonaktif', 'jumlah': '0'},
  ];

  // --------------------------------------------------------
  // DATA TAMPIL
  // --------------------------------------------------------

  List<Map<String, dynamic>> get penggunaTampil {
    final hasil = pengguna.where((item) {
      final kunci = pencarian.toLowerCase().trim();

      final namaAnak = (item['anak'] as List)
          .map((anak) => anak['nama'].toString().toLowerCase())
          .join(' ');

      final cocokCari = kunci.isEmpty ||
          item['nama'].toString().toLowerCase().contains(kunci) ||
          item['email'].toString().toLowerCase().contains(kunci) ||
          namaAnak.contains(kunci);

      final cocokTab = switch (tabTerpilih) {
        'Orang Tua Aktif' => item['status'] == 'Aktif',
        'Akun Baru Pekan Ini' => item['baru'] == true,
        'Akun Nonaktif' => item['status'] == 'Nonaktif',
        _ => true,
      };

      final daftarAnak = item['anak'] as List;
      final cocokUsia = switch (usiaTerpilih) {
        '3 - 5 Tahun' =>
          daftarAnak.any((anak) => (anak['tahun'] as int) <= 5),
        '6 - 10 Tahun' => daftarAnak.any(
            (anak) =>
                (anak['tahun'] as int) >= 6 && (anak['tahun'] as int) <= 10,
          ),
        '11 - 12 Tahun' =>
          daftarAnak.any((anak) => (anak['tahun'] as int) >= 11),
        _ => true,
      };

      final paket = item['paket'].toString().toLowerCase();
      final cocokStatus = switch (statusTerpilih) {
        'Premium' => paket.contains('premium'),
        'Gratis' => paket.contains('gratis'),
        _ => true,
      };

      return cocokCari && cocokTab && cocokUsia && cocokStatus;
    }).toList();

    if (urutanTerpilih == 'Nama A-Z') {
      hasil.sort((a, b) => a['nama'].toString().compareTo(
            b['nama'].toString(),
          ));
    } else if (urutanTerpilih == 'Koin Terbanyak') {
      hasil.sort((a, b) => (b['koin'] as int).compareTo(a['koin'] as int));
    }

    return hasil;
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Pengguna',
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RemahAdmin(['Dashboard', 'Kelola Pengguna']),
                _judulHalaman(),
                const SizedBox(height: 14),
                _keteranganContoh(),
                _barisStatistik(lebar),
                const SizedBox(height: 14),
                _filterBar(),
                const SizedBox(height: 14),
                if (lebar > 1000)
                  _tabelPengguna()
                else
                  Column(
                    children: [
                      for (final item in penggunaTampil)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _kartuPengguna(item),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                _footerTabel(),
                const SizedBox(height: 18),
                _barisInformasi(lebar),
              ],
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------
  // JUDUL HALAMAN
  // --------------------------------------------------------

  Widget _judulHalaman() {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final tombol = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TombolAdmin(
              teks: 'Ekspor Data',
              ikon: Icons.file_download_outlined,
              utama: false,
              onPressed: () => _pesan('Ekspor data pengguna belum dihubungkan.'),
            ),
            TombolAdmin(
              teks: 'Tambah Pengguna Baru',
              ikon: Icons.person_add_alt_1,
              onPressed: _dialogPengguna,
            ),
          ],
        );

        final judul = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: GayaAdmin.biruMuda,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    size: 19,
                    color: GayaAdmin.biruTua,
                  ),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Kelola Pengguna & Anak',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: GayaAdmin.biruTua,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
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
              Expanded(child: judul),
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
              'Kolom koin, level anak, dan langganan belum tersedia di '
              'database. Data contoh ditampilkan agar tampilan tetap lengkap.',
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

  Widget _barisStatistik(double lebar) {
    final kolom = lebar > 1050
        ? 4
        : lebar > 560
            ? 2
            : 1;
    final celah = 12.0;
    final lebarKartu = (lebar - celah * (kolom - 1)) / kolom;

    final data = [
      {
        'judul': 'TOTAL AKUN ORANG TUA',
        'nilai': '123',
        'satuan': 'Akun',
        'catatan': '+12% dibandingkan bulan lalu',
        'ikon': Icons.groups_outlined,
        'warna': GayaAdmin.biruMuda,
        'naik': true,
      },
      {
        'judul': 'TOTAL PROFIL ANAK AKTIF',
        'nilai': '168',
        'satuan': 'Anak',
        'catatan': 'Rata-rata 1,3 anak per keluarga',
        'ikon': Icons.child_care_outlined,
        'warna': GayaAdmin.kremMuda,
        'naik': false,
      },
      {
        'judul': 'AKUN MEMBACA AKTIF',
        'nilai': '94',
        'satuan': 'Akun',
        'catatan': '76,4% pekan ini',
        'ikon': Icons.menu_book_outlined,
        'warna': Colors.white,
        'naik': false,
        'progres': 0.764,
      },
      {
        'judul': 'TOTAL KOIN BEREDAR',
        'nilai': '48.250',
        'satuan': 'Koin',
        'catatan': 'Tabungan hadiah anak, Misi & Kuis',
        'ikon': Icons.savings_outlined,
        'warna': GayaAdmin.krem,
        'naik': false,
      },
    ];

    return Wrap(
      spacing: celah,
      runSpacing: celah,
      children: [
        for (final item in data)
          SizedBox(
            width: lebarKartu,
            child: _kartuStatistik(item),
          ),
      ],
    );
  }

  Widget _kartuStatistik(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: item['warna'] as Color,
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
                  item['judul'] as String,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.teksAbu,
                    letterSpacing: 0.4,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                item['ikon'] as IconData,
                size: 17,
                color: GayaAdmin.biruTua,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['nilai'] as String,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  item['satuan'] as String,
                  style: const TextStyle(
                    fontSize: 9,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (item['progres'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item['progres'] as double,
                minHeight: 4,
                backgroundColor: GayaAdmin.garis,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  GayaAdmin.biru,
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item['naik'] == true) ...[
                const Icon(
                  Icons.trending_up,
                  size: 11,
                  color: GayaAdmin.hijau,
                ),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  item['catatan'] as String,
                  style: TextStyle(
                    fontSize: 8.5,
                    height: 1.3,
                    color: item['naik'] == true
                        ? GayaAdmin.hijau
                        : GayaAdmin.teksAbu,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // FILTER
  // --------------------------------------------------------

  Widget _filterBar() {
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
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 11),
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
                    onChanged: (nilai) {
                      setState(() {
                        pencarian = nilai;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 11,
                      color: GayaAdmin.teks,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Cari nama orang tua, email, atau nama anak...',
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
                for (final item in _tab)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          tabTerpilih = item['judul']!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: tabTerpilih == item['judul']
                              ? GayaAdmin.biruTua
                              : GayaAdmin.latar,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tabTerpilih == item['judul']
                                ? GayaAdmin.biruTua
                                : GayaAdmin.garis,
                          ),
                        ),
                        child: Text(
                          '${item['judul']} (${item['jumlah']})',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: tabTerpilih == item['judul']
                                ? Colors.white
                                : GayaAdmin.teksAbu,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
              _dropdown(
                usiaTerpilih,
                const [
                  'Semua Usia',
                  '3 - 5 Tahun',
                  '6 - 10 Tahun',
                  '11 - 12 Tahun',
                ],
                'Tingkat Usia Anak',
                (nilai) => setState(() => usiaTerpilih = nilai),
              ),
              _dropdown(
                statusTerpilih,
                const ['Semua Status', 'Premium', 'Gratis'],
                'Status Berlangganan',
                (nilai) => setState(() => statusTerpilih = nilai),
              ),
              _dropdown(
                urutanTerpilih,
                const [
                  'Aktivitas Terbaru',
                  'Nama A-Z',
                  'Koin Terbanyak',
                ],
                'Urutan',
                (nilai) => setState(() => urutanTerpilih = nilai),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.sync,
                size: 11,
                color: GayaAdmin.hijau,
              ),
              const SizedBox(width: 4),
              Text(
                'Menampilkan data terverifikasi Pustakoo Sync',
                style: TextStyle(
                  fontSize: 8.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String nilai,
    List<String> opsi,
    String label,
    ValueChanged<String> onPilih,
  ) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: GayaAdmin.garis),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: nilai,
          isDense: true,
          borderRadius: BorderRadius.circular(9),
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: GayaAdmin.teksAbu,
          ),
          hint: Text(
            label,
            style: const TextStyle(fontSize: 9.5),
          ),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: GayaAdmin.teks,
          ),
          items: [
            for (final item in opsi)
              DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
          ],
          onChanged: (baru) {
            if (baru != null) onPilih(baru);
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // TABEL PENGGUNA
  // --------------------------------------------------------

  Widget _tabelPengguna() {
    final daftar = penggunaTampil;

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                Expanded(flex: 3, child: _KepalaTabel('PROFIL ANAK TERDAFTAR')),
                Expanded(flex: 2, child: _KepalaTabel('TABUNGAN KOIN')),
                Expanded(flex: 2, child: _KepalaTabel('AKTIVITAS TERAKHIR')),
                Expanded(flex: 2, child: _KepalaTabel('STATUS AKUN')),
                SizedBox(width: 74, child: _KepalaTabel('AKSI')),
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
              _barisPengguna(daftar[i]),
            ],
        ],
      ),
    );
  }

  Widget _barisPengguna(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: _selOrangTua(item)),
          Expanded(flex: 3, child: _selAnak(item)),
          Expanded(flex: 2, child: _selKoin(item)),
          Expanded(flex: 2, child: _selAktivitas(item)),
          Expanded(flex: 2, child: _selStatus(item)),
          SizedBox(
            width: 74,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _detailPengguna(item),
                style: TextButton.styleFrom(
                  foregroundColor: GayaAdmin.biru,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Detail'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selOrangTua(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(item['nama'] as String),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['nama'] as String,
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
                item['email'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: GayaAdmin.teksAbu,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gabung ${item['bergabung']}',
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

  Widget _selAnak(Map<String, dynamic> item) {
    final daftarAnak = item['anak'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final anak in daftarAnak)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 8),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${anak['nama']} (${anak['usia']})',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: GayaAdmin.teks,
                            ),
                          ),
                          ChipAdmin(
                            anak['level'] as String,
                            kecil: true,
                            warna: const Color(0xFFF1F5F9),
                            teksWarna: GayaAdmin.teksAbu,
                          ),
                        ],
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

  Widget _selKoin(Map<String, dynamic> item) {
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
              '${item['koin']}',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8A5A13),
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              'Koin',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF8A5A13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selAktivitas(Map<String, dynamic> item) {
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
                child: Icon(
                  Icons.circle,
                  size: 5,
                  color: GayaAdmin.biru,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item['aktivitas'] as String,
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
            item['waktu'] as String,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selStatus(Map<String, dynamic> item) {
    final aktif = item['status'] == 'Aktif';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipAdmin(
          aktif ? 'Aktif' : 'Nonaktif',
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
              item['baru'] == true
                  ? Icons.workspace_premium_outlined
                  : Icons.verified_outlined,
              size: 10,
              color: GayaAdmin.teksAbu,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                item['paket'] as String,
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

  Widget _avatar(String nama) {
    final inisial = nama
        .replaceAll('Bunda ', '')
        .replaceAll('Ayah ', '')
        .replaceAll('Ibu ', '')
        .trim()
        .split(' ')
        .where((bagian) => bagian.isNotEmpty)
        .take(2)
        .map((bagian) => bagian[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: 15,
      backgroundColor: GayaAdmin.biruMuda,
      child: Text(
        inisial,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: GayaAdmin.biruTua,
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // KARTU PENGGUNA (LAYAR SEMPIT)
  // --------------------------------------------------------

  Widget _kartuPengguna(Map<String, dynamic> item) {
    return KartuAdmin(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _selOrangTua(item)),
              const SizedBox(width: 8),
              SizedBox(width: 74, child: _selStatus(item)),
            ],
          ),
          const SizedBox(height: 8),
          _selAnak(item),
          const SizedBox(height: 4),
          Row(
            children: [
              _selKoin(item),
              const SizedBox(width: 8),
              Expanded(child: _selAktivitas(item)),
              TextButton(
                onPressed: () => _detailPengguna(item),
                style: TextButton.styleFrom(
                  foregroundColor: GayaAdmin.biru,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // FOOTER TABEL
  // --------------------------------------------------------

  Widget _footerTabel() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Menampilkan 1 - ${penggunaTampil.length} dari '
            '123 pengguna terdaftar',
            style: const TextStyle(
              fontSize: 9,
              color: GayaAdmin.teksAbu,
            ),
          ),
        ),
        Wrap(
          spacing: 3,
          children: [
            for (var i = 1; i <= 3; i++)
              _tombolHalaman('$i', aktif: i == 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '...',
                style: TextStyle(fontSize: 9, color: GayaAdmin.teksAbu),
              ),
            ),
            _tombolHalaman('11'),
          ],
        ),
      ],
    );
  }

  Widget _tombolHalaman(String teks, {bool aktif = false}) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: aktif ? GayaAdmin.biruTua : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: aktif ? GayaAdmin.biruTua : GayaAdmin.garis,
        ),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: aktif ? Colors.white : GayaAdmin.teksAbu,
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // INFORMASI BAWAH
  // --------------------------------------------------------

  Widget _barisInformasi(double lebar) {
    final kolom = lebar > 900 ? 3 : 1;
    final celah = 10.0;
    final lebarKartu = (lebar - celah * (kolom - 1)) / kolom;

    final data = [
      {
        'judul': 'Pengumuman & Notifikasi Massal',
        'isi': 'Kirim pesan pengumuman buku atau tips membaca.',
        'ikon': Icons.campaign_outlined,
        'warna': GayaAdmin.biruMuda,
      },
      {
        'judul': 'Atur Bonus Koin Membaca',
        'isi': 'Kelola rate bonus koin untuk periode liburan.',
        'ikon': Icons.stars_outlined,
        'warna': GayaAdmin.krem,
      },
      {
        'judul': 'Keamanan & Hak Akses Ortu',
        'isi': 'PIN pengaman anak dan kontrol batasan durasi.',
        'ikon': Icons.shield_outlined,
        'warna': GayaAdmin.biruMuda,
      },
    ];

    return Wrap(
      spacing: celah,
      runSpacing: celah,
      children: [
        for (final item in data)
          SizedBox(
            width: lebarKartu,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: item['warna'] as Color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GayaAdmin.garis),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item['ikon'] as IconData,
                    size: 16,
                    color: GayaAdmin.biruTua,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['judul'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: GayaAdmin.biruTua,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['isi'] as String,
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

  Future<void> _dialogPengguna() async {
    final nama = TextEditingController();
    final email = TextEditingController();
    final namaAnak = TextEditingController();
    final usiaAnak = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Tambah Pengguna Baru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: GayaAdmin.biruTua,
            ),
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KotakIsian(
                    label: 'Nama Orang Tua / Wali',
                    hint: 'Contoh: Bunda Sari Pertiwi',
                    controller: nama,
                  ),
                  KotakIsian(
                    label: 'Email',
                    hint: 'nama@email.com',
                    controller: email,
                  ),
                  KotakIsian(
                    label: 'Nama Anak',
                    hint: 'Nama panggilan anak',
                    controller: namaAnak,
                  ),
                  KotakIsian(
                    label: 'Usia Anak',
                    hint: 'Contoh: 5',
                    keyboard: TextInputType.number,
                    controller: usiaAnak,
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
                final namaOrtu = nama.text.trim();
                final namaKecil = namaAnak.text.trim();
                final tahun = int.tryParse(usiaAnak.text.trim()) ?? 0;

                if (namaOrtu.isEmpty || namaKecil.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama orang tua dan nama anak wajib diisi.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  pengguna.insert(0, {
                    'nama': namaOrtu,
                    'email': email.text.trim().isEmpty
                        ? '-'
                        : email.text.trim(),
                    'bergabung': 'Hari ini',
                    'anak': [
                      {
                        'nama': namaKecil,
                        'tahun': tahun,
                        'usia': '$tahun Thn',
                        'level': 'Level 1 - Pra-Membaca',
                      },
                    ],
                    'koin': 0,
                    'aktivitas': 'Registrasi & Verifikasi Akun',
                    'waktu': 'Baru saja',
                    'status': 'Aktif',
                    'paket': 'Akun Baru (Premium Akses)',
                    'baru': true,
                  });
                });

                Navigator.pop(dialogContext);
                _pesan('Pengguna contoh ditambahkan ke daftar.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GayaAdmin.biruTua,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    nama.dispose();
    email.dispose();
    namaAnak.dispose();
    usiaAnak.dispose();
  }

  Future<void> _detailPengguna(Map<String, dynamic> item) async {
    final daftarAnak = item['anak'] as List;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            item['nama'] as String,
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
                    item['email'] as String,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                  const Divider(height: 18),
                  _barisDetail('Status akun', item['status'] as String),
                  _barisDetail('Langganan', item['paket'] as String),
                  _barisDetail('Tabungan koin', '${item['koin']} Koin'),
                  _barisDetail('Bergabung', item['bergabung'] as String),
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
                  for (final anak in daftarAnak)
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
                              '${anak['nama']} (${anak['usia']}) • '
                              '${anak['level']}',
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
                      'Aktivitas terakhir: ${item['aktivitas']} '
                      '(${item['waktu']})',
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

// ==========================================================
// KEPALA KOLOM TABEL
// ==========================================================

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
