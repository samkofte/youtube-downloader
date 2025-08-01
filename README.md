# 🎵 YouTube Downloader

A modern, feature-rich YouTube downloader application built with Flutter and Node.js. Download your favorite YouTube videos as MP3 audio files or MP4 video files with ease.

## ✨ Features

### 🎵 Audio Downloads
- **High-Quality MP3**: Download YouTube videos as high-quality MP3 audio files
- **Fast Processing**: Optimized download speeds with progress tracking
- **Metadata Preservation**: Maintains video title and thumbnail information

### 🎬 Video Downloads
- **Multiple Quality Options**: Choose from various video quality settings (360p, 480p, 720p, 1080p)
- **MP4 Format**: Universal compatibility with all devices and players
- **Smart Quality Selection**: Automatic best quality detection

### 📱 Mobile App Features
- **Cross-Platform**: Built with Flutter for Android and iOS
- **Modern UI**: Clean, intuitive interface with Material Design
- **Real-Time Progress**: Live download progress with percentage indicators
- **Download Management**: View, organize, and manage your downloaded files
- **Search Integration**: Built-in YouTube search functionality
- **Trending Videos**: Discover popular content

### 🌐 Web Interface
- **Responsive Design**: Works perfectly on desktop and mobile browsers
- **Direct URL Support**: Paste any YouTube URL for instant download
- **Search & Download**: Search for videos and download directly
- **No Installation Required**: Use directly in your web browser

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (v3.10 or higher)
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/samkofte/youtube-downloader.git
   cd youtube-downloader
   ```

2. **Install server dependencies**
   ```bash
   npm install
   ```

3. **Start the server**
   ```bash
   npm start
   ```

4. **Set up Flutter app** (optional)
   ```bash
   cd youtube_downloader_new
   flutter pub get
   flutter run
   ```

## 📖 Usage

### Web Interface
1. Open your browser and navigate to `http://localhost:3000`
2. Enter a YouTube URL or search for videos
3. Choose your preferred format (MP3/MP4) and quality
4. Click download and wait for completion

### Mobile App
1. Launch the Flutter app on your device
2. Use the search feature or paste a YouTube URL
3. Select download format and quality
4. Monitor progress in real-time
5. Access downloaded files in the Downloads section

## 🛠️ API Endpoints

### Video Information
```http
POST /api/video-info
Content-Type: application/json

{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID"
}
```

### Download MP3
```http
POST /api/download-mp3
Content-Type: application/json

{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "title": "Video Title"
}
```

### Download MP4
```http
POST /api/download-mp4
Content-Type: application/json

{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "quality": "720p",
  "title": "Video Title"
}
```

### Search Videos
```http
GET /api/search?q=search_query&maxResults=10
```

### Trending Videos
```http
GET /api/trending?maxResults=20
```

## 🏗️ Architecture

### Backend (Node.js)
- **Express.js**: Web server framework
- **youtube-dl-exec**: YouTube video processing
- **CORS**: Cross-origin resource sharing
- **File System**: Download management

### Frontend (Flutter)
- **Provider**: State management
- **HTTP**: API communication
- **Path Provider**: File system access
- **URL Launcher**: External link handling

### Web Interface
- **Vanilla JavaScript**: No framework dependencies
- **Responsive CSS**: Mobile-first design
- **Progressive Enhancement**: Works without JavaScript

## 📁 Project Structure

```
youtube-downloader/
├── 📁 public/                 # Web interface files
│   ├── index.html            # Main web page
│   ├── script.js             # JavaScript functionality
│   └── style.css             # Styling
├── 📁 youtube_downloader_new/ # Flutter mobile app
│   ├── 📁 lib/
│   │   ├── 📁 models/         # Data models
│   │   ├── 📁 providers/      # State management
│   │   ├── 📁 screens/        # UI screens
│   │   ├── 📁 services/       # API services
│   │   └── 📁 widgets/        # Reusable components
│   └── pubspec.yaml          # Flutter dependencies
├── server.js                 # Main server file
├── package.json              # Node.js dependencies
└── README.md                 # This file
```

## 🔧 Configuration

### Environment Variables
```bash
PORT=3000                    # Server port
DOWNLOAD_PATH=./downloads    # Download directory
MAX_FILE_SIZE=100MB          # Maximum file size
```

### Flutter Configuration
Update `lib/services/youtube_service.dart` with your server URL:
```dart
static const String baseUrl = 'http://your-server-url:3000';
```

## 🚨 Troubleshooting

### Common Issues

**"Video information could not be retrieved"**
- Check if the YouTube URL is valid
- Ensure the video is public and not restricted
- Verify internet connection

**"Download failed"**
- Check server logs for detailed error messages
- Ensure sufficient disk space
- Verify youtube-dl is up to date

**"Server connection failed"**
- Confirm the server is running on the correct port
- Check firewall settings
- Verify network connectivity

### Performance Optimization
- Use SSD storage for faster download processing
- Increase server memory for handling multiple downloads
- Configure CDN for better global performance

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow existing code style and conventions
- Add tests for new features
- Update documentation as needed
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚖️ Legal Notice

**Important**: This software is for educational and personal use only. Users are responsible for ensuring they have the right to download and use any content. The developers are not responsible for any legal issues arising from the use of this application.

### Usage Guidelines
- Only download content you have permission to use
- Respect copyright laws and terms of service
- Use downloaded content responsibly
- Do not redistribute copyrighted material

## 🙏 Acknowledgments

- [youtube-dl](https://github.com/ytdl-org/youtube-dl) - Core download functionality
- [Flutter](https://flutter.dev/) - Mobile app framework
- [Express.js](https://expressjs.com/) - Web server framework
- [Material Design](https://material.io/) - UI design system

## 📞 Support

If you encounter any issues or have questions:

- 🐛 [Report bugs](https://github.com/samkofte/youtube-downloader/issues)
- 💡 [Request features](https://github.com/samkofte/youtube-downloader/issues)
- 📧 Contact: [your-email@example.com]

---

<div align="center">
  <strong>Made with ❤️ by the YouTube Downloader Team</strong>
</div>