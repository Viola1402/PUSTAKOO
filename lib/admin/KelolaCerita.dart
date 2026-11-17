import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelolaCeritaPage extends StatefulWidget {
  const KelolaCeritaPage({super.key});

  @override
  State<KelolaCeritaPage> createState() => _KelolaCeritaPageState();
}

class _KelolaCeritaPageState extends State<KelolaCeritaPage> {
  final Color biru = const Color(0xFF006699);
  final Color krem = const Color(0xFFFFF5E5);
  final Color kuning = const Color(0xFFFFE65C);

  String kategoriAktif = 'Semua';
  String pencarian = '';

  final TextEditingController searchController = TextEditingController();

  final List<String> kategori = [
    'Semua',
    'Dongeng',
    'Petualangan',
    'Hewan',
    'Sains',
    'Cerita Rakyat',
  ];

  int menuAktif = 1;

  final List<Map<String, dynamic>> daftarCerita = [
    {
      'judul': 'Kancil dan Buaya',
      'kategori': 'Cerita Rakyat',
      'tingkat': 'Pemula',
      'halaman': 4,
      'status': 'Terbit',
      'warna': const Color(0xFFBCE6CA),
      'huruf': 'K',
    },
    {
      'judul': 'Hutan Pelangi',
      'kategori': 'Petualangan',
      'tingkat': 'Menengah',
      'halaman': 4,
      'status': 'Terbit',
      'warna': const Color(0xFFF7D4E4),
      'huruf': 'H',
    },
    {
      'judul': 'Si Kucing Pemalu',
      'kategori': 'Hewan',
      'tingkat': 'Pemula',
      'halaman': 4,
      'status': 'Terbit',
      'warna': const Color(0xFFFFDDAA),
      'huruf': 'S',
    },
    {
      'judul': 'Mengapa Langit Biru?',
      'kategori': 'Sains',
      'tingkat': 'Mahir',
      'halaman': 4,
      'status': 'Terbit',
      'warna': const Color(0xFFD4DFFF),
      'huruf': 'M',
    },
    {
      'judul': 'Putri dan Naga Kecil',
      'kategori': 'Dongeng',
      'tingkat': 'Menengah',
      'halaman': 4,
      'status': 'Draf',
      'warna': const Color(0xFFFFE3B8),
      'huruf': 'P',
    },
    {
      'judul': 'Malin Kundang',
      'kategori': 'Cerita Rakyat',
      'tingkat': 'Menengah',
      'halaman': 4,
      'status': 'Terbit',
      'warna': const Color(0xFFC9EDF0),
      'huruf': 'M',
    },
  ];

  List<Map<String, dynamic>> get ceritaTerfilter {
    return daftarCerita.where((cerita) {
      final cocokKategori =
          kategoriAktif == 'Semua' || cerita['kategori'] == kategoriAktif;

      final cocokPencarian = cerita['judul']
          .toString()
          .toLowerCase()
          .contains(pencarian.toLowerCase());

      return cocokKategori && cocokPencarian;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      body: Row(
        children: [
          // SIDEBAR
          sidebar(),

          // KONTEN UTAMA
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 25,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PENCARIAN
                      pencarianWidget(),

                      const SizedBox(height: 16),

                      // JUDUL
                      const Text(
                        'Kelola Cerita',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006699),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // KATEGORI
                      kategoriWidget(),

                      const SizedBox(height: 20),

                      // TAMBAH CERITA
                      tambahCeritaButton(),

                      const SizedBox(height: 14),

                      // DAFTAR CERITA
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ceritaTerfilter.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth < 650 ? 1 : 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 94,
                        ),
                        itemBuilder: (context, index) {
                          return kartuCerita(
                            ceritaTerfilter[index],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // SIDEBAR
  Widget sidebar() {
    final List<Map<String, dynamic>> menu = [
      {'nama': 'Dashboard', 'icon': Icons.dashboard_outlined},
      {'nama': 'Cerita', 'icon': Icons.menu_book_outlined},
      {'nama': 'Kategori', 'icon': Icons.category_outlined},
      {'nama': 'Kuis', 'icon': Icons.quiz_outlined},
      {'nama': 'Misi & Poin', 'icon': Icons.stars_outlined},
      {'nama': 'Pengguna', 'icon': Icons.people_outline},
      {'nama': 'Laporan', 'icon': Icons.insert_chart_outlined},
    ];

    return Container(
      width: 76,
      color: const Color(0xFFF2E7D0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // LOGO
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kuning,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF006699),
                fontSize: 17,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // MENU NAVIGASI
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final aktif = menuAktif == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      menuAktif = index;
                    });

                    if (index != 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Menu ${menu[index]['nama']} dipilih',
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: aktif ? biru : Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          menu[index]['icon'],
                          color: aktif ? Colors.white : biru,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menu[index]['nama'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: aktif ? Colors.white : biru,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // KELUAR
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text(
                    'Apakah kamu yakin ingin keluar?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Silakan hubungkan fitur logout.'),
                          ),
                        );
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.logout,
                    color: Color(0xFF006699),
                    size: 21,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      color: Color(0xFF006699),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // KOLOM PENCARIAN
  Widget pencarianWidget() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: biru,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        pencarian = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari cerita, pengguna, kuis...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          width: 95,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8EDCE0),
                Color(0xFFFFD43B),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextButton(
            onPressed: () {
              setState(() {
                pencarian = searchController.text;
              });
            },
            child: const Text(
              'Cari',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // KATEGORI CERITA
  Widget kategoriWidget() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kategori.map((item) {
          final aktif = kategoriAktif == item;

          return GestureDetector(
            onTap: () {
              setState(() {
                kategoriAktif = item;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 5),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: aktif ? kuning : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item == 'Semua' ? 'S' : item[0],
                      style: TextStyle(
                        color: biru,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: aktif ? FontWeight.bold : FontWeight.w500,
                      color: biru,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // TOMBOL TAMBAH CERITA
  Widget tambahCeritaButton() {
    return ElevatedButton.icon(
      onPressed: () {
        tampilkanFormCerita();
      },
      icon: const Icon(Icons.add, size: 17),
      label: const Text('Tambah Cerita'),
      style: ElevatedButton.styleFrom(
        backgroundColor: biru,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  // KARTU CERITA
  Widget kartuCerita(Map<String, dynamic> cerita) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // COVER CERITA
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 62,
                decoration: BoxDecoration(
                  color: cerita['warna'],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                  border: Border(
                    left: BorderSide(
                      color: biru,
                      width: 5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  cerita['huruf'],
                  style: TextStyle(
                    color: biru,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: -5,
                right: 5,
                child: Container(
                  width: 9,
                  height: 13,
                  decoration: BoxDecoration(
                    color: kuning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // INFORMASI CERITA
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cerita['judul'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: biru,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${cerita['kategori']} · ${cerita['tingkat']} · '
                  '${cerita['status']} · ${cerita['halaman']} halaman',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: biru,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                // TOMBOL AKSI
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    tombolAksi(
                      'Ubah',
                      const Color(0xFF006699),
                      () => tampilkanFormCerita(cerita: cerita),
                    ),
                    tombolAksi(
                      cerita['status'] == 'Terbit' ? 'Tarik' : 'Terbit',
                      const Color(0xFF2FA66A),
                      () {
                        setState(() {
                          cerita['status'] =
                              cerita['status'] == 'Terbit' ? 'Draf' : 'Terbit';
                        });
                      },
                    ),
                    tombolAksi(
                      'Hapus',
                      const Color(0xFFE34545),
                      () => hapusCerita(cerita),
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

  // TOMBOL AKSI
  Widget tombolAksi(
    String teks,
    Color warna,
    VoidCallback aksi,
  ) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: aksi,
        style: ElevatedButton.styleFrom(
          backgroundColor: warna,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          teks,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // FORM TAMBAH DAN UBAH CERITA
  void tampilkanFormCerita({
    Map<String, dynamic>? cerita,
  }) {
    final bool edit = cerita != null;

    final judulController = TextEditingController(
      text: cerita?['judul'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        String kategoriForm = cerita?['kategori'] ?? 'Dongeng';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(edit ? 'Ubah Cerita' : 'Tambah Cerita'),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Cerita',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: kategoriForm,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: kategori
                          .where((e) => e != 'Semua')
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          kategoriForm = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (judulController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      if (edit) {
                        cerita['judul'] = judulController.text;
                        cerita['kategori'] = kategoriForm;
                      } else {
                        daftarCerita.add({
                          'judul': judulController.text,
                          'kategori': kategoriForm,
                          'tingkat': 'Pemula',
                          'halaman': 4,
                          'status': 'Draf',
                          'warna': const Color(0xFFD4DFFF),
                          'huruf': judulController.text[0].toUpperCase(),
                        });
                      }
                    });

                    Navigator.pop(context);
                    judulController.dispose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: biru,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      judulController.dispose();
    });
  }

  // HAPUS CERITA
  void hapusCerita(Map<String, dynamic> cerita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cerita'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${cerita['judul']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                daftarCerita.remove(cerita);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
