/// Utility functions for handling URLs in the app.
class UrlUtils {
  UrlUtils._();

  /// Sanitizes backend URLs that point to 'localhost' or '127.0.0.1'.
  /// Replaces them with the actual API base host configured at compile-time.
  static String? sanitizeUrl(String? url) {
    if (url == null) return null;
    
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      const defaultApiUrl = 'http://192.168.1.43:4005/api/';
      final String apiUrl = const String.fromEnvironment('API_URL', defaultValue: defaultApiUrl);
      
      final uri = Uri.tryParse(apiUrl);
      if (uri != null) {
        final hostPart = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
        return url
            .replaceAll('http://localhost:4005', hostPart)
            .replaceAll('http://127.0.0.1:4005', hostPart)
            .replaceAll('http://localhost', hostPart)
            .replaceAll('http://127.0.0.1', hostPart);
      }
    }
    return url;
  }
}
