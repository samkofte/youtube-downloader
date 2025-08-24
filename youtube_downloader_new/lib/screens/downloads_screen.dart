import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:developer' as developer;
import '../providers/download_provider.dart';
import '../models/download_item.dart';
import 'dart:io';
import '../providers/youtube_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load downloads when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadProvider>().loadDownloads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İndirilenler'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.all_inclusive), text: 'Tümü'),
            Tab(icon: Icon(Icons.music_note), text: 'MP3'),
            Tab(icon: Icon(Icons.video_library), text: 'MP4'),
          ],
        ),
        actions: [
          // Eksik dosyaları yeniden indir
          Consumer<DownloadProvider>(builder: (context, provider, child) {
            final missingCount = provider.downloads
                .where((d) =>
                    !File(d.filePath).existsSync() &&
                    (d.originalUrl.isNotEmpty))
                .length;
            return IconButton(
              icon: const Icon(Icons.download_for_offline),
              onPressed: missingCount > 0
                  ? () => _checkAndRedownloadMissing(context)
                  : null,
              tooltip: missingCount > 0
                  ? 'Eksik Dosyaları İndir ($missingCount)'
                  : 'Eksik dosya yok',
            );
          }),
          Consumer<DownloadProvider>(builder: (context, provider, child) {
            if (provider.downloads.isEmpty) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(context),
              tooltip: 'Tümünü Temizle',
            );
          }),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDownloadsList(provider.downloads),
              _buildDownloadsList(provider.getDownloadsByType('mp3')),
              _buildDownloadsList(provider.getDownloadsByType('mp4')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadsList(List<DownloadItem> downloads) {
    if (downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz indirilen dosya yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İndirdiğiniz müzik ve videolar burada görünecek',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        return _buildDownloadCard(download);
      },
    );
  }

  Widget _buildDownloadCard(DownloadItem download) {
    final isMP3 = download.type == 'mp3';
    final file = File(download.filePath);
    final fileExists = file.existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isMP3 ? Colors.orange[100] : Colors.blue[100],
          ),
          child: Icon(
            isMP3 ? Icons.music_note : Icons.video_library,
            color: isMP3 ? Colors.orange[700] : Colors.blue[700],
            size: 28,
          ),
        ),
        title: Text(
          download.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // İlk satır: Süre ve tarih
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    download.duration,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    _formatDate(download.downloadDate),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // İkinci satır: Dosya durumu
            Row(
              children: [
                Icon(
                  fileExists ? Icons.check_circle : Icons.error,
                  size: 12,
                  color: fileExists ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    fileExists ? 'Dosya mevcut' : 'Dosya bulunamadı',
                    style: TextStyle(
                      fontSize: 10,
                      color: fileExists ? Colors.green : Colors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                // Dosya boyutu ekle
                if (fileExists)
                  Flexible(
                    child: Text(
                      _formatFileSize(File(download.filePath).lengthSync()),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, download),
          itemBuilder: (context) => [
            if (fileExists)
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new),
                    SizedBox(width: 8),
                    Text('Dosyayı Aç'),
                  ],
                ),
              ),
            if (!fileExists && download.originalUrl.isNotEmpty)
              const PopupMenuItem(
                value: 'redownload',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Yeniden İndir'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Listeden Kaldır', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, DownloadItem download) {
    switch (action) {
      case 'open':
        _openFile(download);
        break;
      case 'redownload':
        _redownloadSingle(download);
        break;
      case 'delete':
        _deleteDownload(download);
        break;
    }
  }

  Future<void> _redownloadSingle(DownloadItem download) async {
    if (download.originalUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orijinal bağlantı bulunamadı, yeniden indirilemiyor.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ytProvider = context.read<YouTubeProvider>();
    final dlProvider = context.read<DownloadProvider>();

    _showDownloadProgressDialog(title: download.title);

    try {
      if (download.type == 'mp3') {
        await ytProvider.downloadMp3(
          download.originalUrl,
          download.title,
          dlProvider,
          thumbnailUrl: download.thumbnailUrl,
          duration: download.duration,
          existingItemId: download.id,
        );
      } else {
        // Varsayılan kalite: 720p
        await ytProvider.downloadMp4(
          download.originalUrl,
          '720p',
          download.title,
          dlProvider,
          thumbnailUrl: download.thumbnailUrl,
          duration: download.duration,
          existingItemId: download.id,
        );
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yeniden indirildi: ${download.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yeniden indirme hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkAndRedownloadMissing(BuildContext context) async {
    final dlProvider = context.read<DownloadProvider>();
    final ytProvider = context.read<YouTubeProvider>();

    final downloads = List<DownloadItem>.from(dlProvider.downloads);
    final missing = downloads
        .where(
            (d) => !File(d.filePath).existsSync() && d.originalUrl.isNotEmpty)
        .toList();

    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eksik dosya bulunamadı.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksik Dosyaları İndir'),
        content: Text(
            '${missing.length} dosya eksik görünüyor. Hepsini yeniden indirmek ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (int i = 0; i < missing.length; i++) {
      final item = missing[i];
      _showDownloadProgressDialog(
          title: '${i + 1}/${missing.length} - ${item.title}');
      try {
        if (item.type == 'mp3') {
          await ytProvider.downloadMp3(
            item.originalUrl,
            item.title,
            dlProvider,
            thumbnailUrl: item.thumbnailUrl,
            duration: item.duration,
            existingItemId: item.id,
          );
        } else {
          await ytProvider.downloadMp4(
            item.originalUrl,
            '720p',
            item.title,
            dlProvider,
            thumbnailUrl: item.thumbnailUrl,
            duration: item.duration,
            existingItemId: item.id,
          );
        }
      } catch (e) {
        developer.log('Toplu yeniden indirme hatası: $e',
            name: 'DownloadsScreen');
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    // Güncel listeyi yükle
    await dlProvider.loadDownloads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Eksik dosyalar indirildi: ${missing.length}/${missing.length}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDownloadProgressDialog({required String title}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Consumer<YouTubeProvider>(
          builder: (context, provider, child) {
            final progress = provider.downloadProgress;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress?.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 12),
                Text(progress?.status ?? 'Hazırlanıyor...'),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _openFile(DownloadItem download) async {
    try {
      final file = File(download.filePath);

      if (await file.exists()) {
        developer.log('Dosya açılıyor: ${download.filePath}',
            name: 'DownloadsScreen');

        // open_file paketi ile dosyayı aç
        final result = await OpenFile.open(download.filePath);

        if (mounted) {
          if (result.type == ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Dosya açıldı: ${download.title}'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Dosya açılamadı, klasörü açmayı dene
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.folder_open, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Dosya açılamadı, klasör açılıyor...'),
                    ),
                  ],
                ),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );

            // Klasörü aç
            await OpenFile.open(download.filePath, type: "folder");
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Dosya bulunamadı: ${download.title}'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Dosya açma hatası: $e', name: 'DownloadsScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Dosya açılırken hata oluştu: ${e.toString()}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteDownload(DownloadItem download) {
    context.read<DownloadProvider>().removeDownload(download.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${download.title} listeden kaldırıldı'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () {
            context.read<DownloadProvider>().addDownload(download);
          },
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Temizle'),
        content: const Text(
          'Tüm indirme geçmişini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadProvider>().clearDownloads();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm indirme geçmişi temizlendi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}
