import 'package:cleaning_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:firebase_core/firebase_core.dart';
import 'dart:math'; // For generating random code
import 'package:google_fonts/google_fonts.dart'; // For Google Fonts
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CustomerDashboard(),
    );
  }
}

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _profileImageUrl;
  // ignore: unused_field
  String? _fullName;
  // ignore: unused_field
  String? _email;
  late AnimationController _glitterController;

  final List<Widget> _pages = [const HomePage()];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          // Check if the widget is still mounted before calling setState
          setState(() {
            _profileImageUrl = data?['profileImageUrl'];
            _fullName =
                data?['name'] ?? 'Unknown'; // Changed from 'fullName' to 'name'
            _email = data?['email'] ?? 'No Email';
          });
        }
      }
    }
  }

  // ignore: unused_element
  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) => _loadUserProfile());
  }

  @override
  void dispose() {
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65), // Set your custom height here
        child: AppBar(
          elevation: 12, // Enhanced elevation for stronger 3D feel
          shadowColor: const Color.fromARGB(
            255,
            176,
            176,
            178,
          ).withOpacity(0.4), // Softer shadow for depth
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(22),
            ), // Slightly smoother curve
          ),
          title: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Cleanzy',
                style: GoogleFonts.pacifico(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 227, 18, 91),
                  shadows: [
                    Shadow(
                      blurRadius: 6.0, // More blur for a deeper effect
                      color: const Color.fromARGB(
                        255,
                        133,
                        130,
                        130,
                      ).withOpacity(0.3), // Stronger shadow for 3D illusion
                      offset: Offset(3, 4), // Slightly bigger offset
                    ),
                    Shadow(
                      blurRadius: 4.2,
                      color: Colors.white.withOpacity(
                        0.5,
                      ), // Highlight effect for glow
                      offset: Offset(-2, -2),
                    ),
                  ],
                ).copyWith(fontFamilyFallback: ['Roboto']),
              ),
              ...List.generate(
                5,
                (index) => Positioned(
                  left: 10.0 * (index - 2) + (index.isEven ? -20 : 20),
                  top: 10.0 * (index % 3) - 10,
                  child: AnimatedBuilder(
                    animation: _glitterController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _glitterController,
                            curve: Interval(
                              index * 0.2,
                              (index + 1) * 0.2,
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.star,
                          size: 12.0,
                          color: Colors.yellow.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon:
                    _profileImageUrl != null
                        ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, // Make the border circular
                            border: Border.all(
                              color: const Color.fromARGB(255, 90, 87, 87),
                              width: 2,
                            ), // Gray border
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(_profileImageUrl!),
                          ),
                        )
                        : const Icon(Icons.person, size: 45),
                onPressed: () => _navigateToProfile(context),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
    );
  }

  //
}

//

class ReusableBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ReusableBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          label: 'Credits',
        ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getCleaningRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('cleaning_requests')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _navigateToCategoryForm(BuildContext context, String category) async {
    if (category == 'Cleaning') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CleaningFormPage()),
      );
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your cleaning request has been submitted successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteRequest(BuildContext context, String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Request'),
            content: const Text(
              'Are you sure you want to delete this request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await _firestore.collection('cleaning_requests').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Request deleted successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          SingleChildScrollView(
            // ✅ Enables full-page scrolling
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12), // Placeholder for FAB height
                Padding(
                  padding: const EdgeInsets.only(left: 13),
                  child: const Text(
                    'My Requests',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: getCleaningRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading requests.'),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No cleaning requests yet.'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true, // ✅ Makes it fit inside Column
                      physics:
                          const NeverScrollableScrollPhysics(), // ✅ Prevents nested scrolling issues
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var request =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        var docId = snapshot.data!.docs[index].id;
                        String displayStatus =
                            request['status'] == 'accepted_pending_customer'
                                ? 'Awaiting Your Approval'
                                : request['status'] ?? 'Pending';

                        return SizedBox(
                          height: 130,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8.0),
                              leading:
                                  request['images'] != null &&
                                          (request['images'] as List).isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          request['images'][0],
                                          width: 60,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                              title: Text(
                                'Request from you',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${request['date'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (request['status'] == 'accepted')
                                    Text(
                                      'Cleaner: ${request['cleaner_name'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (request['cancellation_reason'] != null)
                                    Text(
                                      'Cancelled: ${request['cancellation_reason']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  if (request['status'] == 'completed' &&
                                      request['verification_code'] != null)
                                    Text(
                                      'Code: ${request['verification_code']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  Text(
                                    'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.pink[700],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        displayStatus,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (request['status'] == 'pending')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => _deleteRequest(
                                                context,
                                                docId,
                                              ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RequestDetailsScreen(
                                            requestDocumentId: docId,
                                            requestData: request,
                                          ),
                                    ),
                                  ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 1,
            child: _buildCategory(context, 'Cleaning', 'assets/cleaning.json'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String title,
    String lottieAsset,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Circular Text Around FAB
        Positioned(
          child: Transform.rotate(
            angle: 0, // Adjust the rotation slightly for better alignment
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Text(
                "ADD REQUEST",
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 74, 75, 74),
                ),
              ),
            ),
          ),
        ),
        // Floating Action Button with Lottie Animation
        FloatingActionButton(
          onPressed: () => _navigateToCategoryForm(context, title),
          backgroundColor: const Color.fromARGB(255, 123, 129, 122),
          elevation: 1.0, // Adds shadow for floating effect
          shape: const CircleBorder(), // ✅ Makes the button circular
          child: SizedBox(
            width: 400,
            height: 400,
            child: Lottie.asset(
              lottieAsset, // ✅ Use JSON animation instead of icon
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ],
    );
  }

  //
}

class RequestDetailsScreen extends StatelessWidget {
  final String requestDocumentId;
  final Map<String, dynamic> requestData;

  const RequestDetailsScreen({
    super.key,
    required this.requestDocumentId,
    required this.requestData,
  });

  String _createVerificationCode() {
    const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random randomGenerator = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) =>
            characters.codeUnitAt(randomGenerator.nextInt(characters.length)),
      ),
    );
  }

  Future<void> _setRequestAsCompleted(BuildContext screenContext) async {
    try {
      await FirebaseFirestore.instance
          .collection('cleaning_requests')
          .doc(requestDocumentId)
          .update({
            'status': 'completed',
            'completion_timestamp': FieldValue.serverTimestamp(),
            'price': requestData['price'],
          });
      ScaffoldMessenger.of(screenContext).showSnackBar(
        const SnackBar(
          content: Text('Request marked as completed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(screenContext);
    } catch (error) {
      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(
          content: Text('Failed to mark request as completed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelCleaningRequest(BuildContext screenContext) async {
    await showDialog(
      context: screenContext,
      builder:
          (dialogContext) => CancellationReasonDialog(
            onConfirmCancellation: (reason) async {
              try {
                final assignedCleanerId = requestData['cleaner_id'];
                await FirebaseFirestore.instance
                    .collection('cleaning_requests')
                    .doc(requestDocumentId)
                    .update({
                      'status': 'pending',
                      'cleaner_id': null,
                      'cleaner_name': null,
                      'cleaner_details': null,
                      'cancellation_reason': reason,
                      'cancelled_by': FirebaseAuth.instance.currentUser?.uid,
                      'cancellation_timestamp': FieldValue.serverTimestamp(),
                      'previous_cleaner_ids':
                          assignedCleanerId != null
                              ? FieldValue.arrayUnion([assignedCleanerId])
                              : FieldValue.arrayUnion([]),
                    });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  const SnackBar(
                    content: Text('Request canceled and made available again'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(screenContext);
              } catch (error) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel request: $error'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
    );
  }

  Future<void> _approveAssignedCleaner(BuildContext screenContext) async {
    try {
      final generatedCode =
          _createVerificationCode(); // Generate code once here
      await FirebaseFirestore.instance
          .collection('cleaning_requests')
          .doc(requestDocumentId)
          .update({
            'status': 'accepted',
            'verification_code': generatedCode, // Store code in Firestore
          });
      ScaffoldMessenger.of(screenContext).showSnackBar(
        const SnackBar(
          content: Text('Cleaner approved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(screenContext);
    } catch (error) {
      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(
          content: Text('Failed to approve cleaner: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _rejectAssignedCleaner(BuildContext screenContext) async {
    await showDialog(
      context: screenContext,
      builder:
          (dialogContext) => CancellationReasonDialog(
            onConfirmCancellation: (reason) async {
              try {
                final assignedCleanerId = requestData['cleaner_id'];
                await FirebaseFirestore.instance
                    .collection('cleaning_requests')
                    .doc(requestDocumentId)
                    .update({
                      'status': 'pending',
                      'cleaner_id': null,
                      'cleaner_name': null,
                      'cleaner_details': null,
                      'cancellation_reason': reason,
                      'cancelled_by': FirebaseAuth.instance.currentUser?.uid,
                      'cancellation_timestamp': FieldValue.serverTimestamp(),
                      'previous_cleaner_ids': FieldValue.arrayUnion([
                        assignedCleanerId,
                      ]),
                    });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cleaner rejected, request is available again',
                    ),
                    backgroundColor: Color.fromARGB(255, 76, 199, 80),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(screenContext);
              } catch (error) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reject cleaner: $error'),
                    backgroundColor: const Color.fromARGB(255, 170, 69, 62),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
    );
  }
  //
  //

  @override
  Widget build(BuildContext screenContext) {
    String requestStatusDisplay =
        requestData['status'] == 'accepted_pending_customer'
            ? 'Awaiting Your Approval'
            : requestData['status'] ?? 'Pending';
    final cleanerInfo = requestData['cleaner_details'] as Map<String, dynamic>?;

    final deviceWidth = MediaQuery.of(screenContext).size.width;
    final isSmallDevice = deviceWidth < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 12, // Enhanced elevation for stronger 3D feel
        shadowColor: const Color.fromARGB(
          255,
          176,
          176,
          178,
        ).withOpacity(0.4), // Softer shadow for depth
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(22),
          ), // Slightly smoother curve
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: Color.fromARGB(255, 87, 87, 88),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallDevice ? 12.0 : 20.0),
          child: Center(
            // Centering the content inside the body
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _displaySectionTitle('House Details')),
                  const SizedBox(height: 12),
                  Center(
                    child: _displayHouseImages(
                      requestData['images'] as List<dynamic>? ?? [],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Adding a Card for 3D effect
                  Card(
                    elevation: 8, // 3D shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _displayInfoRow('Name', requestData['name'] ?? 'N/A'),
                          _displayInfoRow(
                            'Address',
                            requestData['address'] ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Rooms',
                            requestData['rooms']?.toString() ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Bathrooms',
                            requestData['bathrooms']?.toString() ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Living Rooms',
                            requestData['living_rooms']?.toString() ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Flooring Type',
                            requestData['flooring_type'] ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Service Date',
                            requestData['date'] ?? 'N/A',
                          ),
                          _displayInfoRow(
                            'Status',
                            requestStatusDisplay,
                            isBold: true,
                          ),
                          _displayInfoRow(
                            'Price',
                            '\$${requestData['price']?.toStringAsFixed(2) ?? 'N/A'}',
                            textColor: Colors.pink[700],
                            isBold: true,
                          ),
                          if (requestData['status'] == 'accepted' &&
                              requestData['cleaner_name'] != null)
                            _displayInfoRow(
                              'Accepted by',
                              requestData['cleaner_name'],
                              isBold: true,
                            ),
                          if ((requestData['status'] == 'accepted' ||
                                  requestData['status'] == 'completed') &&
                              requestData['verification_code'] != null)
                            _displayInfoRow(
                              'Verification Code',
                              requestData['verification_code'],
                              textColor: Colors.green,
                              isBold: true,
                            ),
                          if (requestData['cancellation_reason'] != null)
                            _displayInfoRow(
                              'Cancellation Reason',
                              requestData['cancellation_reason'],
                              textColor: Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (requestData['status'] == 'accepted_pending_customer' ||
                      requestData['status'] == 'accepted' ||
                      requestData['status'] == 'completed') ...[
                    _displaySectionTitle('Cleaner Details'),
                    const SizedBox(height: 12),
                    if (cleanerInfo != null) ...[
                      if (cleanerInfo['profileImageUrl'] != null)
                        Center(
                          // Added Center widget to center the image
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                            ), // Adjusted padding for symmetry
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                cleanerInfo['profileImageUrl'],
                                width: isSmallDevice ? 100 : 120,
                                height: isSmallDevice ? 100 : 120,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.error,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      _displayDetailsContainer([
                        _displayInfoRow(
                          'Name',
                          cleanerInfo['fullName'] ?? 'N/A',
                        ),
                        _displayInfoRow(
                          'Age',
                          cleanerInfo['age']?.toString() ?? 'N/A',
                        ),
                        _displayInfoRow(
                          'Gender',
                          cleanerInfo['gender'] ?? 'N/A',
                        ),
                        _displayInfoRow('Email', cleanerInfo['email'] ?? 'N/A'),
                        _displayInfoRow(
                          'Phone Number',
                          cleanerInfo['phoneNumber'] ?? 'N/A',
                        ),
                        _displayInfoRow(
                          'Experience',
                          cleanerInfo['experience'] ?? 'N/A',
                        ),
                      ]),
                    ] else
                      const Center(
                        child: Text(
                          'Cleaner details not available.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  if (requestData['status'] == 'accepted_pending_customer')
                    _displayActionButtons(
                      screenContext,
                      approveHandler:
                          () => _approveAssignedCleaner(screenContext),
                      rejectHandler:
                          () => _rejectAssignedCleaner(screenContext),
                    ),
                  if (requestData['status'] == 'accepted')
                    _displayActionButtons(
                      screenContext,
                      completeHandler:
                          () => _setRequestAsCompleted(screenContext),
                      cancelHandler:
                          () => _cancelCleaningRequest(screenContext),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //
  //
  Widget _displaySectionTitle(String sectionTitle) {
    return Center(
      // Centers the text
      child: Text(
        sectionTitle,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 99, 100, 103),
          shadows: [
            Shadow(
              blurRadius: 10.0, // Creates a shadow effect
              color: Colors.black26, // Color and opacity of shadow
              offset: Offset(2, 2), // Position of the shadow
            ),
          ],
        ),
      ),
    );
  }

  //
  //
  Widget _displayHouseImages(List<dynamic> houseImages) {
    if (houseImages.isEmpty) {
      return const Center(
        child: Text(
          'No images available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: Center(
        // Added Center widget to center the ListView horizontally
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: houseImages.length,
          shrinkWrap:
              true, // Ensures the ListView takes only the space it needs
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Image.network(
                    houseImages[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.error,
                          size: 50,
                          color: Colors.grey,
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //
  Widget _displayDetailsContainer(List<Widget> detailRows) {
    return Center(
      // Center the card on the screen
      child: Card(
        elevation: 8, // Increased elevation for a more noticeable shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detailRows,
          ),
        ),
      ),
    );
  }

  Widget _displayInfoRow(
    String infoLabel,
    String infoValue, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Center(
        // Center the content horizontally
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$infoLabel: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  shadows: [
                    // Add shadow for 3D effect
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black12,

                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: infoValue,
                style: TextStyle(
                  color: textColor ?? const Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  shadows: [
                    // Add shadow for 3D effect
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.grey.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayActionButtons(
    BuildContext screenContext, {
    VoidCallback? approveHandler,
    VoidCallback? rejectHandler,
    VoidCallback? completeHandler,
    VoidCallback? cancelHandler,
  }) {
    final deviceWidth = MediaQuery.of(screenContext).size.width;
    final isSmallDevice = deviceWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (approveHandler != null)
            _buildCustomButton(
              screenContext,
              'Accept',
              approveHandler,
              const Color.fromARGB(255, 76, 152, 175),
              isSmallDevice ? 120 : 150,
            ),
          if (rejectHandler != null)
            _buildCustomButton(
              screenContext,
              'Reject',
              rejectHandler,
              const Color.fromARGB(255, 180, 86, 79),
              isSmallDevice ? 120 : 150,
            ),
          if (completeHandler != null)
            _buildCustomButton(
              screenContext,
              'Complete',
              completeHandler,
              const Color.fromARGB(255, 76, 162, 175),
              isSmallDevice ? 120 : 150,
            ),
          if (cancelHandler != null) ...[
            const SizedBox(width: 20.0), // Add a gap between buttons
            _buildCustomButton(
              screenContext,
              'Cancel',
              cancelHandler,
              const Color.fromARGB(255, 190, 87, 80),
              isSmallDevice ? 120 : 150,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomButton(
    BuildContext buttonContext,
    String buttonLabel,
    VoidCallback buttonAction,
    Color buttonColor,
    double buttonWidth,
  ) {
    return SizedBox(
      width: buttonWidth, // Fixed width for consistent sizing
      child: ElevatedButton(
        onPressed: buttonAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4, // Add shadow for a raised effect
        ),
        child: Text(
          buttonLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class CancellationReasonDialog extends StatefulWidget {
  final Function(String) onConfirmCancellation;

  const CancellationReasonDialog({
    super.key,
    required this.onConfirmCancellation,
  });

  @override
  _CancellationReasonDialogState createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<CancellationReasonDialog> {
  final TextEditingController cancellationReasonController =
      TextEditingController();

  @override
  Widget build(BuildContext dialogContext) {
    return AlertDialog(
      title: const Text('Cancel Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for cancellation:'),
          const SizedBox(height: 12),
          TextField(
            controller: cancellationReasonController,
            decoration: InputDecoration(
              hintText: 'Enter reason',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (cancellationReasonController.text.isNotEmpty) {
              widget.onConfirmCancellation(cancellationReasonController.text);
            } else {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a reason'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    cancellationReasonController.dispose();
    super.dispose();
  }
}

class CleaningFormPage extends StatefulWidget {
  const CleaningFormPage({super.key});

  @override
  _CleaningFormPageState createState() => _CleaningFormPageState();
}

class _CleaningFormPageState extends State<CleaningFormPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<XFile> _houseImages = [];
  bool _isUploading = false;
  bool _imageUploadFailed = false;
  int? _selectedRooms;
  int? _selectedBathrooms;
  int? _selectedLivingRooms;
  String? _selectedFlooringType;

  final List<int> _roomOptions = List.generate(10, (index) => index + 1);
  final List<int> _bathroomOptions = List.generate(10, (index) => index + 1);
  final List<int> _livingRoomOptions = List.generate(5, (index) => index + 1);
  final List<String> _flooringTypes = ['Carpet', 'Hardwood', 'Tile', 'Vinyl'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(
        () => _dateController.text = "${picked.toLocal()}".split(' ')[0],
      );
    }
  }

  double _calculatePrice() {
    const double basePrice = 50.0;
    const double roomRate = 20.0;
    const double bathroomRate = 25.0;
    const double livingRoomRate = 30.0;
    Map<String, double> flooringMultipliers = {
      'Carpet': 1.2,
      'Hardwood': 1.0,
      'Tile': 1.1,
      'Vinyl': 1.0,
    };
    double totalPrice = basePrice;
    totalPrice += (_selectedRooms ?? 0) * roomRate;
    totalPrice += (_selectedBathrooms ?? 0) * bathroomRate;
    totalPrice += (_selectedLivingRooms ?? 0) * livingRoomRate;
    totalPrice *= flooringMultipliers[_selectedFlooringType] ?? 1.0;
    return totalPrice;
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    if (_houseImages.isEmpty) return imageUrls;
    for (var image in _houseImages) {
      try {
        String imageUrl =
            kIsWeb
                ? await _uploadToCloudinaryWeb(await image.readAsBytes())
                : await _uploadToCloudinaryMobile(File(image.path));
        imageUrls.add(imageUrl);
      } catch (e) {
        setState(() => _imageUploadFailed = true);
      }
    }
    return imageUrls;
  }

  Future<String> _uploadToCloudinaryWeb(List<int> imageBytes) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';
    final request =
        http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = 'house_images'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: 'house.jpg',
            ),
          );
    final response = await request.send();
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString())['secure_url'];
    }
    throw Exception('Failed to upload image on web');
  }

  Future<String> _uploadToCloudinaryMobile(File file) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';
    final request =
        http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = 'house_images'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString())['secure_url'];
    }
    throw Exception('Failed to upload image on mobile');
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && mounted) {
      setState(() => _houseImages.addAll(pickedFiles));
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      _isLoading = true; // Show loading indicator
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not logged in');
        final imageUrls = await _uploadImages();
        if (_imageUploadFailed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Some images failed to upload, but request will proceed.',
              ),
            ),
          );
        }
        final price = _calculatePrice();
        final requestData = {
          'user_id': user.uid,
          'name': _nameController.text,
          'address': _addressController.text,
          'rooms': _selectedRooms,
          'bathrooms': _selectedBathrooms,
          'living_rooms': _selectedLivingRooms,
          'flooring_type': _selectedFlooringType,
          'date': _dateController.text,
          'additional_notes': _additionalNotesController.text,
          'images': imageUrls,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'price': price,
          'previous_cleaner_ids': [],
        };
        await FirebaseFirestore.instance
            .collection('cleaning_requests')
            .add(requestData);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting request: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 12, // Enhanced elevation for stronger 3D feel
        shadowColor: const Color.fromARGB(
          255,
          176,
          176,
          178,
        ).withOpacity(0.4), // Softer shadow for depth
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(22),
          ), // Slightly smoother curve
        ),
        title: const Text(
          'Service Request',
          style: TextStyle(
            color: Color.fromARGB(255, 87, 87, 88),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        centerTitle: true,
      ),
      body:
          _isUploading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Request a Cleaning Service',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 87, 87, 88),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter your name'
                                      : null,
                        ),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please enter your address'
                                      : null,
                        ),
                        _buildDropdownField<int>(
                          label: 'Number of Rooms',
                          value: _selectedRooms,
                          items: _roomOptions,
                          onChanged:
                              (value) => setState(() => _selectedRooms = value),
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select number of rooms'
                                      : null,
                        ),
                        _buildDropdownField<int>(
                          label: 'Number of Bathrooms',
                          value: _selectedBathrooms,
                          items: _bathroomOptions,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedBathrooms = value),
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select number of bathrooms'
                                      : null,
                        ),
                        _buildDropdownField<int>(
                          label: 'Number of Living Rooms',
                          value: _selectedLivingRooms,
                          items: _livingRoomOptions,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedLivingRooms = value),
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select number of living rooms'
                                      : null,
                        ),
                        _buildDropdownField<String>(
                          label: 'Flooring Type',
                          value: _selectedFlooringType,
                          items: _flooringTypes,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedFlooringType = value),
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Please select flooring type'
                                      : null,
                        ),
                        _buildTextField(
                          controller: _dateController,
                          label: 'Service Date',
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Please select a date'
                                      : null,
                        ),
                        _buildTextField(
                          controller: _additionalNotesController,
                          label: 'Additional Notes (Optional)',
                          maxLines: 3,
                          isRequired: false,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Upload House Images (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Pick Images',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              33,
                              243,
                              54,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _houseImages.isNotEmpty
                            ? SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _houseImages.length,
                                itemBuilder:
                                    (context, index) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child:
                                          kIsWeb
                                              ? FutureBuilder<Uint8List>(
                                                future:
                                                    _houseImages[index]
                                                        .readAsBytes(),
                                                builder:
                                                    (context, snapshot) =>
                                                        snapshot.hasData
                                                            ? Image.memory(
                                                              snapshot.data!,
                                                              width: 100,
                                                              height: 100,
                                                              fit: BoxFit.cover,
                                                            )
                                                            : const CircularProgressIndicator(),
                                              )
                                              : Image.file(
                                                File(_houseImages[index].path),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                              ),
                            )
                            : const Text(
                              'No images selected.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        const SizedBox(height: 20),
                        Text(
                          'Estimated Price: \$${_calculatePrice().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _isLoading ? null : _submitForm,
                          child: AnimatedContainer(
                            width: 260,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      )
                                      : const Text(
                                        'Submit Request',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color.fromARGB(137, 55, 54, 54)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 98, 99, 100),
              width: 2,
            ),
          ),
        ),
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        validator: isRequired ? validator : null,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 88, 89, 90),
              width: 2,
            ),
          ),
        ),
        value: value,
        items:
            items
                .map(
                  (T item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }
}

class RatingAndReportWidget extends StatefulWidget {
  final String userType;

  const RatingAndReportWidget({super.key, required this.userType});

  @override
  _RatingAndReportWidgetState createState() => _RatingAndReportWidgetState();
}

class _RatingAndReportWidgetState extends State<RatingAndReportWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reportController = TextEditingController();
  double _rating = 0.0;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAverageRating();
  }

  Future<void> _fetchAverageRating() async {
    final ratingsSnapshot = await _firestore.collection('app_ratings').get();
    if (ratingsSnapshot.docs.isNotEmpty) {
      double totalRating = 0.0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc.data()['rating'].toDouble();
      }
      if (mounted) {
        setState(() {
          _averageRating = totalRating / ratingsSnapshot.docs.length;
          _totalReviews = ratingsSnapshot.docs.length;
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _averageRating = 0.0;
        _totalReviews = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRatingAndReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }
    if (_rating == 0.0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a rating.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('app_ratings').add({
        'user_id': user.uid,
        'user_type': widget.userType,
        'rating': _rating,
        'report': _reportController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _fetchAverageRating();
      if (mounted) {
        setState(() {
          _rating = 0.0; // Reset rating after submission
          _reportController.clear(); // Clear report text
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating and report submitted successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting rating: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_totalReviews > 0)
                    Row(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < _averageRating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.yellow,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'based on $_totalReviews reviews',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rate the App',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.yellow,
                          size: 32,
                        ),
                        onPressed:
                            () => setState(
                              () => _rating = (index + 1).toDouble(),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Submit a Report (Optional)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reportController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your feedback or report an issue...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitRatingAndReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Submit Rating & Report',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _fullName, _email, _profileImageUrl;
  late AnimationController _glitterController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _fullName = data?['name'] ?? 'Unknown';
            _email = data?['email'] ?? 'No Email';
            _profileImageUrl = data?['profileImageUrl'];
          });
        }
      }
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    try {
      String imageUrl =
          kIsWeb
              ? await _uploadToCloudinaryWeb(await pickedFile.readAsBytes())
              : await _uploadToCloudinaryMobile(File(pickedFile.path));
      await _updateFirestore(imageUrl);
      setState(() => _profileImageUrl = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  Future<String> _uploadToCloudinaryWeb(List<int> imageBytes) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';
    final request =
        http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = 'profile_images'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: 'upload.jpg',
            ),
          );
    final response = await request.send();
    if (response.statusCode == 200)
      return json.decode(await response.stream.bytesToString())['secure_url'];
    throw Exception('Failed to upload image on web');
  }

  Future<String> _uploadToCloudinaryMobile(File file) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';
    final request =
        http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = 'profile_images'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200)
      return json.decode(await response.stream.bytesToString())['secure_url'];
    throw Exception('Failed to upload image on mobile');
  }

  Future<void> _updateFirestore(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': imageUrl},
      );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 12,
        shadowColor: const Color.fromARGB(255, 176, 176, 178).withOpacity(0.4),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 81, 82, 84),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              color: Color.fromARGB(255, 87, 89, 90),
              size: 30,
            ),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        // Added to handle overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12.0,
                          offset: Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 78, 79, 80),
                          width: 4.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('assets/default_profile.png')
                                    as ImageProvider,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 30),
                      color: const Color(0xFF4CAF50),
                      onPressed: _uploadImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileField('Name', _fullName ?? 'Loading...'),
              _buildProfileField('Email', _email ?? 'Loading...'),
              const SizedBox(height: 24),
              // Integrated RatingAndReportWidget
              const RatingAndReportWidget(userType: 'customer'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
