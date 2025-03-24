// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedFile;

  // Pick file from device
  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
      });
    }
  }

  // Submit the form data
  void _submitForm() {
    if (_selectedFile == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
    } else {
      // You can handle the file upload and description here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم رفع الملف بنجاح')),
      );
      // Clear the form after submission
      setState(() {
        _selectedFile = null;
        _descriptionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع الملفات'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File selection section
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey[200],
                  ),
                  child: _selectedFile == null
                      ? Center(
                          child: Icon(Icons.upload_file, size: 40),
                        )
                      : Image.file(
                          _selectedFile!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Description field
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'أدخل وصف الملف',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Submit button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('رفع الملف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
