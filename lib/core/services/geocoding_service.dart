import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final double lat;
  final double lng;
  final String formattedAddress;
  final String placeId;

  GeocodingResult({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.placeId,
  });
}

class GeocodingService {
  static const String _apiKey = 'AIzaSyDSyn100l0J_cdKLi52gl6MMwIVMHSfSOo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  static Future<List<GeocodingResult>> geocode(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'address': query.trim(),
        'key': _apiKey,
        'components': 'country:GB',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [];

      final results = data['results'] as List;
      return results.map((r) {
        final loc = r['geometry']['location'];
        return GeocodingResult(
          lat: (loc['lat'] as num).toDouble(),
          lng: (loc['lng'] as num).toDouble(),
          formattedAddress: r['formatted_address'] as String? ?? query,
          placeId: r['place_id'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<GeocodingResult?> geocodePostcode(String postcode) async {
    final results = await geocode(postcode);
    return results.isNotEmpty ? results.first : null;
  }

  static String googleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  static String googleMapsQueryUrl(String query) {
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }

  static String staticMapUrl(String address, {int width = 400, int height = 200, int zoom = 14}) {
    final encoded = Uri.encodeComponent(address);
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$encoded'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=color:red%7C$encoded'
        '&key=$_apiKey';
  }
}
