import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin_dashboard.dart';
import 'customer_dashboard.dart';
import 'cleaner_dashboard.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscureText = true;
  bool _isLoading = false; // Track loading state

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller to control the Lottie animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 5,
      ), // Set to a longer duration than 3 seconds
    )..addListener(() {
      // Pause the animation at the 3rd second
      if (_animationController.value >= 0.6) {
        // 0.6 means the animation is around the 3rd second
        _animationController.stop();
      }
    });
    _animationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _animationController.removeListener(() {}); // Remove listener first
    _animationController.dispose(); // Then dispose of the controller
    super.dispose();
  }

  // This method builds the Lottie animation header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 0,
        bottom: 0,
      ), // Set top and bottom padding to 0
      child: Lottie.asset(
        'assets/welcome.json', // Path to your JSON file
        height: 70, // Adjust this to make the header bigger/smaller
        repeat: false, // Set to false to prevent looping
        controller:
            _animationController, // Use the controller to control animation
        onLoaded: (composition) {
          // Set the controller's duration to the total duration of the animation
          _animationController.duration = composition.duration;
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _navigateToDashboard(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Try again later.';
          break;
        default:
          errorMessage = 'Incorrect Email or Password.';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _navigateToDashboard(userCredential.user!.uid);
    } catch (e) {
      _showError('Google sign-in failed: $e');
    }
  }

  void _navigateToDashboard(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (!mounted) return; // Prevent navigation if widget is disposed

    if (userDoc.exists) {
      String role = userDoc['role'];
      Widget dashboard;
      switch (role) {
        case 'Admin':
          dashboard = const AdminDashboard();
          break;
        case 'Customer':
          dashboard = const CustomerDashboard();
          break;
        case 'Cleaner':
          dashboard = const CleanerDashboard();
          break;
        default:
          _showError('Invalid role. Contact support.');
          return;
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => dashboard),
        );
      }
    } else {
      _showError('User not found. Please sign up.');
    }
  }

  void _showError(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 0,
            right: 0,
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
                    padding: EdgeInsets.all(10),
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
                        Text(
                          message,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 119, 117, 117),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light Theme Background
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(), // Place Lottie animation here
                      Lottie.asset(
                        'assets/login.json', // Your JSON File Path
                        height: 250,
                        repeat: true,
                        reverse: false,
                        animate: true,
                      ),
                      const SizedBox(height: 0), // Adjusted space
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.15 * 255).toInt(),
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                350, // **Increased maxHeight constraint**
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    // Regular expression for basic email validation
                                    final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                    );

                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    if (value.length > 320) {
                                      return 'Email is too long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Colors.grey,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Enter your password'
                                              : null,
                                ),
                                const SizedBox(
                                  height: 0,
                                ), // This space is creating the gap below password
                                // Forgot Password Row
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    bottom: 0,
                                  ), // No Top and Bottom Space
                                  child: TextButton(
                                    onPressed:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ForgotPasswordScreen(),
                                          ),
                                        ),
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets
                                              .zero, // Remove internal TextButton padding
                                      minimumSize: Size(
                                        0,
                                        0,
                                      ), // Remove default button size
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // Make Button Small
                                    ),
                                    child: Align(
                                      alignment:
                                          Alignment
                                              .centerRight, // This will push text to the right side
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _login,
                                  child: AnimatedContainer(
                                    width: 260,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    duration: Duration(
                                      milliseconds: 150,
                                    ), // Smooth scaling animation
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
                                          offset: Offset(
                                            0,
                                            4,
                                          ), // Shadow position for 3D effect
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child:
                                          _isLoading
                                              ? CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              )
                                              : Text(
                                                'Login',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Column(
                                //   mainAxisAlignment: MainAxisAlignment.end,
                                //   children: [
                                //     Row(
                                //       mainAxisAlignment:
                                //           MainAxisAlignment.center,
                                //       children: [
                                //         GestureDetector(
                                //           onTap: _signInWithGoogle,
                                //           child: Row(
                                //             mainAxisAlignment:
                                //                 MainAxisAlignment.center,
                                //             children: [
                                //               const SizedBox(
                                //                 width: 10,
                                //               ), // Space between the logo and text
                                //               const Text(
                                //                 'Sign with',
                                //                 style: TextStyle(
                                //                   fontWeight: FontWeight.w500,
                                //                   fontSize:
                                //                       14, // Same size as SignUp
                                //                   color: Colors.grey,
                                //                 ),
                                //               ),
                                //               const SizedBox(width: 5), //
                                //               Image.asset(
                                //                 'assets/google_logo.png',
                                //                 height: 20,
                                //               ),
                                //             ],
                                //           ),
                                //         ),
                                //         const SizedBox(width: 20), // Space
                                //         Text(
                                //           '|', // Divider Line
                                //           style: TextStyle(
                                //             fontSize: 14,
                                //             color: Colors.grey,
                                //           ),
                                //         ),
                                //         const SizedBox(width: 10),
                                //         TextButton(
                                //           onPressed:
                                //               () => Navigator.push(
                                //                 context,
                                //                 MaterialPageRoute(
                                //                   builder:
                                //                       (context) =>
                                //                           SignupScreen(),
                                //                 ),
                                //               ),
                                //           child: const Text(
                                //             'Sign Up',
                                //             style: TextStyle(
                                //               fontSize: 14,
                                //               color: Colors.grey,
                                //             ),
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ],
                                // ),
                                //
                                //
                                //
                                //
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _signInWithGoogle,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                    ), // Space between the logo and text
                                    const Text(
                                      'Sign in with',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14, // Same size as SignUp
                                        color: Color.fromARGB(255, 82, 81, 81),
                                      ),
                                    ),
                                    const SizedBox(width: 5), //
                                    Image.asset(
                                      'assets/google_logo.png',
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20), // Space
                              Text(
                                '|', // Divider Line
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 63, 62, 62),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignupScreen(),
                                      ),
                                    ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 93, 92, 92),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        MainAxisSize
                            .min, // To ensure the text and animation are stacked vertically
                    children: [
                      // Lottie Animation
                      Lottie.asset(
                        'assets/female cleaning.json', // Path to your loading JSON file
                        width: 250, // Adjust the width as needed
                        height: 250, // Adjust the height as needed
                        repeat: true, // Set to true if you want it to loop
                      ),
                      const SizedBox(
                        height: 0,
                      ), // Space between animation and text
                      // Fancy "Loading" Text
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
                          ).withAlpha(
                            (0.6 * 255).toInt(),
                          ), // You can adjust the color if needed
                          letterSpacing:
                              0.5, // Adjust the letter spacing for a more playful feel
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
}
