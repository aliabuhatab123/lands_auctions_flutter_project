import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage({super.key});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  String? _otpErrorMessage;
  late Timer _timer;
  int _start = 60;
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String phoneNumber = '';
  String generatedOTP = '';
  bool isLoading = false;

  // Initialize Twilio
  final TwilioFlutter twilioFlutter = TwilioFlutter(
    accountSid: 'AC06f0bddfb47655f7546691e6470aecfe',
    authToken: 'e8dd0a829bd0f4b1a6acf4ebd1b24a45',
    twilioNumber: '+970595148311',
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, String>) {
      setState(() {
        phoneNumber = args['phoneNumber'] ?? '';
      });
    } else {
      print("Phone number argument is missing.");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    _sendOTP(); // Send OTP when page loads
  }

//
  void _startTimer() {
    _start = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_start < 1) {
          timer.cancel();
        } else {
          _start--;
        }
      });
    });
  }

  Future<void> sendOtp(String dialCode, String phoneNumber) async {
    TwilioResponse response = await twilioFlutter.sendVerificationCode(
      verificationServiceId: 'VA01f09b9411576db7fd451df8c79817c0',
      recipient: '$dialCode${phoneNumber.replaceAll(" ", "")}',
      verificationChannel: VerificationChannel.SMS,
    );

    if (response.responseState == ResponseState.SUCCESS) {
      print('OTP sent successfully.');
      // Update your UI accordingly
    } else {
      print('Failed to send OTP: ${response.responseState}');
    }
  }

  void _sendOTP() async {
    if (phoneNumber.isEmpty) {
      print("Phone number is empty");
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Generate a 6-digit OTP
    generatedOTP =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    try {
      await twilioFlutter.sendSMS(
        toNumber: phoneNumber,
        messageBody: 'رمز التحقق الخاص بك هو: $generatedOTP', // OTP in Arabic
      );

      print("OTP sent successfully to $phoneNumber");
    } catch (e) {
      print("Error sending OTP: $e");
      setState(() {
        _otpErrorMessage = "فشل إرسال رمز التحقق. حاول مرة أخرى.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _validateOTP() {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _otpErrorMessage = 'يرجى إدخال رمز تحقق مكون من 6 أرقام.';
      });
      return;
    }

    if (otp == generatedOTP) {
      print("تم التحقق من الرمز بنجاح");
      Navigator.pushNamed(context, '/home');
    } else {
      setState(() {
        _otpErrorMessage = 'رمز التحقق غير صالح. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPhoneNumberMessage(),
            const SizedBox(height: 32),
            _buildOTPInputs(),
            const SizedBox(height: 16),
            _buildResendSection(),
            const SizedBox(height: 24),
            _buildNextButton(),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (_otpErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _otpErrorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التحقق بواسطة رمز التحقق',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'أدخل رمز التحقق المرسل إلى $phoneNumber',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberMessage() {
    return Text(
      'لقد تم إرسال رمز إلى $phoneNumber',
      style: const TextStyle(fontSize: 16, color: Colors.grey),
    );
  }

  Widget _buildOTPInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return _buildOTPInputField(index);
      }),
    );
  }

  Widget _buildOTPInputField(int index) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'أعد الإرسال في $_start ثانية',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        TextButton(
          onPressed: _start == 0 ? _sendOTP : null,
          child: const Text(
            'إعادة إرسال رمز التحقق',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _validateOTP,
        child: const Text('التحقق من رمز التحقق'),
      ),
    );
  }
}
