import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gis/JSON_DATA/lands.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../services/geojson_parcels_service.dart';
import 'account.dart';
import 'lands_auctions_search.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  final String jsonLands;
  final String jsonNeighborhood;
  final String? landNumber; // Used to search for a specific land

  const HomePage({
    Key? key,
    required this.jsonLands,
    required this.jsonNeighborhood,
    required this.landNumber,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isCardVisible = false;
  final TextEditingController _landNumberController = TextEditingController();
  final TextEditingController _neighborhoodNumberController =
      TextEditingController();
  final TextEditingController _basinNumberController = TextEditingController();
  final GeoJsonService geoJsonService = GeoJsonService();
  final GeoJsonParcelsService geoJsonParcelsService = GeoJsonParcelsService();

  bool showParcels = true;
  bool loadingData = true;
  bool showLayers = true;
  bool showSatellite = true;
  bool is3DMode = false;
  int _currentIndex = 2;

  final MapController mapController = MapController();
  Map<String, dynamic>? _selectedLand;
  List<Polygon> selectedPolygons = [];
  List<Marker> selectedMarkers = [];

  double tiltAngle = 0.0;
  double bearing = 0.0;
  late AnimationController _flyController;
  late Animation<LatLng> _flyAnimation;

  @override
  void initState() {
    super.initState();
    _uploadInitialData();
    _initializeMap();
    _landNumberController.addListener(_updateBasinAndNeighborhood);

    _flyController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..addListener(() {
        if (_flyAnimation.value != null) {
          mapController.move(_flyAnimation.value, mapController.zoom);
        }
      });

    // If landNumber is provided, set it and trigger search
    if (widget.landNumber != null && widget.landNumber!.isNotEmpty) {
      _landNumberController.text = widget.landNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchLand();
      });
    }
  }

  @override
  void dispose() {
    _landNumberController.removeListener(_updateBasinAndNeighborhood);
    _landNumberController.dispose();
    _neighborhoodNumberController.dispose();
    _basinNumberController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  Future<void> _uploadInitialData() async {
    // Placeholder for initial data upload logic if needed
  }

  Future<void> _initializeMap() async {
    String parcelsGeoJson =
        widget.jsonLands.isNotEmpty ? widget.jsonLands : "{}";
    String neighborhoodGeoJson =
        widget.jsonNeighborhood.isNotEmpty ? widget.jsonNeighborhood : "{}";

    print('JSON Lands: $parcelsGeoJson');

    try {
      await geoJsonService.processGeoJsonData(parcelsGeoJson);
      await geoJsonParcelsService.processGeoJsonData(neighborhoodGeoJson);
    } catch (e) {
      print('Error processing GeoJSON: $e');
    }

    setState(() {
      loadingData = false;
    });
  }

  void _updateBasinAndNeighborhood() {
    final landNumber = _landNumberController.text.trim();
    if (landNumber.isEmpty) {
      _basinNumberController.clear();
      _neighborhoodNumberController.clear();
      return;
    }

    try {
      final land = LandData.findLandByParcelNumber(landNumber);
      if (land != null) {
        setState(() {
          _basinNumberController.text =
              land['properties']['رقم_ا']?.toString() ?? '';
          _neighborhoodNumberController.text =
              land['properties']['رقم__1']?.toString() ?? '';
        });
      } else {
        _basinNumberController.clear();
        _neighborhoodNumberController.clear();
      }
    } catch (e) {
      print('Error updating fields: $e');
      _basinNumberController.clear();
      _neighborhoodNumberController.clear();
    }
  }

  void _searchLand() {
    final landNumber = _landNumberController.text.trim();
    final basinNumber = _basinNumberController.text.trim();
    final neighborhoodNumber = _neighborhoodNumberController.text.trim();

    if (landNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم القطعة')),
      );
      return;
    }

    try {
      final candidateLand = LandData.findLandByParcelNumber(landNumber);

      if (candidateLand == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على القطعة')),
        );
        return;
      }

      bool matches = true;
      if (basinNumber.isNotEmpty) {
        matches = matches &&
            candidateLand['properties']['رقم_ا'].toString() == basinNumber;
      }
      if (neighborhoodNumber.isNotEmpty) {
        matches = matches &&
            candidateLand['properties']['رقم__1'].toString() ==
                neighborhoodNumber;
      }

      if (matches) {
        setState(() {
          _selectedLand = candidateLand;
          _isCardVisible = true;
        });
        print('Land found: $candidateLand');
        _plotLandPolygonAndMarker(candidateLand);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('لم يتم العثور على القطعة بالمعايير المحددة')),
        );
      }
    } catch (e) {
      print('Error searching land: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في البحث عن القطعة')),
      );
    }
  }

  void _plotLandPolygonAndMarker(Map<String, dynamic> land) {
    selectedPolygons.clear();
    selectedMarkers.clear();

    final geometryType = land['geometry']['type'];
    List<dynamic> polygonsCoords;

    if (geometryType == 'Polygon') {
      polygonsCoords = [land['geometry']['coordinates']];
    } else if (geometryType == 'MultiPolygon') {
      polygonsCoords = land['geometry']['coordinates'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsupported geometry type: $geometryType')),
      );
      return;
    }

    double sumLat = 0.0;
    double sumLng = 0.0;
    int pointCount = 0;

    for (var polygon in polygonsCoords) {
      var exteriorRing = polygon[0];
      List<LatLng> points = [];
      for (var coord in exteriorRing) {
        if (coord[0] != null && coord[1] != null) {
          double lng = coord[0];
          double lat = coord[1];
          points.add(LatLng(lat, lng));
          sumLat += lat;
          sumLng += lng;
          pointCount++;
        }
      }
      if (points.isNotEmpty) {
        selectedPolygons.add(
          Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.4),
            borderColor: Colors.green,
            borderStrokeWidth: 3.0,
            isFilled: true,
            label: land['properties']['number'].toString(),
          ),
        );
      }
    }

    if (pointCount > 0) {
      LatLng centroid = LatLng(sumLat / pointCount, sumLng / pointCount);
      selectedMarkers.add(
        Marker(
          point: centroid,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLand = land;
                _isCardVisible = !_isCardVisible;
              });
            },
            child: const Icon(
              Icons.location_pin,
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
      );
      mapController.move(centroid, 19.0);
    }

    setState(() {});
  }

  Future<void> _enableLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تفعيل خدمة تحديد المواقع GPS')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الوصول للموقع')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'إذن الوصول للموقع مرفوض بشكل دائم. يرجى تفعيله من إعدادات الجهاز'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      mapController.move(LatLng(position.latitude, position.longitude), 19);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الوصول للموقع: $e')),
      );
    }
  }

  void _flyToLocation(LatLng target) {
    final start = mapController.center;
    _flyAnimation = LatLngTween(begin: start, end: target).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeInOut),
    );
    _flyController.forward(from: 0.0);
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required double width,
  }) {
    return Container(
      width: width,
      height: 50,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 14,
            color: const Color.fromARGB(255, 5, 25, 41),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: const Color.fromARGB(255, 189, 152, 152)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: const Color.fromARGB(255, 224, 219, 219)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: const Color.fromARGB(255, 9, 24, 36)),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalIcon(IconData icon, String label,
      {required VoidCallback onPressed}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 8, 1, 45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(math.pi / 180 * tiltAngle)
                ..rotateZ(math.pi / 180 * bearing),
              alignment: Alignment.center,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(32.027292, 35.303998),
                  initialZoom: 13.3,
                ),
                children: [
                  TileLayer(
                    urlTemplate: showSatellite
                        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/{z}/{x}/{y}?access_token=${Constants.mapboxAccessToken}'
                        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${Constants.mapboxAccessToken}',
                    maxZoom: 19,
                  ),
                  if (showParcels && geoJsonParcelsService.polygons.isNotEmpty)
                    PolygonLayer(polygons: geoJsonParcelsService.polygons),
                  if (showLayers && geoJsonService.polygons.isNotEmpty)
                    PolygonLayer(polygons: geoJsonService.polygons),
                  PolygonLayer(polygons: selectedPolygons),
                  MarkerLayer(markers: selectedMarkers),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: 38, bottom: 8, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'خريطة الأراضي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.account_circle,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AccountScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.308,
            child: Column(
              children: [
                _buildVerticalIcon(
                  Icons.satellite,
                  'صور القمر الصناعي',
                  onPressed: () =>
                      setState(() => showSatellite = !showSatellite),
                ),
                _buildVerticalIcon(
                  Icons.zoom_in,
                  'تكبير',
                  onPressed: () => mapController.move(
                    mapController.center,
                    mapController.zoom + 0.5,
                  ),
                ),
                _buildVerticalIcon(
                  Icons.zoom_out,
                  'تصغير',
                  onPressed: () => mapController.move(
                    mapController.center,
                    mapController.zoom - 0.5,
                  ),
                ),
                _buildVerticalIcon(
                  Icons.gps_fixed,
                  'موقعي',
                  onPressed: _enableLocation,
                ),
                _buildVerticalIcon(
                  Icons.threed_rotation,
                  '3D تبديل',
                  onPressed: () => setState(() {
                    is3DMode = !is3DMode;
                    tiltAngle = is3DMode ? 45.0 : 0.0;
                  }),
                ),
                _buildVerticalIcon(
                  Icons.rotate_left,
                  'تدوير يسار',
                  onPressed: () => setState(() {
                    bearing = (bearing - 15) % 360;
                  }),
                ),
                _buildVerticalIcon(
                  Icons.rotate_right,
                  'تدوير يمين',
                  onPressed: () => setState(() {
                    bearing = (bearing + 15) % 360;
                  }),
                ),
                _buildVerticalIcon(
                  Icons.restore,
                  'إعادة تعيين',
                  onPressed: () => setState(() {
                    tiltAngle = 0.0;
                    bearing = 0.0;
                    mapController.move(LatLng(32.027292, 35.303998), 15.3);
                  }),
                ),
              ],
            ),
          ),
          if (_isCardVisible && _selectedLand != null)
            Positioned(
              top: 110,
              left: screenWidth / 3 - 55,
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: ArrowShapeBorder(arrowWidth: 20.0, arrowHeight: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  width: 238,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'القطعة ${_selectedLand!['properties'].containsKey('number') ? _selectedLand!['properties']['number'] : _selectedLand!['properties']['num']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 4),
                      Table(
                        columnWidths: {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: _selectedLand!['properties']
                            .entries
                            .map((entry) {
                              String key = entry.key;
                              dynamic value = entry.value;
                              String displayKey = key;
                              String displayValue =
                                  value?.toString() ?? 'غير متوفر';

                              switch (key) {
                                case 'الحوض':
                                  displayKey = 'اسم الحوض';
                                  break;
                                case 'Basin_name':
                                  displayKey = 'اسم الحوض';
                                  break;
                                case 'Basin_numb':
                                  displayKey = 'رقم الحوض';
                                  break;
                                case 'Neighborho':
                                  displayKey = 'الحي';
                                  break;
                                case 'Neighbor_1':
                                  displayKey = 'رقم الحي';
                                  break;
                                case 'رقم__1':
                                  displayKey = 'رقم الحي';
                                  break;
                                case 'اسم_ا':
                                  displayKey = 'المالك';
                                  break;
                                case 'رقم_ا':
                                  displayKey = 'رقم الحوض';
                                  break;
                                case 'المسا':
                                  displayKey = 'المساحة';
                                  displayValue = '$value م²';
                                  break;
                                case 'التخم':
                                  displayKey = 'التخمين';
                                  break;
                                case 'المال':
                                  displayKey = 'اسم المالك الآخر';
                                  break;
                                case 'سعر_ا':
                                  displayKey = 'السعر قبل التسوية';
                                  break;
                                case 'سعر__1':
                                  displayKey = 'السعر بعد التسوية';
                                  break;
                                case 'ملاحظ':
                                  displayKey = 'ملاحظات';
                                  break;
                                case 'FID':
                                case 'FID_':
                                case 'num':
                                case 'number':
                                  return null;
                                default:
                                  displayKey = key;
                              }

                              if (displayKey == key &&
                                  key.startsWith('رقم__')) {
                                return null;
                              }

                              return TableRow(
                                children: [
                                  Text(
                                    displayKey,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    displayValue,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              );
                            })
                            .where((row) => row != null)
                            .cast<TableRow>()
                            .toList(),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isCardVisible = false;
                            });
                          },
                          child: Text('إغلاق', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchField(
                          controller: _landNumberController,
                          hint: 'رقم القطعة',
                          width: (screenWidth - 48) / 3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildSearchField(
                          controller: _neighborhoodNumberController,
                          hint: 'رقم الحي',
                          width: (screenWidth - 48) / 3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildSearchField(
                          controller: _basinNumberController,
                          hint: 'رقم الحوض',
                          width: (screenWidth - 48) / 3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _searchLand,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(222, 5, 17, 28),
                        foregroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('بحث', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LandsAuctionsSearch()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountScreen()),
            );
          }
        },
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

  Future<List<Map<String, dynamic>>> getLandsByPlotNumber(
      String plotNumber) async {
    try {
      CollectionReference landsCollection =
          FirebaseFirestore.instance.collection('lands');
      QuerySnapshot querySnapshot = await landsCollection
          .where('plotNumber', isEqualTo: plotNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No lands found for PlotNumber: $plotNumber');
        return [];
      }

      List<Map<String, dynamic>> lands = [];
      for (var doc in querySnapshot.docs) {
        lands.add(doc.data() as Map<String, dynamic>);
      }

      return lands;
    } catch (e) {
      print("Error fetching lands: $e");
      return [];
    }
  }
}

class ArrowShapeBorder extends OutlinedBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double cornerRadius;

  ArrowShapeBorder({
    this.arrowWidth = 20.0,
    this.arrowHeight = 10.0,
    this.cornerRadius = 18.0,
    BorderSide side = BorderSide.none,
  }) : super(side: side);

  @override
  ui.Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double left = rect.left;
    final double top = rect.top;
    final double right = rect.right;
    final double bottom = rect.bottom;
    final double width = right - left;

    final path = ui.Path()
      ..moveTo(left + cornerRadius, top)
      ..lineTo(right - cornerRadius, top)
      ..quadraticBezierTo(right, top, right, top + cornerRadius)
      ..lineTo(right, bottom - cornerRadius)
      ..quadraticBezierTo(right, bottom, right - cornerRadius, bottom)
      ..lineTo(left + width / 2 + arrowWidth / 2, bottom)
      ..lineTo(left + width / 2, bottom + arrowHeight)
      ..lineTo(left + width / 2 - arrowWidth / 2, bottom)
      ..lineTo(left + cornerRadius, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - cornerRadius)
      ..lineTo(left, top + cornerRadius)
      ..quadraticBezierTo(left, top, left + cornerRadius, top)
      ..close();

    return path;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return ArrowShapeBorder(
      arrowWidth: arrowWidth * t,
      arrowHeight: arrowHeight * t,
      cornerRadius: cornerRadius * t,
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ArrowShapeBorder) {
      return ArrowShapeBorder(
        arrowWidth: ui.lerpDouble(a.arrowWidth, arrowWidth, t)!,
        arrowHeight: ui.lerpDouble(a.arrowHeight, arrowHeight, t)!,
        cornerRadius: ui.lerpDouble(a.cornerRadius, cornerRadius, t)!,
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ArrowShapeBorder) {
      return ArrowShapeBorder(
        arrowWidth: ui.lerpDouble(arrowWidth, b.arrowWidth, t)!,
        arrowHeight: ui.lerpDouble(arrowHeight, b.arrowHeight, t)!,
        cornerRadius: ui.lerpDouble(cornerRadius, b.cornerRadius, t)!,
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  ui.Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final Paint paint = side.toPaint();
    final ui.Path path = getOuterPath(rect, textDirection: textDirection);
    canvas.drawPath(path, paint);
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return ArrowShapeBorder(
      arrowWidth: arrowWidth,
      arrowHeight: arrowHeight,
      cornerRadius: cornerRadius,
      side: side ?? this.side,
    );
  }
}

class Constants {
  static const String mapboxAccessToken =
      'pk.eyJ1IjoiYWxpYWJ1aGF0YWIiLCJhIjoiY200YTI5YWVjMDM4eDJqczI0dXM2eHZyeCJ9.jB2Wc8mKHTx7KyJLnk5Q8Q';
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({LatLng? begin, LatLng? end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final lat = ui.lerpDouble(begin!.latitude, end!.latitude, t)!;
    final lng = ui.lerpDouble(begin!.longitude, end!.longitude, t)!;
    return LatLng(lat, lng);
  }
}
