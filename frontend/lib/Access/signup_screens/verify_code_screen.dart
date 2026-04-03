import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/Access/login_screens/Login_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String role;
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.role,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController codeController = TextEditingController();
  bool _isLoading = false;

  static const String baseUrl = 'http://10.0.2.2:5000';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      _showMessage("Please enter the verification code");
      return;
    }

    if (code.length != 6) {
      _showMessage("Code must be 6 digits");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "verificationCode": code,
        }),
      );

      debugPrint("VERIFY STATUS: ${response.statusCode}");
      debugPrint("VERIFY BODY: ${response.body}");

      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        _showMessage("Verification successful. Please login.");

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _showMessage(
          data["message"]?.toString() ??
              data["error"]?.toString() ??
              "Invalid or expired verification code",
        );
      }
    } catch (e) {
      _showMessage("Verification failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "Enter the 6-digit verification code",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "We sent a verification code to:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Verification Code",
                hintText: "Enter code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}