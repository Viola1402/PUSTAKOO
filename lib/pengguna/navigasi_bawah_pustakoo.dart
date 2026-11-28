import 'package:flutter/material.dart';
import 'tema_pustakoo.dart';

// Widget untuk setiap item navigasi bawah.
class NavigasiBawahPustakooItem extends StatelessWidget {
  final int index;
  final int totalMenu;
  final VoidCallback onTap;
  final IconData ikon;
  final double ukuranIkon;
  final String label;
  final bool aktif;

  const NavigasiBawahPustakooItem({
    super.key,
    required this.index,
    required this.totalMenu,
    required this.onTap,
    required this.ikon,
    required this.ukuranIkon,
    required this.label,
    required this.aktif,
  });

  @override
  Widget build(BuildContext context) {
    // Menentukan warna berdasarkan menu yang aktif.
    final warnaIkon = aktif ? Warna.kuning : Warna.biruTua;

    return Semantics(
      selected: aktif,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menu Poin menggunakan bintang dalam lingkaran.
              if (index == 3)
                Container(
                  width: ukuranIkon,
                  height: ukuranIkon,
                  decoration: BoxDecoration(
                    color: warnaIkon,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ikon,
                    size: ukuranIkon * 0.7,
                    color: aktif ? Warna.biruTua : Colors.white,
                  ),
                )
              else
                Icon(ikon, size: ukuranIkon, color: warnaIkon),
              const SizedBox(height: 4),
              Text(
                label,
                style: gaya(11, warna: Warna.biruTua),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget navigasi yang dapat digunakan kembali pada halaman pengguna.
class NavigasiBawahPustakoo extends StatelessWidget {
  final List<VoidCallback> onTap;
  final List<IconData> ikon;
  final List<String> label;
  final int indexAktif;

  const NavigasiBawahPustakoo({
    super.key,
    required this.onTap,
    required this.ikon,
    required this.label,
    required this.indexAktif,
  })  : assert(onTap.length == 4),
        assert(ikon.length == 4),
        assert(label.length == 4),
        assert(indexAktif >= 0 && indexAktif < 4);

  @override
  Widget build(BuildContext context) {
    final totalMenu = label.length;

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: List.generate(totalMenu, (index) {
              return Expanded(
                child: NavigasiBawahPustakooItem(
                  index: index,
                  totalMenu: totalMenu,
                  onTap: onTap[index],
                  ikon: ikon[index],
                  ukuranIkon: 30,
                  label: label[index],
                  aktif: index == indexAktif,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
