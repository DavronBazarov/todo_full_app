import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth.dart';
import '../services/http_exception.dart';

enum AuthMode { register, login }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _passwordController = TextEditingController();
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Xatolik"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text("Okay!"),
              ),
            ],
          );
        });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      ///save form
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        if (_authMode == AuthMode.login) {
          //Login
          await Provider.of<Auth>(context, listen: false).signIn(
            _authData['email']!,
            _authData['password']!,
          );
        } else {
          //Register
          await Provider.of<Auth>(context, listen: false).signUp(
            _authData['email']!,
            _authData['password']!,
          );
        }
      } on HttpException catch (error) {
        var errorMessage = "Xatolik sodir bo'ldi";
        if (error.message.contains("EMAIL_EXISTS")) {
          errorMessage = "Bu email oldin ro'yxatdan o'tgan";
        } else if (error.message.contains("TOO_MANY_ATTEMPTS_TRY_LATER")) {
          errorMessage = "Ko'p urunish bo'ldi keyinroq urinib ko'ring";
        } else if (error.message.contains("EMAIL_NOT_FOUND")) {
          errorMessage = "Bu email orqali foydalanuvchi ro'yxatdan o'tmagan";
        } else if (error.message.contains("INVALID_PASSWORD")) {
          errorMessage = "Prol nato'g'ri";
        } else if (error.message.contains("USER_DISABLED")) {
          errorMessage = "Bu foydalanuvchi bloklangan";
        } else if (error.message.contains("INVALID_LOGIN_CREDENTIALS")) {
          errorMessage = "Login yoki parol xato!";
        }
        _showErrorDialog(errorMessage);
      } catch (e) {
        var errorMessage = "Kechirasiz xatolik sodir bo'ldi";
        _showErrorDialog(errorMessage);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.login) {
      setState(() {
        _authMode = AuthMode.register;
      });
    } else {
      setState(() {
        _authMode = AuthMode.login;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Image.asset(
                  'assets/images/logo.png',
                  height: 200,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(),
                    ),
                  ),
                  validator: (email) {
                    if (email == null || email.isEmpty) {
                      return "Iltimos email manzil kiriting";
                    } else if (!email.contains("@")) {
                      return "Iltimos to'g'ri email kiriting";
                    }
                  },
                  onSaved: (email) {
                    _authData['email'] = email!;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(),
                    ),
                  ),
                  controller: _passwordController,
                  validator: (password) {
                    if (password == null || password.isEmpty) {
                      return "Iltimos parolni kiritng";
                    } else if (password.length < 6) {
                      return "Parol juda qisqa";
                    }
                  },
                  onSaved: (password) {
                    _authData['password'] = password!;
                  },
                ),
                if (_authMode == AuthMode.register)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        decoration:  InputDecoration(
                            labelText: "Confirm password",
                          border:  OutlineInputBorder(
                            borderRadius:  BorderRadius.circular(16.0),
                            borderSide: const BorderSide(),
                          ),
                        ),
                        validator: (confirmedPass) {
                          if (_passwordController.text != confirmedPass) {
                            return "Parollar bir biriga mos kelmadi";
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 60),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.teal,
                            shape:  RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0))),
                        child: Text(
                          _authMode == AuthMode.login
                              ? "LOGIN"
                              : "REGISTRATION",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: _switchAuthMode,
                  child: Text(
                    _authMode == AuthMode.login
                        ? "Registration"
                        : "Login",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
