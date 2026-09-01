import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<Map<String, dynamic>> getWeather(
    double latitude,
    double longitude,
  ) async {
    final url =
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=$latitude"
        "&longitude=$longitude"
        "&current=temperature_2m,relative_humidity_2m,wind_speed_10m"
        "&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability"
        "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max"
        "&timezone=auto"
        "&forecast_days=7";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load weather");
  }
}
