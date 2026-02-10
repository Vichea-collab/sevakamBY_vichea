import '../../../domain/entities/profile_settings.dart';
import '../../network/backend_api_client.dart';

class ProfileRemoteDataSource {
  final BackendApiClient _apiClient;

  const ProfileRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<void> pingHealth() async {
    await _apiClient.getJson('/api/health');
  }

  Future<ProfileFormData> fetchProfile({required bool isProvider}) async {
    final meResponse = await _apiClient.getJson('/api/auth/me');
    final rolePath = isProvider
        ? '/api/providers/provider-profile'
        : '/api/finders/finder-profile';
    final roleResponse = await _apiClient.getJson(rolePath);

    final me = _safeMap(meResponse['data']);
    final role = _safeMap(roleResponse['data']);

    return (isProvider
            ? ProfileFormData.providerDefault()
            : ProfileFormData.finderDefault())
        .copyWith(
          name: (me['name'] ?? '').toString(),
          email: (me['email'] ?? '').toString(),
          dateOfBirth: _dateText(role['birthday']),
          country: 'Cambodia',
          phoneNumber: (role['phoneNumber'] ?? '').toString(),
          city: (role['city'] ?? '').toString(),
          bio: (role['bio'] ?? '').toString(),
        );
  }

  Future<void> initUserRole({required bool isProvider}) async {
    await _apiClient.postJson('/api/users/init', {
      'role': isProvider ? 'provider' : 'finder',
    });
  }

  Future<ProfileFormData> updateProfile({
    required bool isProvider,
    required ProfileFormData profile,
  }) async {
    await _apiClient.putJson('/api/users/profile', {
      'name': profile.name,
      'email': profile.email,
    });

    final path = isProvider
        ? '/api/providers/provider-profile'
        : '/api/finders/finder-profile';
    final response = await _apiClient.putJson(path, {
      'city': profile.city,
      'phoneNumber': profile.phoneNumber,
      'birthday': profile.dateOfBirth,
      'bio': profile.bio,
    });
    final role = _safeMap(response['data']);
    return profile.copyWith(
      city: (role['city'] ?? profile.city).toString(),
      phoneNumber: (role['phoneNumber'] ?? profile.phoneNumber).toString(),
      dateOfBirth: _dateText(role['birthday']).isEmpty
          ? profile.dateOfBirth
          : _dateText(role['birthday']),
      bio: (role['bio'] ?? profile.bio).toString(),
    );
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final response = await _apiClient.getJson('/api/users/settings');
    return _safeMap(response['data']);
  }

  Future<void> updateSettings({
    required String paymentMethod,
    required Map<String, dynamic> notifications,
  }) async {
    await _apiClient.putJson('/api/users/settings', {
      'paymentMethod': paymentMethod,
      'notifications': notifications,
    });
  }

  Future<List<Map<String, dynamic>>> fetchHelpTickets() async {
    final response = await _apiClient.getJson('/api/users/help-tickets');
    final data = response['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  Future<void> createHelpTicket({
    required String title,
    required String message,
  }) async {
    await _apiClient.postJson('/api/users/help-tickets', {
      'title': title,
      'message': message,
    });
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  String _dateText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      final date = DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).round(),
      );
      return '${date.day}/${date.month}/${date.year}';
    }
    return value.toString();
  }
}
