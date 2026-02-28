class LocationNotFoundException implements Exception {
  final String locationId;
  const LocationNotFoundException(this.locationId);

  @override
  String toString() => 'Konum bulunamadı: $locationId';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'API Hatası${statusCode != null ? ' ($statusCode)' : ''}: $message';
}
