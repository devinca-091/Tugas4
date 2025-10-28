class Article {
  final String? title;
  final String? description;
  final String? urlToImage;

  Article({
    required this.title,
    this.description,
    this.urlToImage,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    print('Parsing article: ${json['title']}'); // Debug
    
    return Article(
      title: json['title'] as String?,
      description: json['description'] as String?,
      // NewsData.io menggunakan 'image_url' bukan 'urlToImage'
      urlToImage: json['image_url'] as String?,
    );
  }
}