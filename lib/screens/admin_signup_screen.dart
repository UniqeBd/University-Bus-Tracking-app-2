import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import 'admin_login_screen.dart';

class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> signUp() async {
    setState(() { loading = true; error = null; });
    if (passwordController.text != confirmPasswordController.text) {
      setState(() { error = "Passwords do not match"; loading = false; });
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pop(context); // Go back to login
    } catch (e) {
      setState(() { error = e.toString(); });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF23243A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF18192A),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 24),
                Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Please fill the input below here", style: TextStyle(color: Colors.white70)),
                SizedBox(height: 32),
                CustomTextField(hint: "Full Name", icon: Icons.person, controller: nameController),
                SizedBox(height: 16),
                CustomTextField(hint: "Phone", icon: Icons.phone, controller: phoneController, keyboardType: TextInputType.phone),
                SizedBox(height: 16),
                CustomTextField(hint: "Email", icon: Icons.email, controller: emailController, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 16),
                CustomTextField(hint: "Password", icon: Icons.lock, controller: passwordController, obscure: true),
                SizedBox(height: 16),
                CustomTextField(hint: "Confirm Password", icon: Icons.lock, controller: confirmPasswordController, obscure: true),
                if (error != null) ...[
                  SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: Colors.redAccent)),
                ],
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: loading ? null : signUp,
                    child: loading ? CircularProgressIndicator() : Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Sign in", style: TextStyle(color: Colors.cyanAccent)),
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
} 