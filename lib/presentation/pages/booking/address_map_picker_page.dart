import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/config/app_env.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../widgets/app_dialog.dart';
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
  static const double _phnomPenhNorth = 11.82;
  static const double _phnomPenhSouth = 11.35;
  static const double _phnomPenhWest = 104.62;
  static const double _phnomPenhEast = 105.12;
  static const double _phnomPenhMaxDistanceMeters = 60000;

  String get _apiKey => AppEnv.googleMapsApiKey();

  static const Map<String, LatLng> _cambodiaCities = {
    _fixedCity: LatLng(11.5564, 104.9282),
  };

  final TextEditingController _searchController = TextEditingController();
  final fm.MapController _webMapController = fm.MapController();
  late LatLng _selectedPoint;
  GoogleMapController? _googleMapController;
  String _selectedAddress = 'Phnom Penh, Cambodia';
  bool _searching = false;
  bool _locating = false;
  bool _hasLocationPermission = false;

  bool get _useOpenStreetMap {
    // Keep Android debug/emulator stable even when Google Maps SDK key
    // restrictions are not fully configured yet.
    if (!kIsWeb &&
        kDebugMode &&
        defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }
    return kIsWeb || _apiKey.trim().isEmpty;
  }

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
    _googleMapController?.dispose();
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
                  TextButton(
                    onPressed: _confirmLocation,
                    child: const Text('Done'),
                  ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                  child: _mapSupported
                      ? _buildMap()
                      : _buildUnsupportedFallback(),
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
    if (_useOpenStreetMap) return _buildOpenStreetMap();
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _phnomPenh,
        zoom: 11.5,
      ),
      myLocationEnabled: _hasLocationPermission,
      // Use the custom "current location" action so we can enforce Phnom Penh bounds.
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _googleMapController = controller,
      onTap: (point) {
        if (!_isInsidePhnomPenh(point)) {
          _showMessage(
            'Please choose a location inside Phnom Penh.',
            type: AppToastType.warning,
          );
          return;
        }
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

  Widget _buildOpenStreetMap() {
    return fm.FlutterMap(
      mapController: _webMapController,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(_phnomPenh.latitude, _phnomPenh.longitude),
        initialZoom: 11.5,
        minZoom: 10.5,
        maxZoom: 18,
        onTap: (_, point) {
          final selected = LatLng(point.latitude, point.longitude);
          if (!_isInsidePhnomPenh(selected)) {
            _showMessage(
              'Please choose a location inside Phnom Penh.',
              type: AppToastType.warning,
            );
            return;
          }
          setState(() => _selectedPoint = selected);
          _reverseGeocode(selected);
        },
      ),
      children: [
        fm.TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.servicefinder',
        ),
        fm.MarkerLayer(
          markers: [
            fm.Marker(
              width: 42,
              height: 42,
              point: ll.LatLng(
                _selectedPoint.latitude,
                _selectedPoint.longitude,
              ),
              child: const Icon(
                Icons.location_pin,
                size: 38,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
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
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
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
    _moveCamera(target, zoom: 12.4);
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
      final success = _useOpenStreetMap
          ? await _searchWithOpenStreetMap(query)
          : await _searchWithGoogle(query);
      if (!success) {
        _showMessage(
          'No result found for "$query" in Phnom Penh.',
          type: AppToastType.warning,
        );
      }
    } catch (_) {
      _showMessage(
        'Search failed. Please try again.',
        type: AppToastType.error,
      );
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
      'language': 'en',
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
    if (!_isInsidePhnomPenh(point)) return false;
    setState(() {
      _selectedPoint = point;
      _selectedAddress =
          (first['formatted_address'] as String?) ?? 'Phnom Penh, Cambodia';
    });
    await _moveCamera(point, zoom: 14.8);
    return true;
  }

  Future<bool> _searchWithOpenStreetMap(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, Phnom Penh, Cambodia',
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'kh',
      'accept-language': 'en',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent':
            'servicefinder/1.0 (contact: support@servicefinder.local)',
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
    if (!_isInsidePhnomPenh(point)) return false;
    setState(() {
      _selectedPoint = point;
      _selectedAddress =
          (first['display_name'] as String?) ?? 'Phnom Penh, Cambodia';
    });
    await _moveCamera(point, zoom: 14.8);
    return true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(
          'Location service is disabled. Please turn it on.',
          type: AppToastType.warning,
        );
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
          _showMessage(
            'Location permission denied.',
            type: AppToastType.warning,
          );
        }
        return;
      }
      setState(() => _hasLocationPermission = true);

      final position = await _resolveBestCurrentPosition();
      if (position == null) {
        _showMessage(
          'Unable to get your current location.',
          type: AppToastType.error,
        );
        return;
      }
      final point = LatLng(position.latitude, position.longitude);
      final debugNetworkPoint = await _resolveApproxNetworkLocation();
      if (_shouldPreferNetworkFallback(
        position: position,
        gpsPoint: point,
        networkPoint: debugNetworkPoint,
      )) {
        final networkPoint = debugNetworkPoint!;
        setState(() => _selectedPoint = networkPoint);
        await _moveCamera(networkPoint, zoom: 15.0);
        await _reverseGeocode(networkPoint);
        _showMessage(
          'Using emulator/network location for better accuracy.',
          type: AppToastType.info,
        );
        return;
      }

      final outsidePhnomPenh = !_isInsidePhnomPenh(point);
      final reverseMatched =
          outsidePhnomPenh && await _isReverseGeocodedInPhnomPenh(point);
      if (outsidePhnomPenh && !reverseMatched) {
        final networkPoint = await _resolveApproxNetworkLocation();
        if (networkPoint != null) {
          setState(() => _selectedPoint = networkPoint);
          await _moveCamera(networkPoint, zoom: 15.0);
          await _reverseGeocode(networkPoint);
          _showMessage(
            'Using network location fallback for Phnom Penh.',
            type: AppToastType.info,
          );
          return;
        }
        _moveToCity(_fixedCity);
        _showMessage(
          'Current location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}) is outside Phnom Penh. Only Phnom Penh locations are supported.',
          type: AppToastType.warning,
        );
        return;
      }
      setState(() => _selectedPoint = point);
      await _moveCamera(point, zoom: 15.0);
      await _reverseGeocode(point);
    } catch (_) {
      _showMessage('Cannot access current location.', type: AppToastType.error);
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<Position?> _resolveBestCurrentPosition() async {
    final candidates = <Position>[];

    try {
      final LocationSettings primarySettings =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 12),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 12),
            );
      final current = await Geolocator.getCurrentPosition(
        locationSettings: primarySettings,
      );
      candidates.add(current);
    } catch (_) {}

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final secondary = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: false,
            timeLimit: const Duration(seconds: 8),
          ),
        );
        candidates.add(secondary);
      }
    } catch (_) {}

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && _isPositionFresh(lastKnown)) {
        candidates.add(lastKnown);
      }
    } catch (_) {}

    try {
      final streamed = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      ).first.timeout(const Duration(seconds: 8));
      candidates.add(streamed);
    } catch (_) {}

    if (candidates.isEmpty) return null;

    Position best = candidates.first;
    double bestScore = _locationScore(best);
    for (final candidate in candidates.skip(1)) {
      final score = _locationScore(candidate);
      if (score < bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  double _locationScore(Position position) {
    final point = LatLng(position.latitude, position.longitude);
    final insidePenalty = _isInsidePhnomPenh(point) ? 0.0 : 1000000.0;
    final distanceToCenter = Geolocator.distanceBetween(
      _phnomPenh.latitude,
      _phnomPenh.longitude,
      position.latitude,
      position.longitude,
    );
    final accuracyPenalty = position.accuracy.isFinite ? position.accuracy : 0;
    final staleMinutes = _positionAgeMinutes(position);
    final stalePenalty = staleMinutes > 20 ? staleMinutes * 2000 : 0.0;
    final mockedPenalty = position.isMocked ? 5000.0 : 0.0;
    return insidePenalty +
        distanceToCenter +
        (accuracyPenalty * 0.25) +
        stalePenalty +
        mockedPenalty;
  }

  bool _isPositionFresh(Position position) {
    return _positionAgeMinutes(position) <= 30;
  }

  double _positionAgeMinutes(Position position) {
    final nowUtc = DateTime.now().toUtc();
    final timestampUtc = position.timestamp.toUtc();
    final diff = nowUtc.difference(timestampUtc).abs();
    return diff.inSeconds / 60.0;
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
    if (_useOpenStreetMap) return _reverseGeocodeWithOpenStreetMap(point);
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'region': 'kh',
        'language': 'en',
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
            : formatted;
      });
    } catch (_) {
      // Keep current label when reverse geocoding fails.
    }
  }

  Future<void> _reverseGeocodeWithOpenStreetMap(LatLng point) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'format': 'jsonv2',
        'accept-language': 'en',
      });
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent':
              'servicefinder/1.0 (contact: support@servicefinder.local)',
        },
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return;
      final display = (body['display_name'] ?? '').toString().trim();
      if (display.isEmpty) return;
      setState(() => _selectedAddress = display);
    } catch (_) {
      // Keep current label when reverse geocoding fails.
    }
  }

  Future<void> _moveCamera(LatLng target, {required double zoom}) async {
    if (_useOpenStreetMap) {
      _webMapController.move(
        ll.LatLng(target.latitude, target.longitude),
        zoom,
      );
      return;
    }
    await _googleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
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

  bool _isInsidePhnomPenh(LatLng point) {
    final inBounds =
        point.latitude >= _phnomPenhSouth &&
        point.latitude <= _phnomPenhNorth &&
        point.longitude >= _phnomPenhWest &&
        point.longitude <= _phnomPenhEast;
    if (!inBounds) return false;

    final meters = Geolocator.distanceBetween(
      _phnomPenh.latitude,
      _phnomPenh.longitude,
      point.latitude,
      point.longitude,
    );
    return meters <= _phnomPenhMaxDistanceMeters;
  }

  Future<bool> _isReverseGeocodedInPhnomPenh(LatLng point) async {
    try {
      if (_useOpenStreetMap) {
        final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'lat': '${point.latitude}',
          'lon': '${point.longitude}',
          'format': 'jsonv2',
          'accept-language': 'en',
        });
        final response = await http.get(
          uri,
          headers: const {
            'User-Agent':
                'servicefinder/1.0 (contact: support@servicefinder.local)',
          },
        );
        if (response.statusCode != 200) return false;
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) return false;
        final display = (body['display_name'] ?? '').toString().toLowerCase();
        if (display.contains('phnom penh')) return true;
        final address = body['address'];
        if (address is Map<String, dynamic>) {
          for (final value in address.values) {
            if ('${value ?? ''}'.toLowerCase().contains('phnom penh')) {
              return true;
            }
          }
        }
        return false;
      }

      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'region': 'kh',
        'key': _apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List<dynamic>? ?? []);
      if (results.isEmpty) return false;
      for (final item in results) {
        final entry = item as Map<String, dynamic>;
        final formatted = (entry['formatted_address'] ?? '')
            .toString()
            .toLowerCase();
        if (formatted.contains('phnom penh')) return true;
        final components =
            (entry['address_components'] as List<dynamic>? ?? []);
        for (final component in components) {
          final map = component as Map<String, dynamic>;
          final longName = (map['long_name'] ?? '').toString().toLowerCase();
          final shortName = (map['short_name'] ?? '').toString().toLowerCase();
          if (longName.contains('phnom penh') ||
              shortName.contains('phnom penh')) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<LatLng?> _resolveApproxNetworkLocation() async {
    if (kIsWeb) return null;

    final endpoints = <Uri>[
      Uri.https('ipapi.co', '/json'),
      Uri.https('ipwho.is', '/'),
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .get(
              endpoint,
              headers: const {
                'User-Agent':
                    'servicefinder/1.0 (contact: support@servicefinder.local)',
              },
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) continue;
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) continue;

        final lat = _extractDouble(body, const ['latitude', 'lat']);
        final lng = _extractDouble(body, const ['longitude', 'lon', 'lng']);
        if (lat == null || lng == null) continue;

        final point = LatLng(lat, lng);
        if (_isInsidePhnomPenh(point)) {
          return point;
        }
      } catch (_) {
        // Continue to next endpoint.
      }
    }
    return null;
  }

  bool _shouldPreferNetworkFallback({
    required Position position,
    required LatLng gpsPoint,
    required LatLng? networkPoint,
  }) {
    if (networkPoint == null) return false;
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final gpsToNetworkMeters = _distanceMeters(gpsPoint, networkPoint);
    if (gpsToNetworkMeters < 1200) return false;

    final gpsToCityCenterMeters = _distanceMeters(gpsPoint, _phnomPenh);
    final looksSyntheticCenter = gpsToCityCenterMeters <= 150;
    return position.isMocked || looksSyntheticCenter;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  double? _extractDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  void _showMessage(String text, {AppToastType type = AppToastType.info}) {
    if (!mounted) return;
    AppToast.show(context, message: text, type: type);
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    final openSettings = await showAppConfirmDialog(
      context: context,
      icon: Icons.location_on_rounded,
      title: 'Enable Location Permission',
      message:
          'Location access is required to use your current location. Please enable it in app settings.',
      confirmText: 'Open Settings',
      cancelText: 'Not Now',
      tone: AppDialogTone.info,
    );
    if (openSettings != true) return;
    await Geolocator.openAppSettings();
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
