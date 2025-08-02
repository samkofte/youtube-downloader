import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/youtube_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../screens/downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    // Load popular music when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<YouTubeProvider>()
          .searchVideos('popüler müzik 2024', maxResults: 20);
      context.read<DownloadProvider>().loadDownloads();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
      });
      // Load popular music again when search is cleared
      context
          .read<YouTubeProvider>()
          .searchVideos('popüler müzik 2024', maxResults: 20);
    } else {
      setState(() {
        _showSearchResults = true;
      });
      context.read<YouTubeProvider>().searchVideos(query);
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _showSearchResults = true;
      });
      context.read<YouTubeProvider>().searchVideos(query, maxResults: 20);
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Müzik İndirici'),
        elevation: 0,
        actions: [
          // Downloads button with badge
          Consumer<DownloadProvider>(
            builder: (context, downloadProvider, child) {
              final downloadCount = downloadProvider.totalDownloads;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_done),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DownloadsScreen(),
                        ),
                      );
                    },
                    tooltip: 'İndirilenler',
                  ),
                  if (downloadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          downloadCount > 99 ? '99+' : downloadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Folder button
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              _showFolderInfo(context);
            },
            tooltip: 'Dosya Konumu',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<YouTubeProvider>().refresh();
              if (!_showSearchResults) {
                context
                    .read<YouTubeProvider>()
                    .searchVideos('popüler müzik 2024', maxResults: 20);
              }
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                  hintText: 'Müzik ara...',
                ),
                const SizedBox(height: 8),
                Consumer<YouTubeProvider>(
                  builder: (context, provider, child) {
                    if (!provider.serverConnected) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sunucuya bağlanılamıyor. Lütfen sunucunun çalıştığından emin olun.',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Content Section
          Expanded(
            child: Consumer<YouTubeProvider>(
              builder: (context, provider, child) {
                // Show error if exists
                if (provider.error != null && provider.searchResults.isEmpty) {
                  return CustomErrorWidget(
                    message: provider.error!,
                    onRetry: () {
                      provider.clearError();
                      if (_showSearchResults &&
                          _searchController.text.isNotEmpty) {
                        provider.searchVideos(_searchController.text);
                      } else {
                        provider.searchVideos('popüler müzik 2024',
                            maxResults: 20);
                      }
                    },
                  );
                }

                // Show loading
                if (provider.isSearching && provider.searchResults.isEmpty) {
                  return const LoadingWidget(message: 'Müzikler aranıyor...');
                }

                // Show search results or popular music
                final videos = provider.searchResults;
                if (videos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showSearchResults
                              ? 'Arama sonucu bulunamadı'
                              : 'Popüler müzikler yükleniyor...',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        if (_showSearchResults) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Farklı anahtar kelimeler deneyin',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _showSearchResults
                                ? Icons.search
                                : Icons.trending_up,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showSearchResults
                                ? 'Arama Sonuçları (${videos.length})'
                                : 'Popüler Müzikler (${videos.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Video List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (_showSearchResults &&
                              _searchController.text.isNotEmpty) {
                            await provider.searchVideos(_searchController.text);
                          } else {
                            await provider.searchVideos('popüler müzik 2024',
                                maxResults: 20);
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: VideoCard(
                                video: video,
                                onTap: () {
                                  _showDownloadDialog(context, video);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Video info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    video.thumbnail,
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.channelTitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Download options
            Text(
              'İndirme Seçenekleri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // MP3 Download
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<YouTubeProvider>().downloadMp3(
                        video.url,
                        video.title,
                        context.read<DownloadProvider>(),
                        thumbnailUrl: video.thumbnail,
                        duration: video.duration,
                      );
                  _showDownloadProgress(context);
                },
                icon: const Icon(Icons.audiotrack),
                label: const Text('MP3 İndir (Sadece Ses)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // MP4 Download
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<YouTubeProvider>().downloadMp4(
                        video.url,
                        '720p',
                        video.title,
                        context.read<DownloadProvider>(),
                        thumbnailUrl: video.thumbnail,
                        duration: video.duration,
                      );
                  _showDownloadProgress(context);
                },
                icon: const Icon(Icons.videocam),
                label: const Text('MP4 İndir (Video)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showDownloadProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('İndiriliyor...'),
          ],
        ),
        content: Consumer<YouTubeProvider>(
          builder: (context, provider, child) {
            final progress = provider.downloadProgress;
            if (progress == null) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('İndirme başlatılıyor...'),
                ],
              );
            }

            // Check if download is completed
            if (progress.progress >= 1.0 && progress.error == null) {
              // Close dialog after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('İndirme tamamlandı!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              });
            }

            // Check if download failed
            if (progress.error != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('İndirme hatası: ${progress.error}'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  progress.status,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress.progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<YouTubeProvider>(
            builder: (context, provider, child) {
              final progress = provider.downloadProgress;
              if (progress != null &&
                  progress.progress < 1.0 &&
                  progress.error == null) {
                return TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.clearDownloadProgress();
                  },
                  child: const Text('İptal'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _showFolderInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder, color: Colors.blue),
            SizedBox(width: 8),
            Text('Dosya Konumları'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İndirilen dosyalar aşağıdaki konumlarda saklanır:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildFolderItem(
              icon: Icons.music_note,
              title: 'MP3 Dosyaları',
              path: 'Downloads/YouTube_Music/',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildFolderItem(
              icon: Icons.video_library,
              title: 'MP4 Dosyaları',
              path: 'Downloads/YouTube_Videos/',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dosya yöneticisinde bu klasörleri bulabilirsiniz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem({
    required IconData icon,
    required String title,
    required String path,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  path,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
