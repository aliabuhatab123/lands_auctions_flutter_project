import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _nameErrorMessage;
  String? _idErrorMessage;
  String? _phoneErrorMessage;
  String? _passwordErrorMessage;
  String? _emailErrorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // Added loading state

  Future<void> _signUp(String role) async {
    setState(() => _isLoading = true);

    try {
      // 1. Create user with Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Send email verification
      await userCredential.user?.sendEmailVerification();

      // 3. Save user data to Firestore 'users' collection
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'user_id': _idController.text.trim(),
        'email': _emailController.text.trim(),
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. External API call
      final String url = "https://auctions-production.up.railway.app/api/users";
      final Map<String, dynamic> requestBody = {
        "username": _nameController.text.trim(),
        "role": role,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال البيانات بنجاح!')),
        );
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ارسلنا رابط للتحقق من بريدك الالكتروني')),
      );

      // Navigate to login page
      if (_phoneController.text.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/login',
          arguments: {
            'phoneNumber': "+970${_phoneController.text.trim().substring(1)}",
            'email': _emailController.text.trim(),
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جدًا';
          setState(() => _passwordErrorMessage = errorMessage);
          break;
        case 'email-already-in-use':
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          setState(() => _emailErrorMessage = errorMessage);
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صالح';
          setState(() => _emailErrorMessage = errorMessage);
          break;
        default:
          errorMessage = 'فشل في التسجيل، حاول مرة أخرى';
          setState(() => _emailErrorMessage = errorMessage);
      }
      print("Firebase Auth Error: $errorMessage");
    } catch (e) {
      print("General error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ. حاول مرة أخرى')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _validateForm(String role) {
    setState(() {
      _nameErrorMessage = null;
      _idErrorMessage = null;
      _phoneErrorMessage = null;
      _passwordErrorMessage = null;
      _emailErrorMessage = null;

      // Name validation
      if (_nameController.text.isEmpty) {
        _nameErrorMessage = 'الاسم الكامل مطلوب';
      } else if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]{1,50}$')
          .hasMatch(_nameController.text)) {
        _nameErrorMessage = 'الاسم يجب أن يكون بحد أقصى 50 حرفًا';
      }

      // Email validation
      if (_emailController.text.isEmpty) {
        _emailErrorMessage = 'البريد الإلكتروني مطلوب';
      } else if (!RegExp(
              r'^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com|hotmail\.com|outlook\.com|example\.com)$')
          .hasMatch(_emailController.text)) {
        _emailErrorMessage =
            'البريد الإلكتروني يجب أن ينتهي بـ @gmail.com، @yahoo.com، أو @hotmail.com';
      }

      // ID validation
      if (_idController.text.isEmpty) {
        _idErrorMessage = 'رقم الهوية مطلوب';
      } else if (!RegExp(r'^\d{9}$').hasMatch(_idController.text)) {
        _idErrorMessage = 'رقم الهوية يجب أن يكون مكونًا من 9 أرقام';
      }

      // Phone validation
      if (_phoneController.text.isEmpty) {
        _phoneErrorMessage = 'رقم الهاتف مطلوب';
      } else if (!RegExp(r'^(059|056)\d{7}$').hasMatch(_phoneController.text)) {
        _phoneErrorMessage =
            'رقم الهاتف يجب أن يبدأ بـ 059 أو 056 ويكون مكونًا من 10 أرقام';
      }

      // Password validation
      if (_passwordController.text.isEmpty) {
        _passwordErrorMessage = 'كلمة المرور مطلوبة';
      } else if (!RegExp(
              r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&+])[A-Za-z\d@$!%*?&+]{6,}$')
          .hasMatch(_passwordController.text)) {
        _passwordErrorMessage =
            'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل، رقم، حرف كبير، ورمز خاص';
      }

      // If all validations pass, proceed with signup
      if (_nameErrorMessage == null &&
          _idErrorMessage == null &&
          _phoneErrorMessage == null &&
          _passwordErrorMessage == null &&
          _emailErrorMessage == null) {
        FocusScope.of(context).unfocus();
        _signUp(role);
      } else {
        print("Form is invalid, errors present");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 50)),
                const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(201, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _nameController,
                  label: 'الاسم الكامل',
                  hint: 'أدخل اسمك الرباعي',
                  icon: Icons.person,
                  errorMessage: _nameErrorMessage,
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _emailController,
                  label: 'الايميل الالكتروني',
                  hint: 'ادخل بريدك الالكتروني',
                  icon: Icons.email, // Changed to email icon
                  errorMessage: _emailErrorMessage,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _idController,
                  label: 'رقم الهوية',
                  hint: 'أدخل رقم الهوية',
                  isNumeric: true,
                  icon: Icons.credit_card,
                  errorMessage: _idErrorMessage,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  hint: 'أدخل رقم جوالك',
                  icon: Icons.phone,
                  errorMessage: _phoneErrorMessage,
                  isNumeric: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock,
                  isPassword: true,
                  errorMessage: _passwordErrorMessage,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نسيت كلمة المرور؟',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset_password');
                      },
                      child: const Text(
                        'إعادة تعيين كلمة المرور',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _validateForm("TRADER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Center(
                            child: Text(
                              'تسجيل كتاجر',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'DINNextLTArabic'),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _validateForm("browserUser"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'تسجيل كمستعرض',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'DINNextLTArabic'),
                      ),
                    ),
                  ),
                ),
                _buildErrorMessage(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟',
                        style: TextStyle(fontSize: 14)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? errorMessage,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(153, 72, 7, 7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: const Color.fromARGB(255, 241, 237, 237), width: 1),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(233, 220, 211, 211).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: Color.fromARGB(255, 159, 152, 152)),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
              prefixIcon: Icon(
                icon,
                size: 28,
                color: Colors.black,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: isPassword,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            enabled: !_isLoading, // Disable input during loading
          ),
        ),
        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Visibility(
      visible: _nameErrorMessage != null ||
          _idErrorMessage != null ||
          _phoneErrorMessage != null ||
          _passwordErrorMessage != null ||
          _emailErrorMessage != null,
      child: const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          'يرجى تعبئة جميع الحقول بشكل صحيح',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
