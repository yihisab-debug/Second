import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session.dart';

class ApiException implements Exception {
  final int status;
  final String message;

  ApiException(this.status, this.message);

  @override
  String toString() => message;
}

class Api {
  static String baseUrl = 'http://localhost/minibank/api';

  static const String register = 'register.php';
  static const String login = 'login.php';
  static const String logout = 'logout.php';
  static const String setPin = 'set_pin.php';
  static const String checkPin = 'check_pin.php';
  static const String overview = 'overview.php';
  static const String wallets = 'wallets.php';
  static const String walletCreate = 'wallet_create.php';
  static const String deposit = 'deposit.php';
  static const String withdraw = 'withdraw.php';
  static const String transfer = 'transfer.php';
  static const String history = 'history.php';
  static const String findWallet = 'find_wallet.php';
  static const String findUser = 'find_user.php';
  static const String transferPhone = 'transfer_phone.php';
  static const String notifications = 'notifications.php';
  static const String notificationsRead = 'notifications_read.php';

  static Future<Map<String, dynamic>> call(
    String endpoint, [
    Map<String, String> body = const <String, String>{},
  ]) async {
    final params = <String, String>{};
    params.addAll(body);

    final token = Session.token;
    if (token != null && token.isNotEmpty) {
      params['token'] = token;
    }

    http.Response response;
    try {
      response = await http
          .post(Uri.parse('$baseUrl/$endpoint'), body: params)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ApiException(
        0,
        'Сервер не отвечает. Проверьте, что Apache и MySQL запущены, '
        'а адрес $baseUrl указан верно.',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        response.statusCode,
        'Сервер вернул не JSON. Откройте $baseUrl/index.php в браузере '
        'и посмотрите на ошибку PHP.',
      );
    }

    final rawStatus = decoded['status'];
    final status = rawStatus is int ? rawStatus : int.tryParse('$rawStatus') ?? 0;
    final message = '${decoded['message'] ?? ''}';

    if (status != 200) {
      throw ApiException(status, message.isEmpty ? 'Ошибка $status' : message);
    }

    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
