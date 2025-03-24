import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geojson_service.dart';
import '../JSON_DATA/geo_json_data.dart'; // GeoJSON data file

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GeoJsonService geoJsonService = GeoJsonService();
  bool loadingData = true;

  bool showLayers = true; // Single variable to control visibility of all layers
  bool showTable = false; // For showing table with land data

  @override
  void initState() {
    super.initState();

    // Set marker tap callback
    geoJsonService.setMarkerTapCallback((map) {
      // Print marker data when tapped
      print('Marker tapped: $map');
    });

    // Set filter function (optional)
    geoJsonService.filterFunction = (properties) {
      return properties['section'] != 'Point M-4';
    };

    // Process GeoJSON data
    geoJsonService.processGeoJsonData(neighborhoodJsonString).then((_) {
      setState(() {
        loadingData = false;
      });
    });
  }

  // Toggle visibility for all layers
  void toggleLayersVisibility() {
    setState(() {
      showLayers = !showLayers;
    });
  }

  // Function to show the land data table
  void showLandDataTable() {
    setState(() {
      showTable = !showTable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الخريطة',
          textAlign: TextAlign.right,
        ),
        actions: [
          IconButton(
            icon: Icon(showLayers
                ? Icons.visibility
                : Icons
                    .visibility_off), // Toggle visibility icon for all layers
            onPressed:
                toggleLayersVisibility, // Toggle visibility of all layers
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: showLandDataTable,
          ),
        ],
      ),
      body: loadingData
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(32.288, 35.363),
                    initialZoom: 12,
                    maxZoom: 70.0,
                    minZoom: 1.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.mapbox.com/styles/v1/aliabuhatab/cm4a8hf7200ad01qt6g0geazf/tiles/256/{level}/{col}/{row}@2x?access_token=pk.eyJ1IjoiYWxpYWJ1aGF0YWIiLCJhIjoiY200OHR4dnFzMDNjMzJyc2t6aDF6eDhvcCJ9.5IoeGMp7wIbr-mA7uuypKw',
                      additionalOptions: {
                        'accessToken':
                            'pk.eyJ1IjoiYWxpYWJ1aGF0YWIiLCJhIjoiY200OHR4dnFzMDNjMzJyc2t6aDF6eDhvcCJ9.5IoeGMp7wIbr-mA7uuypKw',
                      },
                    ),
                    if (showLayers) ...[
                      PolygonLayer(polygons: geoJsonService.polygons),
                      PolylineLayer(polylines: geoJsonService.polylines),
                      MarkerLayer(markers: geoJsonService.markers),
                      CircleLayer(circles: geoJsonService.circles),
                    ],
                  ],
                ),
                if (showTable)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Directionality(
                      textDirection:
                          TextDirection.rtl, // Set text direction to RTL
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.white.withOpacity(0.8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'بيانات الأرض:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // Arabic Table
                            Table(
                              border: TableBorder.all(),
                              children: [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('المجال'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("تصلح للبناء"),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('المساحة'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('500 متر مربع'),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('المالك'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("اجمد مصطفى بشارات"),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('السعر'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("12 الف دينار"),
                                    ),
                                  ],
                                ),
                              ],
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
