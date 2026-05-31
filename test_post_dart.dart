import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Login first
  var res = await http.post(
    Uri.parse('http://localhost/pastryshop_api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'admin@admin.com', // typical admin email
      'password': 'password123'   // typical admin password
    })
  );
  
  if (res.statusCode != 200) {
    print('Login failed: ${res.body}');
    return;
  }
  
  var token = jsonDecode(res.body)['data']['token'];
  print('Token: $token');
  
  // Now create role
  final body = {
    'nombre': 'TestDart2',
    'descripcion': 'Desc from dart',
    'permisos': ['manage_users']
  };
  
  res = await http.post(
    Uri.parse('http://localhost/pastryshop_api/roles'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode(body)
  );
  
  print('Create Role Status: ${res.statusCode}');
  print('Create Role Body: ${res.body}');
}
