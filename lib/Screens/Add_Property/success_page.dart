import 'package:flutter/material.dart';
import 'package:gis/Screens/My_Properties/my_prop.dart';
import 'package:gis/Screens/account.dart';
// import 'package:gis/Screens/home_page.dart';
import 'package:lottie/lottie.dart';

class SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation (Replace with an actual Lottie URL)
              Lottie.network(
                'https://lottie.host/0a737abc-efbc-40bd-a206-2a68651b18a6/0gIXVNJSzu.json',
                height: 250,
                width: 250,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 24),

              // Success Message
              Text(
                "لقد استلمنا طلبك\nسنقوم بمراجعة المعلومات التي قمت بتزويدها\nسنرد عليك بغضون 24 ساعة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 30),

              // Return to Home Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyPropertiesScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color: const Color.fromARGB(255, 239, 241, 239),
                      width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  " عقاراتي",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
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
