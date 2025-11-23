// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> news = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => isLoading = true);

    try {
      final rawData = await ApiService.getNews();

      if (rawData == null || (rawData is List && rawData.isEmpty)) {
        setState(() {
          news = [];
          isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> processed = (rawData as List).map((item) {
        final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};

        return {
          'id': map['id'] ?? map['ID_TINTUC'] ?? 0,
          'title': map['title'] ?? map['TIEUDE'] ?? map['TEN_TINTUC'] ?? 'Thông báo mới',
          'content': map['content'] ?? map['NOIDUNG'] ?? 'Không có nội dung.',
          'created_at': map['created_at'] ?? map['NGAYDANG'] ?? DateTime.now().toIso8601String(),
          'cover_image': map['cover_image'] ?? map['ANH_BIA'],
          'pdf_file': map['pdf_file'] ?? map['FILE_DINHKEM'],
          'created_by': map['created_by'] ?? map['nguoi_tao'] ?? map['nguoidang'] ?? null,
        };
      }).toList();

      setState(() {
        news = processed;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("LỖI TẢI TIN TỨC: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Không rõ ngày';
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return dateStr.split('T').first;
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      appBar: AppBar(
        title: const Text('Tin tức & Thông báo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)]),
          ),
        ),
      ),
      body: isLoading
          ? const NewsShimmerLoading()
          : RefreshIndicator(
              onRefresh: _loadNews,
              color: Colors.indigo,
              child: news.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined, size: 90, color: Colors.grey[400]),
                            const SizedBox(height: 20),
                            const Text('Không có tin tức nào', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 12),
                            const Text('Kéo xuống để thử lại', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadNews,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Tải lại"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: news.length,
                      itemBuilder: (context, i) {
                        final item = news[i];
                        final imgUrl = item['cover_image'] != null ? "${ApiService.baseStorageUrl}/${item['cover_image']}" : null;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 5))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(newsItem: item))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imgUrl != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: Image.network(
                                      imgUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5)),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.indigo),
                                          const SizedBox(width: 6),
                                          Text(_formatDate(item['created_at']), style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                          const Spacer(),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.indigo),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class NewsShimmerLoading extends StatelessWidget {
  const NewsShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(margin: const EdgeInsets.only(bottom: 20), height: 280, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
      ),
    );
  }
}

// CHI TIẾT TIN TỨC – ĐẸP LUNG LINH, HIỆN NGƯỜI TẠO, NỘI DUNG ĐẸP, KHÔNG CÒN LỖI HTML
class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;
  const NewsDetailScreen({super.key, required this.newsItem});

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Không rõ';
    try {
      final date = DateTime.tryParse(dateStr);
      return date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal()) : dateStr.split('T').first;
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  String _stripHtml(String? html) {
    if (html == null) return "Không có nội dung.";
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = newsItem['cover_image'] != null ? "${ApiService.baseStorageUrl}/${newsItem['cover_image']}" : null;
    final pdfUrl = newsItem['pdf_file'] != null ? "${ApiService.baseStorageUrl}/${newsItem['pdf_file']}" : null;

    final creator = newsItem['created_by']?['HODEM_VA_TEN'] ??
        newsItem['created_by']?['name'] ??
        newsItem['created_by']?.toString() ??
        "Quản trị viên";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi tiết tin tức', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)])),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imgUrl, width: double.infinity, height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 24),

            Text(newsItem['title'] ?? 'Không có tiêu đề', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(_formatDate(newsItem['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.deepPurple, size: 18),
                const SizedBox(width: 8),
                Text("Người đăng: $creator", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),

            const Divider(height: 40, thickness: 1.5, color: Color(0xFFE0E0E0)),

            // NỘI DUNG ĐÃ LOẠI BỎ HTML → ĐẸP, DỄ ĐỌC
            Text(
              _stripHtml(newsItem['content']),
              style: const TextStyle(fontSize: 17, height: 1.7, color: Color(0xFF424242)),
            ),

            if (pdfUrl != null) ...[
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(pdfUrl),
                  icon: const Icon(Icons.picture_as_pdf, size: 32),
                  label: const Text('MỞ TÀI LIỆU ĐÍNH KÈM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}