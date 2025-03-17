import 'package:cleaning_app/cleaner_dashboard.dart';
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
  late AnimationController _glitterController;

  final List<Widget> _pages = [const HomePage(), const CreditsPage()];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        setState(() => _profileImageUrl = userDoc.data()?['profileImageUrl']);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) => _loadProfileImage());
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
        backgroundColor: Colors.white, // Base color for light theme
        elevation: 15, // Increased for stronger 3D effect
        shadowColor: const Color.fromARGB(
          255,
          136,
          133,
          133,
        ).withOpacity(0.1), // Slightly darker shadow for depth
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white, // Top (light source simulation)
                Colors.grey.shade100, // Bottom (subtle depth)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  172,
                  170,
                  170,
                ).withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 2,
                offset: const Offset(0, 4), // Offset for 3D "lifted" effect
              ),
            ],
          ),
        ),
        title: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Cleanzy',
              style: GoogleFonts.greatVibes(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
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
          IconButton(
            icon:
                _profileImageUrl != null
                    ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(
                            255,
                            105,
                            106,
                            105,
                          ), // Green to match your theme
                          width: 2.0, // Border thickness
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(_profileImageUrl!),
                      ),
                    )
                    : const Icon(Icons.person),
            onPressed: () => _navigateToProfile(context),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: ReusableBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _buildCategory(context, 'Cleaning', Icons.cleaning_services),
          ),
          const SizedBox(height: 16),
          Center(
            child: const Text(
              'Cleaning Requests',
              style: TextStyle(
                fontFamily: 'Popins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 56, 55, 55),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCleaningRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return const Center(child: Text('Error loading requests.'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text('No cleaning requests yet.'));
                return ListView.builder(
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RequestDetailsPage(
                                      docId: docId,
                                      request: request,
                                    ),
                              ),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side: Title and Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Request form ${request['name'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 72, 71, 71),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date: ${request['date'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (request['status'] == 'accepted')
                                          Text(
                                            'Cleaner: ${request['cleaner_name'] ?? 'Unknown'}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        if (request['cancellation_reason'] !=
                                            null)
                                          Text(
                                            'Cancelled: ${request['cancellation_reason']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        if (request['status'] == 'completed' &&
                                            request['verification_code'] !=
                                                null)
                                          Text(
                                            'Code: ${request['verification_code']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        Text(
                                          'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.pink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Right side: Image, Status, and Delete Button
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (request['images'] != null &&
                                      (request['images'] as List).isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          request['images'][0],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  if (request['images'] != null &&
                                      (request['images'] as List).isNotEmpty)
                                    const SizedBox(height: 8),
                                  Text(
                                    displayStatus,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          displayStatus == 'completed'
                                              ? Colors.green
                                              : Colors.black,
                                    ),
                                  ),
                                  if (request['status'] == 'pending') ...[
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 24,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _deleteRequest(context, docId),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () => _navigateToCategoryForm(context, title),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, size: 30, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class RequestDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> request;

  const RequestDetailsPage({
    super.key,
    required this.docId,
    required this.request,
  });

  String _generateVerificationCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    try {
      final verificationCode = _generateVerificationCode();
      await FirebaseFirestore.instance
          .collection('cleaning_requests')
          .doc(docId)
          .update({
            'status': 'completed',
            'completion_timestamp': FieldValue.serverTimestamp(),
            'verification_code': verificationCode,
            'price': request['price'],
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request marked as completed')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking request as completed: $e')),
      );
    }
  }

  Future<void> _cancelRequest(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => CancelReasonDialog(
            onConfirm: (reason) async {
              try {
                final currentCleanerId = request['cleaner_id'];
                await FirebaseFirestore.instance
                    .collection('cleaning_requests')
                    .doc(docId)
                    .update({
                      'status': 'pending',
                      'cleaner_id': null,
                      'cleaner_name': null,
                      'cleaner_details': null, // Clear cleaner details
                      'cancellation_reason': reason,
                      'cancelled_by': FirebaseAuth.instance.currentUser?.uid,
                      'cancellation_timestamp': FieldValue.serverTimestamp(),
                      'previous_cleaner_ids':
                          currentCleanerId != null
                              ? FieldValue.arrayUnion([currentCleanerId])
                              : FieldValue.arrayUnion([]),
                    });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request canceled and made available again'),
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error canceling request: $e')),
                );
              }
            },
          ),
    );
  }

  Future<void> _approveCleaner(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('cleaning_requests')
          .doc(docId)
          .update({'status': 'accepted'});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cleaner approved')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving cleaner: $e')));
    }
  }

  Future<void> _rejectCleaner(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => CancelReasonDialog(
            onConfirm: (reason) async {
              try {
                final currentCleanerId = request['cleaner_id'];
                await FirebaseFirestore.instance
                    .collection('cleaning_requests')
                    .doc(docId)
                    .update({
                      'status': 'pending',
                      'cleaner_id': null,
                      'cleaner_name': null,
                      'cleaner_details': null, // Clear cleaner details
                      'cancellation_reason': reason,
                      'cancelled_by': FirebaseAuth.instance.currentUser?.uid,
                      'cancellation_timestamp': FieldValue.serverTimestamp(),
                      'previous_cleaner_ids': FieldValue.arrayUnion([
                        currentCleanerId,
                      ]),
                    });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cleaner rejected, request is available again',
                    ),
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error rejecting cleaner: $e')),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayStatus =
        request['status'] == 'accepted_pending_customer'
            ? 'Awaiting Your Approval'
            : request['status'] ?? 'Pending';
    final cleanerDetails = request['cleaner_details'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Name: ${request['name'] ?? 'N/A'}'),
              Text('Address: ${request['address'] ?? 'N/A'}'),
              Text('Rooms: ${request['rooms'] ?? 'N/A'}'),
              Text('Bathrooms: ${request['bathrooms'] ?? 'N/A'}'),
              Text('Living Rooms: ${request['living_rooms'] ?? 'N/A'}'),
              Text('Flooring Type: ${request['flooring_type'] ?? 'N/A'}'),
              Text('Service Date: ${request['date'] ?? 'N/A'}'),
              Text('Status: $displayStatus'),
              Text(
                'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              if (request['status'] == 'accepted' &&
                  request['cleaner_name'] != null)
                Text(
                  'Accepted by: ${request['cleaner_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (request['status'] == 'completed' &&
                  request['verification_code'] != null)
                Text(
                  'Verification Code: ${request['verification_code']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              if (request['cancellation_reason'] != null)
                Text(
                  'Cancellation Reason: ${request['cancellation_reason']}',
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              if (request['status'] == 'accepted_pending_customer' ||
                  request['status'] == 'accepted' ||
                  request['status'] == 'completed') ...[
                const Text(
                  'Cleaner Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (cleanerDetails != null) ...[
                  Text('Full Name: ${cleanerDetails['fullName'] ?? 'N/A'}'),
                  Text('Age: ${cleanerDetails['age'] ?? 'N/A'}'),
                  Text('Gender: ${cleanerDetails['gender'] ?? 'N/A'}'),
                  Text('Email: ${cleanerDetails['email'] ?? 'N/A'}'),
                  Text(
                    'Phone Number: ${cleanerDetails['phoneNumber'] ?? 'N/A'}',
                  ),
                  Text('Experience: ${cleanerDetails['experience'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  cleanerDetails['profileImageUrl'] != null
                      ? Image.network(
                        cleanerDetails['profileImageUrl'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                      : const Text('No profile picture available.'),
                ] else
                  const Text('Cleaner details not available.'),
              ],
              const SizedBox(height: 16),
              const Text(
                'House Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              request['images'] != null &&
                      (request['images'] as List).isNotEmpty
                  ? SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (request['images'] as List).length,
                      itemBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              request['images'][index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Text('Error loading image'),
                            ),
                          ),
                    ),
                  )
                  : const Text('No images available.'),
              const SizedBox(height: 20),
              if (request['status'] == 'accepted_pending_customer')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveCleaner(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Accept Cleaner'),
                    ),
                    ElevatedButton(
                      onPressed: () => _rejectCleaner(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Reject Cleaner'),
                    ),
                  ],
                ),
              if (request['status'] == 'accepted')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _markAsCompleted(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Complete'),
                    ),
                    ElevatedButton(
                      onPressed: () => _cancelRequest(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CancelReasonDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const CancelReasonDialog({super.key, required this.onConfirm});

  @override
  _CancelReasonDialogState createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for cancellation:'),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(hintText: 'Enter reason'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_reasonController.text.isNotEmpty) {
              widget.onConfirm(_reasonController.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a reason')),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
        await Future.delayed(Duration(seconds: 2));
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
        title: const Text(
          'Service Request',
          style: TextStyle(
            color: Color.fromARGB(255, 87, 87, 88),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
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
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        width: 300, // Enforce a specific width for the TextField
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 84, 82, 82).withOpacity(0.15),
                blurRadius: 2,
                spreadRadius: 2,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 157, 187, 106),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            readOnly: readOnly,
            maxLines: maxLines,
            onTap: onTap,
            validator: isRequired ? validator : null,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        width: 300, // Enforce a specific width for the DropdownField
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 84, 82, 82).withOpacity(0.15),
                blurRadius: 2,
                spreadRadius: 2,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<T>(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 60, 204, 91),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            value: value,
            items:
                items
                    .map(
                      (T item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          item.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            validator: validator,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ),
        ),
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
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
    _fetchAverageRating();
  }

  Future<void> _checkIfRated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ratingDoc =
          await _firestore.collection('app_ratings').doc(user.uid).get();
      if (ratingDoc.exists) {
        setState(() {
          _hasRated = true;
          _rating = ratingDoc.data()!['rating'].toDouble();
        });
      }
    }
  }

  Future<void> _fetchAverageRating() async {
    final ratingsSnapshot = await _firestore.collection('app_ratings').get();
    if (ratingsSnapshot.docs.isNotEmpty) {
      double totalRating = 0.0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc.data()['rating'].toDouble();
      }
      setState(() {
        _averageRating = totalRating / ratingsSnapshot.docs.length;
        _totalReviews = ratingsSnapshot.docs.length;
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
    try {
      await _firestore.collection('app_ratings').doc(user.uid).set({
        'user_id': user.uid,
        'user_type': widget.userType,
        'rating': _rating,
        'report': _reportController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _hasRated = true);
      await _fetchAverageRating();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating and report submitted successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting rating: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          _hasRated
              ? Text(
                'You have already rated: $_rating stars',
                style: TextStyle(color: Colors.grey[600]),
              )
              : Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                      size: 32,
                    ),
                    onPressed:
                        () => setState(() => _rating = (index + 1).toDouble()),
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
            enabled: !_hasRated,
          ),
          const SizedBox(height: 16),
          if (!_hasRated)
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
        setState(() {
          _fullName = data?['fullName'] ?? 'Unknown';
          _email = data?['email'] ?? 'No Email';
          _profileImageUrl = data?['profileImageUrl'];
        });
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
        title: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Cleanzy',
              style: GoogleFonts.greatVibes(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
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
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.blue, size: 30),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0, // Changed from custombottom to bottom
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 30),
                      onPressed: _uploadImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileField('Full Name', _fullName ?? 'Loading...'),
            _buildProfileField('Email', _email ?? 'Loading...'),
          ],
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
