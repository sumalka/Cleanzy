import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'Customer';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Define _isLoading to control loading state

  void _showError(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 15,
            right: 15,
            child: Material(
              color: const Color.fromARGB(0, 255, 255, 255),
              child: Center(
                child: Card(
                  color: const Color.fromARGB(
                    255,
                    255,
                    255,
                    255,
                  ).withAlpha((0.8 * 255).toInt()),

                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/sad face.json',
                          height: 150,
                          repeat: false,
                          reverse: false,
                          animate: true,
                        ),
                        SizedBox(width: 1),
                        Center(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: const Color.fromARGB(255, 88, 86, 86),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    // Insert the overlay entry into the overlay
    overlay.insert(overlayEntry);

    // Remove the overlay entry after a certain delay (e.g., 3 seconds)
    Future.delayed(Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  Future<void> _signupUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _navigateToLogin(context);
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';

      // Check for specific Firebase Auth error codes
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage =
                'The password is too weak. Please use a stronger password.';
            break;
          case 'email-already-in-use':
            errorMessage =
                'The email is already in use. Please use a different email address.';
            break;
          case 'invalid-email':
            errorMessage =
                'The email format is invalid. Please enter a valid email.';
            break;
          default:
            errorMessage = 'An unknown error occurred. Please try again later.';
        }
      }

      _showError(errorMessage); // Show the user-friendly error message
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner after process completes
      });
    }
  }

  void _navigateToLogin(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Up Successful'),
            content: const Text('Your account has been created successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters long';
    if (!RegExp(
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{6,}$',
    ).hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter your email';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Enter your full name';
    return null;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // Match login page background
      body: Stack(
        // Add Stack to overlay loading animation
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation (Same as Login Page)
                  Lottie.asset(
                    'assets/signup.json', // Update path as needed
                    height: 180,
                  ),
                  const SizedBox(height: 0),
                  // Signup Container with 3D effect and similar styling to Login
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 0, bottom: 0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ).withAlpha((0.8 * 255).toInt()),
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.15 * 255).toInt()),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Transform.rotate(
                            angle: 0,
                            child: Text(
                              'Signup',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cursive',
                                color: const Color.fromARGB(255, 90, 91, 91),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 62, 61, 61),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 62, 61, 61),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 10),
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 62, 61, 61),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 62, 61, 61),
                              ),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 10),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 62, 61, 61),
                            ),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 62, 61, 61),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.grey,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 10),
                          // Role Selection Dropdown
                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(
                                Icons.people,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.green,
                            ),
                            iconSize: 30,
                            items:
                                ['Customer', 'Cleaner'].map((role) {
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 68, 67, 67),
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (value) => setState(() => _role = value!),
                            dropdownColor: const Color.fromARGB(
                              255,
                              240,
                              240,
                              240,
                            ),
                            elevation: 2,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Signup Button (Matching the Login Page Style)
                          GestureDetector(
                            onTap: () => _signupUser(context),
                            child: AnimatedContainer(
                              width: 260,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF66BB6A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withAlpha(
                                      (0.5 * 255).toInt(),
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child:
                                //_isLoading
                                // ? Lottie.asset(
                                //   'assets/female cleaning.json', // Path to your Lottie animation
                                //   width: 250,
                                //   height: 250,
                                //   repeat:
                                //       true, // Set to true if you want it to loop
                                // )
                                //: const
                                Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Login Navigation (Styled similarly to Login page)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 101, 99, 99),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 101, 99, 99),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Show loading animation and text when _isLoading is true
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withAlpha((0.8 * 255).toInt()),
                child: Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Stack animation and text vertically
                    children: [
                      Lottie.asset(
                        'assets/female cleaning.json', // Path to your loading JSON file
                        width: 250, // Adjust the size of the animation
                        height: 250,
                        repeat: true, // Set to true if you want it to loop
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please Wait...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(
                            255,
                            97,
                            95,
                            95,
                          ).withAlpha((0.6 * 255).toInt()),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Input Decoration Method (Matches Login Page)
}
