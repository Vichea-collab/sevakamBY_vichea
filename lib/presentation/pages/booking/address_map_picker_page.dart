import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class PickedMapLocation {
  final double lat;
  final double lng;
  final String city;
  final String label;
  final String mapLink;
  final String street;
  final String additionalDetails;
  final String streetHint;

  const PickedMapLocation({
    required this.lat,
    required this.lng,
    required this.city,
    required this.label,
    required this.mapLink,
    required this.street,
    required this.additionalDetails,
    required this.streetHint,
  });
}

class AddressMapPickerPage extends StatefulWidget {
  const AddressMapPickerPage({super.key});

  @override
  State<AddressMapPickerPage> createState() => _AddressMapPickerPageState();
}

class _AddressMapPickerPageState extends State<AddressMapPickerPage> {
  static const LatLng _phnomPenh = LatLng(11.5564, 104.9282);
  static const String _fixedCity = 'Phnom Penh';
  static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const Map<String, LatLng> _cambodiaCities = {
    _fixedCity: LatLng(11.5564, 104.9282),
  };

  final TextEditingController _searchController = TextEditingController();
  late LatLng _selectedPoint;
  GoogleMapController? _mapController;
  String _selectedAddress = 'Phnom Penh, Cambodia';
  bool _searching = false;
  bool _locating = false;
  bool _hasLocationPermission = false;

  bool get _mapSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _selectedPoint = _phnomPenh;
    _prepareLocationPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: AppTopBar(
                title: 'Pick Location',
                subtitle: 'Phnom Penh, Cambodia',
                actions: [
                  TextButton(onPressed: _confirmLocation, child: const Text('Done')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchLocationByName,
                      decoration: InputDecoration(
                        hintText: 'Search location name',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Use current location',
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cambodiaCities.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final city = _cambodiaCities.keys.elementAt(index);
                    return ActionChip(
                      label: Text(city),
                      onPressed: () => _moveToCity(city),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.divider),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _mapSupported ? _buildMap() : _buildUnsupportedFallback(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                12,
                AppSpacing.lg,
                16,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Use this location',
                      onPressed: _confirmLocation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: _phnomPenh, zoom: 11.5),
      myLocationEnabled: _hasLocationPermission,
      myLocationButtonEnabled: _hasLocationPermission,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
      onTap: (point) {
        setState(() => _selectedPoint = point);
        _reverseGeocode(point);
      },
      markers: {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPoint,
        ),
      },
    );
  }

  Widget _buildUnsupportedFallback() {
    return Container(
      color: const Color(0xFFF3F6FF),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Live map is not supported on this device target.\n'
        'Search by location name or use current location to continue.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _moveToCity(String city) {
    final target = _cambodiaCities[city];
    if (target == null) return;
    setState(() {
      _selectedPoint = target;
      _selectedAddress = '$city, Cambodia';
      _searchController.text = city;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 12.4)),
    );
  }

  Future<void> _searchLocationByName(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    final quickCity = _matchCity(query);
    if (quickCity != null) {
      _moveToCity(quickCity);
      return;
    }

    setState(() => _searching = true);
    try {
      final success = _apiKey.isNotEmpty
          ? await _searchWithGoogle(query)
          : await _searchWithOpenStreetMap(query);
      if (!success) {
        _showMessage('No result found for "$query" in Phnom Penh.');
      }
    } catch (_) {
      _showMessage('Search failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<bool> _searchWithGoogle(String query) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': '$query, Phnom Penh, Cambodia',
      'components': 'country:KH',
      'region': 'kh',
      'key': _apiKey,
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);
    if (results.isEmpty) return false;
    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    final lat = (location['lat'] as num?)?.toDouble();
    final lng = (location['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return false;
    final point = LatLng(lat, lng);
    setState(() {
      _selectedPoint = point;
      _selectedAddress =
          (first['formatted_address'] as String?) ?? 'Phnom Penh, Cambodia';
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 14.8)),
    );
    return true;
  }

  Future<bool> _searchWithOpenStreetMap(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, Phnom Penh, Cambodia',
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'kh',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'servicefinder/1.0 (contact: support@servicefinder.local)',
      },
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) return false;
    final first = data.first as Map<String, dynamic>;
    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return false;
    final point = LatLng(lat, lon);
    setState(() {
      _selectedPoint = point;
      _selectedAddress = (first['display_name'] as String?) ?? 'Phnom Penh, Cambodia';
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 14.8)),
    );
    return true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location service is disabled. Please turn it on.');
        if (!kIsWeb) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _hasLocationPermission = false);
        if (permission == LocationPermission.deniedForever) {
          _showPermissionDialog();
        } else {
          _showMessage('Location permission denied.');
        }
        return;
      }
      setState(() => _hasLocationPermission = true);

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        _showMessage('Unable to get your current location.');
        return;
      }
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPoint = point);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 15.0)),
      );
      await _reverseGeocode(point);
    } catch (_) {
      _showMessage('Cannot access current location.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _prepareLocationPermissions() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _hasLocationPermission = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      setState(() {
        _hasLocationPermission =
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasLocationPermission = false);
      }
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (_apiKey.isEmpty) {
      setState(() {
        _selectedAddress = 'Phnom Penh, Cambodia';
      });
      return;
    }
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'region': 'kh',
        'key': _apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List<dynamic>? ?? []);
      if (results.isEmpty) return;
      final first = results.first as Map<String, dynamic>;
      setState(() {
        final formatted = (first['formatted_address'] as String?) ?? '';
        _selectedAddress = formatted.isEmpty
            ? 'Phnom Penh, Cambodia'
            : '$formatted, Phnom Penh, Cambodia';
      });
    } catch (_) {
      // Keep current label when reverse geocoding fails.
    }
  }

  String? _matchCity(String query) {
    final normalized = query.toLowerCase();
    for (final city in _cambodiaCities.keys) {
      if (city.toLowerCase().contains(normalized) ||
          normalized.contains(city.toLowerCase())) {
        return city;
      }
    }
    return null;
  }

  void _confirmLocation() {
    final parsed = _parseAddressParts(_selectedAddress);
    final streetHint = parsed.street.isEmpty
        ? 'Map pin ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}'
        : parsed.street;
    Navigator.pop(
      context,
      PickedMapLocation(
        lat: _selectedPoint.latitude,
        lng: _selectedPoint.longitude,
        city: _fixedCity,
        label: parsed.label,
        mapLink:
            'https://maps.google.com/?q=${_selectedPoint.latitude},${_selectedPoint.longitude}',
        street: parsed.street,
        additionalDetails: parsed.additional,
        streetHint: streetHint,
      ),
    );
  }

  _AddressParts _parseAddressParts(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return const _AddressParts(
        label: 'Map Location',
        street: '',
        additional: '',
      );
    }

    final parts = cleaned
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final street = parts.isNotEmpty ? parts.first : cleaned;
    String label = 'Map Location';

    final lowerStreet = street.toLowerCase();
    if (lowerStreet.contains('road') ||
        lowerStreet.contains('st') ||
        lowerStreet.contains('street') ||
        lowerStreet.contains('boulevard') ||
        lowerStreet.contains('blvd') ||
        lowerStreet.contains('avenue') ||
        lowerStreet.contains('ave')) {
      label = 'Street Address';
    } else if (lowerStreet.contains('market') ||
        lowerStreet.contains('mall') ||
        lowerStreet.contains('shop')) {
      label = 'Business Address';
    } else if (lowerStreet.contains('village') ||
        lowerStreet.contains('khan') ||
        lowerStreet.contains('sangkat')) {
      label = 'Residential Address';
    }

    final extraParts = parts.skip(1).toList();
    final additional = extraParts
        .where(
          (item) =>
              !item.toLowerCase().contains('phnom penh') &&
              !item.toLowerCase().contains('cambodia'),
        )
        .join(', ');

    return _AddressParts(label: label, street: street, additional: additional);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Location Permission'),
        content: const Text(
          'Location access is required to use your current location. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class _AddressParts {
  final String label;
  final String street;
  final String additional;

  const _AddressParts({
    required this.label,
    required this.street,
    required this.additional,
  });
}
