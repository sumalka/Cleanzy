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

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    BookingsPage(),
    CreditsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Customer Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
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

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// Reusable Bottom Navigation Bar
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
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          label: 'Credits',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Updated Home Page - Display customer's own cleaning requests with delete functionality
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
    if (user == null) {
      return const Stream.empty();
    }
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

      if (result == true) {
        if (!mounted) return;
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

  // Function to delete a cleaning request
  Future<void> _deleteRequest(BuildContext context, String docId) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
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
          );
        },
      );

      // Proceed with deletion if confirmed
      if (confirm == true) {
        await _firestore.collection('cleaning_requests').doc(docId).delete();
        if (!mounted) return;
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
      print('Error deleting request: $e');
      if (!mounted) return;

      Future.microtask(() {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Day!..',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Search for services',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: _buildCategory(context, 'Cleaning', Icons.cleaning_services),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Cleaning Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCleaningRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return const Center(child: Text('Error loading requests.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No cleaning requests yet.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var request =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    var docId = snapshot.data!.docs[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: SizedBox(
                        height: 150, // Fixed height of ListTile
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            'Request for ${request['name'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Date: ${request['date'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (request['status'] == 'accepted')
                                Text(
                                  'Cleaner: ${request['cleaner_name'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (request['cancellation_reason'] != null)
                                Text(
                                  'Cancelled: ${request['cancellation_reason']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 17.0),
                                child: Text(
                                  request['status'] ?? 'Pending',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (request['images'] != null &&
                                  (request['images'] as List).isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: 100, // Proportional width
                                    height:
                                        120, // Adjusted to fit within ListTile height
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        request['images'][0], // Show first image
                                        fit: BoxFit.cover, // Fill the space
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons.broken_image,
                                            size:
                                                60, // Adjusted error icon size
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(
                                width: 8,
                              ), // Space before delete button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                onPressed: () => _deleteRequest(context, docId),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RequestDetailsPage(
                                      docId: docId,
                                      request: request,
                                    ),
                              ),
                            );
                          },
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

// Request Details Page
class RequestDetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> request;

  const RequestDetailsPage({
    super.key,
    required this.docId,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
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
              Text('Service Date: ${request['date'] ?? 'N/A'}'),
              Text('Status: ${request['status'] ?? 'N/A'}'),
              if (request['status'] == 'accepted' &&
                  request['cleaner_name'] != null)
                Text('Accepted by: ${request['cleaner_name']}'),
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
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(
                            request['images'][index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Error loading image');
                            },
                          ),
                        );
                      },
                    ),
                  )
                  : const Text('No images available.'),
            ],
          ),
        ),
      ),
    );
  }
}

// Cleaning Form Page
class CleaningFormPage extends StatefulWidget {
  const CleaningFormPage({super.key});

  @override
  _CleaningFormPageState createState() => _CleaningFormPageState();
}

class _CleaningFormPageState extends State<CleaningFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController(); // Placeholder field
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<XFile> _houseImages = [];
  bool _isUploading = false;
  bool _imageUploadFailed = false;
  int? _selectedRooms; // Variable to store the selected number of rooms

  // List of room options (1 to 10 rooms)
  final List<int> _roomOptions = List.generate(
    10,
    (index) => index + 1,
  ); // [1, 2, ..., 10]

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Restrict to today or future dates
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.toLocal()}".split(' ')[0]; // Format: YYYY-MM-DD
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    if (_houseImages.isEmpty) {
      print('No images selected for upload.');
      return imageUrls;
    }

    print('Starting image upload for ${_houseImages.length} images...');
    for (var image in _houseImages) {
      try {
        print('Uploading image: ${image.path}');
        String imageUrl =
            kIsWeb
                ? await _uploadToCloudinaryWeb(await image.readAsBytes())
                : await _uploadToCloudinaryMobile(File(image.path));
        imageUrls.add(imageUrl);
        print('Successfully uploaded image: $imageUrl');
      } catch (e) {
        print('Image upload failed: $e');
        setState(() {
          _imageUploadFailed = true;
        });
      }
    }
    print('Image upload complete. Total URLs: ${imageUrls.length}');
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
      final responseData = json.decode(await response.stream.bytesToString());
      print('Cloudinary response: $responseData');
      return responseData['secure_url'];
    } else {
      final errorData = await response.stream.bytesToString();
      throw Exception(
        'Failed to upload image on web: Status ${response.statusCode}, Error: $errorData',
      );
    }
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
      final responseData = json.decode(await response.stream.bytesToString());
      print('Cloudinary response: $responseData');
      return responseData['secure_url'];
    } else {
      final errorData = await response.stream.bytesToString();
      throw Exception(
        'Failed to upload image on mobile: Status ${response.statusCode}, Error: $errorData',
      );
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _houseImages.addAll(pickedFiles);
        print('Picked ${_houseImages.length} images');
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if images are selected
      if (_houseImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select at least one house picture before submitting.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return; // Exit the function if no images are selected
      }

      setState(() {
        _isUploading = true;
        _imageUploadFailed = false;
      });

      try {
        print('Starting form submission...');
        List<String> imageUrls = await _uploadImages();
        print('Image URLs: $imageUrls');

        final user = _auth.currentUser;
        if (user == null) {
          print('User not logged in. Cannot submit form.');
          throw Exception('User not logged in. Please log in and try again.');
        }
        print('User authenticated: ${user.uid}');

        final requestData = {
          'name': _nameController.text,
          'address': _addressController.text,
          'rooms': _selectedRooms, // Use the selected integer value directly
          'date': _dateController.text,
          'additional_notes': _additionalNotesController.text, // Optional field
          'images': imageUrls,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'user_id': user.uid,
        };
        print('Prepared data to save: $requestData');

        print('Saving data to Firestore in collection: cleaning_requests');
        await FirebaseFirestore.instance
            .collection('cleaning_requests')
            .add(requestData);
        print('Successfully saved data to Firestore');

        Navigator.pop(context, true);
      } catch (e) {
        print('Error submitting form: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting form: $e')));
        Navigator.pop(context, false);
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2, // Subtle shadow like in the checkout form
        // Removed the title: 'Cleaning Form'
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cleaning Form',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Full name on card',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Example: John Jason Doe',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Address',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your address',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) => value!.isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Number of Rooms',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedRooms,
                      items:
                          _roomOptions.map((int rooms) {
                            return DropdownMenuItem<int>(
                              value: rooms,
                              child: Text(rooms.toString()),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedRooms = newValue;
                        });
                      },
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select the number of rooms'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Select a service date'
                                            : null,
                                readOnly: true,
                                onTap: () => _selectDate(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Additional Notes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextFormField(
                                controller: _additionalNotesController,
                                decoration: const InputDecoration(
                                  hintText: 'Optional notes',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => null, // Optional field
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'House Pictures',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._houseImages.map(
                          (image) =>
                              kIsWeb
                                  ? FutureBuilder<Uint8List>(
                                    future: image.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return Text('Error loading image');
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        width: 100,
                                        height: 100,
                                      );
                                    },
                                  )
                                  : Image.file(
                                    File(image.path),
                                    width: 100,
                                    height: 100,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_a_photo, size: 40),
                          onPressed: _pickImages,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    if (_imageUploadFailed)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'One or more images failed to upload. The request was submitted without images.',
                          style: TextStyle(color: Colors.red),
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

// Bookings Page
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Manage your bookings here.'));
  }
}

// Credits Page
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Payment and credit details.'));
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _name;
  String? _email;
  String? _role;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _name = data?['name'] ?? 'Unknown';
          _email = data?['email'] ?? 'No Email';
          _role = data?['role'] ?? 'Customer';
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
      String imageUrl = '';

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        imageUrl = await _uploadToCloudinaryWeb(bytes);
      } else {
        final file = File(pickedFile.path);
        imageUrl = await _uploadToCloudinaryMobile(file);
      }

      await _updateFirestore(imageUrl);
      setState(() {
        _profileImageUrl = imageUrl;
      });
      print('Image uploaded successfully: $imageUrl');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully!')),
      );
    } catch (e) {
      print('Error uploading image: $e');
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
    if (response.statusCode == 200) {
      final responseData = json.decode(await response.stream.bytesToString());
      return responseData['secure_url'];
    } else {
      throw Exception('Failed to upload image on web');
    }
  }

  Future<String> _uploadToCloudinaryMobile(File file) async {
    const cloudinaryUrl =
        'https://api.cloudinary.com/v1_1/dk1thw6tq/image/upload';
    final request =
        http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
          ..fields['upload_preset'] = 'profile_images'
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = json.decode(await response.stream.bytesToString());
      return responseData['secure_url'];
    } else {
      throw Exception('Failed to upload image on mobile');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Page')),
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
            _buildProfileField('Full Name', _name ?? 'Loading...'),
            _buildProfileField('Email', _email ?? 'Loading...'),
            _buildProfileField('Role', _role ?? 'Loading...'),
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
