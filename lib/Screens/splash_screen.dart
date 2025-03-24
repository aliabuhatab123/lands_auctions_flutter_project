import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg.png', // Replace with your background image
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black
                      .withOpacity(0.9), // More black at the top (100px area)
                  Colors.black.withOpacity(0.6),
                  Colors.transparent, // Transparent in the center
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(
                      0.9), // More black at the bottom (100px area)
                ],
                stops: [0.0, 0.1, 0.4, 0.9, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 38, 12, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Diyar',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'IBM_Bold',
                          fontSize: 72),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 124),
                        child: Text(
                          'د يار',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'IBM_Regular',
                              fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const SizedBox(
                      width: 320,
                      child: Text(
                        textDirection: TextDirection.rtl,
                        "اطلب عقارك بطريقة آمنة",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontFamily: "IBM_Bold"),
                      ),
                    ),
                    const SizedBox(
                      width: 300,
                      height: 24,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        backgroundColor: const Color.fromARGB(
                            255, 255, 255, 255), // Button background color
                        foregroundColor: const Color.fromARGB(
                            255, 0, 0, 0), // Button text color
                        textStyle: const TextStyle(
                            fontSize: 16, fontFamily: "IBM_SemiBold"),
                      ),
                      child: const Text(
                        'ابدأ الآن',
                        style: TextStyle(fontSize: 12),
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
}
