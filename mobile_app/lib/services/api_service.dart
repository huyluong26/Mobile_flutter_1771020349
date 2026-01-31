import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Models
import '../models/auth_models.dart';
import '../models/booking_model.dart';
import '../models/member_model.dart';
import '../models/paged_result.dart';
import '../models/tournament_model.dart';
import '../models/wallet_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Base URL Configuration
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:5017/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5017/api';
    return 'http://127.0.0.1:5017/api'; // Windows, iOS, macOS, Linux
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Helper for Headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String fullName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<UserProfile> getUserProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Alias for getUserProfile match
  Future<UserProfile> getProfile() => getUserProfile();

  Future<String?> uploadAvatar(File imageFile) async {
    final token = await _getToken();
    var uri = Uri.parse('$baseUrl/auth/upload-avatar');
    var request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['url'] ?? json['Url'];
      }
    } catch (e) {
      print("Upload error: $e");
    }
    return null;
  }

  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
      body: jsonEncode({
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
    );
    return response.statusCode == 200;
  }

  // ===========================================================================
  // MEMBERS (Admin)
  // ===========================================================================

  Future<PagedResult<Member>> getMembers({
    String? search,
    String? tier,
    int page = 1,
    int pageSize = 10,
  }) async {
    final headers = await _getHeaders();
    String query = 'page=$page&pageSize=$pageSize';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (tier != null) query += '&tier=$tier';

    final response = await http.get(
      Uri.parse('$baseUrl/members?$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return PagedResult<Member>.fromJson(
        jsonDecode(response.body),
        (data) => Member.fromJson(data),
      );
    } else {
      throw Exception('Failed to load members');
    }
  }

  // ===========================================================================
  // WALLET
  // ===========================================================================

  Future<List<WalletTransaction>> getAllTransactions() async {
    final headers = await _getHeaders();
    print('📊 Fetching all transactions for admin...');
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/all'), // Sửa endpoint đúng với backend
      headers: headers,
    );
    print('📊 Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WalletTransaction.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<WalletTransaction>> getTransactions() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WalletTransaction.fromJson(e)).toList();
    }
    return [];
  }

  // Updated to Named Parameters to match frontend calls
  Future<void> requestDeposit({
    required double amount,
    String? description,
    String? proofImageUrl,
  }) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/wallet/deposit'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'description': description,
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      }),
    );
  }

  // Backwards compatibility alias if needed by other files (though we fixed wallet_screen)
  Future<void> deposit(double amount, String paymentMethod) =>
      requestDeposit(amount: amount, description: paymentMethod);

  Future<void> approveDeposit(int transactionId) async {
    final headers = await _getHeaders();
    print('✅ Approving deposit: $transactionId');
    final response = await http.put(
      // Sửa từ POST thành PUT
      Uri.parse('$baseUrl/wallet/approve/$transactionId'),
      headers: headers,
    );
    print('✅ Approve response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Approval failed: ${response.body}');
    }
  }

  // ===========================================================================
  // BOOKINGS & COURTS
  // ===========================================================================

  Future<List<Court>> getCourts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/courts'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Court.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Booking>> getCalendar(DateTime from, DateTime to) async {
    final headers = await _getHeaders();
    final query = 'from=${from.toIso8601String()}&to=${to.toIso8601String()}';

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/calendar?$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Booking.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> createBooking(
    int courtId,
    DateTime startDate,
    int durationMinutes, // Đổi từ durationHours thành durationMinutes
  ) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: headers,
      body: jsonEncode({
        'courtId': courtId,
        'startTime': startDate.toIso8601String(),
        'durationMinutes': durationMinutes, // Đổi key để khớp với backend DTO
      }),
    );
    print(
      '📦 Create Booking Response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// Hủy đặt sân - trả về thông tin hoàn tiền
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/cancel/$bookingId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(response.body);
  }

  Future<void> createCourt(Court court) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/bookings/courts'),
      headers: headers,
      body: jsonEncode(court.toJson()),
    );
  }

  Future<void> updateCourt(Court court) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/bookings/courts/${court.id}'),
      headers: headers,
      body: jsonEncode(court.toJson()),
    );
  }

  Future<void> deleteCourt(int id) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/bookings/courts/$id'),
      headers: headers,
    );
  }

  // ===========================================================================
  // TOURNAMENTS
  // ===========================================================================

  Future<List<Tournament>> getTournaments() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tournaments'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('items')) {
        final items = body['items'] as List;
        return items.map((e) => Tournament.fromJson(e)).toList();
      } else if (body is List) {
        return body.map((e) => Tournament.fromJson(e)).toList();
      }
    }
    return [];
  }

  // Fixed signature to Named Parameters
  Future<void> createTournament({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    required String format,
    required double entryFee,
    required double prizePool,
  }) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/tournaments'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'format': format,
        'entryFee': entryFee,
        'prizePool': prizePool,
      }),
    );
  }

  Future<void> deleteTournament(int id) async {
    final headers = await _getHeaders();
    await http.delete(Uri.parse('$baseUrl/tournaments/$id'), headers: headers);
  }

  Future<void> generateSchedule(int id) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/tournaments/$id/schedule'),
      headers: headers,
    );
  }

  Future<void> joinTournament(int id, String teamName) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tournaments/$id/join'),
      headers: headers,
      body: jsonEncode({'teamName': teamName}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? response.body);
    }
  }
}

final apiService = ApiService();
