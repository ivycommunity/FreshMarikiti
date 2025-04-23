import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String token;
  final String password;

  User(
      {required this.id,
      required this.email,
      required this.name,
      required this.token,
      required this.password});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'token': token,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        email: map['email'] ?? '',
        id: map['_id'] ?? '',
        name: map['name'] ?? '',
        token: map['token'] ?? '',
        password: map['password'] ?? '');
  }

  String toJson() => json.encode(toMap());
  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}
