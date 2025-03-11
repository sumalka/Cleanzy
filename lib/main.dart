import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'admin_dashboard.dart';
import 'customer_dashboard.dart';
import 'cleaner_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD6d3sOA5YoXDuIILjoYeVocr4UeKgm3Dg",
        authDomain: "clean-app-11c2b.firebaseapp.com",
        projectId: "clean-app-11c2b",
        storageBucket: "clean-app-11c2b.firebasestorage.app",
        messagingSenderId: "132466580752",
        appId: "1:132466580752:web:bef1cf58d55aae752e5995",
      ),
    );
    GoogleSignIn _ = GoogleSignIn(
      clientId:
          '132466580752-ftug1pd078eil7fqo5v4ubv19g37c6at.apps.googleusercontent.com',
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleanzy',
      routes: {
        '/': (context) => const AuthenticationWrapper(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/customerDashboard': (context) => const CustomerDashboard(),
        '/cleanerDashboard': (context) => const CleanerDashboard(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          } else {
            return FutureBuilder(
              future: _getUserRole(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  String role = snapshot.data!;
                  if (role == 'Admin') {
                    return const AdminDashboard();
                  } else if (role == 'Customer') {
                    return const CustomerDashboard();
                  } else if (role == 'Cleaner') {
                    return const CleanerDashboard();
                  } else {
                    return const LoginScreen(); // Fallback to login
                  }
                } else {
                  return const Center(child: Text('Error fetching user role'));
                }
              },
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<String> _getUserRole(User user) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (userDoc.exists) {
      return userDoc['role'];
    } else {
      throw Exception('User role not found');
    }
  }
}
