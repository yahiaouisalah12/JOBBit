import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoire/Compane/HoneCompane.dart';

import 'package:memoire/Tabbar.dart';
import 'package:http/http.dart' as http;
import 'package:memoire/auth/self.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool _isVisible = false;
  // Add user type selection
  String _userType = 'jobseeker';

  Future<void> LoginJobSeeker() async {
    String baseUrl =
        "https://f7ec-154-240-177-190.ngrok-free.app/api/Auth/LogInJobSeeker";

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _email.text,
          'password': _password.text,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        final data = jsonDecode(response.body);
        print('Login successful: ${response.body}');

        // You can store the token in shared preferences here
        // final token = data['token'];
        // await SharedPreferences.getInstance().then((prefs) {
        //   prefs.setString('token', token);
        // });

        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => Tabbar()));
      } else {
        // Login failed
        print('Login failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  Future<void> LoginCompany() async {
    String baseUrl =
        "https://f7ec-154-240-177-190.ngrok-free.app/api/Auth/LogInCompany";

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _email.text,
          'password': _password.text,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        final data = jsonDecode(response.body);
        print('Company login successful: ${response.body}');

        // You can store the token in shared preferences here
        // final token = data['token'];
        // await SharedPreferences.getInstance().then((prefs) {
        //   prefs.setString('token', token);
        //   prefs.setString('userType', 'company');
        // });

        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Honecompane()));
      } else {
        // Login failed
        print('Company login failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error during company login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  Future<void> Login() async {
    if (_userType == 'jobseeker') {
      if (_email.text.contains('company')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not registered as a Job Seeker')),
        );
      } else {
        await LoginJobSeeker();
      }
    } else if (_userType == 'company') {
      if (_email.text.contains('jobseeker')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not registered as a Company')),
        );
      } else {
        await LoginCompany();
      }
    }
  }

  // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF36305E),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 80),
              Center(
                  child: Text(
                'Get Started',
                style: TextStyle(color: Colors.white, fontSize: 35),
              )),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),

                        // Add user type selection
                        Text(
                          "Login as",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF36305E),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Job Seeker'),
                                value: 'jobseeker',
                                groupValue: _userType,
                                activeColor: Color(0xFF36305E),
                                onChanged: (value) {
                                  setState(() {
                                    _userType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Company'),
                                value: 'company',
                                groupValue: _userType,
                                activeColor: Color(0xFF36305E),
                                onChanged: (value) {
                                  setState(() {
                                    _userType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        Text(
                          "ُEmail",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF36305E),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon:
                                  Icon(Icons.email, color: Color(0xFF36305E)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Color(0xFF36305E))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.grey))),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }

                            return null;
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "ُPassword",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF36305E),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _password,
                          obscureText: !_isVisible,
                          decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon:
                                  Icon(Icons.lock, color: Color(0xFF36305E)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF36305E),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isVisible = !_isVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide:
                                      BorderSide(color: Color(0xFF36305E))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.grey))),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Forgot password logic
                            },
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: Color(0xFF36305E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Call the appropriate login function based on user type
                                if (_userType == 'jobseeker') {
                                  LoginJobSeeker();
                                } else {
                                  LoginCompany();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF36305E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "Regester",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "Or Continue with",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF42A5F5),
                                    Color(0xFF1E88E5)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  // تسجيل الدخول باستخدام Google
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.asset(
                                    "images/google_gmail.png",
                                    height: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to register page
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SelfandCompany()));
                              },
                              child: Text(
                                "Register",
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF36305E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )));
  }
}
