class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

  static String incidents() => '$baseUrl/incidents';

  static String incidentById(int incidentId) =>
      '$baseUrl/incidents/$incidentId';
}
