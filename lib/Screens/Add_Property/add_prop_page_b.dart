import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gis/Screens/Add_Property/success_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:http/http.dart' as http;

class IdVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> formData;
  const IdVerificationScreen({Key? key, required this.formData})
      : super(key: key);

  @override
  _IdVerificationScreenState createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  @override
  void initState() {
    super.initState();
    _GetBasins(); // Call the API when the widget initializes
  }

  bool isLoading = false; // Flag to track if data is uploading

  // Function to show loading screen
  void _showLoading() {
    setState(() {
      isLoading = true;
    });
  }

  // Function to hide loading screen
  void _hideLoading() {
    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> formattedBasins = [];
  String? selectedDistrict = 'الثعلا';
  Future<void> _GetBasins() async {
    try {
      String apiEndpoint =
          "https://auctions-production.up.railway.app/api/basins";

      var response = await http.get(Uri.parse(apiEndpoint));

      if (response.statusCode == 200) {
        List<dynamic> basins = jsonDecode(response.body);

        formattedBasins = basins.map((basin) {
          return {"basinId": basin['id'], "name": basin['name']};
        }).toList();

        // print(formattedBasins); // Just for debugging purposes
        setState(() {
          formattedBasins = formattedBasins;
        }); // Refresh the UI after fetching data
      } else {
        throw Exception('Failed to get data basins: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  String landId = '';
  Future<void> _uploadDataToAPI() async {
    _showLoading();
    try {
      // First, upload images and get the URLs
      final uploadedUrls = await _uploadImages();

      // Prepare the JSON body for the land API
      Map<String, dynamic> jsonData = {
        'basinId': formattedBasins.firstWhere(
            (basin) => basin['name'] == selectedDistrict)['basinId'],
        'traderId': '67ad2052e4b8607f47e84cb7',
        'name': widget.formData['name'],
        'neighborhood': widget.formData['neighborhood'],
        'location': widget.formData['location'],
        'priceBefore': widget.formData['priceBefore'],
        'priceAfter': widget.formData['priceAfter'],
        'ownerName': widget.formData['ownerName'],
        'ownerPhone': widget.formData['ownerPhone'],
        'ownerNationalId': widget.formData['ownerId'],
      };

      var response = await http.post(
        Uri.parse('https://auctions-production.up.railway.app/api/lands'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        landId = responseData['id'];
        print("Land created with ID: $landId");

        // Create auction for the land
        await _createAuction(landId);

        // Now upload all data to Firestore only once using the image URLs
        await _uploadDataToFirestore(
            uploadedUrls['landDocumentsUrls']!,
            uploadedUrls['userDocumentsUrls']!,
            uploadedUrls['landImagesUrls']!,
            landId);
      } else {
        throw Exception(
            "Failed to upload land. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackbar('فشل رفع البيانات. يرجى المحاولة لاحقًا.');
      print("API error: $e");
    } finally {
      _hideLoading();
    }
  }

  Future<void> _createAuction(String landId) async {
    try {
      Map<String, dynamic> auctionData = {
        "landId": landId,
        "startPrice": widget.formData['priceAfter'],
        "endAt": DateTime.now().add(Duration(days: 30)).toIso8601String(),
      };

      var response = await http.post(
        Uri.parse('https://auctions-production.up.railway.app/api/auctions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(auctionData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Auction created successfully for landId: $landId");
      } else {
        throw Exception(
            "Failed to create auction. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Auction API error: $e");
    }
  }

  List<File> _landDocuments = [];
  List<File> _userDocuments = [];
  List<File> _landImages = [];

  Future<void> _uploadDataToFirestore(
    List<String> landDocumentsUrls,
    List<String> userDocumentsUrls,
    List<String> landImagesUrls,
    String landId,
  ) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("No user is logged in.");
      }

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Extract user-specific data
      String userId = userDoc['user_id']; // Assuming Firestore stores user_id
      String email = user.email ?? ''; // User email from Firebase Auth
      String name = userDoc['name'] ?? ''; // User name from Firestore
      String phone = userDoc['phone'] ?? ''; // User phone from Firestore

      // Prepare the data to save in Firestore
      Map<String, dynamic> formData = {
        'formData': widget.formData, // Include the form data
        'landsDocumentsUrls': landDocumentsUrls,
        'userDocumentsUrls': userDocumentsUrls,
        'landsImagesUrls': landImagesUrls,
        'landId': landId,
        'userId': userId, // Use the session user_id from Firestore
        'email': email, // User email
        'name': name, // User name
        'phone': phone, // User phone number
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
      };

      // Save the data to Firestore in the "lands" collection
      await FirebaseFirestore.instance.collection('lands').add(formData);

      _showSnackbar('تم رفع البيانات بنجاح!');

      // Navigate to Success Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SuccessScreen()),
      );
    } catch (e) {
      _showSnackbar('فشل رفع البيانات. يرجى المحاولة لاحقًا.');
      print(e);
    }
  }

  Future<void> _pickImage(ImageSource source, String section) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        // Use application documents directory (persistent storage)
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final permanentPath = '${appDir.path}/$fileName';

        // Create permanent reference
        final permanentFile = File(permanentPath);

        // Verify original file exists
        if (!await File(pickedFile.path).exists()) {
          throw Exception("Original file missing: ${pickedFile.path}");
        }

        // Copy with verification
        await permanentFile.writeAsBytes(
            await File(pickedFile.path).readAsBytes(),
            flush: true);

        // Immediate verification
        if (!await permanentFile.exists()) {
          throw Exception("Failed to create permanent file copy");
        }

        setState(() {
          switch (section) {
            case 'land':
              _landImages.add(permanentFile);
              break;
            case 'user':
              _userDocuments.add(permanentFile);
              break;
            case 'landDocuments':
              _landDocuments.add(permanentFile);
              break;
          }
        });

        print("Persisted file to: ${permanentFile.path}");
        print("File exists after save: ${await permanentFile.exists()}");
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء اختيار الصورة');
      print("Image pick error: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<Map<String, List<String>>> _uploadImages() async {
    final List<String> landDocumentsUrls = [];
    final List<String> userDocumentsUrls = [];
    final List<String> landImagesUrls = [];

    Future<void> uploadFiles(List<File> files, List<String> urls) async {
      for (final file in files) {
        try {
          if (!file.existsSync()) {
            throw Exception("File vanished: ${file.path}");
          }
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/dewar7lsn/raw/upload'),
          );
          request.fields['upload_preset'] = 'upload_preset1';
          request.files
              .add(await http.MultipartFile.fromPath('file', file.path));

          var response = await request.send();
          if (response.statusCode != 200) {
            throw Exception("Upload failed: ${response.reasonPhrase}");
          }
          var jsonResponse = json.decode(await response.stream.bytesToString());
          urls.add(jsonResponse['secure_url']);
        } catch (e) {
          print("Upload error for ${file.path}: $e");
          rethrow;
        }
      }
    }

    try {
      await uploadFiles(_landDocuments, landDocumentsUrls);
      await uploadFiles(_userDocuments, userDocumentsUrls);
      await uploadFiles(_landImages, landImagesUrls);
      print("Successfully uploaded all files");
    } catch (e) {
      _showSnackbar('فشل الرفع: ${e.toString().split(':').first}');
      print("Global upload error: $e");
      rethrow;
    }

    return {
      'landDocumentsUrls': landDocumentsUrls,
      'userDocumentsUrls': userDocumentsUrls,
      'landImagesUrls': landImagesUrls,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(159, 255, 246, 246),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('التحقق من الهوية',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'قم برفع صورة من بطاقة الهوية الوطنية ووثائق الأرض',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 0, 0, 0))),
                        const SizedBox(height: 14),
                        // Land Documents Section
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 252, 246, 246)
                                    .withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 5,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              UploadSection(
                                sectionTitle: 'وثائق الأرض',
                                onPickImageFromGallery: () => _pickImage(
                                    ImageSource.gallery, 'landDocuments'),
                                onPickImageFromCamera: () => _pickImage(
                                    ImageSource.camera, 'landDocuments'),
                              ),
                              _landDocuments.isEmpty
                                  ? Container()
                                  : ImageGrid(images: _landDocuments),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // User Documents Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 5,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              UploadSection(
                                sectionTitle: 'وثائق المستخدم',
                                onPickImageFromGallery: () =>
                                    _pickImage(ImageSource.gallery, 'user'),
                                onPickImageFromCamera: () =>
                                    _pickImage(ImageSource.camera, 'user'),
                              ),
                              _userDocuments.isEmpty
                                  ? Container()
                                  : ImageGrid(images: _userDocuments),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        // Land Images Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 5,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              UploadSection(
                                sectionTitle: 'صور الأرض',
                                onPickImageFromGallery: () =>
                                    _pickImage(ImageSource.gallery, 'land'),
                                onPickImageFromCamera: () =>
                                    _pickImage(ImageSource.camera, 'land'),
                              ),
                              _landImages.isEmpty
                                  ? Container()
                                  : ImageGrid(images: _landImages),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        ContinueButton(onContinue: () {
                          // _uploadImages();
                          _uploadDataToAPI();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black
                    .withOpacity(0.5), // Semi-transparent background
                child: Center(
                  child: SpinKitCircle(
                    color: Colors.white, // Spinner color
                    size: 50.0, // Size of the spinner
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SpinKitCircle extends StatelessWidget {
  final double size;
  final Color color;

  SpinKitCircle({this.size = 50.0, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Center(
          child: Transform.rotate(
            angle: pi / 2,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
// Other widgets (UploadSection, ImageGrid, ContinueButton) remain unchanged.

class UploadSection extends StatelessWidget {
  final String sectionTitle;
  final VoidCallback onPickImageFromGallery;
  final VoidCallback onPickImageFromCamera;

  const UploadSection({
    Key? key,
    required this.sectionTitle,
    required this.onPickImageFromGallery,
    required this.onPickImageFromCamera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            255, 255, 255, 255), // White background for the container
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(176, 134, 207, 224)
                .withOpacity(0.1), // Light shadow
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color.fromARGB(255, 207, 207, 207)
                .withOpacity(0.09), // Subtle gradient-like shadow at the bottom
            blurRadius: 4,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(
                onTap: onPickImageFromGallery,
                icon: Icons.upload_file,
                label: 'رفع صورة من المعرض',
              ),
              _buildButton(
                onTap: onPickImageFromCamera,
                icon: Icons.camera_alt,
                label: 'فتح الكاميرا',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(225, 242, 240, 240),
              const Color.fromARGB(224, 255, 243, 240),
              const Color.fromARGB(255, 254, 254, 254)
            ], // Gradient for buttons
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 255, 255, 255)
                  .withOpacity(0.1), // Button shadow
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color.fromARGB(255, 32, 0, 0)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageGrid extends StatelessWidget {
  final List<File> images;

  const ImageGrid({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 190 / 170,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.file(images[index], fit: BoxFit.cover);
        },
      ),
    );
  }
}

class ContinueButton extends StatelessWidget {
  final VoidCallback onContinue;

  const ContinueButton({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        color: Colors.white,
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onContinue,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              'اكمال الطلب',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CameraButton extends StatelessWidget {
  final VoidCallback onPickImage;

  const CameraButton({Key? key, required this.onPickImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.fromARGB(255, 255, 255, 255),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onPickImage,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color.fromARGB(255, 0, 0, 0),
              width: 0.8,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 20,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(width: 16),
              Text(
                'فتح الكاميرا والتقاط صورة',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 62, 11, 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
