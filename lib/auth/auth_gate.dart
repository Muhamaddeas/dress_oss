import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../admin/pages/admin_page.dart';
import '../user/user_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getPageByRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const LoginPage();

    final response = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null || response['role'] == null) {
      return const LoginPage(); 
    }

    final role = response['role'];
    if (role == 'admin') {
      return const AdminDashboard(); 
    } else {
      return const UserPage(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session != null) {
          return FutureBuilder(
            future: _getPageByRole(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.data!;
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
