import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Untuk mendapatkan baseUrl

class OrderService {
  final String baseUrl = AuthService.baseUrl;

  // 1. Simpan Alamat
  Future<Map<String, dynamic>> saveAddress(int userId, String title, String fullAddress) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/address'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'full_address': fullAddress,
        }),
      );
      
      // CETAK ERROR DI TERMINAL CHROME
      print('=== DEBUG ADDRESS ===');
      print('Status: ${response.statusCode}');
      print('Isi Response: ${response.body}');
      print('======================');
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // 2. Buat Pesanan Baru
  Future<Map<String, dynamic>> createOrder(
      int userId, String serviceType, int totalPrice, String paymentMethod, bool useReward) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'service_type': serviceType,
          'total_price': totalPrice,
          'payment_method': paymentMethod,
          'use_reward': useReward,
        }),
      );
      
      // CETAK ERROR DI TERMINAL CHROME
      print('=== DEBUG ORDER ===');
      print('Status: ${response.statusCode}');
      print('Isi Response: ${response.body}');
      print('===================');
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // 3. Ambil Profile & Total Poin (Rewards)
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // 4. Ambil Riwayat Pesanan (Dari Backend)
  Future<Map<String, dynamic>> getOrderHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/orders'),
        headers: {
          'Accept': 'application/json',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil riwayat dari server: $e'};
    }
  }
}
