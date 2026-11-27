import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../autentikasi/login.dart';
import 'KelolaCerita.dart';
import 'KelolaKategori.dart';
import 'KelolaKuis.dart';
import 'KelolaMisiPoin.dart';
import 'KelolaPengguna.dart';
import 'Laporan.dart';

// ==========================================================
// WARNA DAN GAYA ADMIN PUSTAKOO
// ==========================================================

class GayaAdmin {
  const GayaAdmin._();

  static const Color biru = Color(0xFF0B669B);
  static const Color biruTua = Color(0xFF073B70);
  static const Color biruMuda = Color(0xFFE0F2FE);
  static const Color latar = Color(0xFFF7F8FC);
  static const Color sidebar = Color(0xFFF0F3FC);
  static const Color garis = Color(0xFFE1E8F2);
  static const Color krem = Color(0xFFF6EEDA);
  static const Color kremMuda = Color(0xFFFBF6EA);
  static const Color teks = Color(0xFF334155);
  static const Color teksAbu = Color(0xFF64748B);
  static const Color hijau = Color(0xFF00A66A);
  static const Color hijauMuda = Color(0xFFE7FFF2);
  static const Color oranye = Color(0xFFB7791F);
  static const Color oranyeMuda = Color(0xFFFDF1DC);
  static const Color merah = Color(0xFFE5484D);
  static const Color merahMuda = Color(0xFFFDECEC);
}

class MenuAdmin {
  final String judul;
  final IconData ikon;

  const MenuAdmin(this.judul, this.ikon);
}

const List<MenuAdmin> daftarMenuAdmin = [
  MenuAdmin('Dashboard', Icons.grid_view_rounded),
  MenuAdmin('Kelola Cerita', Icons.menu_book_outlined),
  MenuAdmin('Kelola Kategori', Icons.category_outlined),
  MenuAdmin('Kelola Kuis', Icons.quiz_outlined),
  MenuAdmin('Kelola Misi & Poin', Icons.emoji_events_outlined),
  MenuAdmin('Kelola Pengguna', Icons.people_outline),
  MenuAdmin('Laporan', Icons.bar_chart_outlined),
];

// ==========================================================
// NAVIGASI MENU ADMIN
// ==========================================================

void bukaMenuAdmin(
  BuildContext context,
  String menu, {
  NavigatorState? navigator,
  ScaffoldMessengerState? messenger,
}) {
  final nav = navigator ?? Navigator.of(context);
  final pesan = messenger ?? ScaffoldMessenger.of(context);

  if (menu == 'Dashboard') {
    nav.popUntil((route) => route.isFirst);
    return;
  }

  Widget? halaman;

  switch (menu) {
    case 'Kelola Cerita':
      halaman = const KelolaCeritaPage();
      break;
    case 'Kelola Kategori':
      halaman = const KelolaKategoriPage();
      break;
    case 'Kelola Kuis':
      halaman = const KelolaKuisPage();
      break;
    case 'Kelola Misi & Poin':
      halaman = const KelolaMisiPoinPage();
      break;
    case 'Kelola Pengguna':
      halaman = const KelolaPenggunaPage();
      break;
    case 'Laporan':
      halaman = const LaporanPage();
      break;
  }

  if (halaman == null) {
    pesan.showSnackBar(
      SnackBar(content: Text('$menu akan segera dihubungkan.')),
    );
    return;
  }

  final tujuan = halaman;

  nav.push(
    MaterialPageRoute(builder: (_) => tujuan),
  );
}

// ==========================================================
// KERANGKA HALAMAN ADMIN (TOPBAR + SIDEBAR)
// ==========================================================

class AdminShell extends StatelessWidget {
  final String aktif;
  final Widget child;

  const AdminShell({
    super.key,
    required this.aktif,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, ukuran) {
        final desktop = ukuran.maxWidth > 900;

        if (!desktop) {
          return Scaffold(
            backgroundColor: GayaAdmin.latar,
            drawer: Drawer(child: _sidebar(context)),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(62),
              child: _topbar(context, false),
            ),
            body: child,
          );
        }

        return Scaffold(
          backgroundColor: GayaAdmin.latar,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 232,
                child: _sidebar(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topbar(context, true),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------
  // TOPBAR
  // --------------------------------------------------------

  Widget _topbar(BuildContext context, bool desktop) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: GayaAdmin.garis)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (!desktop) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: GayaAdmin.biruTua),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    height: 44,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: GayaAdmin.latar,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GayaAdmin.garis),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, size: 18, color: GayaAdmin.teksAbu),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari cerita, pengguna, kuis...',
                              hintStyle: TextStyle(
                                color: GayaAdmin.teksAbu,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pencarian global belum tersedia.'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GayaAdmin.biruTua,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Cari'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Belum ada notifikasi baru.'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: GayaAdmin.teks,
                ),
              ),
              Positioned(
                right: 9,
                top: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: GayaAdmin.merah,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          if (desktop) ...[
            const CircleAvatar(
              radius: 17,
              backgroundColor: GayaAdmin.biru,
              backgroundImage: AssetImage('assets/images/piko.png'),
            ),
            const SizedBox(width: 8),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Pustakoo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: GayaAdmin.teksAbu,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ] else
            const CircleAvatar(
              radius: 16,
              backgroundColor: GayaAdmin.biru,
              backgroundImage: AssetImage('assets/images/piko.png'),
            ),
        ],
      ),
    );
  }

  Widget _merekSidebar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/piko.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Pustakoo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GayaAdmin.biruTua,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // SIDEBAR
  // --------------------------------------------------------

  Widget _sidebar(BuildContext context) {
    return Material(
      color: GayaAdmin.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _merekSidebar(),
          for (final item in daftarMenuAdmin)
            _menu(
              context,
              item.ikon,
              item.judul,
              aktif: item.judul == aktif,
            ),
          const Spacer(),
          Divider(color: GayaAdmin.garis, height: 1),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
              size: 18,
            ),
            title: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _keluar(context),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String judul, {
    bool aktif = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      child: Material(
        color: aktif ? GayaAdmin.biru : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pilihMenu(context, judul),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: aktif ? Colors.white : GayaAdmin.teks,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    judul,
                    style: TextStyle(
                      color: aktif ? Colors.white : GayaAdmin.teks,
                      fontSize: 11.5,
                      fontWeight:
                          aktif ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pilihMenu(BuildContext context, String menu) {
    if (menu == aktif) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scaffold = Scaffold.maybeOf(context);

    if (scaffold != null && scaffold.isDrawerOpen) {
      nav.pop();
    }

    bukaMenuAdmin(
      context,
      menu,
      navigator: nav,
      messenger: messenger,
    );
  }

  Future<void> _keluar(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

// ==========================================================
// WIDGET PENDUKUNG
// ==========================================================

class KartuAdmin extends StatelessWidget {
  final Widget child;
  final Color? warna;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;

  const KartuAdmin({
    super.key,
    required this.child,
    this.warna,
    this.padding = const EdgeInsets.all(16),
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: warna ?? Colors.white,
        borderRadius: radius ?? BorderRadius.circular(13),
        border: Border.all(color: GayaAdmin.garis),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ChipAdmin extends StatelessWidget {
  final String teks;
  final Color? warna;
  final Color? teksWarna;
  final IconData? ikon;
  final bool kecil;

  const ChipAdmin(
    this.teks, {
    super.key,
    this.warna,
    this.teksWarna,
    this.ikon,
    this.kecil = false,
  });

  @override
  Widget build(BuildContext context) {
    final latar = warna ?? GayaAdmin.biruMuda;
    final depan = teksWarna ?? GayaAdmin.biruTua;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kecil ? 7 : 9,
        vertical: kecil ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: kecil ? 8 : 10, color: depan),
            const SizedBox(width: 4),
          ],
          Text(
            teks,
            style: TextStyle(
              fontSize: kecil ? 8.5 : 10,
              fontWeight: FontWeight.w700,
              color: depan,
            ),
          ),
        ],
      ),
    );
  }
}

class RemahAdmin extends StatelessWidget {
  final List<String> jejak;

  const RemahAdmin(this.jejak, {super.key});

  @override
  Widget build(BuildContext context) {
    final anak = <Widget>[];

    for (var i = 0; i < jejak.length; i++) {
      final akhir = i == jejak.length - 1;

      anak.add(
        Text(
          jejak[i],
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: akhir ? FontWeight.bold : FontWeight.w500,
            color: akhir ? GayaAdmin.biruTua : GayaAdmin.teksAbu,
          ),
        ),
      );

      if (!akhir) {
        anak.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 12,
              color: GayaAdmin.teksAbu,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: anak,
      ),
    );
  }
}

class JudulBagian extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String? subjudul;
  final Widget? kanan;
  final Color? warnaIkon;

  const JudulBagian({
    super.key,
    required this.ikon,
    required this.judul,
    this.subjudul,
    this.kanan,
    this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: warnaIkon ?? GayaAdmin.biruMuda,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(ikon, size: 16, color: GayaAdmin.biruTua),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: GayaAdmin.biruTua,
                ),
              ),
              if (subjudul != null) ...[
                const SizedBox(height: 2),
                Text(
                  subjudul!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: GayaAdmin.teksAbu,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (kanan != null) ...[
          const SizedBox(width: 8),
          kanan!,
        ],
      ],
    );
  }
}

class TombolAdmin extends StatelessWidget {
  final String teks;
  final IconData? ikon;
  final VoidCallback? onPressed;
  final bool utama;
  final Color? warna;

  const TombolAdmin({
    super.key,
    required this.teks,
    this.ikon,
    this.onPressed,
    this.utama = true,
    this.warna,
  });

  @override
  Widget build(BuildContext context) {
    final gayaTeks = const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.bold,
    );

    if (!utama) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: ikon == null ? const SizedBox.shrink() : Icon(ikon, size: 14),
        label: Text(teks),
        style: OutlinedButton.styleFrom(
          foregroundColor: GayaAdmin.biruTua,
          backgroundColor: Colors.white,
          side: const BorderSide(color: GayaAdmin.garis),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: gayaTeks,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: ikon == null ? const SizedBox.shrink() : Icon(ikon, size: 15),
      label: Text(teks),
      style: ElevatedButton.styleFrom(
        backgroundColor: warna ?? GayaAdmin.biruTua,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: gayaTeks,
      ),
    );
  }
}

// ==========================================================
// KOTAK INPUT ADMIN
// ==========================================================

class KotakIsian extends StatelessWidget {
  final String label;
  final String? bantuan;
  final String? akhiran;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;

  const KotakIsian({
    super.key,
    required this.label,
    this.bantuan,
    this.akhiran,
    this.controller,
    this.hint,
    this.keyboard,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: GayaAdmin.biruTua,
                  ),
                ),
              ),
              if (bantuan != null)
                Flexible(
                  child: Text(
                    bantuan!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 8,
                      color: GayaAdmin.teksAbu,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GayaAdmin.garis),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboard,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GayaAdmin.teks,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: GayaAdmin.teksAbu,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (akhiran != null)
                  Text(
                    akhiran!,
                    style: const TextStyle(
                      fontSize: 9,
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

