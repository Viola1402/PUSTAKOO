import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../autentikasi/login.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Selamat datang, Admin Pustakoo!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
