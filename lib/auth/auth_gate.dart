import 'package:flutter/material.dart';
import 'package:conecta_mais/screens/pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:conecta_mais/auth/auth_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const HomePage();
      },
    );
  }
}
