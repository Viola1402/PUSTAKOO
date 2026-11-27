/// Kumpulan fungsi bantu untuk mengubah nilai dari Supabase (Map) menjadi
/// tipe data Dart. Dipakai bersama oleh semua model supaya penanganan nilai
/// null dan konversi tipe selalu konsisten.
library;

/// Mengubah nilai apa pun menjadi int. Kalau gagal, pakai [bawaan].
int keInt(dynamic nilai, {int bawaan = 0}) {
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();
  if (nilai is String) return int.tryParse(nilai) ?? bawaan;
  return bawaan;
}

/// Mengubah nilai menjadi teks yang sudah dipangkas. Null -> [bawaan].
String keTeks(dynamic nilai, {String bawaan = ''}) {
  if (nilai == null) return bawaan;
  final teks = nilai.toString().trim();
  return teks.isEmpty ? bawaan : teks;
}

/// Mengubah nilai menjadi DateTime. Null / format salah -> null.
DateTime? keTanggal(dynamic nilai) {
  if (nilai == null) return null;
  if (nilai is DateTime) return nilai;
  return DateTime.tryParse(nilai.toString());
}
