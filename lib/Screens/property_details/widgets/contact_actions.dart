import 'package:flutter/material.dart';

class ContactActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.broken_image_outlined,
              label: 'المشاركة بالمزاد',
              onTap: () {},
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'اتصل الان',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Color.fromARGB(235, 0, 0, 0),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
