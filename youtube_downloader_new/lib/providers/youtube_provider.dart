import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/video_model.dart';
import '../models/download_item.dart';
import '../services/youtube_service.dart';
import 'download_provider.dart';

class YouTubeProvider extends ChangeNotifier {
  List<VideoModel> _searchResults = [];
  List<VideoModel> _trendingVideos = [];
  List<String> _searchSuggestions = [];
  VideoInfo? _currentVideoInfo;
  DownloadProgress? _downloadProgress;
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isDownloading = false;
  bool _serverConnected = false;
  String? _error;

  // Getters
  List<VideoModel> get searchResults => _searchResults;
  List<VideoModel> get trendingVideos => _trendingVideos;
  List<String> get searchSuggestions => _searchSuggestions;
  VideoInfo? get currentVideoInfo => _currentVideoInfo;
  DownloadProgress? get downloadProgress => _downloadProgress;
  
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isDownloading => _isDownloading;
  bool get serverConnected => _serverConnected;
  String? get error => _error;

  // Initialize provider
  YouTubeProvider() {
    checkServerConnection();
    loadTrendingVideos();
  }

  // Check server connection
  Future<void> checkServerConnection() async {
    try {
      _serverConnected = await YouTubeService.checkServerStatus();
      _error = _serverConnected ? null : 'Server is not available';
    } catch (e) {
      _serverConnected = false;
      _error = 'Failed to connect to server';
    }
    notifyListeners();
  }

  // Search videos
  Future<void> searchVideos(String query, {int maxResults = 10}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await YouTubeService.searchVideos(query, maxResults: maxResults);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Get search suggestions
  Future<void> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      _searchSuggestions = await YouTubeService.getSearchSuggestions(query);
    } catch (e) {
      _searchSuggestions = [];
    }
    notifyListeners();
  }

  // Load trending videos
  Future<void> loadTrendingVideos({int maxResults = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trendingVideos = await YouTubeService.getTrendingVideos(maxResults: maxResults);
    } catch (e) {
      _error = e.toString();
      _trendingVideos = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get video info
  Future<void> getVideoInfo(String url) async {
    _isLoading = true;
    _error = null;
    _currentVideoInfo = null;
    notifyListeners();

    try {
      _currentVideoInfo = await YouTubeService.getVideoInfo(url);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Download MP3
  Future<void> downloadMp3(String url, String title, DownloadProvider downloadProvider, {String? thumbnailUrl, String? duration, String? existingItemId}) async {
    developer.log('🎵 MP3 indirme başlatılıyor: $url', name: 'YouTubeProvider');
    _isDownloading = true;
    _error = null;
    _downloadProgress = DownloadProgress(progress: 0.0, status: 'Starting download...');
    notifyListeners();

    try {
      developer.log('🔄 YouTubeService.downloadMp3 çağrılıyor...', name: 'YouTubeProvider');
      final result = await YouTubeService.downloadMp3(url, title, (progress) {
        developer.log('📊 İndirme ilerlemesi: ${(progress * 100).toInt()}%', name: 'YouTubeProvider');
        _downloadProgress = DownloadProgress(
          progress: progress,
          status: 'Downloading MP3... ${(progress * 100).toInt()}%',
        );
        notifyListeners();
      });
      
      // Parse result to get file path and download item id
      final parts = result.split('|');
      if (parts.length > 1) {
        final downloadItem = DownloadItem(
          id: existingItemId ?? parts[1],
          title: title,
          filePath: parts[0].replaceAll('MP3 başarıyla indirildi: ', ''),
          type: 'mp3',
          downloadDate: DateTime.now(),
          thumbnailUrl: thumbnailUrl ?? '',
          duration: duration ?? '',
          originalUrl: url,
        );
        if (existingItemId != null) {
          await downloadProvider.updateDownload(downloadItem);
        } else {
          await downloadProvider.addDownload(downloadItem);
        }
      }
      
      developer.log('✅ MP3 indirme tamamlandı!', name: 'YouTubeProvider');
      _downloadProgress = DownloadProgress(
        progress: 1.0,
        status: 'Download completed!',
      );
    } catch (e) {
      developer.log('❌ MP3 indirme hatası: $e', name: 'YouTubeProvider');
      _error = e.toString();
      _downloadProgress = DownloadProgress(
        progress: 0.0,
        status: 'Download failed',
        error: e.toString(),
      );
    }

    _isDownloading = false;
    notifyListeners();
  }

  // Download MP4
  Future<void> downloadMp4(String url, String quality, String title, DownloadProvider downloadProvider, {String? thumbnailUrl, String? duration, String? existingItemId}) async {
    _isDownloading = true;
    _error = null;
    _downloadProgress = DownloadProgress(progress: 0.0, status: 'Starting download...');
    notifyListeners();

    try {
      final result = await YouTubeService.downloadMp4(url, quality, title, (progress) {
        _downloadProgress = DownloadProgress(
          progress: progress,
          status: 'Downloading MP4 ($quality)... ${(progress * 100).toInt()}%',
        );
        notifyListeners();
      });
      
      // Parse result to get file path and download item id
      final parts = result.split('|');
      if (parts.length > 1) {
        final downloadItem = DownloadItem(
          id: existingItemId ?? parts[1],
          title: title,
          filePath: parts[0].replaceAll('MP4 başarıyla indirildi: ', ''),
          type: 'mp4',
          downloadDate: DateTime.now(),
          thumbnailUrl: thumbnailUrl ?? '',
          duration: duration ?? '',
          originalUrl: url,
        );
        if (existingItemId != null) {
          await downloadProvider.updateDownload(downloadItem);
        } else {
          await downloadProvider.addDownload(downloadItem);
        }
      }
      
      _downloadProgress = DownloadProgress(
        progress: 1.0,
        status: 'Download completed!',
      );
    } catch (e) {
      _error = e.toString();
      _downloadProgress = DownloadProgress(
        progress: 0.0,
        status: 'Download failed',
        error: e.toString(),
      );
    }

    _isDownloading = false;
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _searchSuggestions = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear download progress
  void clearDownloadProgress() {
    _downloadProgress = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await checkServerConnection();
    if (_serverConnected) {
      await loadTrendingVideos();
    }
  }
}