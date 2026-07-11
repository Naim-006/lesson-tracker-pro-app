import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final _searchController = TextEditingController();
  final _markers = <Marker>{};
  final _results = <GeocodingResult>[];
  LatLng? _selectedLatLng;
  String? _selectedAddress;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _showResults = false;
  Timer? _debounce;

  static const _defaultLocation = LatLng(51.5074, -0.1278);

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialAddress ?? '';
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _geocodeAndSelect(widget.initialAddress!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() { _results.clear(); _showResults = false; });
      return;
    }
    setState(() => _showResults = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await GeocodingService.geocode(query);
    if (mounted) {
      setState(() {
        _results
          ..clear()
          ..addAll(results);
        _isLoading = false;
      });
    }
  }

  Future<void> _geocodeAndSelect(String query) async {
    setState(() => _isLoading = true);
    final result = await GeocodingService.geocodePostcode(query);
    if (result != null && mounted) {
      _applySelection(result);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(result.lat, result.lng), 15));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onResultTap(GeocodingResult r) {
    _applySelection(r);
    _results.clear();
    _showResults = false;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(r.lat, r.lng), 16));
  }

  void _applySelection(GeocodingResult r) {
    _selectedLatLng = LatLng(r.lat, r.lng);
    _selectedAddress = r.formattedAddress;
    _searchController.text = r.formattedAddress;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _updateMarker();
  }

  void _updateMarker() {
    if (_selectedLatLng == null) return;
    _markers
      ..clear()
      ..add(Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLatLng!,
        draggable: true,
        onDragEnd: (pos) {
          _selectedLatLng = pos;
          _reverseGeocode(pos);
        },
      ));
    setState(() {});
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoading = true);
    final results = await GeocodingService.geocode('${pos.latitude},${pos.longitude}');
    if (results.isNotEmpty && mounted) {
      _selectedAddress = results.first.formattedAddress;
      _searchController.text = _selectedAddress!;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _autoLocate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!(await Geolocator.openLocationSettings())) return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Enable in settings.')),
        );
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _selectedLatLng = LatLng(pos.latitude, pos.longitude);
      _selectedAddress = null;
      _results.clear();
      _showResults = false;
      _updateMarker();
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLatLng!, 16));
      _reverseGeocode(_selectedLatLng!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  void _onMapTap(LatLng pos) {
    _selectedLatLng = pos;
    _selectedAddress = null;
    _results.clear();
    _showResults = false;
    _updateMarker();
    _reverseGeocode(pos);
    FocusScope.of(context).unfocus();
  }

  void _confirm() {
    final address = _selectedAddress ?? _searchController.text.trim();
    if (address.isNotEmpty && _selectedLatLng != null) {
      Navigator.pop(context, {
        'address': address,
        'lat': _selectedLatLng!.latitude,
        'lng': _selectedLatLng!.longitude,
      });
    } else if (address.isNotEmpty) {
      Navigator.pop(context, {'address': address});
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _markers.clear();
    _results.clear();
    setState(() {
      _selectedLatLng = null;
      _selectedAddress = null;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.darkText : AppColors.lightText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pick Location', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_selectedLatLng != null)
            TextButton(
              onPressed: _confirm,
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sunsetBright)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _defaultLocation, zoom: 10),
            onMapCreated: (ctrl) => _mapController = ctrl,
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            style: isDark ? _darkMapStyle : null,
          ),

          // Search bar
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: _showResults && _results.isNotEmpty ? 0 : 4,
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? AppColors.darkCard : Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search postcode or address...',
                      hintStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                      prefixIcon: Icon(Icons.search, color: AppColors.sunsetBright, size: 22),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearSearch)
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) {
                      _geocodeAndSelect(q);
                      setState(() { _results.clear(); _showResults = false; });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                // Results dropdown
                if (_showResults && _results.isNotEmpty)
                  Material(
                    elevation: 8,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    color: isDark ? AppColors.darkCard : Colors.white,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          final sameAsSelected = _selectedAddress == r.formattedAddress;
                          return InkWell(
                            onTap: () => _onResultTap(r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: sameAsSelected ? AppColors.sunsetBright.withValues(alpha: 0.06) : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    sameAsSelected ? Icons.location_on : Icons.location_on_outlined,
                                    size: 18,
                                    color: sameAsSelected ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.formattedAddress,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: sameAsSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isDark ? AppColors.darkText : AppColors.lightText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                                          style: TextStyle(fontSize: 10, color: AppColors.sunsetBright.withValues(alpha: 0.7)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sameAsSelected)
                                    const Icon(Icons.check_circle, size: 18, color: AppColors.sunsetBright),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom info card
          if (_selectedAddress != null && !_showResults)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkMuted : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.sunsetBright.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: AppColors.sunsetBright, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected Location',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                              const SizedBox(height: 4),
                              Text(_selectedAddress!,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkText : AppColors.lightText)),
                              if (_selectedLatLng != null) ...[
                                const SizedBox(height: 2),
                                Text('${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                                    style: TextStyle(fontSize: 11, color: AppColors.sunsetBright)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _confirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm Location'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunsetBright,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // FABs
          Positioned(
            right: 16,
            bottom: (_selectedAddress != null && !_showResults) ? 220 : 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: _autoLocate,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  child: Icon(Icons.my_location, color: AppColors.sunsetBright, size: 22),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  child: Icon(Icons.add, color: isDark ? AppColors.darkText : AppColors.lightText, size: 22),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  child: Icon(Icons.remove, color: isDark ? AppColors.darkText : AppColors.lightText, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{ "color": "#242f3e" }]},
  {"elementType": "labels.text.fill", "stylers": [{ "color": "#746855" }]},
  {"elementType": "labels.text.stroke", "stylers": [{ "color": "#242f3e" }]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#d59563" }]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#38414e" }]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#746855" }]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#17263c" }]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#515c6d" }]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{ "color": "#283d4a" }]}
]
''';
