import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import 'admin_signup_screen.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminPanelScreen()));
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
                Text("Login", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Please sign in to continue.", style: TextStyle(color: Colors.white70)),
                SizedBox(height: 32),
                CustomTextField(hint: "Email", icon: Icons.email, controller: emailController, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 16),
                CustomTextField(hint: "Password", icon: Icons.lock, controller: passwordController, obscure: true),
                if (error != null) ...[
                  SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: Colors.redAccent)),
                ],
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      if (emailController.text.isNotEmpty) {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset email sent!")));
                      }
                    },
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ),
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
                    onPressed: loading ? null : login,
                    child: loading ? CircularProgressIndicator() : Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSignUpScreen()));
                      },
                      child: Text("Sign up", style: TextStyle(color: Colors.cyanAccent)),
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