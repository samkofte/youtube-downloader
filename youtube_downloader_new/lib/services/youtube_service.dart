import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_model.dart';
import '../models/download_item.dart';

class YouTubeService {
  static String get baseUrl {
    return 'http://localhost:3001';
    // return 'https://youtube-downloader-5rl2.onrender.com';
  }

  // Yerel geliştirme için indirme taban adresi (mobil için uygun loopback)
  static String get downloadBaseUrl {
    if (Platform.isAndroid) {
      // Android cihaz -> host makine: gerçek IP adresi
      return 'http://192.168.1.14:3001';
    } else if (Platform.isIOS) {
      // iOS Simulator -> host makine: localhost
      return 'http://localhost:3001';
    }
    // Diğer platformlarda gerekirse LAN IP kullanın
    return 'http://localhost:3001';
  }

  static final YoutubeExplode _yt = YoutubeExplode();

  // Search videos
  static Future<List<VideoModel>> searchVideos(String query,
      {int maxResults = 10}) async {
    developer.log('🔍 Video arama başlatıldı: $query', name: 'YouTubeService');
    try {
      developer.log('📡 Backend API arama isteği gönderiliyor...',
          name: 'YouTubeService');
      final response = await http.post(
        Uri.parse('$downloadBaseUrl/api/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> videos = json.decode(response.body);
        developer.log(
            '✅ Backend API arama başarılı: ${videos.length} video bulundu',
            name: 'YouTubeService');
        return videos
            .map((video) => VideoModel(
                  id: video['id'] ?? '',
                  title: video['title'] ?? '',
                  thumbnail: video['thumbnail'] ?? '',
                  duration: video['duration'] ?? '',
                  description: '',
                  channelTitle: video['channel'] ?? '',
                  viewCount: video['viewCount']?.toString() ?? '0',
                  publishedAt: video['publishedAt'] ?? '',
                  url: video['url'] ??
                      'https://www.youtube.com/watch?v=${video['id'] ?? ''}',
                ))
            .toList();
      } else {
        throw Exception('Failed to search videos: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
          '⚠️ Backend API arama başarısız, youtube_explode_dart kullanılıyor: $e',
          name: 'YouTubeService');
      throw Exception('Error searching videos: $e');
    }
  }

  // Get video info
  static Future<VideoInfo> getVideoInfo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VideoInfo.fromJson(data);
      } else {
        throw Exception('Failed to get video info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting video info: $e');
    }
  }

  // Get search suggestions
  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$downloadBaseUrl/api/search-suggestions?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> suggestions = json.decode(response.body);
        return suggestions.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Download MP3 using youtube_explode_dart (direct download)
  static Future<String> downloadMp3(
      String url, String title, Function(double) onProgress) async {
    developer.log('🚀 MP3 İndirme Başlatıldı (Direct Download)',
        name: 'YouTubeService');
    developer.log('🔗 Video URL: $url', name: 'YouTubeService');
    developer.log('📁 Dosya adı: $title', name: 'YouTubeService');

    try {
      onProgress(0.1);

      // Video bilgilerini al
      final video = await _yt.videos.get(url);
      onProgress(0.2);

      // Audio stream'i al
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();

      onProgress(0.3);

      // Kayıt konumu: Downloads/YouTube_Music (yoksa Documents)
      final baseDirectory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final directory = Directory('${baseDirectory.path}/YouTube_Music');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        developer.log('📁 YouTube_Music klasörü oluşturuldu: ${directory.path}',
            name: 'YouTubeService');
      }

      final fileName = '${_sanitizeFileName(title)}.mp3';
      final file = File('${directory.path}/$fileName');
      final sink = file.openWrite();

      onProgress(0.4);

      // Audio stream'i indir
      final audioStreamData = _yt.videos.streamsClient.get(audioStream);
      final totalBytes = audioStream.size.totalBytes;
      int downloadedBytes = 0;

      await for (final chunk in audioStreamData) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = 0.4 + (0.5 * downloadedBytes / totalBytes);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();

      onProgress(1.0);

      developer.log('✅ MP3 başarıyla indirildi: ${file.path}',
          name: 'YouTubeService');

      final downloadItem = DownloadItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: file.path,
        type: 'mp3',
        downloadDate: DateTime.now(),
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration?.toString() ?? '',
        originalUrl: url,
      );

      return 'MP3 başarıyla indirildi: ${file.path}|${downloadItem.id}';
    } catch (e) {
      developer.log('❌ MP3 indirme hatası: $e', name: 'YouTubeService');
      throw Exception('MP3 indirme hatası: $e');
    }
  }

  // Download MP4 using youtube_explode_dart (direct download)
  static Future<String> downloadMp4(String url, String quality, String title,
      Function(double) onProgress) async {
    developer.log('🚀 MP4 İndirme Başlatıldı (Direct Download)',
        name: 'YouTubeService');
    developer.log('🔗 Video URL: $url', name: 'YouTubeService');
    developer.log('📁 Dosya adı: $title', name: 'YouTubeService');
    developer.log('🎯 Kalite: $quality', name: 'YouTubeService');

    try {
      onProgress(0.1);

      // Video bilgilerini al
      final video = await _yt.videos.get(url);
      onProgress(0.2);

      // Video stream'i al
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);

      // Kalite seçimi
      VideoStreamInfo videoStream;
      if (quality == 'highest') {
        videoStream = manifest.muxed.withHighestBitrate();
      } else {
        // Use highest quality available
        videoStream = manifest.muxed.withHighestBitrate();
      }

      onProgress(0.3);

      // Kayıt konumu: Downloads/YouTube_Videos (yoksa Documents)
      final baseDirectory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final directory = Directory('${baseDirectory.path}/YouTube_Videos');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        developer.log(
            '📁 YouTube_Videos klasörü oluşturuldu: ${directory.path}',
            name: 'YouTubeService');
      }

      final fileName = '${_sanitizeFileName(title)}.mp4';
      final file = File('${directory.path}/$fileName');
      final sink = file.openWrite();

      onProgress(0.4);

      // Video stream'i indir
      final videoStreamData = _yt.videos.streamsClient.get(videoStream);
      final totalBytes = videoStream.size.totalBytes;
      int downloadedBytes = 0;

      await for (final chunk in videoStreamData) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = 0.4 + (0.5 * downloadedBytes / totalBytes);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();

      onProgress(1.0);

      developer.log('✅ MP4 başarıyla indirildi: ${file.path}',
          name: 'YouTubeService');

      final downloadItem = DownloadItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: file.path,
        type: 'mp4',
        downloadDate: DateTime.now(),
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration?.toString() ?? '',
        originalUrl: url,
      );

      return 'MP4 başarıyla indirildi: ${file.path}|${downloadItem.id}';
    } catch (e) {
      developer.log('❌ MP4 indirme hatası: $e', name: 'YouTubeService');
      throw Exception('MP4 indirme hatası: $e');
    }
  }

  // Get trending videos
  static Future<List<VideoModel>> getTrendingVideos(
      {int maxResults = 20}) async {
    developer.log('📈 Trending videolar alınıyor...', name: 'YouTubeService');
    try {
      final response = await http.get(
        Uri.parse('$downloadBaseUrl/trending?maxResults=$maxResults'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> videos = data['videos'] ?? [];

        final videoModels = videos
            .map((video) => VideoModel(
                  id: video['id'] ?? '',
                  title: video['title'] ?? '',
                  thumbnail: video['thumbnail'] ?? '',
                  duration: video['duration'] ?? '',
                  description: '',
                  channelTitle: video['channel'] ?? '',
                  viewCount: video['viewCount']?.toString() ?? '0',
                  publishedAt: video['publishedAt'] ?? '',
                  url: video['url'] ??
                      'https://www.youtube.com/watch?v=${video['id'] ?? ''}',
                ))
            .toList();

        developer.log(
            '✅ Trending videolar başarıyla alındı: ${videoModels.length} video',
            name: 'YouTubeService');
        return videoModels;
      } else {
        throw Exception(
            'Failed to get trending videos: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Trending videolar alınamadı: $e',
          name: 'YouTubeService');
      throw Exception('Error getting trending videos: $e');
    }
  }

  // Get video info using backend API (fallback to avoid cipher issues)
  static Future<Map<String, dynamic>> getVideoInfoDirect(String url) async {
    developer.log('📺 Video bilgisi alınıyor: $url', name: 'YouTubeService');

    try {
      // Try backend API first
      try {
        developer.log('🌐 Backend API ile video bilgisi deneniyor...',
            name: 'YouTubeService');
        developer.log('📤 İstek URL: $downloadBaseUrl/video-info',
            name: 'YouTubeService');
        developer.log('📤 İstek body: {"url": "$url"}', name: 'YouTubeService');

        final response = await http
            .post(
              Uri.parse('$downloadBaseUrl/video-info'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'url': url}),
            )
            .timeout(const Duration(seconds: 30));

        developer.log('📡 Backend API yanıtı: ${response.statusCode}',
            name: 'YouTubeService');
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          developer.log(
              '✅ Backend API ile video bilgisi alındı: ${data['videoInfo']['title']}',
              name: 'YouTubeService');
          return {
            'title': data['videoInfo']['title'] ?? '',
            'duration': data['videoInfo']['duration']?.toString() ?? '0',
            'thumbnail': data['videoInfo']['thumbnail'] ?? '',
            'author': data['videoInfo']['author'] ?? '',
            'viewCount': data['videoInfo']['viewCount']?.toString() ?? '0',
            'qualities': ['720p', '480p', '360p'], // Default qualities
          };
        } else {
          developer.log(
              '❌ Backend API video bilgisi hatası: ${response.statusCode}',
              name: 'YouTubeService');
          developer.log('❌ Hata detayı: ${response.body}',
              name: 'YouTubeService');
          throw Exception(
              'Backend API hatası: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        // Fallback to youtube_explode_dart if backend fails
        developer.log('❌ Backend API başarısız: $e', name: 'YouTubeService');
        developer.log('🔄 youtube_explode_dart fallback başlatılıyor...',
            name: 'YouTubeService');
      }

      // Fallback: Use youtube_explode_dart with retry mechanism
      final video = await _yt.videos.get(url);

      StreamManifest? manifest;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          manifest = await _yt.videos.streamsClient.getManifest(video.id);
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception(
                'Cipher hatası: Video akışları alınamadı. Backend API ve youtube_explode_dart başarısız oldu.');
          }
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      if (manifest == null) {
        throw Exception('Video manifest alınamadı');
      }

      final qualities =
          manifest.muxed.map((s) => s.qualityLabel).toSet().toList();
      qualities.sort((a, b) => _parseQuality(b).compareTo(_parseQuality(a)));

      return {
        'title': video.title,
        'duration': video.duration?.inSeconds.toString() ?? '0',
        'thumbnail': video.thumbnails.highResUrl,
        'author': video.author,
        'viewCount': video.engagement.viewCount.toString(),
        'qualities': qualities,
      };
    } catch (e) {
      throw Exception('Video bilgisi alınamadı: $e');
    }
  }

  // Helper function to sanitize file names
  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 100 ? 100 : fileName.length);
  }

  // Helper function to parse quality for sorting
  static int _parseQuality(String quality) {
    final match = RegExp(r'(\d+)').firstMatch(quality);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  // Check server status
  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$downloadBaseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
