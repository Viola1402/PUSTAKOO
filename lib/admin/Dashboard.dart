
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final supabase = Supabase.instance.client;

  final Color krem = const Color(0xFFF2EBD9);

  int totalPengguna = 0;
  int totalAnak = 0;
  int totalCerita = 0;
  int totalKuisDikerjakan = 0;

  double rataRataKuis = 0;
  double persentaseMisi = 0;

  String ceritaTerpopuler = 'Belum ada data';

  List<Map<String, dynamic>> ceritaPopuler = [];
  List<Map<String, dynamic>> aktivitas = [];

  bool sedangMemuat = true;
  String? pesanError;

  @override
  void initState() {
    super.initState();
    muatDashboard();
  }

  Future<void> muatDashboard() async {
    if (mounted) {
      setState(() {
        sedangMemuat = true;
        pesanError = null;
      });
    }

    try {
      final sekarang = DateTime.now();
      final awalPekan = sekarang.subtract(const Duration(days: 7));
      final batasWaktu = awalPekan.toIso8601String();

      final hasilPengguna =
          await supabase.from('pengguna').count(CountOption.exact);

      final hasilAnak =
          await supabase.from('anak').count(CountOption.exact);

      final hasilBuku =
          await supabase.from('buku').count(CountOption.exact);

      final hasilKuis =
          await supabase.from('riwayat_kuis').count(CountOption.exact);

      final dataKuis = await supabase
          .from('riwayat_kuis')
          .select('id, nilai, waktu_selesai, anak_id, kuis_id')
          .gte('waktu_selesai', batasWaktu)
          .order('waktu_selesai', ascending: false);

      double jumlahNilai = 0;

      for (final item in dataKuis) {
        jumlahNilai += (item['nilai'] as num?)?.toDouble() ?? 0;
      }

      final rataNilai =
          dataKuis.isEmpty ? 0.0 : jumlahNilai / dataKuis.length;

      final dataMisi = await supabase
          .from('progres_misi')
          .select('id, status, waktu_selesai');

      final totalMisi = dataMisi.length;

      final misiSelesai =
          dataMisi.where((item) => item['status'] == 'selesai').length;

      final persenMisi =
          totalMisi == 0 ? 0.0 : (misiSelesai / totalMisi) * 100;

      final dataProgres = await supabase
          .from('progres_membaca')
          .select('buku_id')
          .gte('terakhir_diperbarui', batasWaktu);

      final Map<int, int> jumlahBaca = {};

      for (final item in dataProgres) {
        final idBuku = (item['buku_id'] as num).toInt();
        jumlahBaca[idBuku] = (jumlahBaca[idBuku] ?? 0) + 1;
      }

      final dataBuku =
          await supabase.from('buku').select('id, judul, kategori_id');

      final dataKategori =
          await supabase.from('kategori').select('id, nama');

      final Map<int, String> namaKategori = {};

      for (final item in dataKategori) {
        namaKategori[(item['id'] as num).toInt()] =
            item['nama']?.toString() ?? '-';
      }

      final List<Map<String, dynamic>> daftarCerita = [];

      for (final item in dataBuku) {
        final id = (item['id'] as num).toInt();
        final jumlah = jumlahBaca[id] ?? 0;

        if (jumlah > 0) {
          final kategoriId = (item['kategori_id'] as num).toInt();

          daftarCerita.add({
            'judul': item['judul'] ?? '-',
            'kategori': namaKategori[kategoriId] ?? '-',
            'jumlah': jumlah,
          });
        }
      }

      daftarCerita.sort(
        (a, b) => (b['jumlah'] as int).compareTo(a['jumlah'] as int),
      );

      final populer = daftarCerita.take(5).toList();

      final judulTerpopuler = populer.isEmpty
          ? 'Belum ada data'
          : populer.first['judul'].toString();

      final List<Map<String, dynamic>> daftarAktivitas = [];

      final penggunaBaru = await supabase
          .from('pengguna')
          .select('nama, tanggal_dibuat')
          .order('tanggal_dibuat', ascending: false)
          .limit(5);

      for (final item in penggunaBaru) {
        daftarAktivitas.add({
          'judul': '${item['nama'] ?? 'Pengguna'} mendaftar',
          'waktu': item['tanggal_dibuat'],
          'icon': Icons.person_add,
        });
      }

      final kuisTerbaru = await supabase
          .from('riwayat_kuis')
          .select('id, waktu_selesai, nilai')
          .order('waktu_selesai', ascending: false)
          .limit(5);

      for (final item in kuisTerbaru) {
        daftarAktivitas.add({
          'judul': 'Pengguna menyelesaikan kuis '
              '(nilai ${item['nilai']})',
          'waktu': item['waktu_selesai'],
          'icon': Icons.quiz,
        });
      }

      final transaksiTerbaru = await supabase
          .from('transaksi_poin')
          .select('jumlah_poin, jenis, keterangan, tanggal_transaksi')
          .order('tanggal_transaksi', ascending: false)
          .limit(5);

      for (final item in transaksiTerbaru) {
        daftarAktivitas.add({
          'judul': item['keterangan'] ??
              'Transaksi poin: ${item['jenis']} '
                  '(${item['jumlah_poin']} poin)',
          'waktu': item['tanggal_transaksi'],
          'icon': Icons.stars,
        });
      }

      final misiTerbaru = await supabase
          .from('progres_misi')
          .select('id, status, waktu_selesai')
          .eq('status', 'selesai')
          .order('waktu_selesai', ascending: false)
          .limit(5);

      for (final item in misiTerbaru) {
        daftarAktivitas.add({
          'judul': 'Pengguna menyelesaikan misi',
          'waktu': item['waktu_selesai'],
          'icon': Icons.flag,
        });
      }

      daftarAktivitas.sort((a, b) {
        final waktuA =
            DateTime.tryParse(a['waktu']?.toString() ?? '');

        final waktuB =
            DateTime.tryParse(b['waktu']?.toString() ?? '');

        if (waktuA == null) return 1;
        if (waktuB == null) return -1;

        return waktuB.compareTo(waktuA);
      });

      if (!mounted) return;

      setState(() {
        totalPengguna = hasilPengguna;
        totalAnak = hasilAnak;
        totalCerita = hasilBuku;
        totalKuisDikerjakan = hasilKuis;

        rataRataKuis = rataNilai;
        persentaseMisi = persenMisi;

        ceritaPopuler = populer;
        ceritaTerpopuler = judulTerpopuler;

        aktivitas = daftarAktivitas.take(5).toList();

        sedangMemuat = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat dashboard: $e');

      if (!mounted) return;

      setState(() {
        sedangMemuat = false;
        pesanError = e.toString();
      });
    }
  }

  String formatWaktu(dynamic waktu) {
    if (waktu == null) return 'Waktu tidak tersedia';

    final tanggal = DateTime.tryParse(waktu.toString());

    if (tanggal == null) return 'Waktu tidak tersedia';

    final selisih = DateTime.now().difference(tanggal);

    if (selisih.isNegative) return 'Baru saja';
    if (selisih.inMinutes < 1) return 'Baru saja';

    if (selisih.inMinutes < 60) {
      return '${selisih.inMinutes} menit lalu';
    }

    if (selisih.inHours < 24) {
      return '${selisih.inHours} jam lalu';
    }

    if (selisih.inDays < 7) {
      return '${selisih.inDays} hari lalu';
    }

    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      aktif: 'Dashboard',
      child: LayoutBuilder(
        builder: (context, ukuran) {
          return _konten(context, ukuran.maxWidth);
        },
      ),
    );
  }

  Widget _konten(BuildContext context, double lebar) {
    final jumlahKolom = lebar > 1100
        ? 4
        : lebar > 550
            ? 2
            : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF286795),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selamat datang kembali! Berikut ringkasan '
            'performa perpustakaan digital anak Pustakoo hari ini.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 22),
          if (pesanError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gagal memuat data dashboard.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesanError!,
                    style: const TextStyle(fontSize: 11),
                  ),
                  TextButton.icon(
                    onPressed: muatDashboard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          GridView.count(
            crossAxisCount: jumlahKolom,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: jumlahKolom == 1 ? 2.4 : 1.5,
            children: [
              _statistik(
                'TOTAL PENGGUNA',
                totalPengguna.toString(),
                Icons.groups,
                const Color(0xFF91C5EC),
              ),
              _statistik(
                'TOTAL ANAK',
                totalAnak.toString(),
                Icons.child_care,
                const Color(0xFFF0E77A),
              ),
              _statistik(
                'TOTAL CERITA',
                totalCerita.toString(),
                Icons.menu_book,
                const Color(0xFFF7C64F),
              ),
              _statistik(
                'TOTAL KUIS DIKERJAKAN',
                totalKuisDikerjakan.toString(),
                Icons.quiz,
                krem,
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (lebar > 1100)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _ceritaPopuler(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _aktivitas(),
                ),
              ],
            )
          else
            Column(
              children: [
                _ceritaPopuler(),
                const SizedBox(height: 16),
                _aktivitas(),
              ],
            ),
          const SizedBox(height: 20),
          _laporan(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statistik(
    String judul,
    String angka,
    IconData icon,
    Color warna,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  judul,
                  style: const TextStyle(
                    color: Color(0xFF286795),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF286795)),
            ],
          ),
          Text(
            sedangMemuat ? '...' : angka,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF286795),
            ),
          ),
          const Text(
            'Ringkasan data Pustakoo',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF286795),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ceritaPopuler() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cerita Populer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF286795),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Buku cerita yang paling sering dibaca pekan ini',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 18),
          if (sedangMemuat)
            const Center(child: CircularProgressIndicator())
          else if (ceritaPopuler.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Belum ada cerita yang dibaca pekan ini.'),
            )
          else
            for (final item in ceritaPopuler)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F1FC),
                  child: Icon(
                    Icons.menu_book,
                    color: Color(0xFF286795),
                  ),
                ),
                title: Text(
                  item['judul'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${item['kategori']} • '
                  '${item['jumlah']} Kali Dibaca',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.more_vert),
              ),
        ],
      ),
    );
  }

  Widget _aktivitas() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: krem,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF286795),
            ),
          ),
          const SizedBox(height: 14),
          if (sedangMemuat)
            const Center(child: CircularProgressIndicator())
          else if (aktivitas.isEmpty)
            const Text('Belum ada aktivitas.')
          else
            for (final item in aktivitas)
              Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: const Color(0xFF286795),
                  ),
                  title: Text(
                    item['judul'].toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    formatWaktu(item['waktu']),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _laporan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: krem,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Laporan Pekan Ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF286795),
            ),
          ),
          const SizedBox(height: 14),
          Text('Cerita terpopuler: $ceritaTerpopuler'),
          const SizedBox(height: 10),
          Text(
            'Rata-rata skor kuis: '
            '${rataRataKuis.toStringAsFixed(1)} / 100',
          ),
          const SizedBox(height: 10),
          Text(
            'Misi selesai: ${persentaseMisi.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}
