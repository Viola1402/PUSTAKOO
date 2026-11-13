-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 13 Nov 2026 pada 09.11
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pustakoo`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `anak`
--

CREATE TABLE `anak` (
  `id_anak` int(11) NOT NULL,
  `id_pengguna` int(11) NOT NULL,
  `nama_orang_tua` varchar(100) NOT NULL,
  `nama_panggilan` varchar(100) NOT NULL,
  `umur` int(11) NOT NULL,
  `jumlah_poin` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `buku`
--

CREATE TABLE `buku` (
  `id_buku` int(11) NOT NULL,
  `id_kategori` int(11) NOT NULL,
  `judul` varchar(150) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `tingkat_baca` varchar(50) DEFAULT NULL,
  `gambar_sampul` varchar(255) DEFAULT NULL,
  `harga_poin` int(11) NOT NULL DEFAULT 0,
  `status` enum('draf','diterbitkan') DEFAULT 'draf'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `buku_dibuka`
--

CREATE TABLE `buku_dibuka` (
  `id_pembukaan` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `id_buku` int(11) NOT NULL,
  `poin_digunakan` int(11) NOT NULL DEFAULT 0,
  `tanggal_dibuka` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `halaman_buku`
--

CREATE TABLE `halaman_buku` (
  `id_halaman` int(11) NOT NULL,
  `id_buku` int(11) NOT NULL,
  `nomor_halaman` int(11) NOT NULL,
  `isi_cerita` text NOT NULL,
  `ilustrasi` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `kategori`
--

CREATE TABLE `kategori` (
  `id_kategori` int(11) NOT NULL,
  `nama_kategori` varchar(100) NOT NULL,
  `deskripsi` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `kuis`
--

CREATE TABLE `kuis` (
  `id_kuis` int(11) NOT NULL,
  `id_buku` int(11) NOT NULL,
  `judul_kuis` varchar(150) NOT NULL,
  `jumlah_pertanyaan` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `minat_anak`
--

CREATE TABLE `minat_anak` (
  `id_minat` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `id_kategori` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `misi`
--

CREATE TABLE `misi` (
  `id_misi` int(11) NOT NULL,
  `judul_misi` varchar(150) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `target` int(11) NOT NULL,
  `hadiah_poin` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `pengguna`
--

CREATE TABLE `pengguna` (
  `id_pengguna` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `kata_sandi` varchar(255) NOT NULL,
  `peran` enum('orang_tua','admin') NOT NULL DEFAULT 'orang_tua',
  `tanggal_dibuat` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `percobaan_kuis`
--

CREATE TABLE `percobaan_kuis` (
  `id_percobaan` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `id_kuis` int(11) NOT NULL,
  `nomor_percobaan` int(11) NOT NULL,
  `nilai` int(11) NOT NULL DEFAULT 0,
  `waktu_selesai` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `pertanyaan`
--

CREATE TABLE `pertanyaan` (
  `id_pertanyaan` int(11) NOT NULL,
  `id_kuis` int(11) NOT NULL,
  `isi_pertanyaan` text NOT NULL,
  `jawaban_benar` varchar(255) NOT NULL,
  `jawaban_salah_1` varchar(255) NOT NULL,
  `jawaban_salah_2` varchar(255) NOT NULL,
  `jawaban_salah_3` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `progres_membaca`
--

CREATE TABLE `progres_membaca` (
  `id_progres` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `id_buku` int(11) NOT NULL,
  `halaman_terakhir` int(11) NOT NULL DEFAULT 1,
  `status` enum('sedang_dibaca','selesai') DEFAULT 'sedang_dibaca',
  `terakhir_diperbarui` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `progres_misi`
--

CREATE TABLE `progres_misi` (
  `id_progres_misi` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `id_misi` int(11) NOT NULL,
  `progres_saat_ini` int(11) NOT NULL DEFAULT 0,
  `status` enum('berlangsung','selesai') DEFAULT 'berlangsung',
  `tanggal_selesai` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `transaksi_poin`
--

CREATE TABLE `transaksi_poin` (
  `id_transaksi` int(11) NOT NULL,
  `id_anak` int(11) NOT NULL,
  `jumlah_poin` int(11) NOT NULL,
  `jenis_transaksi` enum('diperoleh','digunakan') NOT NULL,
  `keterangan` text DEFAULT NULL,
  `tanggal_transaksi` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `anak`
--
ALTER TABLE `anak`
  ADD PRIMARY KEY (`id_anak`),
  ADD KEY `id_pengguna` (`id_pengguna`);

--
-- Indeks untuk tabel `buku`
--
ALTER TABLE `buku`
  ADD PRIMARY KEY (`id_buku`),
  ADD KEY `id_kategori` (`id_kategori`);

--
-- Indeks untuk tabel `buku_dibuka`
--
ALTER TABLE `buku_dibuka`
  ADD PRIMARY KEY (`id_pembukaan`),
  ADD UNIQUE KEY `id_anak` (`id_anak`,`id_buku`),
  ADD KEY `id_buku` (`id_buku`);

--
-- Indeks untuk tabel `halaman_buku`
--
ALTER TABLE `halaman_buku`
  ADD PRIMARY KEY (`id_halaman`),
  ADD UNIQUE KEY `id_buku` (`id_buku`,`nomor_halaman`);

--
-- Indeks untuk tabel `kategori`
--
ALTER TABLE `kategori`
  ADD PRIMARY KEY (`id_kategori`);

--
-- Indeks untuk tabel `kuis`
--
ALTER TABLE `kuis`
  ADD PRIMARY KEY (`id_kuis`),
  ADD KEY `id_buku` (`id_buku`);

--
-- Indeks untuk tabel `minat_anak`
--
ALTER TABLE `minat_anak`
  ADD PRIMARY KEY (`id_minat`),
  ADD UNIQUE KEY `id_anak` (`id_anak`,`id_kategori`),
  ADD KEY `id_kategori` (`id_kategori`);

--
-- Indeks untuk tabel `misi`
--
ALTER TABLE `misi`
  ADD PRIMARY KEY (`id_misi`);

--
-- Indeks untuk tabel `pengguna`
--
ALTER TABLE `pengguna`
  ADD PRIMARY KEY (`id_pengguna`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indeks untuk tabel `percobaan_kuis`
--
ALTER TABLE `percobaan_kuis`
  ADD PRIMARY KEY (`id_percobaan`),
  ADD UNIQUE KEY `id_anak` (`id_anak`,`id_kuis`,`nomor_percobaan`),
  ADD KEY `id_kuis` (`id_kuis`);

--
-- Indeks untuk tabel `pertanyaan`
--
ALTER TABLE `pertanyaan`
  ADD PRIMARY KEY (`id_pertanyaan`),
  ADD KEY `id_kuis` (`id_kuis`);

--
-- Indeks untuk tabel `progres_membaca`
--
ALTER TABLE `progres_membaca`
  ADD PRIMARY KEY (`id_progres`),
  ADD UNIQUE KEY `id_anak` (`id_anak`,`id_buku`),
  ADD KEY `id_buku` (`id_buku`);

--
-- Indeks untuk tabel `progres_misi`
--
ALTER TABLE `progres_misi`
  ADD PRIMARY KEY (`id_progres_misi`),
  ADD UNIQUE KEY `id_anak` (`id_anak`,`id_misi`),
  ADD KEY `id_misi` (`id_misi`);

--
-- Indeks untuk tabel `transaksi_poin`
--
ALTER TABLE `transaksi_poin`
  ADD PRIMARY KEY (`id_transaksi`),
  ADD KEY `id_anak` (`id_anak`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `anak`
--
ALTER TABLE `anak`
  MODIFY `id_anak` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `buku`
--
ALTER TABLE `buku`
  MODIFY `id_buku` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `buku_dibuka`
--
ALTER TABLE `buku_dibuka`
  MODIFY `id_pembukaan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `halaman_buku`
--
ALTER TABLE `halaman_buku`
  MODIFY `id_halaman` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `kategori`
--
ALTER TABLE `kategori`
  MODIFY `id_kategori` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `kuis`
--
ALTER TABLE `kuis`
  MODIFY `id_kuis` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `minat_anak`
--
ALTER TABLE `minat_anak`
  MODIFY `id_minat` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `misi`
--
ALTER TABLE `misi`
  MODIFY `id_misi` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `pengguna`
--
ALTER TABLE `pengguna`
  MODIFY `id_pengguna` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `percobaan_kuis`
--
ALTER TABLE `percobaan_kuis`
  MODIFY `id_percobaan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `pertanyaan`
--
ALTER TABLE `pertanyaan`
  MODIFY `id_pertanyaan` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `progres_membaca`
--
ALTER TABLE `progres_membaca`
  MODIFY `id_progres` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `progres_misi`
--
ALTER TABLE `progres_misi`
  MODIFY `id_progres_misi` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `transaksi_poin`
--
ALTER TABLE `transaksi_poin`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `anak`
--
ALTER TABLE `anak`
  ADD CONSTRAINT `anak_ibfk_1` FOREIGN KEY (`id_pengguna`) REFERENCES `pengguna` (`id_pengguna`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `buku`
--
ALTER TABLE `buku`
  ADD CONSTRAINT `buku_ibfk_1` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`) ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `buku_dibuka`
--
ALTER TABLE `buku_dibuka`
  ADD CONSTRAINT `buku_dibuka_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `buku_dibuka_ibfk_2` FOREIGN KEY (`id_buku`) REFERENCES `buku` (`id_buku`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `halaman_buku`
--
ALTER TABLE `halaman_buku`
  ADD CONSTRAINT `halaman_buku_ibfk_1` FOREIGN KEY (`id_buku`) REFERENCES `buku` (`id_buku`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `kuis`
--
ALTER TABLE `kuis`
  ADD CONSTRAINT `kuis_ibfk_1` FOREIGN KEY (`id_buku`) REFERENCES `buku` (`id_buku`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `minat_anak`
--
ALTER TABLE `minat_anak`
  ADD CONSTRAINT `minat_anak_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `minat_anak_ibfk_2` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `percobaan_kuis`
--
ALTER TABLE `percobaan_kuis`
  ADD CONSTRAINT `percobaan_kuis_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `percobaan_kuis_ibfk_2` FOREIGN KEY (`id_kuis`) REFERENCES `kuis` (`id_kuis`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `pertanyaan`
--
ALTER TABLE `pertanyaan`
  ADD CONSTRAINT `pertanyaan_ibfk_1` FOREIGN KEY (`id_kuis`) REFERENCES `kuis` (`id_kuis`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `progres_membaca`
--
ALTER TABLE `progres_membaca`
  ADD CONSTRAINT `progres_membaca_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `progres_membaca_ibfk_2` FOREIGN KEY (`id_buku`) REFERENCES `buku` (`id_buku`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `progres_misi`
--
ALTER TABLE `progres_misi`
  ADD CONSTRAINT `progres_misi_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `progres_misi_ibfk_2` FOREIGN KEY (`id_misi`) REFERENCES `misi` (`id_misi`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `transaksi_poin`
--
ALTER TABLE `transaksi_poin`
  ADD CONSTRAINT `transaksi_poin_ibfk_1` FOREIGN KEY (`id_anak`) REFERENCES `anak` (`id_anak`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
