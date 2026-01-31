class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5017/api'; // Use 10.0.2.2 for Android emulator to reach localhost
  
  // Alternative URLs depending on platform
  static String getPlatformBaseUrl() {
    // For Android emulator, use 10.0.2.2
    // For iOS simulator, use localhost
    // For physical device, use actual IP address of the machine running the server
    return baseUrl;
  }
}