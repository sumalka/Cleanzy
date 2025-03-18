import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const ServiceRequestsPage(),
    const CustomersPage(),
    const CleanersPage(),
    const RatingsPage(), // New RatingsPage added here
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (!userDoc.exists || userDoc['role'] != 'Admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not authorized as an admin')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cleanzy',
          style: GoogleFonts.greatVibes(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ).copyWith(fontFamilyFallback: ['Roboto']),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cleaning_services),
            label: 'Cleaners',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Ratings', // New navigation item for Ratings
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey, // Added for better visibility
        onTap: _onItemTapped,
      ),
    );
  }
}

// Service Requests Page
class ServiceRequestsPage extends StatelessWidget {
  const ServiceRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Service Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildRequestsList(),
          ],
        ),
      ),
    );
  }
}

// Customers Page
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Customers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildUsersList('users', 'Customer'),
          ],
        ),
      ),
    );
  }
}

// Cleaners Page
class CleanersPage extends StatelessWidget {
  const CleanersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cleaners',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildUsersList('users', 'Cleaner'),
          ],
        ),
      ),
    );
  }
}

// New Ratings Page
class RatingsPage extends StatelessWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ratings & Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildRatingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('app_ratings').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading ratings: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text('No ratings or reports found.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ratingData = docs[index].data() as Map<String, dynamic>;
            final userId = ratingData['user_id'] ?? 'Unknown';
            final userType = ratingData['user_type'] ?? 'N/A';
            final rating = ratingData['rating']?.toString() ?? 'N/A';
            final report = ratingData['report'] ?? 'No report provided';
            final timestamp =
                (ratingData['timestamp'] as Timestamp?)?.toDate().toString() ??
                'N/A';

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
              builder: (context, userSnapshot) {
                String userName = 'Unknown';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  userName = userSnapshot.data!.get('name') ?? 'Unknown';
                }

                return Card(
                  child: ListTile(
                    title: Text('$userType: $userName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating: $rating stars'),
                        Text('Report: $report'),
                        Text('Submitted: $timestamp'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Helper method with block/unblock functionality
Widget _buildUsersList(String collectionName, String role) {
  return StreamBuilder<QuerySnapshot>(
    stream:
        FirebaseFirestore.instance
            .collection(collectionName)
            .where('role', isEqualTo: role)
            .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Error loading $role: ${snapshot.error}');
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return Text('No $role found.');
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final userData = docs[index].data();
          if (userData is! Map<String, dynamic>) {
            return const Card(child: ListTile(title: Text('Invalid Data')));
          }

          final bool isBlocked = userData['blocked'] == true;

          return Card(
            child: ListTile(
              title: Text(userData['name'] ?? 'No Name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${userData['email'] ?? 'No Email'}'),
                  if (role == 'Cleaner')
                    Text('Phone: ${userData['phone'] ?? 'No Phone'}'),
                  if (role == 'Cleaner')
                    Text('Status: ${userData['status'] ?? 'N/A'}'),
                  Text('Blocked: ${isBlocked ? 'Yes' : 'No'}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isBlocked ? Icons.lock_open : Icons.lock,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection(collectionName)
                        .doc(docs[index].id)
                        .update({'blocked': !isBlocked});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBlocked
                              ? '${userData['name'] ?? 'User'} unblocked successfully'
                              : '${userData['name'] ?? 'User'} blocked successfully',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating status: $e')),
                    );
                  }
                },
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildRequestsList() {
  return StreamBuilder<QuerySnapshot>(
    stream:
        FirebaseFirestore.instance.collection('cleaning_requests').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Error loading requests: ${snapshot.error}');
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;
      if (docs.isEmpty) {
        return const Text('No service requests found.');
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final requestData = docs[index].data();
          if (requestData is! Map<String, dynamic>) {
            return const Card(
              child: ListTile(title: Text('Invalid Request Data')),
            );
          }

          return Card(
            child: ListTile(
              title: Text('Request #${docs[index].id}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer ID: ${requestData['user_id'] ?? 'N/A'}'),
                  Text(
                    'Cleaner ID: ${requestData['cleaner_id'] ?? 'Not Assigned'}',
                  ),
                  Text('Status: ${requestData['status'] ?? 'Pending'}'),
                  Text('Date: ${requestData['date'] ?? 'N/A'}'),
                ],
              ),
              trailing:
                  requestData['status'] == 'Completed'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(
                        Icons.pending,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
            ),
          );
        },
      );
    },
  );
}
