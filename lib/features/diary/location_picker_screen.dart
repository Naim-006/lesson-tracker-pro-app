import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import 'map_location_picker_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = TextEditingController();
  List<GeocodingResult> _results = [];
  GeocodingResult? _selected;
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final results = await GeocodingService.geocode(query);
    if (mounted) {
      setState(() {
        _results = results;
        _hasSearched = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _centerMapOn(double lat, double lng) async {
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
  }

  Future<void> _pushToFullMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(initialAddress: _selected?.formattedAddress ?? _controller.text),
      ),
    );
    if (result != null && mounted) {
      final address = result['address'] as String? ?? '';
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      if (address.isNotEmpty) {
        _controller.text = address;
        if (lat != null && lng != null) {
          setState(() {
            _selected = GeocodingResult(lat: lat, lng: lng, formattedAddress: address, placeId: '');
          });
          _centerMapOn(lat, lng);
        }
      }
    }
  }

  Future<void> _openInMaps(GeocodingResult r) async {
    final url = GeocodingService.googleMapsUrl(r.lat, r.lng);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _confirm() {
    final address = _selected?.formattedAddress ?? _controller.text.trim();
    if (address.isNotEmpty) {
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Set Location', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Open Map',
            onPressed: _pushToFullMap,
          ),
          if (_selected != null)
            TextButton(
              onPressed: _confirm,
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sunsetBright)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search postcode or address...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.sunsetBright),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _selected = null;
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),

          // Selected location card with map preview
          if (_selected != null)
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sunsetBright.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border(
                      top: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                      left: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                      right: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.sunsetBright.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on, color: AppColors.sunsetBright, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Selected Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _openInMaps(_selected!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map, size: 14, color: AppColors.info),
                                  const SizedBox(width: 4),
                                  Text('Open Map', style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selected!.formattedAddress,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selected!.lat.toStringAsFixed(5)}, ${_selected!.lng.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                      ),
                    ],
                  ),
                ),
                // Mini map preview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    border: Border(
                      bottom: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                      left: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                      right: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_selected!.lat, _selected!.lng),
                          zoom: 16,
                        ),
                        onMapCreated: (ctrl) => _mapController = ctrl,
                        markers: {
                          Marker(
                            markerId: const MarkerId('preview'),
                            position: LatLng(_selected!.lat, _selected!.lng),
                          ),
                        },
                        gestureRecognizers: const {},
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                      ),
                      // Tap overlay to open full map
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _pushToFullMap(),
                            splashColor: AppColors.sunsetBright.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Open map overlay label
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_full, size: 12, color: AppColors.sunsetBright),
                              const SizedBox(width: 4),
                              Text('Explore Map', style: TextStyle(fontSize: 10, color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          if (_selected != null) const SizedBox(height: 16),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _hasSearched
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                const SizedBox(height: 12),
                                Text('No results found', style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                              ],
                            ),
                          )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_searching, size: 48, color: AppColors.sunsetBright.withValues(alpha: 0.4)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Enter a UK postcode or address',
                                    style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'e.g. SW1A 1AA or 10 Downing Street',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton.icon(
                                    onPressed: _pushToFullMap,
                                    icon: const Icon(Icons.map, size: 16),
                                    label: const Text('Pick on Map'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.sunsetBright,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final r = _results[i];
                          final isSelected = _selected?.placeId == r.placeId;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Material(
                              color: isSelected
                                  ? AppColors.sunsetBright.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selected = r);
                                  _controller.text = r.formattedAddress;
                                  _controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: _controller.text.length),
                                  );
                                  _centerMapOn(r.lat, r.lng);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.sunsetBright.withValues(alpha: 0.15)
                                              : (isDark ? AppColors.darkCard : Colors.grey.shade100),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isSelected ? Icons.location_on : Icons.location_on_outlined,
                                          color: isSelected ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.formattedAddress,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                color: isDark ? AppColors.darkText : AppColors.lightText,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                                                style: TextStyle(fontSize: 11, color: AppColors.sunsetBright),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (!isSelected)
                                        Icon(Icons.chevron_right, size: 18, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                      if (isSelected)
                                        Icon(Icons.check_circle, size: 20, color: AppColors.sunsetBright),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
