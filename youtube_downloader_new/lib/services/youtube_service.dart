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
    return 'https://youtube-api-js-4htn.onrender.com';
  }

  static final YoutubeExplode _yt = YoutubeExplode();

  // Search videos
  static Future<List<VideoModel>> searchVideos(String query,
      {int maxResults = 10}) async {
    developer.log('🔍 Video arama başlatıldı: $query', name: 'YouTubeService');
    try {
      developer.log('📡 Backend API arama isteği gönderiliyor...',
          name: 'YouTubeService');
      final response = await http.get(
        Uri.parse('$baseUrl/ara/v2/${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> videos = json.decode(response.body);
        developer.log(
            '✅ Backend API arama başarılı: ${videos.length} video bulundu',
            name: 'YouTubeService');
        return videos
            .map((video) => VideoModel(
                  id: video['videoId'] ?? '',
                  title: video['title'] ?? '',
                  thumbnail: video['thumbnail'] ?? '',
                  duration: video['duration'] ?? '',
                  description: '',
                  channelTitle: '',
                  viewCount: '0',
                  publishedAt: '',
                  url:
                      'https://www.youtube.com/watch?v=${video['videoId'] ?? ''}',
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
        Uri.parse('$baseUrl/complete/${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> suggestions = data.values.first ?? [];
        return suggestions.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Download MP3 using Backend API
  static Future<String> downloadMp3(
      String url, String title, Function(double) onProgress) async {
    developer.log('🚀 MP3 İndirme Başlatıldı (Backend API)', name: 'YouTubeService');
    developer.log('🔗 Video URL: $url', name: 'YouTubeService');
    developer.log('📁 Dosya adı: $title', name: 'YouTubeService');

    try {
      // Extract video ID from URL
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        throw Exception('Video ID çıkarılamadı');
      }

      developer.log('🎵 Backend API ile MP3 indirme başlatılıyor...',
          name: 'YouTubeService');

      // Update progress to show we're starting
      onProgress(0.1);
      
      // Get MP3 stream URL from backend
      final response = await http.get(
        Uri.parse('$baseUrl/dinle/$videoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 302) {
        throw Exception(
            'Backend API MP3 stream alınamadı: ${response.statusCode}');
      }

      onProgress(0.3); // Backend responded

      // Backend redirects to the actual stream URL
      final streamUrl = response.request?.url.toString() ?? '';
      if (streamUrl.isEmpty) {
        throw Exception('Stream URL alınamadı');
      }

      developer.log('✅ MP3 stream URL alındı', name: 'YouTubeService');
      onProgress(0.5); // Stream URL obtained

      // Download the stream - MP3 files go to Downloads/YouTube_Music folder
      final baseDirectory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      
      // Create custom folder for YouTube music downloads
      final directory = Directory('${baseDirectory.path}/YouTube_Music');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        developer.log('📁 YouTube_Music klasörü oluşturuldu: ${directory.path}', name: 'YouTubeService');
      }
      
      final fileName = '${_sanitizeFileName(title)}.mp3';
      final file = File('${directory.path}/$fileName');

      developer.log('💾 Dosya kaydediliyor: ${file.path}', name: 'YouTubeService');
      onProgress(0.7); // Starting file download

      final streamResponse = await http.get(Uri.parse(streamUrl));
      if (streamResponse.statusCode == 200) {
        onProgress(0.9); // File downloaded, writing to disk
        await file.writeAsBytes(streamResponse.bodyBytes);
        
        onProgress(1.0); // Mark as complete

        developer.log('✅ MP3 başarıyla indirildi: ${file.path}',
            name: 'YouTubeService');
        
        // Create download item for tracking
        final downloadItem = DownloadItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          filePath: file.path,
          type: 'mp3',
          downloadDate: DateTime.now(),
          thumbnailUrl: '', // Will be set from video data
          duration: '', // Will be set from video data
        );
        
        return 'MP3 başarıyla indirildi: ${file.path}|${downloadItem.id}';
      } else {
        throw Exception('Stream indirilemedi: ${streamResponse.statusCode}');
      }
    } catch (e) {
      developer.log('❌ MP3 indirme hatası: $e', name: 'YouTubeService');
      throw Exception('MP3 indirme hatası: $e');
    }
  }

  // Download MP4 using Backend API
  static Future<String> downloadMp4(String url, String quality, String title,
      Function(double) onProgress) async {
    developer.log('🚀 MP4 İndirme Başlatıldı (Backend API)', name: 'YouTubeService');
    developer.log('🔗 Video URL: $url', name: 'YouTubeService');
    developer.log('📁 Dosya adı: $title', name: 'YouTubeService');
    developer.log('🎯 Kalite: $quality', name: 'YouTubeService');

    try {
      // Extract video ID from URL
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        throw Exception('Video ID çıkarılamadı');
      }

      developer.log('🎬 Backend API ile MP4 indirme başlatılıyor...',
          name: 'YouTubeService');

      // Update progress to show we're starting
      onProgress(0.1);

      // Get MP4 stream URL from backend
      final response = await http.get(
        Uri.parse('$baseUrl/yt/$videoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 302) {
        throw Exception(
            'Backend API MP4 stream alınamadı: ${response.statusCode}');
      }

      onProgress(0.3); // Backend responded

      // Backend redirects to the actual stream URL
      final streamUrl = response.request?.url.toString() ?? '';
      if (streamUrl.isEmpty) {
        throw Exception('Stream URL alınamadı');
      }

      developer.log('✅ MP4 stream URL alındı', name: 'YouTubeService');
      onProgress(0.5); // Stream URL obtained

      // Download the stream - MP4 files go to Downloads/YouTube_Videos
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      
      // Create custom folder for YouTube video downloads
      final customFolder = Directory('${directory.path}/YouTube_Videos');
      if (!await customFolder.exists()) {
        await customFolder.create(recursive: true);
        developer.log('📁 YouTube_Videos klasörü oluşturuldu: ${customFolder.path}', name: 'YouTubeService');
      }
      
      final fileName = '${_sanitizeFileName(title)}.mp4';
      final file = File('${customFolder.path}/$fileName');

      developer.log('💾 Dosya kaydediliyor: ${file.path}', name: 'YouTubeService');
      onProgress(0.7); // Starting file download

      final streamResponse = await http.get(Uri.parse(streamUrl));
      if (streamResponse.statusCode == 200) {
        onProgress(0.9); // File downloaded, writing to disk
        await file.writeAsBytes(streamResponse.bodyBytes);
        
        onProgress(1.0); // Mark as complete

        developer.log('✅ MP4 başarıyla indirildi!', name: 'YouTubeService');
        developer.log('✅ MP4 başarıyla indirildi: ${file.path}',
            name: 'YouTubeService');
        
        // Create download item for tracking
        final downloadItem = DownloadItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          filePath: file.path,
          type: 'mp4',
          downloadDate: DateTime.now(),
          thumbnailUrl: '', // Will be set from video data
          duration: '', // Will be set from video data
        );
        
        return 'MP4 başarıyla indirildi: ${file.path}|${downloadItem.id}';
      } else {
        throw Exception('Stream indirilemedi: ${streamResponse.statusCode}');
      }
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
        Uri.parse('$baseUrl/liste/tr'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> playLists = data['playLists'] ?? [];
        List<VideoModel> videos = [];

        for (var playlist in playLists) {
          for (var playlistName in playlist.keys) {
            final Map<String, dynamic> playlistVideos = playlist[playlistName];
            for (var videoId in playlistVideos.keys) {
              final videoData = playlistVideos[videoId];
              videos.add(VideoModel(
                id: videoId,
                title: videoData['title'] ?? '',
                thumbnail: videoData['thumbnail'] ?? '',
                duration: videoData['duration'] ?? '',
                description: '',
                channelTitle: '',
                viewCount: '0',
                publishedAt: '',
                url: 'https://www.youtube.com/watch?v=$videoId',
              ));
            }
          }
        }

        developer.log(
            '✅ Trending videolar başarıyla alındı: ${videos.length} video',
            name: 'YouTubeService');
        return videos;
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
        developer.log('📤 İstek URL: $baseUrl/video-info',
            name: 'YouTubeService');
        developer.log('📤 İstek body: {"url": "$url"}', name: 'YouTubeService');

        final response = await http
            .post(
              Uri.parse('$baseUrl/video-info'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'url': url}),
            )
            .timeout(const Duration(seconds: 30));

        developer.log('📡 Backend API yanıtı: ${response.statusCode}',
            name: 'YouTubeService');
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          developer.log(
              '✅ Backend API ile video bilgisi alındı: ${data['title']}',
              name: 'YouTubeService');
          return {
            'title': data['title'] ?? '',
            'duration': data['duration']?.toString() ?? '0',
            'thumbnail': data['thumbnail'] ?? '',
            'author': data['author'] ?? '',
            'viewCount': data['viewCount']?.toString() ?? '0',
            'qualities': data['qualities'] ?? ['720p', '480p', '360p'],
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

  // Helper function to extract video ID from YouTube URL
  static String? _extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Check server status
  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
