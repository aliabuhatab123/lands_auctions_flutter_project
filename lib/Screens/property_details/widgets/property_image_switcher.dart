import 'package:flutter/material.dart';

class PropertyImageSwitcher extends StatefulWidget {
  final String propertyId;

  const PropertyImageSwitcher({Key? key, required this.propertyId})
      : super(key: key);

  @override
  _PropertyImageSwitcherState createState() => _PropertyImageSwitcherState();
}

class _PropertyImageSwitcherState extends State<PropertyImageSwitcher> {
  int _currentIndex = 0;

  final List<String> _images = [
    'assets/img3.jpg',
    'assets/img4.jpg',
    'assets/img5.jpg',
  ];

  void _nextImage() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;
    });
  }

  void _previousImage() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _images.length) % _images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildImageSwitcher(),
        ],
      ),
    );
  }

  Widget _buildImageSwitcher() {
    return Container(
      width: double.infinity,
      height: 325,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(100)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(
                    255, 237, 235, 235), // Set the border color
                width: 2, // Set the border width
              ),
              // Optional: for rounded corners
            ),
            child: Image(
              image: AssetImage(_images[_currentIndex]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 325,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Container(
                    child: Icon(Icons.error_outline,
                        size: 40, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color:
                    const Color.fromARGB(255, 178, 167, 167).withOpacity(0.6),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Color.fromARGB(255, 255, 255, 255), size: 26),
                onPressed: _previousImage,
              ),
            ),
          ),
          Positioned(
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color:
                    const Color.fromARGB(255, 178, 167, 167).withOpacity(0.6),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Color.fromARGB(255, 255, 255, 255), size: 26),
                onPressed: _previousImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
