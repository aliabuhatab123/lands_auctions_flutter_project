import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gis/Screens/Add_Property/add_prop_page_a.dart';
import 'package:gis/Screens/account.dart';
import 'package:gis/Screens/auction_page.dart';
import 'package:gis/Screens/home_page.dart';
import 'package:gis/Screens/lands_auctions_search.dart';
import 'package:gis/Screens/map_page.dart';
import 'package:gis/Screens/search_page.dart';

import '../property_details/property_details_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  @override
  _MyPropertiesScreenState createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userId = '';
  late Future<List<Map<String, dynamic>>> _landDataFuture;

  @override
  void initState() {
    super.initState();
    _getUserAndFetchData();
    _fetchLandData();
    _landDataFuture = _fetchLandData(); // Initialize _landDataFuture here
  }

  // Get the current user and then fetch all lands matching the userId
  void _getUserAndFetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      userId = userDoc['user_id'];
      print(
          'User ID...........................................................: $userId');
      await _fetchLandData();
      setState(() {
        userId = userDoc['user_id'];
        print(userId);
        // Now fetch all lands where formData.userId equals the current user's id.
        _landDataFuture = _fetchLandData();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLandData() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('lands')
          .where('userId', isEqualTo: userId)
          .get();

      // Print raw documents
      print("Raw Documents: ${snapshot.docs}");

      // Map each document to a Map<String, dynamic>
      List<Map<String, dynamic>> lands = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("Document Data: $data"); // Print each document
        lands.add(data);
      }

      // Print mapped lands
      print("Mapped Lands: $lands");

      return lands;
    } catch (e) {
      print("Error fetching land data: $e");
      return [];
    }
  }

  int _selectedIndex = 3; // Default to 'عقارتي' (index 3)
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_currentIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LandsAuctionsSearch()),
      );
    }
    if (_currentIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  jsonLands: '',
                  jsonNeighborhood: '',
                  landNumber: '',
                )),
      );
    }
    if (_currentIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddPropertyScreen()),
      );
    }
    if (_currentIndex == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyPropertiesScreen()),
      );
    }
    if (_currentIndex == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildContent(context),
              ),
              BottomNavigation(
                onItemTapped: _onItemTapped,
                selectedIndex: _selectedIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return Center(child: Text('المزادات'));
      case 1:
        return Center(child: Text('الخرائط'));
      case 2:
        return Center(child: Text('إضافة عقار'));
      case 3:
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _landDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            // else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //   return Center(child: Text('No properties found.'));
            // }
            else {
              return MyPropertiesContent(lands: snapshot.data!);
            }
          },
        );
      case 4:
        // Navigate to MyAccount Page when "حسابي" is tapped
        return MyAccountPage();
      default:
        return Center(child: Text('صفحة غير موجودة'));
    }
  }
}

class MyPropertiesContent extends StatelessWidget {
  final List<Map<String, dynamic>> lands;

  MyPropertiesContent({required this.lands});
  String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "$days يوم: $hours ساعة : $minutes دقيقة $seconds ثانية";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عقاراتي',
            style: TextStyle(
              color: Color.fromARGB(255, 66, 27, 27),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          CustomTabBar(),
          SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: lands.length,
              itemBuilder: (context, index) {
                var land = lands[index];
                // land['timestamp'] is assumed to be a Firebase Timestamp.
                DateTime landTimestamp =
                    (land['timestamp'] as Timestamp).toDate();
                Duration timeDiff = DateTime.now().difference(landTimestamp);
                String formattedDuration = formatDuration(timeDiff);

                // print("Land Images URLs: ${land["landsImagesUrls"]}");
                print("Land:::::::::::::::::::::::::::::::::::::::: : ${land}");
                return Padding(
                  padding:
                      EdgeInsets.only(bottom: 26), // Add margin at the bottom
                  child: PropertyCard(
                    timestamp:
                        formattedDuration, // Display the formatted duration
                    status: land['status'] ?? 'منشورة',
                    landArea:
                        land['formData']['landArea'].toString() ?? 'error',
                    numberOfBids: (land['bids'] ?? []).length,
                    numberOfViews: land['numberOfViews'] ?? 0,
                    description: land['description'] ?? 'لا يوجد وصف',
                    basinNumber: land['basinNumber'] ?? 'غير معروف',
                    plotNumber: land['plotNumber'] ?? 'غير معروف',
                    neighborhood: land['formData']['neighborhood'] ??
                        'غير معروف', // Fetch neighborhood from formData
                    initialPrice: land['formData']['priceBefore']?.toString() ??
                        'غير معروف', // Fetch priceBefore from formData
                    ownerName: land['formData']['ownerName'] ??
                        'غير معروف', // Fetch ownerName from formData
                    landImages: (land["landsImagesUrls"] as List<dynamic>)
                        .cast<String>(), // Cast to List<String>
                    location: land['formData']['location'] ?? 'غير معروف',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String status;
  final String landArea;
  final int numberOfBids;
  final int numberOfViews;
  final String description;
  final String basinNumber;
  final String plotNumber;
  final String location;
  final String timestamp;

  final String neighborhood;
  final String initialPrice;
  final String ownerName;
  final List<String> landImages; // List of image URLs (List<String>)

  PropertyCard({
    required this.status,
    required this.landArea,
    required this.numberOfBids,
    required this.numberOfViews,
    required this.description,
    required this.basinNumber,
    required this.plotNumber,
    required this.neighborhood,
    required this.initialPrice,
    required this.ownerName,
    required this.landImages,
    required this.location,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 128,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Color.fromARGB(51, 117, 117, 37)),
            image: landImages.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(landImages[0]), // Use the first image
                    fit: BoxFit.cover,
                  )
                : null,
            color: landImages.isEmpty
                ? Color.fromARGB(255, 93, 55, 55)
                : null, // Fallback color
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ' متبقي على المزاد ',
                style: TextStyle(
                  color: Color(0xFF7C7C7C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                '$timestamp ',
                style: TextStyle(
                  color: Color.fromARGB(195, 39, 5, 67),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Color(0xFF7C7C7C),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '$initialPrice',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(214, 36, 28, 3)),
                    ),
                    WidgetSpan(child: SizedBox(width: 8)),
                    TextSpan(
                      text: 'دينار اردني',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'حي $neighborhood في $location',
                style: TextStyle(
                  color: Color(0xFF7C7C7C),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildIconWithText(Icons.landscape_sharp, '$landArea m²'),
                      SizedBox(width: 8),
                      _buildIconWithText(
                          Icons.visibility, '$numberOfViews مشاهدات'),
                      SizedBox(width: 14),
                      _buildIconWithText(Icons.gavel, '$numberOfBids مزايدات'),
                    ],
                  ),
                  Icon(Icons.more_vert, size: 14, color: Color(0xFF7C7C7C)),
                ],
              ),
              SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'اسم المالك: ',
                      style: TextStyle(
                        color: Color.fromARGB(
                            255, 0, 0, 0), // Style for the label text
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '$ownerName',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 243, 135,
                            33), // Custom style for the owner's name
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Row(
              //   children: [
              //     Expanded(
              //       child:
              //           _buildButton('حذف', icon: Icons.delete, onPressed: () {
              //         // إضافة وظيفة الحذف هنا
              //       }),
              //     ),
              //     SizedBox(width: 6),
              //     Expanded(
              //       child:
              //           _buildButton('نشر', icon: Icons.publish, onPressed: () {
              //         Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //                 builder: (context) => PropertyDetailsScreen(
              //                       propertyId: '',
              //                     )));
              //         // إضافة وظيفة النشر هنا
              //       }),
              //     ),
              //     SizedBox(width: 6),
              //   ],
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconWithText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Color.fromARGB(240, 145, 95, 91)),
        SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: Color.fromARGB(255, 174, 136, 136),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {IconData? icon, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: Color.fromARGB(209, 36, 12, 2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 12, color: Color.fromARGB(255, 255, 255, 255)),
            if (icon != null) SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // child: Row(
          //   children: [
          //     _buildFilterChip('منشور', isSelected: true),
          //     SizedBox(width: 5),
          //     _buildFilterChip('قيد الانتظار'),
          //     SizedBox(width: 5),
          //     _buildFilterChip('مرفوض'),
          //     SizedBox(width: 5),
          //     _buildFilterChip('غير نشط'),
          //   ],
          // ),
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(22, 117, 117, 37),
            blurRadius: 8,
            offset: Offset(0, 8),
          ),
        ],
        color: Color.fromARGB(234, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: Color.fromARGB(72, 209, 179, 87))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.fromARGB(255, 87, 21, 21),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MyAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('حسابي - صفحة حساب المستخدم'),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex; // Add the selected index

  BottomNavigation({required this.onItemTapped, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(199, 5, 3, 1), // Pure Black
            const Color.fromARGB(193, 23, 3, 3), // Very Dark Gray (near black)
            const Color.fromARGB(249, 66, 33, 5), // Very Dark Gray (near black)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem('المزادات', Icons.gavel_outlined, 0),
              _buildNavItem('الخرائط', Icons.map_outlined, 1),
              _buildAddButton(),
              _buildNavItem('عقارتي', Icons.home_outlined, 3),
              _buildNavItem('حسابي', Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    bool isSelected = index == selectedIndex; // Check if the item is selected
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color.fromARGB(255, 228, 228, 228)
                : Color(0xFFBDC3C7), // Change color if selected
            size: 24,
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : Color.fromARGB(
                      255, 136, 118, 132), // Change color if selected
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 20,
              height: 2,
              color: const Color.fromARGB(
                  255, 162, 197, 154), // Add an indicator like a small line
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        // Change the selected index to 2 (إضافة عقار)
        onItemTapped(2);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(251, 87, 13, 23),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: const Color.fromARGB(255, 80, 43, 43), width: 1),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

Future<List<QueryDocumentSnapshot>> getUserLands() async {
  try {
    // Get the currently logged-in user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("No user is logged in.");
    }

    // Fetch all lands where the userId matches the logged-in user's uid
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('lands')
        .where('userId', isEqualTo: user.uid)
        .get();
    // print(querySnapshot.docs);
    // Return the list of documents
    return querySnapshot.docs;
  } catch (e) {
    print("Error fetching lands: $e");
    return [];
  }
}
