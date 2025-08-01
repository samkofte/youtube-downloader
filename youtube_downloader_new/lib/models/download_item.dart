class DownloadItem {
  final String id;
  final String title;
  final String filePath;
  final String type; // 'mp3' or 'mp4'
  final DateTime downloadDate;
  final String thumbnailUrl;
  final String duration;

  DownloadItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.type,
    required this.downloadDate,
    required this.thumbnailUrl,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'type': type,
        'downloadDate': downloadDate.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        id: json['id'],
        title: json['title'],
        filePath: json['filePath'],
        type: json['type'],
        downloadDate: DateTime.parse(json['downloadDate']),
        thumbnailUrl: json['thumbnailUrl'],
        duration: json['duration'],
      );
}