// ==========================================================
// LAYANAN DATA KELOLA PENGGUNA
// Abstraksi PenggunaRepository memungkinkan sumber data
// diganti (Supabase, data tiruan, atau data uji) tanpa
// mengubah halaman kelola pengguna.
// ==========================================================

import '../model/pengguna_model.dart';

abstract class PenggunaRepository {
  Future<DataPengguna> muatPengguna();
}

/// Sumber data contoh.
///
/// Tabel `pengguna` di Supabase baru menyimpan `id`, `nama`,
/// `tanggal_dibuat`, dan `peran`; kolom email, usia anak, koin,
/// serta status langganan belum tersedia. Karena itu halaman ini
/// memakai data contoh yang bentuknya sudah siap ditukar dengan
/// implementasi Supabase saat kolomnya tersedia.
class ContohPenggunaRepository implements PenggunaRepository {
  const ContohPenggunaRepository();

  static const List<BarisPengguna> _pengguna = [
    BarisPengguna(
      nama: 'Bunda Sari Pertiwi',
      email: 'sari.pertiwi@gmail.com',
      bergabung: '12 Jan 2024',
      anak: [
        ProfilAnak(
          nama: 'Rayyan',
          usia: 5,
          level: 'Level 1 - Pra-Membaca',
        ),
      ],
      koin: 1450,
      aktivitas: 'Membaca "Kancil dan Buaya"',
      waktuAktivitas: '10 menit lalu',
      status: StatusAkun.aktif,
      paket: 'Premium Family',
      menitAktivitas: 10,
    ),
    BarisPengguna(
      nama: 'Ayah Budi Pratama',
      email: 'budi.pratama@office.id',
      bergabung: '04 Feb 2024',
      anak: [
        ProfilAnak(
          nama: 'Kiki',
          usia: 7,
          level: 'Level 2 - Pemula Lancar',
        ),
      ],
      koin: 890,
      aktivitas: 'Selesai Kuis "Hutan Pelangi"',
      waktuAktivitas: '1 jam lalu',
      status: StatusAkun.aktif,
      paket: 'Gratis (Premium)',
      menitAktivitas: 60,
    ),
    BarisPengguna(
      nama: 'Bunda Hana Lestari',
      email: 'hana.lestari@yahoo.com',
      bergabung: '18 Nov 2023',
      anak: [
        ProfilAnak(
          nama: 'Aifi',
          usia: 4,
          level: 'Level 1 - Pra-Membaca',
        ),
        ProfilAnak(
          nama: 'Nia',
          usia: 9,
          level: 'Level 2 - Lancar Membaca',
        ),
      ],
      koin: 2340,
      aktivitas: 'Klaim Misi Mingguan',
      waktuAktivitas: '3 jam lalu',
      status: StatusAkun.aktif,
      paket: 'Premium Family',
      menitAktivitas: 180,
    ),
    BarisPengguna(
      nama: 'Bunda Rina Melati',
      email: 'rina.melati@gmail.com',
      bergabung: 'Hari ini',
      anak: [
        ProfilAnak(
          nama: 'Dimas',
          usia: 6,
          level: 'Level 2 - Transisi Membaca',
        ),
      ],
      koin: 320,
      aktivitas: 'Registrasi & Verifikasi Akun',
      waktuAktivitas: 'Hari ini, 08:00',
      status: StatusAkun.aktif,
      paket: 'Akun Baru (Premium Akses)',
      terdaftarPekanIni: true,
      menitAktivitas: 480,
    ),
    BarisPengguna(
      nama: 'Ayah Hendra Wijaya',
      email: 'hendra.wijaya@outlook.com',
      bergabung: '09 Mar 2023',
      anak: [
        ProfilAnak(
          nama: 'Sabahila',
          usia: 10,
          level: 'Level 3 - Pembaca Mandiri',
        ),
      ],
      koin: 1850,
      aktivitas: 'Membaca "Mulan Kandung"',
      waktuAktivitas: 'Kemarin, 19:40',
      status: StatusAkun.aktif,
      paket: 'Premium Family',
      menitAktivitas: 1140,
    ),
    BarisPengguna(
      nama: 'Ibu Citra Dewi',
      email: 'citra.dewi@gmail.com',
      bergabung: '15 Jan 2024',
      anak: [
        ProfilAnak(
          nama: 'Kenzo',
          usia: 5,
          level: 'Level 1 - Belajar Lancar',
        ),
      ],
      koin: 770,
      aktivitas: 'Membaca "Putri & Naga Kecil"',
      waktuAktivitas: '2 hari lalu',
      status: StatusAkun.aktif,
      paket: 'Gratis (Premium)',
      menitAktivitas: 2880,
    ),
  ];

  static const RingkasanPengguna _ringkasan = RingkasanPengguna(
    totalAkun: 123,
    akunAktif: 108,
    akunBaruPekanIni: 15,
    akunNonaktif: 0,
    profilAnak: 168,
    akunMembaca: 94,
    totalKoin: 48250,
    persenMembaca: 76.4,
    persenPertumbuhan: 12,
  );

  @override
  Future<DataPengguna> muatPengguna() async {
    return DataPengguna(
      pengguna: List<BarisPengguna>.unmodifiable(_pengguna),
      ringkasan: _ringkasan,
      dimuatPada: DateTime.now(),
    );
  }
}
