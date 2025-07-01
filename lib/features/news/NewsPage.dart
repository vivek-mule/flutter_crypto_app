import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/behavior_settings/behavior_settings_provider.dart';

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  List<CryptoNews> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCryptoNews();
  }

  Future<void> fetchCryptoNews() async {
    setState(() => _isLoading = true);
    final apiKey = dotenv.env['COINDESK_API_KEY'] ?? '';
    final url =
        'https://data-api.coindesk.com/news/v1/article/list?lang=EN&limit=10&api_key=$apiKey';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> articles = body['Data'] as List<dynamic>;

      setState(() {
        _newsList = articles
            .map((e) => CryptoNews.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching CoinDesk news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching news: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(behaviorSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Today's Top Crypto News"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : settings.refreshNews
          ? RefreshIndicator(
        onRefresh: fetchCryptoNews,
        color: Colors.deepPurpleAccent,
        backgroundColor: Colors.black,
        child: _buildNewsList(settings.openInWebView),
      )
          : _buildNewsList(settings.openInWebView),
    );
  }

  Widget _buildNewsList(bool openInWebView) {
    if (_newsList.isEmpty) {
      return const Center(
        child: Text("No news articles found.", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _newsList.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.white.withOpacity(0.05),
        thickness: 1,
        height: 12,
      ),
      itemBuilder: (context, i) {
        final news = _newsList[i];
        final sentimentBadge = _getSentimentBadge(news.sentiment);

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.all(10),
            leading: news.imageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                news.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
                : const Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                sentimentBadge,
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  news.publishedOn,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (news.source != null)
                  Text(
                    news.source!,
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            onTap: () => _openNews(news.url, openInWebView),
          ),
        );
      },
    );
  }

  Widget _getSentimentBadge(String sentiment) {
    Color color;
    String label;

    switch (sentiment.toLowerCase()) {
      case 'positive':
        color = Colors.greenAccent;
        label = '🟢 Positive';
        break;
      case 'negative':
        color = Colors.redAccent;
        label = '🔴 Negative';
        break;
      default:
        color = Colors.amberAccent;
        label = '🟡 Neutral';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }


  void _openNews(String url, bool openInWebView) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: openInWebView
          ? LaunchMode.inAppWebView
          : LaunchMode.externalApplication,
    );

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open the news article'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class CryptoNews {
  final String title;
  final String url;
  final String? imageUrl;
  final String? source;
  final String sentiment;
  final String publishedOn;

  CryptoNews({
    required this.title,
    required this.url,
    this.imageUrl,
    this.source,
    required this.sentiment,
    required this.publishedOn,
  });

  factory CryptoNews.fromJson(Map<String, dynamic> j) {
    final int ts = j['PUBLISHED_ON'] as int;
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal();
    final String formattedDate = DateFormat.yMMMd().add_jm().format(dt);

    final String? img = (j['IMAGE_URL'] as String?)?.isNotEmpty == true
        ? j['IMAGE_URL'] as String
        : null;
    final Map<String, dynamic>? src = j['SOURCE_DATA'] as Map<String, dynamic>?;
    final String? srcName = src?['NAME'] as String?;

    return CryptoNews(
      title: j['TITLE'] as String? ?? '',
      url: j['URL'] as String? ?? '',
      imageUrl: img,
      source: srcName,
      sentiment: j['SENTIMENT'] as String? ?? '',
      publishedOn: formattedDate,
    );
  }
}
