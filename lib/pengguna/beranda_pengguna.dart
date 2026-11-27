import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../autentikasi/login.dart';
import 'baca_buku.dart';
import 'layanan_beranda.dart';
import 'model_anak.dart';
import 'model_buku.dart';
import 'model_kategori.dart';
import 'model_misi.dart';
import 'progres_belajar.dart';
import 'rekomendasi_buku.dart';
import 'tema_pustakoo.dart';
import 'navigasi_bawah_pustakoo.dart';

/// Layar Beranda Orang Tua (Figma: 02-beranda).
///
/// PEMISAHAN TANGGUNG JAWAB:
/// - model  : file model_*.dart (Anak, Buku, Kategori, Misi, ProgresMisi)
/// - layanan: LayananBeranda (semua query Supabase)
/// - strategi: RekomendasiBuku + turunannya
/// - UI     : class ini, hanya menampilkan objek dan menangani interaksi
///
/// COMPOSITION: state di bawah memiliki objek LayananBeranda dan memakai
/// objek-objek model, bukan Map mentah dari Supabase.
class BerandaOrangTua extends StatefulWidget {
  const BerandaOrangTua({super.key});

  @override
  State<BerandaOrangTua> createState() => _BerandaOrangTuaState();
}

class _BerandaOrangTuaState extends State<BerandaOrangTua> {
  // COMPOSITION: layanan data dibuat sekali untuk layar ini.
  final LayananBeranda _layanan = LayananBeranda();

  // Data anak (bisa lebih dari satu profil).
  List<Anak> _daftarAnak = [];
  int? _anakAktifId;

  // Data milik anak yang sedang dipilih.
  List<Buku> _buku = [];
  List<ProgresMembaca> _progres = [];
  List<Kategori> _kategori = [];
  List<int> _idMinat = [];
  List<MisiAnak> _misi = [];

  // Status tampilan tiap bagian.
  bool _memuatAwal = true;
  bool _memuatDataAnak = false;
  String? _galatAwal;
  String? _galatBuku;
  String? _galatProgres;
  String? _galatKategori;
  String? _galatMinat;
  String? _galatMisi;

  // Penjaga urutan query: kalau pengguna cepat berganti profil, hasil query
  // lama tidak boleh menimpa data profil yang baru dipilih.
  int _versi = 0;

  static const _warnaSampul = <Color>[
    Warna.persik,
    Color(0xFFF8D7E6),
    Warna.hijauMuda,
    Warna.biruTitik,
  ];

  /// Timer penunda penyegaran setelah kembali dari layar baca/kuis.
  Timer? _penundaSegarkan;

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  @override
  void dispose() {
    _penundaSegarkan?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PENGAMBILAN DATA
  // ---------------------------------------------------------------------------

  /// Memuat daftar anak lalu data bagian Beranda untuk anak yang aktif.
  Future<void> _muatSemua() async {
    final versi = ++_versi;

    setState(() {
      if (_daftarAnak.isEmpty) _memuatAwal = true;
      _galatAwal = null;
    });

    List<Anak> daftarAnak;
    try {
      daftarAnak = await _layanan.ambilDaftarAnak();
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        _memuatAwal = false;
        _memuatDataAnak = false;
        _galatAwal = _pesanGalat(e);
      });
      return;
    }

    if (!mounted || versi != _versi) return;

    // Pertahankan anak yang sedang dipilih bila masih ada.
    final anakAktif = daftarAnak.isEmpty
        ? null
        : daftarAnak.firstWhere(
            (a) => a.id == _anakAktifId,
            orElse: () => daftarAnak.first,
          );

    setState(() {
      _daftarAnak = daftarAnak;
      _anakAktifId = anakAktif?.id;
      _memuatAwal = false;
      _memuatDataAnak = anakAktif != null;
      _kosongkanDataAnak();
    });

    if (anakAktif == null) return;
    await _muatBagianAnak(anakAktif.id, versi);
  }

  /// Mengganti profil anak yang dipilih.
  Future<void> _gantiAnak(Anak anak) async {
    if (anak.id == _anakAktifId) return;

    final versi = ++_versi;
    setState(() {
      _anakAktifId = anak.id;
      // Data anak sebelumnya langsung dibuang supaya tidak ikut tampil.
      _kosongkanDataAnak();
      _memuatDataAnak = true;
    });

    await _muatBagianAnak(anak.id, versi);
  }

  /// Mengambil semua bagian data untuk satu anak.
  ///
  /// Setiap bagian memakai try/catch sendiri supaya kalau satu query gagal
  /// (misalnya RLS menolak), bagian lain tetap bisa ditampilkan.
  Future<void> _muatBagianAnak(int anakId, int versi) async {
    var buku = <Buku>[];
    var progres = <ProgresMembaca>[];
    var kategori = <Kategori>[];
    var idMinat = <int>[];
    var misi = <MisiAnak>[];
    String? galatBuku;
    String? galatProgres;
    String? galatKategori;
    String? galatMinat;
    String? galatMisi;

    try {
      buku = await _layanan.ambilBukuTerbit();
    } catch (e) {
      galatBuku = _pesanGalat(e);
    }
    if (!mounted || versi != _versi) return;

    try {
      progres = await _layanan.ambilProgresMembaca(anakId);
    } catch (e) {
      galatProgres = _pesanGalat(e);
    }
    if (!mounted || versi != _versi) return;

    try {
      kategori = await _layanan.ambilKategori();
    } catch (e) {
      galatKategori = _pesanGalat(e);
    }
    if (!mounted || versi != _versi) return;

    try {
      idMinat = await _layanan.ambilIdMinatAnak(anakId);
    } catch (e) {
      galatMinat = _pesanGalat(e);
    }
    if (!mounted || versi != _versi) return;

    try {
      misi = await _layanan.ambilMisiAnak(anakId);
    } catch (e) {
      galatMisi = _pesanGalat(e);
    }
    if (!mounted || versi != _versi) return;

    setState(() {
      _buku = buku;
      _progres = progres;
      _kategori = kategori;
      _idMinat = idMinat;
      _misi = misi;
      _galatBuku = galatBuku;
      _galatProgres = galatProgres;
      _galatKategori = galatKategori;
      _galatMinat = galatMinat;
      _galatMisi = galatMisi;
      _memuatDataAnak = false;
    });
  }

  /// Mengosongkan data anak aktif beserta pesan galatnya.
  void _kosongkanDataAnak() {
    _buku = [];
    _progres = [];
    _kategori = [];
    _idMinat = [];
    _misi = [];
    _galatBuku = null;
    _galatProgres = null;
    _galatKategori = null;
    _galatMinat = null;
    _galatMisi = null;
  }

  /// Pesan galat yang ramah untuk ditampilkan di layar.
  String _pesanGalat(Object e) {
    if (e is PostgrestException) {
      return 'Server tidak dapat diakses (${e.message}).';
    }
    if (e is AuthException) {
      return 'Sesi login bermasalah: ${e.message}';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  // ---------------------------------------------------------------------------
  // DATA TURUNAN (hasil pengolahan objek)
  // ---------------------------------------------------------------------------

  Anak? get _anakAktif {
    if (_daftarAnak.isEmpty) return null;
    for (final a in _daftarAnak) {
      if (a.id == _anakAktifId) return a;
    }
    return _daftarAnak.first;
  }

  /// Kategori yang menjadi minat anak (hasil pencocokan id minat + kategori).
  List<Kategori> get _minatKategori =>
      _kategori.where((k) => _idMinat.contains(k.id)).toList();

  /// Bacaan terakhir yang belum selesai, untuk kartu "Lanjutkan Membaca".
  BacaanBerjalan? get _lanjutan {
    for (final p in _progres) {
      // Filter tetap: hanya bacaan yang belum selesai. Status tidak diubah.
      if (p.selesai) continue;
      for (final b in _buku) {
        if (b.id != p.bukuId) continue;
        // Buku yang terbukti belum punya halaman tidak bisa dilanjutkan.
        if (b.tanpaHalaman) break;
        return BacaanBerjalan(b, p);
      }
    }
    return null;
  }

  /// POLYMORPHISM saat program berjalan:
  /// variabel `strategi` bertipe abstract [RekomendasiBuku], isinya bisa
  /// RekomendasiMinat atau RekomendasiUmum tergantung data minat anak.
  /// Pemanggilan `strategi.rekomendasikan()` menjalankan method yang berbeda
  /// sesuai objek aslinya.
  List<Buku> _susunRekomendasi() {
    final minat = _minatKategori;

    final RekomendasiBuku strategi;
    if (minat.isEmpty) {
      strategi = RekomendasiUmum(_buku);
    } else {
      strategi = RekomendasiMinat(_buku, minat.map((k) => k.id).toList());
    }

    return strategi.rekomendasikan(batas: 6);
  }

  // ---------------------------------------------------------------------------
  // INTERAKSI
  // ---------------------------------------------------------------------------

  void _infoPengembangan(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fitur akan tersedia pada tahap berikutnya.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pesan singkat di bagian bawah layar.
  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), behavior: SnackBarBehavior.floating),
    );
  }

  /// Membuka layar baca milik anggota lain tanpa mengubah kontraknya.
  ///
  /// Buku yang sudah terbukti belum punya halaman tidak dibuka supaya
  /// pengguna tidak masuk ke layar baca yang kosong.
  Future<void> _bukaBaca(Buku buku) async {
    final anak = _anakAktif;
    if (anak == null) return;

    if (buku.tanpaHalaman) {
      _pesan('Cerita "${buku.judul}" belum tersedia untuk dibaca.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BacaBuku(
          anakId: anak.id,
          bukuId: buku.id,
          judul: buku.judul,
        ),
      ),
    );

    // Segarkan progres setelah kembali dari layar baca.
    if (mounted) _segarkanSetelahKembali();
  }

  /// Menunda penyegaran sampai Beranda kembali menjadi halaman aktif.
  ///
  /// Layar baca berpindah ke kuis dengan `pushReplacement`, sehingga future
  /// `Navigator.push` di atas selesai ketika kuis masih terbuka. Kalau data
  /// dimuat ulang tepat di titik itu, hasil kuis dan progres terakhir bisa
  /// terlewat. Penyegaran karena itu menunggu Beranda aktif kembali, tanpa
  /// mengubah alur navigasi bersama milik anggota lain.
  void _segarkanSetelahKembali() {
    _penundaSegarkan?.cancel();

    final rute = ModalRoute.of(context);
    if (rute == null || rute.isCurrent) {
      _muatSemua();
      return;
    }

    _penundaSegarkan =
        Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        _penundaSegarkan = null;
        return;
      }
      final sekarang = ModalRoute.of(context);
      if (sekarang == null || sekarang.isCurrent) {
        timer.cancel();
        _penundaSegarkan = null;
        _muatSemua();
      }
    });
  }

  /// Membuka layar Progres Belajar milik anggota lain.
  Future<void> _bukaProgres() async {
    final anak = _anakAktif;
    if (anak == null) {
      _infoPengembangan('Progres belajar');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgresBelajar(anakId: anak.id)),
    );

    if (mounted) await _muatSemua();
  }

  Future<void> _konfirmasiLogout() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar dari akun?', style: gaya(16)),
        content: Text(
          'Kamu bisa masuk kembali kapan saja.',
          style: gaya(13, warna: Warna.biruGelap),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Batal', style: gaya(13)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Keluar', style: gaya(13, warna: Warna.biruTua)),
          ),
        ],
      ),
    );

    if (keluar == true) await _logout();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Detail singkat buku. Halaman Detail Buku penuh dikerjakan pada tahap
  /// Perpustakaan, jadi untuk sekarang cukup lembar ringkas + tombol baca.
  Future<void> _tampilkanDetailBuku(Buku buku) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Warna.latar,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Warna.biruTitik,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sampulBuku(buku, lebar: 92, tinggi: 120),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buku.judul, style: gaya(19)),
                          const SizedBox(height: 4),
                          if (buku.keteranganSingkat.isNotEmpty)
                            Text(
                              buku.keteranganSingkat,
                              style: gaya(12, warna: Warna.biruGelap),
                            ),
                          const SizedBox(height: 10),
                          _keteranganHalaman(
                            buku,
                            onPeriksaUlang: () {
                              Navigator.pop(sheetContext);
                              _muatSemua();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (buku.deskripsi != null) ...[
                  const SizedBox(height: 18),
                  Text('Sinopsis', style: gaya(14)),
                  const SizedBox(height: 6),
                  Text(
                    buku.deskripsi!,
                    style: gaya(12, warna: Warna.biruGelap, tinggi: 1.45),
                  ),
                ],
                const SizedBox(height: 20),
                TombolPustakoo(
                  label: 'Mulai Membaca',
                  onTap: buku.tanpaHalaman
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _bukaBaca(buku);
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  'Detail buku lengkap akan tersedia di halaman Perpustakaan.',
                  textAlign: TextAlign.center,
                  style: gaya(10, warna: Warna.biruGelap),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Keterangan jumlah halaman dengan tiga keadaan yang berbeda:
  /// sudah ada isi, terverifikasi belum ada halaman, dan belum diketahui.
  Widget _keteranganHalaman(Buku buku, {VoidCallback? onPeriksaUlang}) {
    if (buku.punyaHalaman) {
      return Text(
        '${buku.jumlahHalaman} halaman',
        style: gaya(12, warna: Warna.biruGelap),
      );
    }

    if (buku.tanpaHalaman) {
      return Row(
        children: [
          const Icon(Icons.menu_book_rounded, size: 15, color: Warna.abuGelap),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Cerita belum tersedia',
              style: gaya(12, warna: Warna.abuGelap),
            ),
          ),
        ],
      );
    }

    // Null: query gagal atau hasilnya belum bisa dipercaya, jadi buku tidak
    // langsung dianggap tidak punya halaman. Sediakan pemeriksaan ulang.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah halaman belum diketahui.',
          style: gaya(12, warna: Warna.abuGelap),
        ),
        SizedBox(
          height: 34,
          child: TextButton(
            onPressed: onPeriksaUlang,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Periksa ulang', style: gaya(11, warna: Warna.biruTua)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return KerangkaSeluler(
      child: Column(
        children: [
          _bilahAtas(),
          Expanded(child: _isi()),
          _navigasiBawah(),
        ],
      ),
    );
  }

  /// Bilah atas: saldo poin anak dan avatar (sesuai desain Figma).
  Widget _bilahAtas() {
    final anak = _anakAktif;

    return Container(
      width: double.infinity,
      color: Warna.biruMuda,
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _konfirmasiLogout,
            icon: const Icon(Icons.logout_rounded, color: Warna.biruTua),
          ),
          const Spacer(),
          if (anak != null)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _infoPengembangan('Penukaran poin'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Warna.persik,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${anak.poin} Poin', style: gaya(14)),
              ),
            ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Warna.kuning,
              shape: BoxShape.circle,
            ),
            child: Text(
              anak?.hurufAwal ?? '?',
              style: gaya(16, warna: Warna.biruTua),
            ),
          ),
        ],
      ),
    );
  }

  Widget _isi() {
    if (_memuatAwal) {
      return const Center(
          child: CircularProgressIndicator(color: Warna.biruTua));
    }

    if (_galatAwal != null) {
      return KotakGalat(
        judul: 'Gagal memuat beranda.',
        pesan: _galatAwal!,
        onUlang: _muatSemua,
      );
    }

    return RefreshIndicator(
      onRefresh: _muatSemua,
      color: Warna.biruTua,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _kepala(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_daftarAnak.length > 1) ...[
                  _pemilihAnak(),
                  const SizedBox(height: 18),
                ],
                if (_daftarAnak.isEmpty) ...[
                  _kartuKosong(
                    'Akun ini belum memiliki profil anak. Fitur tambah profil '
                    'anak akan tersedia pada tahap Profil Anak.',
                  ),
                ] else if (_memuatDataAnak) ...[
                  _kartuMemuat(),
                ] else ...[
                  _bagianLanjutkan(),
                  const SizedBox(height: 24),
                  _bagianRekomendasi(),
                  const SizedBox(height: 24),
                  _bagianKategori(),
                  const SizedBox(height: 24),
                  _bagianMisi(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sapaan, maskot, dan informasi anak yang sedang dipilih.
  Widget _kepala() {
    final anak = _anakAktif;

    final String sapaan;
    final String keterangan;
    if (anak == null) {
      sapaan = 'Halo, Ayah & Bunda!';
      keterangan = 'Yuk baca bareng si kecil hari ini';
    } else {
      sapaan = 'Halo, ${anak.namaPanggilan}!';
      keterangan =
          'Didampingi ${anak.namaOrangTua ?? 'orang tua'} • ${anak.keteranganUsia}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Warna.biruMuda, width: 2),
            ),
            child: const Center(child: Panda(ukuran: 52)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sapaan, style: gaya(23)),
                const SizedBox(height: 2),
                Text(
                  keterangan,
                  style: gaya(12, warna: Warna.biruGelap, tinggi: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pemilih profil sederhana (tampil hanya jika anak lebih dari satu).
  Widget _pemilihAnak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih profil anak', style: gaya(12, warna: Warna.biruGelap)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _daftarAnak.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final anak = _daftarAnak[i];
              final dipilih = anak.id == _anakAktifId;

              return ChoiceChip(
                label: Text(
                  anak.namaPanggilan,
                  style: gaya(12, warna: Warna.biruTua),
                ),
                selected: dipilih,
                onSelected: (_) => _gantiAnak(anak),
                selectedColor: Warna.kuning,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Warna.biruTitik),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bagianLanjutkan() {
    final lanjut = _lanjutan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judulBagian('Lanjutkan Membaca'),
        const SizedBox(height: 10),
        if (_galatBuku != null || _galatProgres != null)
          _kartuGalatBagian(_galatBuku ?? _galatProgres!)
        else if (lanjut == null)
          _kartuKosong(
            'Belum ada bacaan yang sedang berjalan. Pilih cerita dari '
            'rekomendasi di bawah untuk memulai.',
          )
        else
          _kartuLanjutkan(lanjut),
      ],
    );
  }

  Widget _kartuLanjutkan(BacaanBerjalan lanjut) {
    final buku = lanjut.buku;
    final progres = lanjut.progres;
    final total = buku.jumlahHalaman;
    final adaTotal = total != null && total > 0;
    // Progress bar hanya tampil kalau total halaman valid. Total null (belum
    // diketahui) atau 0 tidak dipakai sebagai pembagi.
    final kemajuan = adaTotal
        ? (progres.halamanTampil(total) / total).clamp(0.0, 1.0).toDouble()
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _bukaBaca(buku),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Warna.biruMuda,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            _sampulBuku(buku, lebar: 72, tinggi: 88),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buku.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: gaya(16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adaTotal
                        ? 'Halaman ${progres.halamanTampil(total)} dari $total'
                        : buku.tanpaHalaman
                            ? 'Cerita belum tersedia'
                            : 'Halaman ${progres.halamanTerakhir}',
                    style: gaya(12, warna: Warna.biruGelap),
                  ),
                  const SizedBox(height: 10),
                  if (kemajuan != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: kemajuan,
                        minHeight: 10,
                        backgroundColor: Colors.white,
                        color: Warna.emas,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_fill_rounded,
                color: Warna.biruTua, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _bagianRekomendasi() {
    if (_galatBuku != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _judulBagian('Rekomendasi Buku'),
          const SizedBox(height: 10),
          _kartuGalatBagian(_galatBuku!),
        ],
      );
    }

    final rekomendasi = _susunRekomendasi();
    final minat = _minatKategori;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judulBagian('Rekomendasi Buku'),
        const SizedBox(height: 4),
        Text(
          minat.isEmpty
              ? 'Pilihan dari semua cerita terbit'
              : 'Sesuai minat: ${minat.map((k) => k.nama).join(', ')}',
          style: gaya(11, warna: Warna.biruGelap),
        ),
        if (_galatMinat != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Minat anak belum dapat dimuat, memakai rekomendasi umum.',
              style: gaya(10, warna: Warna.biruGelap),
            ),
          ),
        const SizedBox(height: 12),
        if (_buku.isEmpty)
          _kartuKosong('Belum ada cerita yang diterbitkan saat ini.')
        else
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
              childAspectRatio: 0.62,
            ),
            itemCount: rekomendasi.length,
            itemBuilder: (context, i) => _kartuBuku(rekomendasi[i]),
          ),
      ],
    );
  }

  Widget _kartuBuku(Buku buku) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _tampilkanDetailBuku(buku),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _sampulBuku(buku, lebar: double.infinity)),
          const SizedBox(height: 10),
          Text(
            buku.judul,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: gaya(14),
          ),
          if (buku.keteranganSingkat.isNotEmpty)
            Text(
              buku.keteranganSingkat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gaya(11, warna: Warna.biruGelap),
            ),
          if (buku.tanpaHalaman)
            Text(
              'Cerita belum tersedia',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gaya(10, warna: Warna.abuGelap),
            )
          else if (buku.jumlahHalamanBelumDiketahui)
            Text(
              'Jumlah halaman belum diketahui',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gaya(10, warna: Warna.abuGelap),
            ),
        ],
      ),
    );
  }

  /// Sampul buku: gambar jaringan kalau ada, kalau tidak pakai huruf awal
  /// di dalam lingkaran putih dengan latar pastel seperti desain Figma.
  Widget _sampulBuku(Buku buku, {double? lebar, double? tinggi}) {
    final warna = _warnaSampul[buku.id % _warnaSampul.length];

    final huruf = Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(buku.hurufAwal, style: gaya(34)),
    );

    final cadangan = Container(
      color: warna,
      alignment: Alignment.center,
      child: huruf,
    );

    final url = buku.gambarSampul;
    final isi = (url == null || url.isEmpty)
        ? cadangan
        : Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => cadangan,
          );

    return SizedBox(
      width: lebar ?? 56,
      height: tinggi,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isi,
      ),
    );
  }

  Widget _bagianKategori() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judulBagian(
          'Kategori Cerita',
          aksi: 'Lihat semua',
          onAksi: () => _infoPengembangan('Perpustakaan digital'),
        ),
        const SizedBox(height: 10),
        if (_galatKategori != null)
          _kartuGalatBagian(_galatKategori!)
        else if (_kategori.isEmpty)
          _kartuKosong('Belum ada kategori cerita.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in _kategori)
                ActionChip(
                  label: Text(k.nama, style: gaya(12)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Warna.biruTitik),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () =>
                      _infoPengembangan('Daftar cerita per kategori'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _bagianMisi() {
    final daftar = _misi.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judulBagian('Misi Membaca'),
        const SizedBox(height: 10),
        if (_galatMisi != null)
          _kartuGalatBagian(_galatMisi!)
        else if (daftar.isEmpty)
          _kartuKosong('Belum ada misi membaca untuk saat ini.')
        else
          for (final item in daftar) _kartuMisi(item),
      ],
    );
  }

  Widget _kartuMisi(MisiAnak item) {
    final selesai = item.selesai;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Warna.krem,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.flag_rounded, size: 18, color: Warna.emas),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(item.misi.judul, style: gaya(14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selesai ? Warna.hijauMuda : Warna.biruTitik,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.keteranganStatus,
                  style: gaya(10, warna: selesai ? Warna.hijau : Warna.biruTua),
                ),
              ),
            ],
          ),
          if (item.misi.deskripsi != null) ...[
            const SizedBox(height: 6),
            Text(
              item.misi.deskripsi!,
              style: gaya(11, warna: Warna.biruGelap, tinggi: 1.3),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.kemajuan,
              minHeight: 8,
              backgroundColor: Warna.biruTitik,
              color: selesai ? Warna.hijau : Warna.emas,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.misi.target > 0
                    ? '${item.progresSaatIni} dari ${item.misi.target}'
                    : 'Target belum ditentukan',
                style: gaya(11, warna: Warna.biruGelap),
              ),
              const Spacer(),
              const Icon(Icons.stars_rounded, size: 14, color: Warna.emas),
              const SizedBox(width: 4),
              Text('${item.misi.hadiahPoin} poin', style: gaya(11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _judulBagian(String judul, {String? aksi, VoidCallback? onAksi}) {
    return Row(
      children: [
        Expanded(child: Text(judul, style: gaya(17))),
        if (aksi != null)
          TextButton(
            onPressed: onAksi,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(aksi, style: gaya(11, warna: Warna.biruGelap)),
          ),
      ],
    );
  }

  Widget _kartuMemuat() {
    final anak = _anakAktif;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Warna.biruTua),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat data ${anak?.namaPanggilan ?? 'anak'}...',
            style: gaya(12, warna: Warna.biruGelap),
          ),
        ],
      ),
    );
  }

  /// Empty state: data berhasil diambil, tetapi isinya kosong.
  Widget _kartuKosong(String pesan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Warna.biruTitik),
      ),
      child: Text(
        pesan,
        style: gaya(12, warna: Warna.biruGelap, tinggi: 1.4),
      ),
    );
  }

  /// Error state per bagian: bagian lain tetap bisa tampil.
  Widget _kartuGalatBagian(String pesan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Warna.biruTitik),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gagal memuat bagian ini.',
            style: gaya(12, warna: Warna.biruTua),
          ),
          const SizedBox(height: 4),
          Text(
            pesan,
            style: gaya(11, warna: Warna.biruGelap, tinggi: 1.35),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 140,
            child: TombolPustakoo(label: 'Coba lagi', onTap: _muatSemua),
          ),
        ],
      ),
    );
  }

  // Navigasi bawah sesuai desain Figma Pustakoo.
  Widget _navigasiBawah() {
    const List<IconData> ikonNav = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.pie_chart_outline,
      Icons.star_outlined,
    ];

    const List<String> labelNav = [
      'Beranda',
      'Perpustakaan',
      'Progres',
      'Poin',
    ];

    return NavigasiBawahPustakoo(
      onTap: [
        () {},
        () => _infoPengembangan('Perpustakaan digital'),
        () => _bukaProgres(),
        () => _infoPengembangan('Penukaran poin'),
      ],
      ikon: ikonNav,
      label: labelNav,
      indexAktif: 0,
    );
  }
}
