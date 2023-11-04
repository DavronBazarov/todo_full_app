import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/http_exception.dart';

class Auth extends ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  Timer? _autoLogoutTimer;
  static const apiKey = 'AIzaSyCFqs3IBH8WSJ96T2ZnRtxlPs5Whuo7Q6U';

  bool get isAuth {
    return _token != null;
  }

  String? get userId {
    return _userId;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    //token mavjud emas
    return null;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=$apiKey');
    try {
      final response = await http.post(
        url,
        body: jsonEncode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw HttpException(data['error']['message']);
      }
      _token = data['idToken'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            data['expiresIn'],
          ),
        ),
      );
      _userId = data['localId'];
      autoLogOut();
      final prefs = await SharedPreferences
          .getInstance(); //dastur va qurulma orasidagi tunel
      final userData = jsonEncode({
        'token': _token,
        'userId': _userId,
        'expiryData': _expiryDate!.toIso8601String(),
      });
      prefs.setString("userData", userData);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> signIn(String email, String password) async {
    return _authenticate(email, password, "signInWithPassword");
  }

  Future<bool> autoLogIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("userData")) {
      return false;
    }
    final userData = jsonDecode(prefs.getString("userData")!) as Map<String, dynamic>;
    final expiryData = DateTime.parse(userData['expiryData']);
    //expiryData = 10:00 - Hozir vaqt 10:30
    if (expiryData.isBefore(DateTime.now())) {
      return false;
    }
    //muddati holi tugamagan
    _token = userData['token'];
    _userId = userData['userId'];
    _expiryDate = expiryData;
    notifyListeners();
    autoLogOut();
    return true;
  }

  void logOut() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_autoLogoutTimer != null) {
      _autoLogoutTimer!.cancel();
      _autoLogoutTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // prefs.remove('userData');
    prefs.clear();
  }

  void autoLogOut()  {
    if (_autoLogoutTimer != null) {
      _autoLogoutTimer!.cancel();
    }
    final timerToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _autoLogoutTimer = Timer(Duration(seconds: timerToExpiry), logOut);

  }
}