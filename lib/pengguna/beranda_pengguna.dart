import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../autentikasi/login.dart';
import 'baca_buku.dart';

class BerandaOrangTua extends StatefulWidget {
  const BerandaOrangTua({super.key});

  @override
  State<BerandaOrangTua> createState() => _BerandaOrangTuaState();
}

class _BerandaOrangTuaState extends State<BerandaOrangTua> {
  final _supabase = Supabase.instance.client;

  bool _memuat = true;
  String? _error;
  Map<String, dynamic>? _anak;
  List<Map<String, dynamic>> _buku = [];
  // buku_id -> data progres
  Map<int, Map<String, dynamic>> _progres = {};

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Belum login');

      final daftarAnak = await _supabase
          .from('anak')
          .select()
          .eq('pengguna_id', user.id)
          .order('id')
          .limit(1);

      if (daftarAnak.isEmpty) {
        setState(() {
          _anak = null;
          _buku = [];
          _progres = {};
          _memuat = false;
        });
        return;
      }

      final anak = Map<String, dynamic>.from(daftarAnak.first);

      final buku = await _supabase
          .from('buku')
          .select('id, judul, deskripsi, tingkat_membaca, gambar_sampul, kategori(nama)')
          .eq('status', 'diterbitkan')
          .order('judul');

      final progres = await _supabase
          .from('progres_membaca')
          .select('buku_id, halaman_terakhir, status')
          .eq('anak_id', anak['id']);

      final peta = <int, Map<String, dynamic>>{};
      for (final p in progres) {
        peta[p['buku_id'] as int] = Map<String, dynamic>.from(p);
      }

      setState(() {
        _anak = anak;
        _buku = List<Map<String, dynamic>>.from(buku);
        _progres = peta;
        _memuat = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _memuat = false;
      });
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _bukaBuku(Map<String, dynamic> buku) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BacaBuku(
          anakId: _anak!['id'] as int,
          bukuId: buku['id'] as int,
          judul: buku['judul'] as String,
        ),
      ),
    );
    // Segarkan status progres setelah kembali dari layar baca.
    if (mounted) _muatData();
  }

  String _subjudul(Map<String, dynamic> buku) {
    final kategori = buku['kategori'];
    final namaKategori = kategori is Map ? kategori['nama'] as String? : null;
    final tingkat = buku['tingkat_membaca'] as String?;
    return [namaKategori, tingkat]
        .where((e) => e != null && e.isNotEmpty)
        .join(' • ');
  }

  Widget _sampul(String? url) {
    final kotak = Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.menu_book, color: Colors.blue.shade700),
    );
    if (url == null || url.isEmpty) return kotak;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 56,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => kotak,
      ),
    );
  }

  Widget _labelProgres(Map<String, dynamic>? p) {
    if (p == null) return const SizedBox.shrink();
    final selesai = p['status'] == 'selesai';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        selesai ? 'Selesai dibaca' : 'Terakhir di halaman ${p['halaman_terakhir']}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selesai ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _isi() {
    if (_memuat) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat data.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _muatData, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    if (_anak == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada data anak untuk akun ini.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Halo, ${_anak!['nama_panggilan']}!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Pilih buku yang ingin dibaca hari ini.'),
          const SizedBox(height: 16),
          if (_buku.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Belum ada buku yang diterbitkan.')),
            ),
          for (final b in _buku)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _bukaBuku(b),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _sampul(b['gambar_sampul'] as String?),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['judul'] as String,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_subjudul(b).isNotEmpty)
                              Text(
                                _subjudul(b),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            _labelProgres(_progres[b['id'] as int]),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Orang Tua'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isi(),
    );
  }
}
