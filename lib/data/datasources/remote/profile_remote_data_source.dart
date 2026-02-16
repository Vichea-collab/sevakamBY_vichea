import '../../../domain/entities/profile_settings.dart';
import '../../../domain/entities/pagination.dart';
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
    final resolvedFinderLocation = _locationText(role['location']);
    final resolvedCity = (role['city'] ?? '').toString().trim().isEmpty
        ? resolvedFinderLocation
        : (role['city'] ?? '').toString();

    return (isProvider
            ? ProfileFormData.providerDefault()
            : ProfileFormData.finderDefault())
        .copyWith(
          name: (me['name'] ?? '').toString(),
          email: (me['email'] ?? '').toString(),
          dateOfBirth: _dateText(role['birthday']),
          country: 'Cambodia',
          phoneNumber: (role['phoneNumber'] ?? '').toString(),
          city: isProvider ? (role['city'] ?? '').toString() : resolvedCity,
          bio: (role['bio'] ?? '').toString(),
        );
  }

  Future<bool> hasRoleProfile({required bool isProvider}) async {
    final rolePath = isProvider
        ? '/api/providers/provider-profile'
        : '/api/finders/finder-profile';
    try {
      await _apiClient.getJson(rolePath);
      return true;
    } on BackendApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) {
        return false;
      }
      rethrow;
    }
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
    final rolePayload = <String, dynamic>{
      'city': profile.city,
      'phoneNumber': profile.phoneNumber,
      'birthday': profile.dateOfBirth,
      'bio': profile.bio,
    };
    if (!isProvider) {
      rolePayload['location'] = profile.city;
    }
    final response = await _apiClient.putJson(path, rolePayload);
    final role = _safeMap(response['data']);
    final resolvedFinderLocation = _locationText(role['location']);
    final resolvedCity = (role['city'] ?? '').toString().trim().isEmpty
        ? resolvedFinderLocation
        : (role['city'] ?? profile.city).toString();
    return profile.copyWith(
      city: isProvider
          ? (role['city'] ?? profile.city).toString()
          : resolvedCity,
      phoneNumber: (role['phoneNumber'] ?? profile.phoneNumber).toString(),
      dateOfBirth: _dateText(role['birthday']).isEmpty
          ? profile.dateOfBirth
          : _dateText(role['birthday']),
      bio: (role['bio'] ?? profile.bio).toString(),
    );
  }

  Future<ProviderProfessionData> fetchProviderProfession() async {
    final response = await _apiClient.getJson(
      '/api/providers/provider-profile',
    );
    final role = _safeMap(response['data']);
    return _providerProfessionFromRole(role);
  }

  Future<ProviderProfessionData> updateProviderProfession({
    required ProviderProfessionData profession,
  }) async {
    final response = await _apiClient.putJson(
      '/api/providers/provider-profile',
      profession.toMap(),
    );
    final role = _safeMap(response['data']);
    return _providerProfessionFromRole(role);
  }

  Future<int> fetchProviderCompletedOrders() async {
    final response = await _apiClient.getJson(
      '/api/providers/provider-profile',
    );
    final role = _safeMap(response['data']);
    final raw = role['completedOrder'];
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) return raw < 0 ? 0 : raw.toInt();
    final parsed = int.tryParse((raw ?? '').toString());
    if (parsed == null || parsed < 0) return 0;
    return parsed;
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

  Future<PaginatedResult<Map<String, dynamic>>> fetchHelpTickets({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.getJson(
      '/api/users/help-tickets?page=$page&limit=$limit',
    );
    final data = response['data'];
    final items = data is! List
        ? const <Map<String, dynamic>>[]
        : data.whereType<Map>().map((item) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          }).toList();
    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: items.length,
    );
    return PaginatedResult(items: items, pagination: pagination);
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

  ProviderProfessionData _providerProfessionFromRole(
    Map<String, dynamic> role,
  ) {
    final parsed = ProviderProfessionData.fromMap(role);
    final defaults = ProviderProfessionData.defaults();
    return parsed.copyWith(
      serviceName: parsed.serviceName.trim().isEmpty
          ? defaults.serviceName
          : parsed.serviceName,
      expertIn: parsed.expertIn.trim().isEmpty
          ? defaults.expertIn
          : parsed.expertIn,
      availableFrom: parsed.availableFrom.trim().isEmpty
          ? defaults.availableFrom
          : parsed.availableFrom,
      availableTo: parsed.availableTo.trim().isEmpty
          ? defaults.availableTo
          : parsed.availableTo,
      experienceYears: parsed.experienceYears.trim().isEmpty
          ? defaults.experienceYears
          : parsed.experienceYears,
      serviceArea: parsed.serviceArea.trim().isEmpty
          ? defaults.serviceArea
          : parsed.serviceArea,
    );
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

  String _locationText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) {
      final label = (value['label'] ?? '').toString().trim();
      if (label.isNotEmpty) return label;
      final city = (value['city'] ?? '').toString().trim();
      if (city.isNotEmpty) return city;
      final address = (value['address'] ?? '').toString().trim();
      if (address.isNotEmpty) return address;
    }
    return value.toString().trim();
  }
}
