import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gis/Screens/account.dart';
import 'package:gis/Screens/admin_page.dart';
import 'package:gis/Screens/home_page.dart';
import 'package:gis/Screens/property_details/property_details_screen.dart';
import 'package:http/http.dart' as http;

class LandsAdminAuctionsSearch extends StatefulWidget {
  @override
  _LandsAdminAuctionsSearchState createState() =>
      _LandsAdminAuctionsSearchState();
}

class _LandsAdminAuctionsSearchState extends State<LandsAdminAuctionsSearch> {
  bool isFilterVisible = false; // To toggle the filter navigation
  bool showMoreZones = false; // To toggle more zones
  bool showMoreBasins = false; // To toggle more basins
  int _currentIndex = 0;
  List<Map<String, dynamic>> combinedData = [];
  late Map<String, dynamic> formData;
  @override
  void initState() {
    isFilterVisible = false;
    super.initState();
    fetchLands();
    fetchAuctions();
    fetchLands().then((firebaseLandData) {
      fetchAuctions().then((railwayLandData) {
        combineAuctionData(firebaseLandData, railwayLandData);
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchLands() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot snapshot = await firestore.collection('lands').get();

    // Print raw Firestore data
    for (var doc in snapshot.docs) {
      // print("Raw Firestore Document: ${doc.data()}");
    }

    List<Map<String, dynamic>> landsData = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Access nested formData and extract its values
      formData = data["formData"] ?? {};

      // Combine the data
      Map<String, dynamic> landData = {
        "basinId": formData["basinId"] ?? '',
        "location": formData["location"] ?? '',
        "name": formData["name"] ?? '',
        "neighborhood": formData["neighborhood"] ?? '',
        "ownerName": formData["ownerName"] ?? '',
        "ownerPhone": formData["ownerPhone"] ?? '',
        "ownerId": formData["ownerId"] ?? '',
        "priceAfter": formData["priceAfter"] ?? 0,
        "priceBefore": formData["priceBefore"] ?? 0,
        "traderId": formData["traderId"] ?? '',
        "landId": data["landId"] ?? '',
        "landsDocumentsUrls":
            (data["landsDocumentsUrls"] as List?)?.cast<String>() ?? [],
        "landsImagesUrls":
            (data["landsImagesUrls"] as List?)?.cast<String>() ?? [],
        "userDocumentsUrls":
            (data["userDocumentsUrls"] as List?)?.cast<String>() ?? [],
        "userId": data["userId"] ?? '',
        "auctionId": data["auctionId"] ?? '',
        "auctionStartPrice": data["auctionStartPrice"] ?? 0,
        "auctionEndAt": data["auctionEndAt"] ?? '',
        "auctionStatus": data["auctionStatus"] ?? '',
        "auctionWinnerId": data["auctionWinnerId"] ?? '',
        "auctionLand": data["auctionLand"] ?? {},
        "bids": (data["bids"] as List?) ?? [],
        "landArea": formData["landArea"] ?? 0,
        "description": formData["description"] ?? '',
      };

      return landData;
    }).toList();

    // Print the processed data as JSON
    print(jsonEncode({"Processed Data": landsData}));

    return landsData;
  }

////////////
  Future<List<Map<String, dynamic>>> fetchAuctions() async {
    final Uri url = Uri.parse(
        'https://auctions-production.up.railway.app/api/auctions'); // Replace with your actual API URL

    try {
      // Send a GET request to fetch the auctions data
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON
        List<dynamic> data = jsonDecode(response.body);

        List<Map<String, dynamic>> auctions = data.map((auction) {
          // Modify this mapping based on the structure of your auction response
          return {
            "auctionId": auction.containsKey('id') ? auction['id'] : '',
            "landId": auction.containsKey('landId') ? auction['landId'] : '',
            "startPrice":
                auction.containsKey('startPrice') ? auction['startPrice'] : 0,
            "endAt": auction.containsKey('endAt') ? auction['endAt'] : '',
            "status": auction.containsKey('status') ? auction['status'] : '',
            "winnerId":
                auction.containsKey('winnerId') ? auction['winnerId'] : null,
            "land": auction.containsKey('land')
                ? {
                    "id": auction['land']['id'] ?? '',
                    "basinId": auction['land']['basinId'] ?? '',
                    "traderId": auction['land']['traderId'] ?? '',
                    "name": auction['land']['name'] ?? '',
                    "neighborhood": auction['land']['neighborhood'] ?? '',
                    "location": auction['land']['location'] ?? '',
                    "priceBefore": auction['land']['priceBefore'] ?? 0,
                    "priceAfter": auction['land']['priceAfter'] ?? 0,
                    "ownerName": auction['land']['ownerName'] ?? '',
                    "ownerPhone": auction['land']['ownerPhone'] ?? '',
                    "ownerId": auction['land']['ownerId'] ?? '',
                  }
                : {},
            "bids": auction.containsKey('bids') ? auction['bids'] : [],
          };
        }).toList();

        var jsonEncoder = JsonEncoder.withIndent('  ');
        // print(jsonEncoder.convert(auctions)); // Pretty print for debugging

        return auctions;
      } else {
        throw Exception('Failed to load auctions');
      }
    } catch (e) {
      // Handle errors and exceptions
      print('Error fetching auctions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> combineAuctionData(
      List<Map<String, dynamic>> firebaseData,
      List<Map<String, dynamic>> railwayData) async {
    List<Map<String, dynamic>> newCombinedData = [];
    for (var firebaseItem in firebaseData) {
      var landId = firebaseItem['landId'];
      if (landId == null || landId.isEmpty) {
        print("Skipping item due to missing or invalid landId: $firebaseItem");
        continue;
      }

      var auctionDetails =
          railwayData.where((auction) => auction['landId'] == landId).toList();

      if (auctionDetails.isEmpty) {
        print("No auction details found for landId: $landId");
        auctionDetails = [];
      }

      var combinedItem = {...firebaseItem, 'auctionDetails': auctionDetails};
      newCombinedData.add(combinedItem);
    }

    setState(() {
      combinedData = newCombinedData;
    });

    var jsonEncoder = JsonEncoder.withIndent('  ');
    print(jsonEncoder.convert(combinedData));

    return combinedData;
  }

  List<String> zones = [
    "خلة البلد",
    "ابو الحولزان",
    "ابو النتش",
    "صدر الثعلا",
    "خلة نصره",
    "عراق نصره",
  ];
  List<String> basins = [
    "الثعلا",
    "جوزه نصره",
    "المكسر",
    "جورة الحسينية",
    "باب النقب",
  ];
  List<String> selectedZones = [];
  List<String> selectedBasins = [];

  Future<void> getAllLandData() async {
    try {
      // Query all lands from Firestore
      QuerySnapshot landsSnapshot =
          await FirebaseFirestore.instance.collection('lands').get();

      // Iterate through each land document
      for (var landDoc in landsSnapshot.docs) {
        // Extract lists from the Firestore document, defaulting to an empty list if missing
        List<dynamic> landImagesUrls = landDoc['landsImagesUrls'] ?? [];
        List<dynamic> landDocumentsUrls = landDoc['landDocumentsUrls'] ?? [];
        List<dynamic> userDocumentsUrls = landDoc['userDocumentsUrls'] ?? [];

        // Process land images URLs
        if (landImagesUrls.isNotEmpty) {
          for (var imageUrl in landImagesUrls) {
            print('Land ID: ${landDoc.id}, Image URL: $imageUrl');
            // Process or store the image URLs as needed
          }
        } else {
          print('No land images found for Land ID: ${landDoc.id}');
        }

        // Process land documents URLs
        if (landDocumentsUrls.isNotEmpty) {
          for (var docUrl in landDocumentsUrls) {
            print('Land ID: ${landDoc.id}, Land Document URL: $docUrl');
            // Process or store the land document URLs as needed
          }
        } else {
          print('No land documents found for Land ID: ${landDoc.id}');
        }

        // Process user documents URLs
        if (userDocumentsUrls.isNotEmpty) {
          for (var userDocUrl in userDocumentsUrls) {
            print('Land ID: ${landDoc.id}, User Document URL: $userDocUrl');
            // Process or store the user document URLs as needed
          }
        } else {
          print('No user documents found for Land ID: ${landDoc.id}');
        }
      }
    } catch (e) {
      print('Error getting land data: $e');
    }
  }

// Function to get land auction data from the API
  Future<List<Map<String, dynamic>>> getLandAuctionData() async {
    // Define the API endpoint
    final String apiUrl =
        'https://auctions-production.up.railway.app/api/auctions'; // Replace with your actual API URL

    try {
      // Send a GET request to the API
      final response = await http.get(Uri.parse(apiUrl));

      // If the server returns a successful response (status code 200)
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        List<dynamic> data = json.decode(response.body);
        print("data is ::::::::::::::::::::::::::::::::::::;; : $data");
        // Map the data to a list of auction details (you can modify this structure as needed)
        List<Map<String, dynamic>> auctionData = [];

        for (var auction in data) {
          auctionData.add({
            'id': auction['id'],
            'landId': auction['landId'],
            'startPrice': auction['startPrice'],
            'endAt': auction['endAt'],
            'status': auction['status'],
            'land': auction['land']['name'], // Extracting 'land' name
            'bids': auction['bids'],
          });
        }
        print(
            "auctionData Lenght is KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK ${auctionData.length}");
        return auctionData;
      } else {
        // If the response was unsuccessful, throw an error
        throw Exception('Failed to load land auction data');
      }
    } catch (e) {
      // Handle any errors that occur during the request
      print('Error: $e');
      return [];
    }
  }

  void toggleSelection(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  void resetFilters() {
    setState(() {
      selectedZones.clear();
      selectedBasins.clear();
      isFilterVisible = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_currentIndex == 1) {
      // Navigate to the LandsAdminAuctionsSearch page when the new item is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountScreen()),
      );
    }
    if (_currentIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header Container
              SizedBox(
                height: 50,
              ),
              Container(
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(78, 160, 180, 190),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث عن قطعة ارض',
                          hintStyle: TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.search,
                              color: const Color.fromARGB(255, 3, 20, 34)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          fillColor: const Color.fromARGB(224, 255, 255, 255),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Filter Icon (Right Side)
                    IconButton(
                      icon: Icon(Icons.filter_alt,
                          color: const Color.fromARGB(255, 1, 11, 18)),
                      onPressed: () {
                        setState(() {
                          isFilterVisible = true;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Cards
              Directionality(
                textDirection: TextDirection.rtl,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 10),
                    child: PropertiesAuctionContent(
                      combinedData: combinedData,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Filter Navigation (Appears from the right)
          if (isFilterVisible)
            Positioned(
              right: 0, // Positioned to the right
              top: 50,
              bottom: 0,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  color: const Color.fromARGB(255, 245, 245, 245),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel Button
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(right: 14, left: 0),
                          children: [
                            SizedBox(height: 22),
                            // Zone Selection Title
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'اسم الحي',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Column(
                              children: zones
                                  .take(showMoreZones ? zones.length : 6)
                                  .map(
                                    (zone) => Column(
                                      children: [
                                        CheckboxListTile(
                                          value: selectedZones.contains(zone),
                                          onChanged: (value) {
                                            toggleSelection(
                                                selectedZones, zone);
                                          },
                                          title: Text(
                                            zone,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.only(
                                            right: 32,
                                            left: 80,
                                            top: 0,
                                            bottom: 0,
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.grey.withOpacity(0.4),
                                          height: 1,
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    showMoreZones = !showMoreZones;
                                  });
                                },
                                child: Text(
                                  showMoreZones ? 'إخفاء المزيد' : 'عرض المزيد',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Basin Selection Title
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'اسم الحوض',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Column(
                              children: basins
                                  .take(showMoreBasins ? basins.length : 6)
                                  .map(
                                    (basin) => Column(
                                      children: [
                                        CheckboxListTile(
                                          value: selectedBasins.contains(basin),
                                          onChanged: (value) {
                                            toggleSelection(
                                                selectedBasins, basin);
                                          },
                                          title: Text(
                                            basin,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.only(
                                            right: 32,
                                            left: 80,
                                            top: 0,
                                            bottom: 0,
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.grey.withOpacity(0.4),
                                          height: 1,
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    showMoreBasins = !showMoreBasins;
                                  });
                                },
                                child: Text(
                                  showMoreBasins
                                      ? 'إخفاء المزيد'
                                      : 'عرض المزيد',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Reset and Apply Buttons
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reset Button
                            TextButton(
                              onPressed: resetFilters,
                              child: Text(
                                'إعادة تعيين',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Apply Button
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isFilterVisible = false;
                                });
                              },
                              child: Text(
                                'تطبيق الفلاتر',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(250, 23, 30, 20),
              Color.fromARGB(206, 13, 17, 16),
              Color.fromARGB(206, 72, 37, 5)
            ], // Adjust gradient colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BottomNavigationBar(
          elevation: 1,
          backgroundColor:
              Colors.transparent, // Make it transparent to show the gradient
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel),
              label: 'المزادات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'حسابي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.maps_home_work_outlined),
              label: 'الخريطة',
            ),
          ],
        ),
      ),
    );
  }
}

class PropertiesAuctionContent extends StatelessWidget {
  final List<Map<String, dynamic>>
      combinedData; // Add this to accept dynamic data.

  PropertiesAuctionContent({required this.combinedData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: combinedData.length, // Dynamic count based on the data
            itemBuilder: (context, index) {
              var property = combinedData[index];
              print(property['landsImagesUrls']);
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: PropertyCard(
                  status: property['auctionStatus'] ?? 'غير معروف',
                  landArea: property['landArea']?.toString() ?? 'غير محدد',
                  numberOfBids:
                      property['bids']?.length ?? 0, // Assuming bids is a list
                  numberOfViews: property['numberOfViews'] ?? 0,
                  description: property['description'] ?? 'لا يوجد وصف',
                  basinNumber: property['basinId'] ??
                      'غير معروف', // Updated to 'basinId' as it seems to be the correct field
                  plotNumber: property['landId'] ??
                      'غير معروف', // Using 'landId' as the plot number
                  neighborhood: property['neighborhood'] ?? 'غير محدد',
                  initialPrice: property['priceBefore']?.toString() ??
                      '0', // Using 'priceBefore' for initial price
                  ownerName: property['ownerName'] ?? 'غير محدد',
                  ownerPhone: property['ownerPhone'] ?? 'غير محدد',
                  landImagesUrls: property['landsImagesUrls'] != null
                      ? List<String>.from(property['landsImagesUrls'])
                      : [],
                  landDocuments: property['landsDocumentsUrls'] != null
                      ? List<String>.from(property['landsDocumentsUrls'])
                      : [],
                  userDocuments: property['userDocumentsUrls'] != null
                      ? List<String>.from(property['userDocumentsUrls'])
                      : [],
                  ownerId: property['ownerId'] ?? 'غير محدد',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Full-screen image view widget.
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dark background for full-screen image viewing.
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // A close button to pop this view.
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Image.network(imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}

class PropertyCard extends StatefulWidget {
  final String status;
  final String landArea;
  final int numberOfBids;
  final int numberOfViews;
  final String description;
  final String basinNumber;
  final String plotNumber;
  final String neighborhood;
  final String initialPrice;
  final String ownerName;
  final String ownerPhone;
  final String ownerId;
  final List<String> landImagesUrls; // List of image URLs
  final List<String> landDocuments; // List of land document URLs
  final List<String> userDocuments; // List of user document URLs

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
    required this.ownerPhone,
    required this.landImagesUrls,
    required this.landDocuments,
    required this.userDocuments,
    required this.ownerId,
  });

  @override
  _PropertyCardState createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool isEditing = false;
  late TextEditingController _landAreaController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _ownerController;
  late TextEditingController _ownerIdController;
  late TextEditingController _ownerPhoneController;
  late List<TextEditingController> _imageControllers;
  var landAuctionId;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    landAuctionId = widget.plotNumber;
  }

  void _initializeControllers() {
    _landAreaController = TextEditingController(text: widget.landArea);
    _priceController = TextEditingController(text: widget.initialPrice);
    _descriptionController = TextEditingController(text: widget.description);
    _ownerController = TextEditingController(text: widget.ownerName);
    // _ownerController = TextEditingController(text: widget.ownerID);
    _ownerPhoneController = TextEditingController(text: widget.ownerPhone);
    _ownerIdController = TextEditingController(text: widget.ownerId);

    _imageControllers = widget.landImagesUrls
        .map((url) => TextEditingController(text: url))
        .toList();
  }

  Future<void> _updateLandData() async {
    try {
      final updatedData = {
        'landArea': _landAreaController.text,
        'priceBefore': _priceController.text,
        'description': _descriptionController.text,
        'ownerName': _ownerController.text,
        'landsImagesUrls': _imageControllers.map((c) => c.text).toList(),
      };

      await FirebaseFirestore.instance
          .collection('lands')
          .doc(widget.plotNumber)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحديث: $e')),
      );
    }
  }

  Widget _buildEditableField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // String variable to store the JSON data
// Function to upload lands polygon JSON data
    Future<void> _uploadLandsJson() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String fileContent = await File(filePath).readAsString();

        // Optionally, decode and re-encode if you need to validate or format the JSON
        var jsonMap = jsonDecode(fileContent);
        String jsonStringLands = jsonEncode(jsonMap);

        // Update the Firestore document for lands
        var landsRef = FirebaseFirestore.instance.collection('lands');
        var querySnapshot = await landsRef.get();
        for (var doc in querySnapshot.docs) {
          if (doc['landId'] == landAuctionId) {
            await landsRef.doc(doc.id).update({
              'JsonStringLands': jsonStringLands,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم تحديث أرض ${doc['landId']}')),
            );
          }
        }
      }
    }

// Function to upload neighborhood polygon JSON data
    Future<void> _uploadNeighborhoodJson() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String fileContent = await File(filePath).readAsString();

        // Optionally, decode and re-encode if you need to validate or format the JSON
        var jsonMap = jsonDecode(fileContent);
        String jsonStringNeighborhood = jsonEncode(jsonMap);

        // Update the Firestore document for neighborhoods
        var landsRef = FirebaseFirestore.instance.collection('lands');
        var querySnapshot = await landsRef.get();
        for (var doc in querySnapshot.docs) {
          if (doc['landId'] == landAuctionId) {
            await landsRef.doc(doc.id).update({
              'JsonStringNeighborhood': jsonStringNeighborhood,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم تحديث الحي للأرض ${doc['landId']}')),
            );
          }
        }
      }
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 79, 8, 8).withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical scrollable image section.
          _buildImageSection(),
          SizedBox(width: 16),
          // Edit/details container with no extra top margin.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action row with edit button and auction status.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        color: const Color.fromARGB(255, 16, 35, 52),
                      ),
                      onPressed: () async {
                        if (isEditing) {
                          await _updateLandData();
                        }
                        setState(() => isEditing = !isEditing);
                      },
                    ),
                    Text(
                      widget.status,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Editable fields or details.
                isEditing
                    ? Column(
                        children: [
                          _buildEditableField(_priceController, 'السعر'),
                          _buildEditableField(_landAreaController, 'المساحة'),
                          _buildEditableField(_ownerController, 'المالك'),
                          _buildEditableField(
                              _ownerPhoneController, 'جوال المالك'),
                          _buildEditableField(_ownerIdController, 'رقم الهوية'),
                          _buildEditableField(_descriptionController, 'الوصف'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceSection(),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              _buildIconWithText(
                                  Icons.location_on, widget.neighborhood),
                              SizedBox(width: 12),
                              _buildIconWithText(
                                  Icons.person, widget.ownerName),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'قطعة ارض مميزة في حي ${widget.neighborhood}',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 24),
                          Column(
                            children: [
                              Container(
                                width: double
                                    .infinity, // Expands to the full width
                                child: Align(
                                  alignment: Alignment
                                      .centerRight, // Aligns text to the right
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.description.isNotEmpty
                                            ? widget.description
                                            : 'لا يوجد وصف متاح', // Fallback text
                                        textAlign: TextAlign
                                            .right, // Ensures text alignment in RTL
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        widget.landArea.isNotEmpty
                                            ? 'المساحة:  ${widget.landArea} م2 '
                                            : 'لا يوجد وصف متاح', // Fallback text
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        widget.ownerPhone.isNotEmpty
                                            ? 'اسم المالك:  ${widget.ownerName} '
                                            : 'لا يوجد وصف متاح', // Fallback text
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        widget.ownerPhone.isNotEmpty
                                            ? 'رقم جوال المالك:  ${widget.ownerPhone} '
                                            : 'لا يوجد وصف متاح', // Fallback text
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                SizedBox(
                  height: 12,
                ),
                // Button to upload JSON file
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadLandsJson,
                      icon: Icon(
                        Icons.upload_file,
                        color: const Color.fromARGB(255, 163, 222, 0),
                      ), // Icon for uploading file
                      label: Text(
                        'رفع ملف الأرض',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 242, 36, 36),
                        backgroundColor: Color.fromARGB(
                            255, 255, 255, 255), // Custom text color
                        padding: EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0), // Custom padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(2), // Rounded corners
                        ),
                        elevation: 4, // Custom elevation
                        shadowColor: const Color.fromARGB(
                            115, 255, 255, 255), // Custom shadow color
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    ElevatedButton.icon(
                      onPressed: _uploadNeighborhoodJson,
                      icon: Icon(Icons.upload_file), // Icon for uploading file
                      label: Text(
                        'رفع ملف الحي',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w200,
                          color: const Color.fromARGB(255, 161, 115, 16),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 54, 26, 26),
                        backgroundColor: Color.fromARGB(
                            255, 255, 252, 252), // Custom text color
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2), // Custom padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(4), // Rounded corners
                        ),
                        elevation: 4, // Custom elevation
                        shadowColor: const Color.fromARGB(
                            115, 255, 255, 255), // Custom shadow color
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSectionOld() {
    // Combine all images from different sources into one list.
    final List<String> allImages = [
      ...widget.landImagesUrls,
      ...widget.landDocuments,
      ...widget.userDocuments,
    ];

    if (allImages.isEmpty) {
      return Container(
        width: 120,
        height: 190,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Color.fromARGB(255, 73, 19, 19)),
      );
    }

    // Display images in a vertical ListView.
    return Container(
      width: 160,
      height: 500,
      child: ListView.builder(
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navigate to the full-screen image view when tapped.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FullScreenImageView(imageUrl: allImages[index]),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              height: 500,
              child: Stack(
                children: [
                  // Display the image.
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(allImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Overlay the expand icon in the top-right corner.
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    // Combine all images from different sources into one list.
    final List<String> allImages = [
      ...widget.landImagesUrls,
      ...widget.landDocuments,
      ...widget.userDocuments,
    ];

    if (allImages.isEmpty) {
      return Container(
        width: 120,
        height: 560,
        color: const Color.fromARGB(255, 241, 241, 241),
        child: Icon(Icons.image, color: Color.fromARGB(255, 73, 19, 19)),
      );
    }

    // Display images in a vertical ListView.
    return Padding(
      padding: EdgeInsets.all(2),
      child: Container(
        width: 130,
        height: 280,
        child: ListView.builder(
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to the full-screen image view when tapped.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImageView(imageUrl: allImages[index]),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                height: 80,
                child: Stack(
                  children: [
                    // Display the image with a loading indicator.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        allImages[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    // Overlay the expand icon in the top-right corner.
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: const Color.fromARGB(255, 110, 56, 56)),
        children: [
          TextSpan(
            text: widget.initialPrice,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 2, 16, 28),
            ),
          ),
          TextSpan(text: ' دينار أردني'),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle user document logic here
          },
          child: Text('عرض مستندات المستخدم'),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            // Handle land document logic here
          },
          child: Text('عرض مستندات الأرض'),
        ),
      ],
    );
  }
}

Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: TextButton.icon(
          icon: Icon(Icons.map, color: const Color.fromARGB(255, 29, 37, 43)),
          label: Text('الخريطة'),
          onPressed: () {},
        ),
      ),
      Expanded(
        child: TextButton.icon(
          icon: Icon(Icons.visibility, color: Colors.blue),
          label: Text('عرض المزاد'),
          onPressed: () {},
        ),
      ),
    ],
  );
}

Widget _buildIconWithText(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 14, color: Color.fromARGB(255, 0, 0, 0)),
      SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(color: Color(0xFF7C7C7C), fontSize: 12),
      ),
    ],
  );
}

Widget _buildButton(String text,
    {required IconData icon, required VoidCallback onPressed}) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color.fromARGB(198, 97, 26, 164),
          Color.fromARGB(255, 68, 11, 7)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    // Clip the button to match the container's rounded corners
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 12,
          color: const Color.fromARGB(255, 219, 219, 193),
        ),
        label: Text(
          text,
          style: const TextStyle(fontSize: 10),
        ),
        style: ElevatedButton.styleFrom(
          // Set minimal padding for a smaller button
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          // Make the background transparent so the gradient shows
          backgroundColor: const Color.fromARGB(147, 160, 91, 91),
          // Remove the shadow
          shadowColor: const Color.fromARGB(0, 161, 143, 143),
          // Use a smaller minimum size
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    ),
  );
}
