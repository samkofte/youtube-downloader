import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/download_item.dart';

class DownloadProvider with ChangeNotifier {
  List<DownloadItem> _downloads = [];
  bool _isLoading = false;

  List<DownloadItem> get downloads => _downloads;
  bool get isLoading => _isLoading;

  // Load downloads from SharedPreferences
  Future<void> loadDownloads() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getStringList('downloads') ?? [];
      
      _downloads = downloadsJson
          .map((json) => DownloadItem.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort by download date (newest first)
      _downloads.sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
    } catch (e) {
      developer.log('Error loading downloads: $e', name: 'DownloadProvider');
      _downloads = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save downloads to SharedPreferences
  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = _downloads
          .map((download) => jsonEncode(download.toJson()))
          .toList();
      
      await prefs.setStringList('downloads', downloadsJson);
    } catch (e) {
      developer.log('Error saving downloads: $e', name: 'DownloadProvider');
    }
  }

  // Add a new download
  Future<void> addDownload(DownloadItem download) async {
    _downloads.insert(0, download); // Add to beginning
    notifyListeners();
    await _saveDownloads();
  }

  // Update an existing download by id (or add if not exists)
  Future<void> updateDownload(DownloadItem download) async {
    final index = _downloads.indexWhere((d) => d.id == download.id);
    if (index >= 0) {
      _downloads[index] = download;
    } else {
      _downloads.insert(0, download);
    }
    notifyListeners();
    await _saveDownloads();
  }

  // Remove a download
  Future<void> removeDownload(String id) async {
    _downloads.removeWhere((download) => download.id == id);
    notifyListeners();
    await _saveDownloads();
  }

  // Clear all downloads
  Future<void> clearDownloads() async {
    _downloads.clear();
    notifyListeners();
    await _saveDownloads();
  }

  // Get downloads by type
  List<DownloadItem> getDownloadsByType(String type) {
    return _downloads.where((download) => download.type == type).toList();
  }

  // Get total downloads count
  int get totalDownloads => _downloads.length;

  // Get MP3 downloads count
  int get mp3Downloads => _downloads.where((d) => d.type == 'mp3').length;

  // Get MP4 downloads count
  int get mp4Downloads => _downloads.where((d) => d.type == 'mp4').length;
}