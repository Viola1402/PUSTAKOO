import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Awalan data URI untuk gambar hasil unggahan dari laptop.
const String awalanDataGambar = 'data:image/';

/// Mengubah bytes gambar menjadi data URI agar bisa disimpan pada kolom
/// `buku.gambar_sampul` tanpa memerlukan storage bucket.
String dataUriGambar(Uint8List bytes, String namaBerkas) {
  final ekstensi = namaBerkas.toLowerCase().split('.').last;
  final jenis = switch (ekstensi) {
    'png' => 'png',
    'webp' => 'webp',
    'gif' => 'gif',
    _ => 'jpeg',
  };

  return '$awalanDataGambar$jenis;base64,${base64Encode(bytes)}';
}

/// Mengambil bytes dari data URI gambar. Null bila bukan data URI.
Uint8List? byteDariSampul(String? sumber) {
  if (sumber == null || !sumber.startsWith(awalanDataGambar)) return null;

  final pemisah = sumber.indexOf(',');
  if (pemisah < 0) return null;

  try {
    return base64Decode(sumber.substring(pemisah + 1));
  } catch (_) {
    return null;
  }
}

/// Menampilkan sampul cerita dari URL (http/https) maupun gambar yang
/// diunggah dari laptop (data URI base64).
class SampulCerita extends StatelessWidget {
  final String? sumber;
  final double lebar;
  final double tinggi;
  final BorderRadius radius;
  final IconData ikon;
  final Color? warnaIkon;
  final Color? warnaLatar;

  const SampulCerita({
    super.key,
    required this.sumber,
    this.lebar = 76,
    this.tinggi = 100,
    this.radius = const BorderRadius.all(Radius.circular(8)),
    this.ikon = Icons.menu_book,
    this.warnaIkon,
    this.warnaLatar,
  });

  @override
  Widget build(BuildContext context) {
    final alamat = sumber?.trim() ?? '';

    Widget isi;

    if (alamat.isEmpty) {
      isi = _gambarKosong();
    } else if (alamat.startsWith(awalanDataGambar)) {
      final bytes = byteDariSampul(alamat);

      isi = bytes == null
          ? _gambarKosong()
          : Image.memory(
              bytes,
              width: lebar,
              height: tinggi,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _gambarKosong(),
            );
    } else {
      isi = Image.network(
        alamat,
        width: lebar,
        height: tinggi,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gambarKosong(),
      );
    }

    return Container(
      width: lebar,
      height: tinggi,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: warnaLatar ?? const Color(0xFFE5F1FB),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: isi,
    );
  }

  Widget _gambarKosong() {
    return Center(
      child: Icon(
        ikon,
        size: tinggi * 0.32,
        color: warnaIkon ?? const Color(0xFF0B669B),
      ),
    );
  }
}
