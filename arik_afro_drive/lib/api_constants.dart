class ApiConstants {
  // OPTION A: For Development (Disabled)
  /*
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.0.2.2:5000'; 
  }
  */

  // OPTION B: For Production (Enabled!)
  static String baseUrl = 'https://arik-api.onrender.com'; // 👈 Paste your Render URL here
}