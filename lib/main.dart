import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'autentikasi/login.dart';
import 'pengguna/beranda_pengguna.dart';
import 'admin/Dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rzegnujjuuiezcjwwlql.supabase.co',
    publishableKey: 'sb_publishable_tEf-AdHoqb5j-NvVNtaWvQ_gPfGGMKe',
  );

  runApp(const PustakooApp());
}

class PustakooApp extends StatelessWidget {
  const PustakooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pustakoo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

Future<Widget> halamanPengguna() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return const LoginPage();
  }

  final profil = await supabase
      .from('pengguna')
      .select('peran')
      .eq('id', user.id)
      .single();

  if (profil['peran'] == 'admin') {
    return const DashboardAdmin();
  }

  return const BerandaOrangTua();
}
