import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String _errorMessage = ''; // Store error message to display

  // Regular expression for phone number validation
  bool isPhoneValid(String phone) {
    final phoneRegExp = RegExp(r'^(059|056)[0-9]{7}$');
    return phoneRegExp.hasMatch(phone);
  }

  void _formatPhoneNumber(String phone) {
    // Remove 11th character if phone number is longer than 10 digits
    if (phone.length > 10) {
      phone = phone.substring(0, 10); // Keep only the first 10 digits
      _phoneController.text = phone; // Update the controller with the new value
      _phoneController.selection = TextSelection.collapsed(
          offset: phone.length); // Place cursor at the end
    }
  }

  Future<void> _login() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    // Format phone number before proceeding
    _formatPhoneNumber(phone);

    if (phone.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال جميع الحقول'; // Error message in Arabic
      });
      return;
    }

    // Check if the credentials match the admin login
    if (phone == '0594725923' && password == 'admin') {
      // Save session data for admin login
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', 'admin');
      await prefs.setBool('isLoggedIn', true);

      // Navigate to the admin screen
      Navigator.pushNamed(context, '/admin');
      return; // Don't continue to Firebase logic for admin user
    }

    // Check phone number format
    if (!isPhoneValid(phone)) {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم جوال صحيح يبدأ بـ 059 أو 056';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve email associated with phone number from Firestore
      var snapshot = await FirebaseFirestore.instance
          .collection(
              'users') // Assuming 'users' collection stores the user info
          .where('phone', isEqualTo: phone)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'رقم الجوال غير مسجل';
        });
        return;
      }

      // Get the email from the first document (assuming one user per phone number)
      String email = snapshot.docs.first['email'];

      // Authenticate with Firebase using the retrieved email and entered password
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        setState(() {
          _errorMessage = 'يرجى التحقق من بريدك الإلكتروني';
        });

        // Allow user to resend the verification email and handle wait time
        await _showResendEmailDialog(userCredential.user!);

        return; // Don't proceed to home screen if email is not verified
      }

      // Save session data locally
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // After successful login
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setBool('isLoggedIn', true);

      // Save login timestamp
      DateTime now = DateTime.now();
      await prefs.setInt('loginTimestamp', now.millisecondsSinceEpoch);

      // Navigate to Home Page
      Navigator.pushNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'رقم الجوال غير مسجل';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'كلمة المرور غير صحيحة';
      } else {
        errorMessage = 'كلمة المرور غير صحيحة';
      }

      setState(() {
        _errorMessage = errorMessage; // Update error message
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: $e'; // General error message
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Method to show the Resend Email dialog
  Future<void> _showResendEmailDialog(User user) async {
    // 60 seconds wait time logic
    int waitTime = 30;
    bool canResend = false;

    setState(() {
      _errorMessage =
          'يمكنك المحاولة بعد 30 ثانية من الان لانك لم تثبت بريدك الالكتروني';
    });

    while (waitTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      waitTime--;
      if (waitTime == 0) {
        canResend = true;
        setState(() {
          _errorMessage =
              'لم تقم بالتحقق من البريد الإلكتروني بعد. يمكنك الآن إعادة إرسال الرابط.';
        });
      }
    }

    if (canResend) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('إعادة إرسال رابط التحقق'),
            content: const Text('هل تريد إعادة إرسال رابط التحقق؟'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    setState(() {
                      _errorMessage =
                          'تم إرسال رابط التحقق إلى بريدك الإلكتروني.';
                    });
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'حدث خطأ في إرسال الرابط: $e';
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('إرسال الرابط'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('إلغاء'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 68),
              // Breadcrumb Navigation
              Row(
                children: [
                  const Text(
                    'البداية',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  const Icon(Icons.arrow_right, color: Colors.black, size: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.arrow_right, color: Colors.black, size: 18),
                  const Text(
                    'التحقق من الهاتف',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'رقم الجوال',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged:
                    _formatPhoneNumber, // Listen for phone number changes
                decoration: InputDecoration(
                  hintText: 'ادخل رقم جوالك',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'كلمة المرور',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'ادخل كلمة المرور',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Reset Password Logic
                    },
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(215, 24, 5, 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color.fromARGB(255, 0, 0, 0))
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 12),
                          ),
                  ),
                ],
              ),
              // Display Error Message if Exists
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'انشأ حساب جديد',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
