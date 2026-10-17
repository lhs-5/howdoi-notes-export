/// Semantic field description used by host applications to render URL inputs.
class GoogleMapsUrlFieldSpec {
  const GoogleMapsUrlFieldSpec({required this.key, required this.label});

  final String key;
  final String label;
}

const googleMapsUrlFields = <String>{
  'googleMapsUrl',
  'originGoogleMapsUrl',
  'destinationGoogleMapsUrl',
};

const googleMapsPlaceUrlField = GoogleMapsUrlFieldSpec(
  key: 'googleMapsUrl',
  label: 'Google Maps 地址 URL（可空）',
);
const googleMapsOriginUrlField = GoogleMapsUrlFieldSpec(
  key: 'originGoogleMapsUrl',
  label: 'Google Maps 起点 URL（可空）',
);
const googleMapsDestinationUrlField = GoogleMapsUrlFieldSpec(
  key: 'destinationGoogleMapsUrl',
  label: 'Google Maps 终点 URL（可空）',
);

/// Returns the URL inputs a host should show for an item.
///
/// Flights never have map URL inputs. Non-flight transport has independent
/// origin and destination URLs; single-place items have one location URL.
List<GoogleMapsUrlFieldSpec> googleMapsUrlFieldsFor({
  required bool isTransport,
  required bool isFlight,
}) {
  if (isFlight) return const [];
  if (isTransport) {
    return const [googleMapsOriginUrlField, googleMapsDestinationUrlField];
  }
  return const [googleMapsPlaceUrlField];
}

/// Validates a URL without performing any network or map lookup.
bool isValidGoogleMapsUrl(String value) {
  if (value.isEmpty ||
      value != value.trim() ||
      RegExp(r'[\s<>\\]').hasMatch(value)) {
    return false;
  }
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

/// Copies item fields and removes stale Google Maps URLs from flights.
Map<String, dynamic> normalizeGoogleMapsUrlFields({
  required bool isFlight,
  required Map<String, dynamic> fields,
}) {
  final normalized = Map<String, dynamic>.from(fields);
  if (isFlight) {
    normalized.removeWhere((key, _) => googleMapsUrlFields.contains(key));
  }
  return normalized;
}

/// Throws [FormatException] when a saved URL is invalid or belongs to a flight.
void validateGoogleMapsUrlFields({
  required bool isFlight,
  required Map<String, dynamic> fields,
}) {
  for (final key in googleMapsUrlFields) {
    final url = fields[key] as String? ?? '';
    if (url.isNotEmpty && !isValidGoogleMapsUrl(url)) {
      throw FormatException('$key 必须是有效的 HTTPS URL');
    }
    if (isFlight && url.isNotEmpty) {
      throw const FormatException('航班记录不支持 Google Maps URL');
    }
  }
}
