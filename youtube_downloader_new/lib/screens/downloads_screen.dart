import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../providers/download_provider.dart';
import '../models/download_item.dart';
import 'dart:io';
import 'package:flutter/services.dart';

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
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              if (provider.downloads.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearDialog(context),
                tooltip: 'Tümünü Temizle',
              );
            },
          ),
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
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  download.duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(download.downloadDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  fileExists ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: fileExists ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fileExists ? 'Dosya mevcut' : 'Dosya bulunamadı',
                    style: TextStyle(
                      fontSize: 12,
                      color: fileExists ? Colors.green : Colors.red,
                    ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleMenuAction(String action, DownloadItem download) {
    switch (action) {
      case 'open':
        _openFile(download);
        break;
      case 'delete':
        _deleteDownload(download);
        break;
    }
  }

  void _openFile(DownloadItem download) async {
    try {
      final file = File(download.filePath);
      
      if (await file.exists()) {
        developer.log('Dosya açılıyor: ${download.filePath}', name: 'DownloadsScreen');
        
        bool success = false;
        
        // Try different methods based on platform
        if (Platform.isWindows) {
          try {
            // Method 1: Use Windows explorer to open file
            final result = await Process.run(
              'explorer',
              ['/select,', download.filePath],
              runInShell: true,
            );
            success = result.exitCode == 0;
            
            if (!success) {
              // Method 2: Try to open with default application
              final result2 = await Process.run(
                'cmd',
                ['/c', 'start', '', '"${download.filePath}"'],
                runInShell: true,
              );
              success = result2.exitCode == 0;
            }
          } catch (e) {
            developer.log('Windows dosya açma hatası: $e', name: 'DownloadsScreen');
          }
        } else {
          // For other platforms, try url_launcher
          try {
            final uri = Uri.file(download.filePath);
            success = await launchUrl(uri);
          } catch (e) {
            developer.log('URL launcher hatası: $e', name: 'DownloadsScreen');
          }
        }
        
        if (mounted) {
          if (success) {
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
            // Fallback: Show file path and copy to clipboard
            await Clipboard.setData(ClipboardData(text: download.filePath));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.content_copy, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Dosya yolu panoya kopyalandı: ${download.title}'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.blue,
                action: SnackBarAction(
                  label: 'Klasörü Aç',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      final directory = file.parent;
                      if (Platform.isWindows) {
                        await Process.run(
                          'explorer',
                          [directory.path],
                          runInShell: true,
                        );
                      } else {
                        final dirUri = Uri.file(directory.path);
                        await launchUrl(dirUri);
                      }
                    } catch (e) {
                      developer.log('Klasör açma hatası: $e', name: 'DownloadsScreen');
                    }
                  },
                ),
              ),
            );
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