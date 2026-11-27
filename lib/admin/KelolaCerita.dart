import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/sampul_cerita.dart';
import 'admin_shell.dart';

class KelolaCeritaPage extends StatefulWidget {
  const KelolaCeritaPage({super.key});

  @override
  State<KelolaCeritaPage> createState() => _KelolaCeritaPageState();
}

class _KelolaCeritaPageState extends State<KelolaCeritaPage> {
  final supabase = Supabase.instance.client;

  final Color biru = const Color(0xFF006B9F);
  final Color biruTua = const Color(0xFF073B70);
  final Color latar = const Color(0xFFF7F8FC);
  final Color garis = const Color(0xFFE1E8F2);

  List<Map<String, dynamic>> cerita = [];
  List<Map<String, dynamic>> kategori = [];

  bool sedangMemuat = true;
  String? pesanError;

  String pencarian = '';
  String kategoriTerpilih = 'Semua';
  String statusTerpilih = 'Semua Status';
  String urutanTerpilih = 'Terbaru';

  @override
  void initState() {
    super.initState();
    muatCerita();
  }

  Future<void> muatCerita() async {
    if (!mounted) return;

    setState(() {
      sedangMemuat = true;
      pesanError = null;
    });

    try {
      final hasilCerita =
          await supabase.from('buku').select('*').order('id', ascending: false);

      final hasilKategori =
          await supabase.from('kategori').select('id, nama').order('nama');

      if (!mounted) return;

      setState(() {
        cerita = List<Map<String, dynamic>>.from(hasilCerita);
        kategori = List<Map<String, dynamic>>.from(hasilKategori);
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

  String teks(dynamic nilai, [String defaultValue = '-']) {
    if (nilai == null || nilai.toString().trim().isEmpty) {
      return defaultValue;
    }

    return nilai.toString();
  }

  int angka(dynamic nilai) {
    if (nilai is num) return nilai.toInt();
    return int.tryParse(nilai?.toString() ?? '') ?? 0;
  }

  String namaKategori(dynamic kategoriId) {
    final hasil = kategori.where(
      (item) => item['id'].toString() == kategoriId.toString(),
    );

    if (hasil.isEmpty) return 'Tanpa Kategori';

    return teks(hasil.first['nama'], 'Tanpa Kategori');
  }

  String statusCerita(Map<String, dynamic> item) {
    final status = item['status']?.toString().toLowerCase();

    if (status == 'diterbitkan') return 'Diterbitkan';
    if (status == 'draf') return 'Draft';

    return 'Tidak diketahui';
  }

  List<Map<String, dynamic>> get ceritaTampil {
    final hasil = cerita.where((item) {
      final judul = teks(item['judul'], '').toLowerCase();
      final cocokPencarian = judul.contains(pencarian.toLowerCase());

      final cocokKategori = kategoriTerpilih == 'Semua' ||
          namaKategori(item['kategori_id']) == kategoriTerpilih;

      final status = statusCerita(item);
      final cocokStatus =
          statusTerpilih == 'Semua Status' || status == statusTerpilih;

      return cocokPencarian && cocokKategori && cocokStatus;
    }).toList();

    if (urutanTerpilih == 'Judul A-Z') {
      hasil.sort(
        (a, b) => teks(a['judul']).compareTo(teks(b['judul'])),
      );
    } else if (urutanTerpilih == 'Judul Z-A') {
      hasil.sort(
        (a, b) => teks(b['judul']).compareTo(teks(a['judul'])),
      );
    } else {
      hasil.sort(
        (a, b) => angka(b['id']).compareTo(angka(a['id'])),
      );
    }

    return hasil;
  }

  int jumlahKategori(String nama) {
    if (nama == 'Semua') return cerita.length;

    return cerita
        .where(
          (item) => namaKategori(item['kategori_id']) == nama,
        )
        .length;
  }

  void tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  Future<void> tambahCerita() async {
    await dialogCerita();
  }

  Future<void> editCerita(Map<String, dynamic> item) async {
    await dialogCerita(item: item);
  }

  Future<void> dialogCerita({
    Map<String, dynamic>? item,
  }) async {
    final isEdit = item != null;

    final judulController = TextEditingController(
      text: item?['judul']?.toString() ?? '',
    );

    final deskripsiController = TextEditingController(
      text: item?['deskripsi']?.toString() ?? '',
    );

    final gambarController = TextEditingController(
      text: item?['gambar_sampul']?.toString() ?? '',
    );

    final hargaController = TextEditingController(
      text: item?['harga_poin']?.toString() ?? '0',
    );

    int? kategoriId = item == null ? null : angka(item['kategori_id']);

    String tingkatMembaca = item?['tingkat_membaca']?.toString() ?? 'Pemula';

    String status = item?['status']?.toString() ?? 'draf';

    if (status != 'draf' && status != 'diterbitkan') {
      status = 'draf';
    }

    if (!kategori.any((k) => angka(k['id']) == kategoriId)) {
      kategoriId = null;
    }

    bool menyimpan = false;

    bool pakaiUnggahan =
        gambarController.text.trim().startsWith(awalanDataGambar);
    Uint8List? bytesSampul;
    String? namaSampul;

    Future<void> pilihBerkas(StateSetter aturDialog) async {
      try {
        final hasil = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );

        if (hasil == null || hasil.files.isEmpty) return;

        final berkas = hasil.files.first;
        final bytes = berkas.bytes;

        if (bytes == null || bytes.isEmpty) {
          tampilkanPesan('Berkas gambar tidak bisa dibaca.');
          return;
        }

        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          tampilkanPesan('Ukuran gambar maksimal 2 MB.');
          return;
        }

        aturDialog(() {
          bytesSampul = bytes;
          namaSampul = berkas.name;
          pakaiUnggahan = true;
        });
      } catch (e) {
        tampilkanPesan('Gagal memilih gambar: $e');
      }
    }

    if (!mounted) {
      judulController.dispose();
      deskripsiController.dispose();
      gambarController.dispose();
      hargaController.dispose();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Ubah Cerita' : 'Tambah Cerita',
                style: TextStyle(
                  color: biruTua,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _labelForm('Judul Cerita'),
                      TextField(
                        controller: judulController,
                        decoration: _dekorasiForm(
                          'Masukkan judul cerita',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Deskripsi'),
                      TextField(
                        controller: deskripsiController,
                        maxLines: 3,
                        decoration: _dekorasiForm(
                          'Masukkan deskripsi cerita',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Kategori'),
                      DropdownButtonFormField<int>(
                        value: kategoriId,
                        isExpanded: true,
                        decoration: _dekorasiForm('Pilih kategori'),
                        items: kategori.map((k) {
                          return DropdownMenuItem<int>(
                            value: angka(k['id']),
                            child: Text(teks(k['nama'])),
                          );
                        }).toList(),
                        onChanged: menyimpan
                            ? null
                            : (value) {
                                setDialogState(() {
                                  kategoriId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Tingkat Membaca'),
                      DropdownButtonFormField<String>(
                        value: tingkatMembaca,
                        isExpanded: true,
                        decoration: _dekorasiForm(
                          'Pilih tingkat membaca',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pemula',
                            child: Text('Pemula'),
                          ),
                          DropdownMenuItem(
                            value: 'Menengah',
                            child: Text('Menengah'),
                          ),
                          DropdownMenuItem(
                            value: 'Lanjutan',
                            child: Text('Lanjutan'),
                          ),
                        ],
                        onChanged: menyimpan
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  tingkatMembaca = value;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Gambar Sampul'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pilihanSampul(
                            'URL Gambar',
                            Icons.link,
                            !pakaiUnggahan,
                            () => setDialogState(() {
                              if (gambarController.text
                                  .trim()
                                  .startsWith(awalanDataGambar)) {
                                gambarController.clear();
                              }
                              pakaiUnggahan = false;
                            }),
                          ),
                          _pilihanSampul(
                            'Unggah dari Laptop',
                            Icons.upload_file_outlined,
                            pakaiUnggahan,
                            () => setDialogState(
                              () => pakaiUnggahan = true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: pakaiUnggahan
                                ? _kotakUnggah(
                                    namaBerkas: namaSampul,
                                    sedangMenyimpan: menyimpan,
                                    onPilih: () => pilihBerkas(
                                      setDialogState,
                                    ),
                                    onHapus: () => setDialogState(() {
                                      bytesSampul = null;
                                      namaSampul = null;
                                    }),
                                  )
                                : TextField(
                                    controller: gambarController,
                                    onChanged: (_) => setDialogState(() {}),
                                    decoration: _dekorasiForm(
                                      'https://contoh.com/sampul.jpg',
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          SampulCerita(
                            sumber: pakaiUnggahan && bytesSampul != null
                                ? dataUriGambar(
                                    bytesSampul!,
                                    namaSampul ?? 'sampul.jpg',
                                  )
                                : gambarController.text.trim(),
                            lebar: 70,
                            tinggi: 92,
                            warnaIkon: biru,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Harga Poin'),
                      TextField(
                        controller: hargaController,
                        keyboardType: TextInputType.number,
                        decoration: _dekorasiForm(
                          'Contoh: 0',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _labelForm('Status Cerita'),
                      DropdownButtonFormField<String>(
                        value: status,
                        isExpanded: true,
                        decoration: _dekorasiForm(
                          'Pilih status cerita',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draf',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'diterbitkan',
                            child: Text('Diterbitkan'),
                          ),
                        ],
                        onChanged: menyimpan
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  status = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      menyimpan ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: biru,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: menyimpan
                      ? null
                      : () async {
                          final judul = judulController.text.trim();
                          final deskripsi = deskripsiController.text.trim();
                          final gambarUrl = gambarController.text.trim();
                          final gambar = pakaiUnggahan && bytesSampul != null
                              ? dataUriGambar(
                                  bytesSampul!,
                                  namaSampul ?? 'sampul.jpg',
                                )
                              : gambarUrl;
                          final harga =
                              int.tryParse(hargaController.text.trim());

                          if (judul.isEmpty) {
                            tampilkanPesan('Judul cerita wajib diisi.');
                            return;
                          }

                          if (kategoriId == null) {
                            tampilkanPesan('Silakan pilih kategori.');
                            return;
                          }

                          if (harga == null || harga < 0) {
                            tampilkanPesan(
                              'Harga poin harus berupa angka 0 atau lebih.',
                            );
                            return;
                          }

                          setDialogState(() {
                            menyimpan = true;
                          });

                          final data = {
                            'judul': judul,
                            'deskripsi': deskripsi,
                            'kategori_id': kategoriId,
                            'tingkat_membaca': tingkatMembaca,
                            'gambar_sampul': gambar.isEmpty ? null : gambar,
                            'harga_poin': harga,
                            'status': status,
                          };

                          try {
                            if (isEdit) {
                              await supabase
                                  .from('buku')
                                  .update(data)
                                  .eq('id', item['id']);
                            } else {
                              await supabase.from('buku').insert(data);
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);
                            await muatCerita();

                            tampilkanPesan(
                              isEdit
                                  ? 'Cerita berhasil diperbarui.'
                                  : 'Cerita berhasil ditambahkan.',
                            );
                          } catch (e) {
                            setDialogState(() {
                              menyimpan = false;
                            });

                            tampilkanPesan('Gagal menyimpan cerita: $e');
                          }
                        },
                  child: menyimpan
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Cerita'),
                ),
              ],
            );
          },
        );
      },
    );

    judulController.dispose();
    deskripsiController.dispose();
    gambarController.dispose();
    hargaController.dispose();
  }

  Widget _pilihanSampul(
    String judul,
    IconData ikon,
    bool aktif,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: aktif ? biru : latar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: aktif ? biru : garis),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 14, color: aktif ? Colors.white : biruTua),
            const SizedBox(width: 6),
            Text(
              judul,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : biruTua,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kotakUnggah({
    required String? namaBerkas,
    required bool sedangMenyimpan,
    required VoidCallback onPilih,
    required VoidCallback onHapus,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  namaBerkas ?? 'Belum ada gambar dipilih',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        namaBerkas == null ? const Color(0xFF94A3B8) : biruTua,
                  ),
                ),
              ),
              if (namaBerkas != null)
                IconButton(
                  tooltip: 'Hapus gambar',
                  onPressed: sedangMenyimpan ? null : onHapus,
                  icon: const Icon(Icons.close, size: 16),
                  color: Colors.red,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: sedangMenyimpan ? null : onPilih,
              icon: const Icon(Icons.folder_open, size: 15),
              label: Text(
                namaBerkas == null ? 'Pilih Gambar' : 'Ganti Gambar',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: biru,
                side: BorderSide(color: garis),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'JPG, PNG, atau WEBP maksimal 2 MB.',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dekorasiForm(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: latar,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: garis),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: garis),
      ),
    );
  }

  Widget _labelForm(String judul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        judul,
        style: TextStyle(
          color: biruTua,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> ubahStatus(Map<String, dynamic> item) async {
    final statusSekarang = item['status']?.toString().toLowerCase();

    if (statusSekarang != 'draf' && statusSekarang != 'diterbitkan') {
      tampilkanPesan('Status cerita tidak dikenali.');
      return;
    }

    final statusBaru = statusSekarang == 'draf' ? 'diterbitkan' : 'draf';

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          statusBaru == 'diterbitkan' ? 'Terbitkan Cerita' : 'Tarik Cerita',
        ),
        content: Text(
          statusBaru == 'diterbitkan'
              ? 'Apakah kamu yakin ingin menerbitkan cerita "${item['judul']}"?'
              : 'Apakah kamu yakin ingin menarik cerita "${item['judul']}" menjadi draft?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await supabase
          .from('buku')
          .update({'status': statusBaru}).eq('id', item['id']);

      await muatCerita();

      tampilkanPesan(
        statusBaru == 'diterbitkan'
            ? 'Cerita berhasil diterbitkan.'
            : 'Cerita berhasil ditarik menjadi draft.',
      );
    } catch (e) {
      tampilkanPesan('Gagal mengubah status cerita: $e');
    }
  }

  Future<void> hapusCerita(Map<String, dynamic> item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Cerita'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${item['judul']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await supabase.from('buku').delete().eq('id', item['id']);

      await muatCerita();

      tampilkanPesan('Cerita berhasil dihapus.');
    } catch (e) {
      tampilkanPesan('Gagal menghapus cerita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Kelola Cerita',
      child: _konten(),
    );
  }

  Widget _konten() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _judulHalaman(),
          const SizedBox(height: 20),
          _filterUtama(),
          const SizedBox(height: 20),
          if (sedangMemuat)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(45),
                child: CircularProgressIndicator(),
              ),
            )
          else if (pesanError != null)
            _errorData()
          else if (ceritaTampil.isEmpty)
            _kosong()
          else
            ...ceritaTampil.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _cardCerita(item),
              ),
            ),
          const SizedBox(height: 10),
          _footer(),
        ],
      ),
    );
  }

  Widget _judulHalaman() {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final tombol = ElevatedButton.icon(
          onPressed: tambahCerita,
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Tambah Cerita'),
          style: ElevatedButton.styleFrom(
            backgroundColor: biru,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        return ukuran.maxWidth > 600
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _judulDanJumlah()),
                  tombol,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _judulDanJumlah(),
                  const SizedBox(height: 12),
                  tombol,
                ],
              );
      },
    );
  }

  Widget _judulDanJumlah() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(
              'Kelola Cerita',
              style: TextStyle(
                color: biruTua,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total ${cerita.length} Buku',
                style: TextStyle(
                  color: biru,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola cerita, kategori, tingkat membaca, dan status publikasi.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _filterUtama() {
    final daftarKategori = [
      'Semua',
      ...kategori.map((item) => teks(item['nama'])),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: latar,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: garis),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        pencarian = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari judul cerita...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ...daftarKategori.map((nama) {
                final aktif = kategoriTerpilih == nama;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      kategoriTerpilih = nama;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: aktif ? biru : const Color(0xFFF0F3FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$nama (${jumlahKategori(nama)})',
                      style: TextStyle(
                        color: aktif ? Colors.white : biruTua,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              _dropdownFilter(
                statusTerpilih,
                const [
                  'Semua Status',
                  'Diterbitkan',
                  'Draft',
                ],
                (value) {
                  setState(() {
                    statusTerpilih = value;
                  });
                },
                135,
              ),
              _dropdownFilter(
                urutanTerpilih,
                const [
                  'Terbaru',
                  'Judul A-Z',
                  'Judul Z-A',
                ],
                (value) {
                  setState(() {
                    urutanTerpilih = value;
                  });
                },
                145,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter(
    String nilai,
    List<String> pilihan,
    ValueChanged<String> onChanged,
    double lebar,
  ) {
    return Container(
      width: lebar,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: garis),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: nilai,
          isExpanded: true,
          isDense: true,
          items: pilihan.map((p) {
            return DropdownMenuItem<String>(
              value: p,
              child: Text(
                p,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _cardCerita(Map<String, dynamic> item) {
    final judul = teks(item['judul'], 'Tanpa Judul');
    final deskripsi = teks(item['deskripsi'], 'Belum ada deskripsi');
    final kategoriNama = namaKategori(item['kategori_id']);
    final status = statusCerita(item);
    final tingkat = teks(item['tingkat_membaca'], 'Belum diatur');
    final harga = angka(item['harga_poin']);
    final gambar = teks(item['gambar_sampul'], '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: garis),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, ukuran) {
          final sampul = SampulCerita(
            sumber: gambar,
            lebar: 76,
            tinggi: 100,
            warnaIkon: biru,
          );

          final detail = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _label(
                      kategoriNama,
                      const Color(0xFFE0F2FE),
                      biru,
                    ),
                    _label(
                      tingkat,
                      const Color(0xFFE8EDFF),
                      biruTua,
                    ),
                    _label(
                      status,
                      status == 'Diterbitkan'
                          ? const Color(0xFFE7FFF2)
                          : const Color(0xFFFFF1DF),
                      status == 'Diterbitkan'
                          ? const Color(0xFF00A66A)
                          : const Color(0xFFB7791F),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: biruTua,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 7),
                _infoCerita(
                  Icons.stars_outlined,
                  '$harga Poin',
                ),
              ],
            ),
          );

          final aksi = _aksiCerita(item, status);

          if (ukuran.maxWidth > 650) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sampul,
                const SizedBox(width: 14),
                detail,
                const SizedBox(width: 12),
                aksi,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sampul,
                  const SizedBox(width: 12),
                  detail,
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: aksi,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String tulisan, Color background, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tulisan,
        style: TextStyle(
          color: warna,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoCerita(IconData icon, String tulisan) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              tulisan,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aksiCerita(
    Map<String, dynamic> item,
    String status,
  ) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => editCerita(item),
          icon: const Icon(Icons.edit_outlined, size: 14),
          label: const Text('Ubah'),
          style: OutlinedButton.styleFrom(
            foregroundColor: biruTua,
            side: BorderSide(color: garis),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => ubahStatus(item),
          icon: Icon(
            status == 'Diterbitkan'
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 14,
          ),
          label: Text(
            status == 'Diterbitkan' ? 'Tarik' : 'Terbitkan',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                status == 'Diterbitkan' ? const Color(0xFFFFF1DF) : biru,
            foregroundColor: status == 'Diterbitkan'
                ? const Color(0xFFB7791F)
                : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Hapus cerita',
          onPressed: () => hapusCerita(item),
          icon: const Icon(Icons.delete_outline, size: 19),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _kosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: garis),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: biru.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Cerita tidak ditemukan',
            style: TextStyle(
              color: biruTua,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Coba gunakan kata pencarian atau kategori lain.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal memuat data cerita.',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pesanError ?? '',
            style: const TextStyle(fontSize: 11),
          ),
          TextButton.icon(
            onPressed: muatCerita,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Menampilkan ${ceritaTampil.length} dari ${cerita.length} cerita',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blueGrey,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: muatCerita,
          icon: Icon(Icons.refresh, color: biru),
        ),
      ],
    );
  }
}
