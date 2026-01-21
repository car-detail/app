List<Map<String, dynamic>> mapPackagesForDisplay(dynamic rawPackages) {
  if (rawPackages is! List) {
    return [];
  }

  return rawPackages
      .map<Map<String, dynamic>?>((pkg) => _normalizePackage(pkg))
      .whereType<Map<String, dynamic>>()
      .toList();
}

Map<String, dynamic>? _normalizePackage(dynamic pkg) {
  if (pkg is! Map<String, dynamic>) {
    return null;
  }

  final servicesIncludedRaw = pkg['servicesIncluded'];
  final List<Map<String, dynamic>> servicesIncluded = [];
  final List<String> derivedFeatures = [];

  if (servicesIncludedRaw is List) {
    for (final service in servicesIncludedRaw) {
      if (service is Map<String, dynamic>) {
        final serviceTitle =
            service['serviceTitle']?.toString() ?? service['categoryName']?.toString();
        final serviceDuration = service['serviceDuration']?.toString();
        final normalizedService = {
          'id': service['_id']?.toString() ?? service['id']?.toString(),
          'title': serviceTitle,
          'price': service['price'],
          'duration': serviceDuration,
          'raw': service,
        };
        servicesIncluded.add(normalizedService);

        if (serviceTitle != null && serviceTitle.isNotEmpty) {
          derivedFeatures.add(serviceTitle);
        }
      } else if (service != null) {
        derivedFeatures.add(service.toString());
      }
    }
  }

  final List<String> featureList = (pkg['features'] is List)
      ? (pkg['features'] as List)
          .map((feature) => feature?.toString())
          .whereType<String>()
          .toList()
      : derivedFeatures;

  final duration = pkg['duration']?.toString() ??
      pkg['packageDuration']?.toString() ??
      _buildDurationFromServices(servicesIncluded) ??
      (servicesIncluded.isNotEmpty
          ? "${servicesIncluded.length} services"
          : "Custom duration");

  return {
    'id': pkg['_id']?.toString() ?? pkg['id']?.toString(),
    'title': pkg['title']?.toString() ?? pkg['packageName']?.toString() ?? 'Service Package',
    'packageName': pkg['packageName']?.toString(),
    'description': pkg['description']?.toString() ?? '',
    'price': pkg['price'],
    'discount': pkg['discount'],
    'duration': duration,
    'features': featureList,
    'servicesIncluded': servicesIncluded,
    'coverImage': pkg['coverImage'],
    'detailImages': pkg['detailImages'] ?? [],
    'raw': pkg,
  };
}

String? _buildDurationFromServices(List<Map<String, dynamic>> servicesIncluded) {
  if (servicesIncluded.isEmpty) {
    return null;
  }

  final durations = servicesIncluded
      .map((service) => service['duration']?.toString())
      .where((duration) => duration != null && duration.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  if (durations.isEmpty) {
    return null;
  }

  return durations.length == 1 ? durations.first : durations.join(', ');
}



