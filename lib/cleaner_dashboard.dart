import 'package:cleaning_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:async/async.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CleanerDashboard(),
    );
  }
}

class CleanerDashboard extends StatefulWidget {
  const CleanerDashboard({super.key});

  @override
  State<CleanerDashboard> createState() => _CleanerDashboardState();
}

class _CleanerDashboardState extends State<CleanerDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _profileImageUrl;
  late AnimationController _glitterController;

  final List<Widget> _pages = [const HomePage(), const RatingsPage()];

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
      if (userDoc.exists && mounted) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        title: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Cleanzy',
              style: GoogleFonts.greatVibes(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 227, 18, 91),
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
            icon: CircleAvatar(
              radius: 15,
              backgroundImage:
                  _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
              backgroundColor: Colors.grey[300],
            ),
            onPressed: () => _navigateToProfile(context),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 10),
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
      selectedItemColor: Colors.grey[600],
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Ratings',
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

  Stream<List<Map<String, dynamic>>> getCleaningRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final pendingRequests =
        _firestore
            .collection('cleaning_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots();
    final ownRequests =
        _firestore
            .collection('cleaning_requests')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots();
    return StreamZip([pendingRequests, ownRequests]).map((snapshots) {
      final pendingDocs =
          snapshots[0].docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
      final ownDocs =
          snapshots[1].docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
      final allRequestsMap = <String, Map<String, dynamic>>{};
      for (var request in [...pendingDocs, ...ownDocs]) {
        allRequestsMap[request['id']] = request;
      }
      final allRequests =
          allRequestsMap.values.where((request) {
            List<dynamic>? previousCleanerIds = request['previous_cleaner_ids'];
            return previousCleanerIds == null ||
                !previousCleanerIds.contains(user.uid);
          }).toList();
      allRequests.sort(
        (a, b) => (b['timestamp'] as Timestamp).compareTo(
          a['timestamp'] as Timestamp,
        ),
      );
      return allRequests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Cleaning Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getCleaningRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending cleaning requests available.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var request = snapshot.data![index];
                    var docId = request['id'];
                    return Card(
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
                                ? Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      request['images'][0],
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
                                )
                                : const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                        title: Text(
                          'Request from ${request['name'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Date: ${request['date'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                              style: TextStyle(color: Colors.pink[700]),
                            ),
                          ],
                        ),
                        trailing: Text(
                          request['status'] ?? 'Pending',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
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
}

class CleanerProfileFormPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> request;

  const CleanerProfileFormPage({
    super.key,
    required this.docId,
    required this.request,
  });

  @override
  _CleanerProfileFormPageState createState() => _CleanerProfileFormPageState();
}

class _CleanerProfileFormPageState extends State<CleanerProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  String? _gender;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null && mounted) {
      print('Selected file path: ${pickedFile.path}');
      setState(() => _profileImage = pickedFile);
    }
  }

  Future<String> _uploadImage() async {
    if (_profileImage == null) throw Exception('No image selected');
    try {
      return kIsWeb
          ? await _uploadToCloudinaryWeb(await _profileImage!.readAsBytes())
          : await _uploadToCloudinaryMobile(File(_profileImage!.path));
    } catch (e) {
      print('Upload image error: $e');
      throw Exception('Failed to upload image: $e');
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
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString())['secure_url'];
    }
    throw Exception('Failed to upload image on web');
  }

  Future<String> _uploadToCloudinaryMobile(File file) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';

    // Validate the file
    if (!file.existsSync()) {
      throw Exception('File does not exist at path: ${file.path}');
    }

    try {
      final imageBytes = await file.readAsBytes();
      final request =
          http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
            ..fields['upload_preset'] = 'profile_images'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                imageBytes,
                filename: 'upload.${file.path.split('.').last}',
              ),
            );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = json.decode(await response.stream.bytesToString());
        return responseData['secure_url'];
      } else {
        throw Exception(
          'Failed to upload image on mobile. Status code: ${response.statusCode}, Response: ${await response.stream.bytesToString()}',
        );
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }

  Future<void> _submitFormAndAccept() async {
    if (_formKey.currentState!.validate() && _profileImage != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');
        final imageUrl = await _uploadImage();
        final profileData = {
          'fullName': _fullNameController.text,
          'age': int.parse(_ageController.text),
          'gender': _gender,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
          'experience': _experienceController.text,
          'profileImageUrl': imageUrl,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('cleaning_requests')
            .doc(widget.docId)
            .update({
              'status': 'accepted_pending_customer',
              'cleaner_id': user.uid,
              'cleaner_name': _fullNameController.text,
              'cleaner_details': profileData,
            });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated and request accepted'),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CleanerDashboard()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      if (_profileImage == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a profile picture')),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields correctly')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFormField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Enter your full name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _ageController,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter your age' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownButtonFormField(),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _emailController,
                          label: 'Email',
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Enter your phone number'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _experienceController,
                          label: 'Experience as Cleaner',
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Enter your experience'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _buildImageUploadSection(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitFormAndAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Submit and Accept Request',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownButtonFormField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      value: _gender,
      items:
          ['Male', 'Female', 'Other']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
      onChanged: (newValue) => setState(() => _gender = newValue),
      validator: (value) => value == null ? 'Select your gender' : null,
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            _profileImage == null
                ? const Center(child: Text('Upload Picture'))
                : kIsWeb
                ? FutureBuilder<Uint8List>(
                  future: _profileImage!.readAsBytes(),
                  builder:
                      (context, snapshot) =>
                          snapshot.hasData
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const CircularProgressIndicator(),
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_profileImage!.path),
                    fit: BoxFit.cover,
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    super.dispose();
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

  Future<bool> _isProfileComplete(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Profile check: User not logged in');
      return false;
    }
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!userDoc.exists) {
      print('Profile check: User document does not exist');
      return false;
    }
    final data = userDoc.data()!;
    bool isComplete =
        data['fullName'] != null &&
        data['age'] != null &&
        data['gender'] != null &&
        data['email'] != null &&
        data['phoneNumber'] != null &&
        data['experience'] != null &&
        data['profileImageUrl'] != null;
    print('Profile check: User document exists. Is complete? $isComplete');
    print('Profile data: $data');
    return isComplete;
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final cleaner = FirebaseAuth.instance.currentUser;
    if (cleaner == null) {
      print('Update status: Cleaner not logged in');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cleaner not logged in.')));
      return;
    }
    print('Update status: Cleaner logged in with UID: ${cleaner.uid}');
    bool profileComplete = await _isProfileComplete(context);
    print('Update status: Profile complete? $profileComplete');

    if (!profileComplete) {
      print('Update status: Navigating to CleanerProfileFormPage');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  CleanerProfileFormPage(docId: docId, request: request),
        ),
      ).then(
        (_) => print('Update status: Returned from CleanerProfileFormPage'),
      );
    } else {
      print('Update status: Profile complete, attempting direct update');
      try {
        final cleanerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(cleaner.uid)
                .get();
        final cleanerName = cleanerDoc.data()?['fullName'] ?? 'Unknown Cleaner';
        final cleanerDetails = cleanerDoc.data()!;
        print('Update status: Cleaner details fetched: $cleanerDetails');
        await FirebaseFirestore.instance
            .collection('cleaning_requests')
            .doc(docId)
            .update({
              'status': 'accepted_pending_customer',
              'cleaner_id': cleaner.uid,
              'cleaner_name': cleanerName,
              'cleaner_details': {
                'fullName': cleanerDetails['fullName'],
                'age': cleanerDetails['age'],
                'gender': cleanerDetails['gender'],
                'email': cleanerDetails['email'],
                'phoneNumber': cleanerDetails['phoneNumber'],
                'experience': cleanerDetails['experience'],
                'profileImageUrl': cleanerDetails['profileImageUrl'],
              },
            });
        print('Update status: Cleaning request updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted, awaiting customer approval'),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Update status: Error updating status: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Future<void> _cancelRequest(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (dialogContext) => CancelReasonDialog(
            onConfirm: (reason) async {
              try {
                final cleaner = FirebaseAuth.instance.currentUser;
                if (cleaner == null) throw Exception('Cleaner not logged in.');
                await FirebaseFirestore.instance
                    .collection('cleaning_requests')
                    .doc(docId)
                    .update({
                      'status': 'pending',
                      'cleaner_id': null,
                      'cleaner_name': null,
                      'cleaner_details': null,
                      'cancellation_reason': reason,
                      'cancelled_by': cleaner.uid,
                      'cancellation_timestamp': FieldValue.serverTimestamp(),
                    });
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request cancelled successfully'),
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling request: $e')),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayStatus =
        request['status'] == 'completed'
            ? 'completed'
            : request['status'] ?? 'Pending';
    bool isPreviouslyAssigned =
        user != null &&
        request['previous_cleaner_ids'] != null &&
        (request['previous_cleaner_ids'] as List<dynamic>).contains(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'House Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Single house image or placeholder
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              request['images'] != null &&
                                      (request['images'] as List).isNotEmpty
                                  ? Image.network(
                                    request['images'][0],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 50,
                                        ),
                                  )
                                  : const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Centered details in a single column
                      Text(
                        'Name: ${request['name']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Address: ${request['address']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Rooms: ${request['rooms']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Bathrooms: ${request['bathrooms']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Living Rooms: ${request['living_rooms']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Flooring Type: ${request['flooring_type']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Service Date: ${request['date']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Status: $displayStatus',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.pink[700],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (request['status'] == 'completed' &&
                          request['verification_code'] != null)
                        Text(
                          'Verification Code: ${request['verification_code']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (request['cancellation_reason'] != null)
                        Text(
                          'Cancellation Reason: ${request['cancellation_reason']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (request['status'] == 'pending' && !isPreviouslyAssigned)
                    ElevatedButton(
                      onPressed:
                          () => _updateStatus(
                            context,
                            'accepted_pending_customer',
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (request['status'] == 'accepted')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _cancelRequest(context),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Colors.white),
                      ),
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
    if (ratingsSnapshot.docs.isNotEmpty && mounted) {
      double totalRating = 0.0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc.data()['rating'].toDouble();
      }
      setState(() {
        _averageRating = totalRating / ratingsSnapshot.docs.length;
        _totalReviews = ratingsSnapshot.docs.length;
        _isLoading = false;
      });
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
              : SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
              ),
    );
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }
}

class RatingsPage extends StatelessWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RatingAndReportWidget(userType: 'cleaner');
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
      if (userDoc.exists && mounted) {
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
      if (mounted) {
        setState(() => _profileImageUrl = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
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
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString())['secure_url'];
    }
    throw Exception('Failed to upload image on web');
  }

  Future<String> _uploadToCloudinaryMobile(File file) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';

    if (!file.existsSync()) {
      throw Exception('File does not exist at path: ${file.path}');
    }

    try {
      final imageBytes = await file.readAsBytes();
      final request =
          http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
            ..fields['upload_preset'] = 'profile_images'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                imageBytes,
                filename: 'upload.${file.path.split('.').last}',
              ),
            );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = json.decode(await response.stream.bytesToString());
        return responseData['secure_url'];
      } else {
        throw Exception(
          'Failed to upload image on mobile. Status code: ${response.statusCode}, Response: ${await response.stream.bytesToString()}',
        );
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Error uploading image to Cloudinary: $e');
    }
  }

  Future<void> _updateFirestore(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profileImageUrl': imageUrl},
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getAcceptedRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final acceptedRequests =
        _firestore
            .collection('cleaning_requests')
            .where('cleaner_id', isEqualTo: user.uid)
            .where(
              'status',
              whereIn: ['accepted_pending_customer', 'accepted', 'completed'],
            )
            .orderBy('timestamp', descending: true)
            .snapshots();
    final canceledRequests =
        _firestore
            .collection('cleaning_requests')
            .where('previous_cleaner_ids', arrayContains: user.uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots();
    return StreamZip([acceptedRequests, canceledRequests]).map((snapshots) {
      print('ProfilePage: Fetching accepted requests snapshot');
      final acceptedDocs =
          snapshots[0].docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
      final canceledDocs =
          snapshots[1].docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
      final allRequestsMap = <String, Map<String, dynamic>>{};
      for (var request in [...acceptedDocs, ...canceledDocs]) {
        allRequestsMap[request['id']] = request;
      }
      final allRequests = allRequestsMap.values.toList();
      allRequests.sort(
        (a, b) => (b['timestamp'] as Timestamp).compareTo(
          a['timestamp'] as Timestamp,
        ),
      );
      print('ProfilePage: Accepted requests count: ${allRequests.length}');
      return allRequests;
    });
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
        child: SingleChildScrollView(
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
                      bottom: 0,
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
              const SizedBox(height: 24),
              const Text(
                'My Accepted Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getAcceptedRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No accepted requests.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var request = snapshot.data![index];
                        var docId = request['id'];
                        String displayStatus =
                            request['status'] == 'completed'
                                ? 'Customer Completed'
                                : request['status'] ==
                                    'accepted_pending_customer'
                                ? 'Accepted (Pending Customer)'
                                : request['status'] ?? 'Accepted';
                        bool isCanceledByCustomer = false;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final previousCleanerIds =
                              request['previous_cleaner_ids'] as List<dynamic>?;
                          isCanceledByCustomer =
                              (previousCleanerIds != null &&
                                  previousCleanerIds.contains(user.uid)) &&
                              request['status'] == 'pending' &&
                              request['cancellation_reason'] != null;
                        }
                        return Card(
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
                                    ? Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          request['images'][0],
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
                                    )
                                    : const Icon(
                                      Icons.image_not_supported,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            title: Text(
                              'Request from ${request['name'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Date: ${request['date'] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (isCanceledByCustomer)
                                  Text(
                                    'Canceled by Customer: ${request['cancellation_reason']}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (request['status'] == 'completed' &&
                                    request['verification_code'] != null)
                                  Text(
                                    'Code: ${request['verification_code']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  'Price: \$${request['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                  style: TextStyle(color: Colors.pink[700]),
                                ),
                              ],
                            ),
                            trailing: Text(
                              displayStatus,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}

class CancelReasonDialog extends StatelessWidget {
  final Function(String) onConfirm;

  const CancelReasonDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _reasonController = TextEditingController();

    return AlertDialog(
      title: const Text('Cancel Request'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          hintText: 'Enter cancellation reason',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_reasonController.text.isNotEmpty) {
              onConfirm(_reasonController.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a reason')),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
