import 'package:flutter/material.dart';
import 'social_auth_service.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => SocialAuthService().signInWithGoogle(context),
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Sign in with Google'),
        ),
      ],
    );
  }
}
