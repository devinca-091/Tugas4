import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'api_service.dart';
import 'article_model.dart';

void main() {
  runApp(const BeritaApp());
}

class BeritaApp extends StatelessWidget {
  const BeritaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Aplikasi Berita",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Enable scrolling with mouse drag on web
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      home: const BeritaScreen(),
    );
  }
}

class BeritaScreen extends StatefulWidget {
  const BeritaScreen({super.key});

  @override
  State<BeritaScreen> createState() => _BeritaScreenState();
}

class _BeritaScreenState extends State<BeritaScreen> {
  late Future<List<Article>> _articlesFuture;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;
  bool _isRefreshing = false;
  
  // Variables untuk pull-to-refresh di web
  double _pullDistance = 0;
  bool _isPulling = false;
  final double _refreshTriggerDistance = 100;

  @override
  void initState() {
    super.initState();
    _articlesFuture = ApiService().fetchArticles();
    
    // Listener untuk mendeteksi scroll
    _scrollController.addListener(() {
      if (_scrollController.offset >= 400) {
        if (!_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = true;
          });
        }
      } else {
        if (_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk refresh data
  Future<void> _refreshArticles() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      setState(() {
        _articlesFuture = ApiService().fetchArticles();
      });
      await _articlesFuture;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0;
          _isPulling = false;
        });
      }
    }
  }

  // Fungsi untuk scroll ke atas
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Handle pointer move untuk pull-to-refresh
  void _onPointerMove(PointerMoveEvent event) {
    // Hanya aktif jika sudah di posisi paling atas
    if (_scrollController.hasClients && _scrollController.offset <= 0) {
      if (event.delta.dy > 0 && !_isRefreshing) {
        setState(() {
          _isPulling = true;
          _pullDistance += event.delta.dy;
          if (_pullDistance > _refreshTriggerDistance * 1.5) {
            _pullDistance = _refreshTriggerDistance * 1.5;
          }
        });
      }
    }
  }

  // Handle pointer up untuk trigger refresh
  void _onPointerUp(PointerUpEvent event) {
    if (_isPulling && _pullDistance >= _refreshTriggerDistance) {
      _refreshArticles();
    } else {
      setState(() {
        _pullDistance = 0;
        _isPulling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Berita Terbaru"),
        elevation: 2,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshArticles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Listener(
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: Stack(
          children: [
            FutureBuilder<List<Article>>(
              future: _articlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshArticles,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final articles = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refreshArticles,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: articles.length,
                      padding: const EdgeInsets.all(8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return ArticleCard(article: article);
                      },
                    ),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: _refreshArticles,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "Tidak ada berita",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            // Pull-to-refresh indicator untuk web
            if (_isPulling || _isRefreshing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isPulling 
                      ? (_pullDistance / _refreshTriggerDistance * 60).clamp(0, 60)
                      : (_isRefreshing ? 60 : 0),
                  child: Center(
                    child: _isRefreshing
                        ? const CircularProgressIndicator()
                        : Transform.rotate(
                            angle: (_pullDistance / _refreshTriggerDistance * 3.14).clamp(0, 3.14),
                            child: Icon(
                              Icons.arrow_downward,
                              color: _pullDistance >= _refreshTriggerDistance
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Kembali ke atas',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null && article.urlToImage!.isNotEmpty)
              Image.network(
                article.urlToImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title ?? 'Tidak ada judul',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description ?? 'Tidak ada deskripsi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}