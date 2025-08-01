class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String channelTitle;
  final String duration;
  final String viewCount;
  final String publishedAt;
  final String url;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.channelTitle,
    required this.duration,
    required this.viewCount,
    required this.publishedAt,
    required this.url,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      channelTitle: json['channel']?.toString() ?? json['channelTitle']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      viewCount: json['viewCount']?.toString() ?? '0',
      publishedAt: json['publishedAt']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'channelTitle': channelTitle,
      'duration': duration,
      'viewCount': viewCount,
      'publishedAt': publishedAt,
      'url': url,
    };
  }
}

class VideoInfo {
  final String title;
  final String description;
  final String thumbnail;
  final String channelTitle;
  final String duration;
  final String viewCount;
  final String publishedAt;
  final List<VideoFormat> formats;

  VideoInfo({
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.channelTitle,
    required this.duration,
    required this.viewCount,
    required this.publishedAt,
    required this.formats,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      duration: json['duration'] ?? '',
      viewCount: json['viewCount'] ?? '0',
      publishedAt: json['publishedAt'] ?? '',
      formats: (json['formats'] as List<dynamic>? ?? [])
          .map((format) => VideoFormat.fromJson(format))
          .toList(),
    );
  }
}

class VideoFormat {
  final String quality;
  final String format;
  final String url;
  final String filesize;

  VideoFormat({
    required this.quality,
    required this.format,
    required this.url,
    required this.filesize,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      quality: json['quality'] ?? '',
      format: json['format'] ?? '',
      url: json['url'] ?? '',
      filesize: json['filesize'] ?? '',
    );
  }
}

class DownloadProgress {
  final double progress;
  final String status;
  final String? error;

  DownloadProgress({
    required this.progress,
    required this.status,
    this.error,
  });
}