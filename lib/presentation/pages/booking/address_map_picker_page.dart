import 'dart:async';
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
  static const LatLng _cambodiaCenter = LatLng(12.5657, 104.9910);
  static const String _defaultCountry = 'Cambodia';
  static const String _defaultCity = 'Phnom Penh';
  static const double _cambodiaNorth = 14.80;
  static const double _cambodiaSouth = 10.30;
  static const double _cambodiaWest = 102.30;
  static const double _cambodiaEast = 107.70;

  String get _apiKey => AppEnv.googleMapsApiKey();

  static const Map<String, LatLng> _cambodiaCities = {
    'Phnom Penh': LatLng(11.5564, 104.9282),
    'Siem Reap': LatLng(13.3671, 103.8448),
    'Battambang': LatLng(13.0957, 103.2022),
    'Sihanoukville': LatLng(10.6250, 103.5239),
    'Kampot': LatLng(10.6104, 104.1814),
  };

  final TextEditingController _searchController = TextEditingController();
  final fm.MapController _webMapController = fm.MapController();
  late LatLng _selectedPoint;
  LatLng? _currentLiveLocation;
  GoogleMapController? _googleMapController;
  String _selectedAddress = _defaultCountry;
  bool _searching = false;
  bool _locating = false;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _reverseGeocodeDebounce;

  bool _followCurrentLocation = false;
  bool _cameraMoveByApp = false;

  LatLng get _defaultStartPoint => _cambodiaCities[_defaultCity]!;

  bool get _useOpenStreetMap {
    // Keep iOS and Android debug stable even when Google Maps platform-view
    // integration or SDK restrictions are unreliable.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
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
    _selectedPoint = _defaultStartPoint;
    _selectedAddress = '$_defaultCity, $_defaultCountry';
    _prepareLocationPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _googleMapController?.dispose();
    _positionSubscription?.cancel();
    _reverseGeocodeDebounce?.cancel();
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
                subtitle: 'Cambodia only',
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
                      onChanged: (_) => _stopFollowingCurrentLocation(),
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
      initialCameraPosition: CameraPosition(
        target: _selectedPoint,
        zoom: _defaultMapZoom,
      ),
      myLocationEnabled: _hasLocationPermission,
      // Use the custom "current location" action so we can enforce Cambodia bounds.
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onCameraMoveStarted: () {
        if (_cameraMoveByApp) return;
        _stopFollowingCurrentLocation();
      },
      onMapCreated: (controller) {
        _googleMapController = controller;
        if (_selectedPoint != _cambodiaCenter) {
          _moveCamera(_selectedPoint, zoom: 15.0);
        }
      },
      onTap: (point) {
        _stopFollowingCurrentLocation();
        if (!_isInsideCambodia(point)) {
          _showMessage(
            'Please choose a location inside Cambodia.',
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
    final markers = <fm.Marker>[
      fm.Marker(
        width: 42,
        height: 42,
        point: ll.LatLng(_selectedPoint.latitude, _selectedPoint.longitude),
        child: const Icon(Icons.location_pin, size: 38, color: Colors.red),
      ),
    ];

    if (_currentLiveLocation != null) {
      markers.add(
        fm.Marker(
          width: 24,
          height: 24,
          point: ll.LatLng(
            _currentLiveLocation!.latitude,
            _currentLiveLocation!.longitude,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return fm.FlutterMap(
      mapController: _webMapController,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(
          _selectedPoint.latitude,
          _selectedPoint.longitude,
        ),
        initialZoom: _defaultMapZoom,
        minZoom: 6.0,
        maxZoom: 18,
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture) _stopFollowingCurrentLocation();
        },
        onTap: (_, point) {
          _stopFollowingCurrentLocation();
          final selected = LatLng(point.latitude, point.longitude);
          if (!_isInsideCambodia(selected)) {
            _showMessage(
              'Please choose a location inside Cambodia.',
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
          userAgentPackageName: 'com.company.sevekam',
        ),
        fm.MarkerLayer(markers: markers),
      ],
    );
  }

  double get _defaultMapZoom =>
      _selectedPoint == _defaultStartPoint ? 12.4 : 11.5;

  Widget _buildUnsupportedFallback() {
    return Container(
      color: const Color(0xFFF3F6FF),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Live map is not supported on this device target.\n'
        'Search by location name or pick manually on the map in Cambodia.',
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
    _stopFollowingCurrentLocation();

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
          'No result found for "$query" in Cambodia.',
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
      'address': '$query, Cambodia',
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
    if (!_isInsideCambodia(point)) return false;
    setState(() {
      _selectedPoint = point;
      _selectedAddress =
          (first['formatted_address'] as String?) ?? _defaultCountry;
    });
    await _moveCamera(point, zoom: 14.8);
    return true;
  }

  Future<bool> _searchWithOpenStreetMap(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, Cambodia',
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
    if (!_isInsideCambodia(point)) return false;
    setState(() {
      _selectedPoint = point;
      _selectedAddress = (first['display_name'] as String?) ?? _defaultCountry;
    });
    await _moveCamera(point, zoom: 14.8);
    return true;
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    _startFollowingCurrentLocation();
    if (!silent) {
      setState(() => _locating = true);
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) {
          _showMessage(
            'Location service is disabled. Please turn it on.',
            type: AppToastType.warning,
          );
          if (!kIsWeb) {
            await Geolocator.openLocationSettings();
          }
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent) {
          setState(() => _hasLocationPermission = false);
          if (permission == LocationPermission.deniedForever) {
            _showPermissionDialog();
          } else {
            _showMessage(
              'Location permission denied.',
              type: AppToastType.warning,
            );
          }
        }
        return;
      }
      setState(() => _hasLocationPermission = true);

      _startLiveTracking();

      final position = await _resolveBestCurrentPosition(forceRefresh: !silent);
      var point = position == null
          ? null
          : LatLng(position.latitude, position.longitude);

      if (point == null) {
        final simulatorFallback = _simulatorFallbackPoint();
        if (simulatorFallback != null) {
          point = simulatorFallback;
          setState(() {
            _currentLiveLocation = simulatorFallback;
            _selectedPoint = simulatorFallback;
            _selectedAddress = '$_defaultCity, $_defaultCountry';
          });
          await _moveCamera(simulatorFallback, zoom: 15.0);
          if (!silent) {
            _showMessage(
              'Using simulator fallback location in Phnom Penh. Set a Cambodia location in the simulator for live GPS tracking.',
              type: AppToastType.info,
            );
          }
          return;
        }
        if (!silent) {
          _showMessage(
            'Unable to get a real Cambodia device location. Set a Cambodia location on the device or pick manually on the map.',
            type: AppToastType.error,
          );
        }
        return;
      }

      final isSimulatorHq = _isSimulatorDefaultHq(position);
      final outsideCambodia = !_isInsideCambodia(point);
      if (outsideCambodia || isSimulatorHq) {
        final simulatorFallback = _simulatorFallbackPoint();
        if (simulatorFallback != null) {
          final fallbackPoint = simulatorFallback;
          if (mounted) {
            setState(() {
              _currentLiveLocation = fallbackPoint;
              _selectedPoint = fallbackPoint;
              _selectedAddress = '$_defaultCity, $_defaultCountry';
            });
          }
          await _moveCamera(fallbackPoint, zoom: 15.0);
          if (!silent) {
            final message = isSimulatorHq
                ? 'Simulator is still using its default mock position. Using Phnom Penh fallback until you set a Cambodia location.'
                : 'Simulator location is outside Cambodia. Using Phnom Penh fallback for testing.';
            _showMessage(message, type: AppToastType.info);
          }
          return;
        }

        _stopFollowingCurrentLocation();
        if (mounted) {
          setState(() {
            _currentLiveLocation = null;
            _selectedPoint = _defaultStartPoint;
            _selectedAddress = '$_defaultCity, $_defaultCountry';
          });
        }
        await _moveCamera(_defaultStartPoint, zoom: 12.4);
        if (!silent) {
          final message = isSimulatorHq
              ? 'The iOS simulator is still using its default mock location. In Simulator, choose Features > Location and set a Cambodia location.'
              : 'Current location is outside Cambodia. This picker works in Cambodia only.';
          _showMessage(message, type: AppToastType.info);
        }
        return;
      }

      final resolvedPoint = point;
      setState(() {
        _currentLiveLocation = resolvedPoint;
        _selectedPoint = resolvedPoint;
      });
      await _moveCamera(resolvedPoint, zoom: 15.0);
      await _reverseGeocode(resolvedPoint);
    } catch (e) {
      debugPrint('Location error: $e');
      if (!silent) {
        _showMessage(
          'Cannot access current location.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _locating = false);
      }
    }
  }

  LatLng? _simulatorFallbackPoint() {
    if (!kDebugMode || kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    return _defaultStartPoint;
  }

  bool _isSimulatorDefaultHq(Position? position) {
    if (position == null || !kDebugMode || kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        37.422,
        -122.084,
      );
      return dist < 1000;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        37.332,
        -122.031,
      );
      return dist < 1000;
    }
    return false;
  }

  void _startLiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _liveTrackingLocationSettings(),
        ).listen(
          (position) {
            if (mounted) {
              final point = LatLng(position.latitude, position.longitude);
              if (!_isInsideCambodia(point) ||
                  _isSimulatorDefaultHq(position)) {
                return;
              }
              setState(() {
                _currentLiveLocation = point;
              });

              if (_followCurrentLocation) {
                final movedMeters = Geolocator.distanceBetween(
                  _selectedPoint.latitude,
                  _selectedPoint.longitude,
                  point.latitude,
                  point.longitude,
                );
                final shouldRefreshSelection =
                    _selectedPoint == _defaultStartPoint || movedMeters >= 3;
                if (!shouldRefreshSelection) return;

                setState(() => _selectedPoint = point);
                unawaited(_moveCamera(point, zoom: 15.0));
                _scheduleReverseGeocode(point);
              }
            }
          },
          onError: (e) {
            debugPrint('Live tracking error: $e');
          },
        );
  }

  Future<Position?> _resolveBestCurrentPosition({
    bool forceRefresh = false,
  }) async {
    final livePosition = await _awaitLivePosition(
      timeout: forceRefresh
          ? const Duration(seconds: 6)
          : const Duration(seconds: 4),
    );
    if (livePosition != null) {
      return livePosition;
    }

    try {
      // Try high accuracy first with a shorter timeout
      final LocationSettings highAccuracy =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? AndroidSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: const Duration(seconds: 8),
              forceLocationManager: true,
            )
          : (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
          ? AppleSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
              pauseLocationUpdatesAutomatically: false,
              activityType: ActivityType.otherNavigation,
              showBackgroundLocationIndicator: false,
              timeLimit: const Duration(seconds: 8),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 8),
            );
      return await Geolocator.getCurrentPosition(
        locationSettings: highAccuracy,
      );
    } catch (_) {
      // Try medium accuracy as fallback
      try {
        final LocationSettings mediumAccuracy =
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? AndroidSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 5),
                forceLocationManager: true,
              )
            : (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
            ? AppleSettings(
                accuracy: LocationAccuracy.medium,
                distanceFilter: 0,
                pauseLocationUpdatesAutomatically: false,
                activityType: ActivityType.otherNavigation,
                showBackgroundLocationIndicator: false,
                timeLimit: const Duration(seconds: 5),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 5),
              );
        return await Geolocator.getCurrentPosition(
          locationSettings: mediumAccuracy,
        );
      } catch (__) {
        if (!forceRefresh) {
          try {
            final lastKnown = await Geolocator.getLastKnownPosition();
            if (lastKnown != null && _isPositionFresh(lastKnown)) {
              return lastKnown;
            }
          } catch (_) {}
        }
        return null;
      }
    }
  }

  Future<Position?> _awaitLivePosition({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      return await Geolocator.getPositionStream(
            locationSettings: _liveTrackingLocationSettings(),
          )
          .where((position) {
            return position.latitude != 0 || position.longitude != 0;
          })
          .first
          .timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  LocationSettings _liveTrackingLocationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        forceLocationManager: true,
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.otherNavigation,
        showBackgroundLocationIndicator: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  bool _isPositionFresh(Position position) {
    final nowUtc = DateTime.now().toUtc();
    final timestampUtc = position.timestamp.toUtc();
    final diff = nowUtc.difference(timestampUtc).abs();
    // Use 1 minute instead of 30 for better responsiveness in simulators
    return diff.inMinutes <= 1;
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

      if (_hasLocationPermission) {
        _startLiveTracking();
        _useCurrentLocation(silent: true);
      }
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
        _selectedAddress = formatted.isEmpty ? _defaultCountry : formatted;
      });
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> _moveCamera(LatLng target, {required double zoom}) async {
    if (_useOpenStreetMap) {
      _webMapController.move(
        ll.LatLng(target.latitude, target.longitude),
        zoom,
      );
      return;
    }
    _cameraMoveByApp = true;
    try {
      await _googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _cameraMoveByApp = false;
    }
  }

  void _startFollowingCurrentLocation() {
    _followCurrentLocation = true;
  }

  void _stopFollowingCurrentLocation() {
    _followCurrentLocation = false;
  }

  void _scheduleReverseGeocode(LatLng point) {
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(_reverseGeocode(point));
    });
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
        city: _resolveCityFromAddress(_selectedAddress),
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

  String _resolveCityFromAddress(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return _defaultCity;

    final parts = cleaned
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    for (final part in parts) {
      for (final city in _cambodiaCities.keys) {
        if (part.toLowerCase().contains(city.toLowerCase())) {
          return city;
        }
      }
    }

    final filtered = parts
        .where(
          (item) =>
              !item.toLowerCase().contains('cambodia') &&
              !item.toLowerCase().contains('kingdom of cambodia'),
        )
        .toList(growable: false);
    if (filtered.isEmpty) return _defaultCity;
    if (filtered.length == 1) return filtered.first;
    return filtered.last;
  }

  bool _isInsideCambodia(LatLng point) {
    return point.latitude >= _cambodiaSouth &&
        point.latitude <= _cambodiaNorth &&
        point.longitude >= _cambodiaWest &&
        point.longitude <= _cambodiaEast;
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
