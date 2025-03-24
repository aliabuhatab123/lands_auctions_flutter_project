import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gis/Screens/admin_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For encoding JSON data

class UpdatePoolsPage extends StatefulWidget {
  @override
  _UpdatePoolsPageState createState() => _UpdatePoolsPageState();
}

class _UpdatePoolsPageState extends State<UpdatePoolsPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _numberController = TextEditingController();
  TextEditingController _areaController = TextEditingController();
  TextEditingController _latController = TextEditingController();
  TextEditingController _longController = TextEditingController();
  File? _jsonFile;

  Future<void> _pickJsonFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _jsonFile = File(pickedFile.path);
      });
    }
  }

  // Function to submit the form data to the server
  Future<void> _submitForm() async {
    print("اسم الحوض: ${_nameController.text}");
    print("رقم الحوض: ${_numberController.text}");
    print("مساحة الحوض: ${_areaController.text}");
    print("الإحداثيات: ${_latController.text}, ${_longController.text}");
    print("الملف: ${_jsonFile?.path ?? "لم يتم اختيار ملف"}");

    var data = {
      'name': _nameController.text,
      'number': _numberController.text,
      'area': _areaController.text,
      'latitude': _latController.text,
      'longitude': _longController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://auctions-production.up.railway.app/api/basins'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text("تم إرسال البيانات بنجاح!")),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to another screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AdminPage()), // Change to your actual screen widget
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل في إرسال البيانات. حاول مرة أخرى."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI code remains unchanged
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? unit,
    bool isPassword = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon above the input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
          ),
          // Label above the input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                  color: const Color.fromARGB(255, 36, 10, 10), fontSize: 16),
            ),
          ),
          // Text Field with unit as a placeholder inside the input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  style: TextStyle(color: Colors.black, fontSize: 10),
                  decoration: InputDecoration(
                    labelText:
                        unit != null ? unit : null, // Unit as placeholder
                    labelStyle:
                        TextStyle(color: const Color.fromARGB(255, 35, 5, 5)),
                    prefixIcon: Icon(icon,
                        color: const Color.fromARGB(154, 52, 35, 19)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 250, 241, 241)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      width: 360,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shadowColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.symmetric(horizontal: 125, vertical: 22),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Ensures the row only takes the space it needs
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor),
              SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("تحديث الأحواض",
              style: TextStyle(color: const Color.fromARGB(255, 135, 80, 80))),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Column(
              children: [
                _buildTextField(
                  label: "اسم الحوض",
                  icon: Icons.landslide_outlined,
                  controller: _nameController,
                ),
                _buildTextField(
                  label: "رقم الحوض",
                  icon: Icons.numbers,
                  controller: _numberController,
                ),
                _buildTextField(
                  label: "مساحة الحوض",
                  icon: Icons.square_foot,
                  controller: _areaController,
                  unit: "م²", // Unit as a placeholder for area
                ),
                _buildTextField(
                  label: "خط العرض",
                  icon: Icons.more_horiz_sharp,
                  controller: _latController,
                ),
                _buildTextField(
                  label: "خط الطول",
                  icon: Icons.location_on,
                  controller: _longController,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 28),
                      _buildButton(
                        text: "اختيار ملف JSON",
                        onPressed: _pickJsonFile,
                        icon: Icons.attach_file,
                        backgroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
                        textColor: Colors.black,
                      ),
                      SizedBox(height: 20),
                      _buildButton(
                        text: "إدخال البيانات",
                        onPressed: _submitForm, // Call _submitForm when clicked
                        icon: Icons.send,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
