import 'dart:convert';
import 'package:http/http.dart' as http;
import 'article_model.dart';

class ApiService {
  // API key NewsData.io yang valid
  static const String _apiKey = 'pub_6cde9ca3284942aca6768ca041d75055';
  static const String _baseUrl = 'https://newsdata.io/api/1/news';

  Future<List<Article>> fetchArticles() async {
    try {
      // Parameter untuk NewsData.io
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'apikey': _apiKey,
        'q': 'teknologi', // Query pencarian
        'language': 'id', // Bahasa Indonesia
        'country': 'id', // Negara Indonesia
      });

      print('Requesting: $uri'); // Debug

      final response = await http.get(uri);
      
      print('Status: ${response.statusCode}'); // Debug
      print('Response: ${response.body.substring(0, 200)}...'); // Debug
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        
        // NewsData.io menggunakan 'results' bukan 'articles'
        final List<dynamic> articlesJson = json['results'] ?? [];
        
        print('Total articles: ${articlesJson.length}'); // Debug
        
        return articlesJson
            .map((json) => Article.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception(
          'API Key tidak valid. Silakan daftar di https://newsdata.io/register untuk mendapatkan API key baru.'
        );
      } else {
        throw Exception(
          'Failed to load articles. Status code: ${response.statusCode}'
        );
      }
    } catch (e) {
      print('Error detail: $e'); // Debug
      throw Exception('Failed to connect to the server: $e');
    }
  }
}