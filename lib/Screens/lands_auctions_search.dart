import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gis/Screens/auction_landing_Screen.dart';
import 'package:gis/Screens/account.dart';
import 'package:gis/Screens/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class LandsAuctionsSearch extends StatefulWidget {
  const LandsAuctionsSearch({Key? key}) : super(key: key);

  @override
  _LandsAuctionsSearchState createState() => _LandsAuctionsSearchState();
}

class _LandsAuctionsSearchState extends State<LandsAuctionsSearch> {
  late String JsonStringLands;
  late String JsonStringNeighborhood;
  bool isFilterVisible = false;
  int _currentIndex = 0;
  List<Map<String, dynamic>> combinedData = [];
  List<Map<String, dynamic>> filteredData = [];
  late Map<String, dynamic> formData;

  // Controllers for filter fields
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _basinNameController = TextEditingController();
  final TextEditingController _basinNumberController = TextEditingController();
  final TextEditingController _landNumberController = TextEditingController();
  final TextEditingController _priceBeforeController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerIdController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();

  Timer? _debounceTimer;

  List<String> locations = ["طمون", "ترمسعيا"];
  String? selectedLocation;

  RangeValues priceRange = RangeValues(0, 1000000);
  RangeValues areaRange = RangeValues(0, 10000);

  @override
  void initState() {
    super.initState();
    isFilterVisible = false;
    fetchLands().then((firebaseLandData) {
      fetchAuctions().then((railwayLandData) {
        combineAuctionData(firebaseLandData, railwayLandData);
      });
    });

    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _filterData();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _neighborhoodController.dispose();
    _basinNameController.dispose();
    _basinNumberController.dispose();
    _landNumberController.dispose();
    _priceBeforeController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    _ownerNameController.dispose();
    _ownerIdController.dispose();
    _coordinatesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _filterData() {
    if (combinedData.isEmpty) return;

    setState(() {
      String searchQuery = _searchController.text.toLowerCase();

      filteredData = combinedData.where((property) {
        Map<String, dynamic> formData = property['formData'];

        bool matchesSearch = searchQuery.isEmpty ||
            formData['landNumber']
                    ?.toString()
                    .toLowerCase()
                    .contains(searchQuery) ==
                true ||
            formData['description']
                    ?.toString()
                    .toLowerCase()
                    .contains(searchQuery) ==
                true ||
            formData['location']
                    ?.toString()
                    .toLowerCase()
                    .contains(searchQuery) ==
                true;

        bool matchesNeighborhood = _neighborhoodController.text.isEmpty ||
            formData['neighborhood']
                    ?.toString()
                    .toLowerCase()
                    .contains(_neighborhoodController.text.toLowerCase()) ==
                true;

        bool matchesBasinName = _basinNameController.text.isEmpty ||
            formData['basinName']
                    ?.toString()
                    .toLowerCase()
                    .contains(_basinNameController.text.toLowerCase()) ==
                true;

        bool matchesBasinNumber = _basinNumberController.text.isEmpty ||
            formData['basinId']
                    ?.toString()
                    .toLowerCase()
                    .contains(_basinNumberController.text.toLowerCase()) ==
                true;

        bool matchesLandNumber = _landNumberController.text.isEmpty ||
            formData['landNumber']
                    ?.toString()
                    .toLowerCase()
                    .contains(_landNumberController.text.toLowerCase()) ==
                true;

        bool matchesOwnerName = _ownerNameController.text.isEmpty ||
            formData['ownerName']
                    ?.toString()
                    .toLowerCase()
                    .contains(_ownerNameController.text.toLowerCase()) ==
                true;

        bool matchesOwnerId = _ownerIdController.text.isEmpty ||
            formData['ownerId']
                    ?.toString()
                    .toLowerCase()
                    .contains(_ownerIdController.text.toLowerCase()) ==
                true;

        bool matchesLocation = selectedLocation == null ||
            formData['location'] == selectedLocation;

        num price =
            num.tryParse(formData['priceBefore']?.toString() ?? '0') ?? 0;
        bool matchesPriceRange =
            price >= priceRange.start && price <= priceRange.end;

        num area = num.tryParse(formData['landArea']?.toString() ?? '0') ?? 0;
        bool matchesAreaRange =
            area >= areaRange.start && area <= areaRange.end;

        return matchesSearch &&
            matchesNeighborhood &&
            matchesBasinName &&
            matchesBasinNumber &&
            matchesLandNumber &&
            matchesOwnerName &&
            matchesOwnerId &&
            matchesLocation &&
            matchesPriceRange &&
            matchesAreaRange;
      }).toList();
    });
  }

  Widget _buildFilterField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (_) => _filterData(),
      ),
    );
  }

  Widget _buildRangeSlider(
      String label, RangeValues values, void Function(RangeValues) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        RangeSlider(
          values: values,
          min: 0,
          max: label.contains('السعر') ? 1000000 : 10000,
          divisions: 100,
          labels: RangeLabels(
            values.start.round().toString(),
            values.end.round().toString(),
          ),
          onChanged: (newValues) {
            setState(() {
              onChanged(newValues);
              _filterData();
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(values.start.round().toString()),
              Text(values.end.round().toString()),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedLocation,
        decoration: InputDecoration(
          labelText: 'الموقع',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('الكل'),
          ),
          ...locations.map((location) => DropdownMenuItem<String>(
                value: location,
                child: Text(location),
              )),
        ],
        onChanged: (value) {
          setState(() {
            selectedLocation = value;
            _filterData();
          });
        },
      ),
    );
  }

  Widget _buildEnhancedFilterPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تصفية النتائج',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => isFilterVisible = false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFilterField('اسم الحي', _neighborhoodController),
                    _buildFilterField('رقم الحوض', _basinNumberController),
                    _buildFilterField('اسم الحوض', _basinNameController),
                    _buildFilterField('رقم القطعة', _landNumberController),
                    _buildLocationDropdown(),
                    _buildRangeSlider(
                      'السعر قبل التسوية',
                      priceRange,
                      (newValues) => priceRange = newValues,
                    ),
                    _buildRangeSlider(
                      'المساحة',
                      areaRange,
                      (newValues) => areaRange = newValues,
                    ),
                    _buildFilterField('اسم المالك', _ownerNameController),
                    _buildFilterField('رقم هوية المالك', _ownerIdController),
                    _buildFilterField('الإحداثيات', _coordinatesController),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _neighborhoodController.clear();
                            _basinNameController.clear();
                            _basinNumberController.clear();
                            _landNumberController.clear();
                            _priceBeforeController.clear();
                            _areaController.clear();
                            _locationController.clear();
                            _ownerNameController.clear();
                            _ownerIdController.clear();
                            _coordinatesController.clear();
                            selectedLocation = null;
                            priceRange = const RangeValues(0, 1000000);
                            areaRange = const RangeValues(0, 10000);
                            _filterData();
                          });
                        },
                        child: const Text('إعادة تعيين'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isFilterVisible = false;
                            _filterData();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('تطبيق'),
                      ),
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

  Future<List<Map<String, dynamic>>> fetchLands() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('lands').get();
      print('Fetched ${snapshot.docs.length} lands');

      List<Map<String, dynamic>> landsData = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> formData = data["formData"] ?? {};
        return {
          "landId": data["landId"] ?? '',
          "formData": {
            "plotNumber": formData["plotNumber"] ?? '', // Add this line
            "basinId": formData["basinId"] ?? '',
            "basinName": formData["basinName"] ?? '',
            "neighborhood": formData["neighborhood"] ?? '',
            "neighborhoodNumber": formData["neighborhoodNumber"] ?? '',
            "location": formData["location"] ?? '',
            "landArea": formData["landArea"] ?? 0,
            "description": formData["description"] ?? '',
            "price": formData["price"] ?? 0,
            "priceAfter": formData["priceAfter"] ?? 0,
            "priceBefore": formData["priceBefore"] ?? 0,
            "ownerName": formData["ownerName"] ?? '',
            "ownerPhone": formData["ownerPhone"] ?? '',
            "ownerId": formData["ownerId"] ?? '',
            "coordinates": {
              "latitude": formData["coordinates"]?["latitude"] ?? 0.0,
              "longitude": formData["coordinates"]?["longitude"] ?? 0.0,
            },
          },
          "landsImagesUrls":
              (data["landsImagesUrls"] as List?)?.cast<String>() ?? [],
          "JsonStringLands": data["JsonStringLands"] ?? '',
          "JsonStringNeighborhood": data["JsonStringNeighborhood"] ?? '',
        };
      }).toList();

      print('Successfully processed ${landsData.length} land records');
      return landsData;
    } catch (e) {
      print('Error fetching lands: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAuctions() async {
    try {
      final response = await http.get(
        Uri.parse('https://auctions-production.up.railway.app/api/auctions'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((auction) => {
                  "auctionId": auction['id'] ?? '',
                  "landId": auction['landId'] ?? '',
                  "startPrice": auction['startPrice'] ?? 0,
                  "endAt": auction['endAt'] ?? '',
                  "status": auction['status'] ?? '',
                  "winnerId": auction['winnerId'],
                  "bids": auction['bids'] ?? [],
                })
            .toList();
      } else {
        throw Exception('Failed to load auctions');
      }
    } catch (e) {
      print('Error fetching auctions: $e');
      return [];
    }
  }

  Future<void> combineAuctionData(List<Map<String, dynamic>> firebaseData,
      List<Map<String, dynamic>> railwayData) async {
    List<Map<String, dynamic>> newCombinedData = [];

    for (var firebaseItem in firebaseData) {
      var landId = firebaseItem['landId'];
      if (landId == null || landId.isEmpty) continue;

      var auctionDetails =
          railwayData.where((auction) => auction['landId'] == landId).toList();

      var combinedItem = {
        ...firebaseItem,
        'auctionDetails': auctionDetails,
      };
      newCombinedData.add(combinedItem);
    }

    setState(() {
      combinedData = newCombinedData;
      filteredData = newCombinedData;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AccountScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              jsonLands: combinedData.isNotEmpty
                  ? combinedData[0]['JsonStringLands']
                  : '',
              jsonNeighborhood: combinedData.isNotEmpty
                  ? combinedData[0]['JsonStringNeighborhood']
                  : '',
              landNumber: filteredData.isNotEmpty
                  ? filteredData[0]['formData']['landNumber']?.toString()
                  : null,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'مزادات الأراضي',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                isFilterVisible = !isFilterVisible;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'بحث عن قطعة ارض',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      var lands = await fetchLands();
                      var auctions = await fetchAuctions();
                      await combineAuctionData(lands, auctions);
                    },
                    child: ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        var property = filteredData[index];
                        print(property);
                        return PropertyCard(
                          property: property,
                          onMapTap: () {
                            print(
                                'Navigating to HomePage with landNumber: ${property['formData']['plotNumber']}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  jsonLands: property['JsonStringLands'],
                                  jsonNeighborhood:
                                      property['JsonStringNeighborhood'],
                                  landNumber: property['formData']['plotNumber']
                                      ?.toString(),
                                ),
                              ),
                            );
                          },
                          onDetailsTap: () {
                            final propertyData =
                                Map<String, dynamic>.from(property);
                            propertyData['formData'] =
                                Map<String, dynamic>.from(property['formData']);
                            propertyData['traderId'] =
                                propertyData['formData']['ownerId'];
                            propertyData['ownerPhone'] =
                                propertyData['formData']['ownerPhone'];
                            propertyData['description'] =
                                propertyData['formData']['description'];
                            propertyData['landsImagesUrls'] =
                                propertyData['landsImagesUrls'] ?? [];
                            propertyData['priceBefore'] =
                                propertyData['formData']['priceBefore'];
                            propertyData['landArea'] =
                                propertyData['formData']['landArea'];
                            propertyData['location'] =
                                propertyData['formData']['location'];
                            propertyData['name'] =
                                propertyData['formData']['landNumber'];
                            propertyData['ownerName'] =
                                propertyData['formData']['ownerName'];
                            propertyData['basinId'] =
                                propertyData['formData']['basinId'];
                            propertyData['basinName'] =
                                propertyData['formData']['basinName'];
                            propertyData['neighborhood'] =
                                propertyData['formData']['neighborhood'];
                            propertyData['neighborhoodNumber'] =
                                propertyData['formData']['neighborhoodNumber'];
                            propertyData['coordinates'] =
                                propertyData['formData']['coordinates'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LandAuctionPage(
                                  propertyData: [propertyData],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isFilterVisible) _buildEnhancedFilterPanel(),
        ],
      ),
      bottomNavigationBar: _buildEnhancedBottomNavigationBar(),
    );
  }

  Widget _buildEnhancedBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'المزادات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الخريطة',
          ),
        ],
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onMapTap;
  final VoidCallback onDetailsTap;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onMapTap,
    required this.onDetailsTap,
  }) : super(key: key);

  Widget _buildIconWithText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Color(0xFF7C7C7C)),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF7C7C7C),
          ),
        ),
      ],
    );
  }

  void _showImageGallery(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryView(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = property['formData'] as Map<String, dynamic>;
    final images = property['landsImagesUrls'] as List<String>;
    final auctionDetails = property['auctionDetails'] as List<dynamic>;
    final numberOfBids =
        auctionDetails.isNotEmpty ? auctionDetails[0]['bids']?.length ?? 0 : 0;
    final numberOfViews = 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 128,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                image: images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(images[0]),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: images.isEmpty ? Colors.grey[200] : null,
              ),
              child: images.isNotEmpty
                  ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showImageGallery(context, images, 0),
                        borderRadius: BorderRadius.circular(8),
                        child: images.length > 1
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${images.length - 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    )
                  : Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'نشط',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'منذ 13 ساعة',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: formData['priceBefore']?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        WidgetSpan(child: SizedBox(width: 4)),
                        TextSpan(
                          text: 'دينار اردني',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'قطعة ارض مميزة في حي ${formData['neighborhood'] ?? ''}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildIconWithText(
                        Icons.crop_square,
                        '${formData['landArea'] ?? 0} دنم',
                      ),
                      SizedBox(width: 16),
                      _buildIconWithText(
                        Icons.visibility,
                        '$numberOfViews مشاهدات',
                      ),
                      SizedBox(width: 16),
                      _buildIconWithText(
                        Icons.gavel,
                        '$numberOfBids مزايدات',
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.map, size: 18),
                          label: Text('الخريطة'),
                          onPressed: onMapTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[800],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.remove_red_eye, size: 18),
                          label: Text('التفاصيل'),
                          onPressed: onDetailsTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildPriceRow(String label, String price) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black),
            children: [
              TextSpan(
                text: price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              TextSpan(
                text: ' دينار',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ImageGalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryView({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _ImageGalleryViewState createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<ImageGalleryView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
