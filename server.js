const express = require('express');
const ytdl = require('ytdl-core');
const youtubedl = require('youtube-dl-exec');
const cors = require('cors');
const path = require('path');
const YouTube = require('youtube-sr').default;
const ffmpegPath = require('ffmpeg-static');
const { spawn } = require('child_process');

// Basit ytdl seçenekleri
const ytdlOptions = {
    requestOptions: {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
    }
};

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Ana sayfa
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'Server is running' });
});

// Trending videos endpoint
app.get('/trending', async (req, res) => {
    try {
        const { maxResults = 20 } = req.query;
        
        console.log('Trending videolar getiriliyor...');
        
        // YouTube Search API kullanarak popüler videoları al
        const searchResults = await YouTube.search('trending', { limit: parseInt(maxResults) });
        
        if (!searchResults || searchResults.length === 0) {
            console.log('Trending video bulunamadı');
            return res.json({ videos: [] });
        }
        
        // Sonuçları formatla
        const formattedResults = searchResults.map(video => {
            let viewCount = 0;
            if (video.viewCount) {
                const cleanViewCount = video.viewCount.toString().replace(/[^0-9]/g, '');
                viewCount = parseInt(cleanViewCount) || 0;
            }
            
            return {
                id: video.id,
                title: video.title,
                channel: video.channel?.name || video.channel,
                duration: video.duration?.text || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.uploadedAt || '',
                thumbnail: video.thumbnail?.url || '',
                url: video.url || `https://www.youtube.com/watch?v=${video.id}`
            };
        });
        
        console.log('Trending videolar:', formattedResults.length, 'video bulundu');
        res.json({ videos: formattedResults });
    } catch (error) {
        console.error('Trending video hatası:', error);
        res.status(500).json({ error: 'Trending videolar alınamadı' });
    }
});

// Search videos endpoint
app.get('/search', async (req, res) => {
    try {
        const { q, maxResults = 10 } = req.query;
        
        if (!q) {
            return res.status(400).json({ error: 'Arama sorgusu gerekli' });
        }
        
        console.log('YouTube arama yapılıyor:', q);
        
        const searchResults = await YouTube.search(q, { limit: parseInt(maxResults) });
        
        if (!searchResults || searchResults.length === 0) {
            console.log('Arama sonucu bulunamadı');
            return res.json({ videos: [] });
        }
        
        const formattedResults = searchResults.map(video => {
            let viewCount = 0;
            if (video.viewCount) {
                const cleanViewCount = video.viewCount.toString().replace(/[^0-9]/g, '');
                viewCount = parseInt(cleanViewCount) || 0;
            }
            
            return {
                id: video.id,
                title: video.title,
                channel: video.channel?.name || video.channel,
                duration: video.duration?.text || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.uploadedAt || '',
                thumbnail: video.thumbnail?.url || '',
                url: video.url || `https://www.youtube.com/watch?v=${video.id}`
            };
        });
        
        console.log('Arama sonuçları:', formattedResults.length, 'video bulundu');
        res.json({ videos: formattedResults });
    } catch (error) {
        console.error('Arama hatası:', error);
        res.status(500).json({ error: 'Arama hatası: ' + error.message });
    }
});

// Video info endpoint
app.post('/info', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'URL gerekli' });
        }
        
        if (!ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }
        
        const info = await ytdl.getInfo(url, ytdlOptions);
        const videoDetails = {
            title: info.videoDetails.title,
            thumbnail: info.videoDetails.thumbnails[0]?.url,
            duration: info.videoDetails.lengthSeconds,
            author: info.videoDetails.author.name,
            viewCount: info.videoDetails.viewCount,
            formats: info.formats
                .filter(format => format.hasVideo && format.hasAudio)
                .map(format => ({
                    quality: format.qualityLabel,
                    container: format.container,
                    size: format.contentLength
                }))
        };
        
        res.json(videoDetails);
    } catch (error) {
        console.error('Video bilgisi alınırken hata:', error);
        res.status(500).json({ error: 'Video bilgisi alınamadı' });
    }
});

// Search suggestions endpoint
app.get('/suggestions', async (req, res) => {
    try {
        const { q } = req.query;
        
        if (!q || q.length < 2) {
            return res.json({ suggestions: [] });
        }
        
        console.log('Arama önerileri getiriliyor:', q);
        
        const searchResults = await YouTube.search(q, { limit: 8 });
        
        const suggestions = [];
        
        if (searchResults && searchResults.length > 0) {
            searchResults.forEach(video => {
                if (video.title && suggestions.length < 8) {
                    let cleanTitle = video.title
                        .replace(/[\[\](){}]/g, '')
                        .replace(/\s+/g, ' ')
                        .trim();
                    
                    if (cleanTitle.length > 50) {
                        cleanTitle = cleanTitle.substring(0, 50) + '...';
                    }
                    
                    if (!suggestions.includes(cleanTitle)) {
                        suggestions.push(cleanTitle);
                    }
                }
            });
        }
        
        if (suggestions.length === 0) {
            suggestions.push(q);
        }
        
        console.log('Arama önerileri:', suggestions);
        res.json({ suggestions });
    } catch (error) {
        console.error('Öneri hatası:', error);
        res.json({ suggestions: [q] });
    }
});

// Get video info for download (works for both Flutter and web)
app.post('/video-info', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'URL gerekli' });
        }

        try {
            // youtube-dl-exec kullanarak video bilgilerini al
            const info = await youtubedl(url, {
                dumpSingleJson: true,
                noPlaylist: true,
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            });
            
            const videoDetails = {
                title: info.title || 'Unknown',
                duration: info.duration || 0,
                thumbnail: info.thumbnail || '',
                author: info.uploader || 'Unknown',
                viewCount: info.view_count || 0,
                uploadDate: info.upload_date || '',
                description: info.description?.substring(0, 500) || '',
                videoId: info.id || '',
                url: url,
                available: true,
                formats: info.formats?.map(f => ({
                    format_id: f.format_id,
                    ext: f.ext,
                    quality: f.quality,
                    height: f.height,
                    width: f.width
                })) || []
            };
            
            res.json({ success: true, videoInfo: videoDetails });
            
        } catch (ytdlError) {
            console.log('Video bilgisi alınamadı:', ytdlError.message);
            res.status(404).json({ 
                error: 'Video bilgisi alınamadı', 
                message: 'Video mevcut değil veya erişilemiyor',
                available: false 
            });
        }
        
    } catch (error) {
        console.error('Video info hatası:', error);
        res.status(500).json({ error: 'Video bilgisi alınamadı: ' + error.message });
    }
});

// Download MP3 endpoint for web
app.post('/download-mp3', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'URL gerekli' });
        }

        console.log('MP3 indirme başlatılıyor:', url);
        
        // youtube-dl-exec kullanarak MP3 indirme
        const output = await youtubedl(url, {
            extractAudio: true,
            audioFormat: 'mp3',
            audioQuality: '192K',
            output: '%(title)s.%(ext)s',
            restrictFilenames: true,
            noPlaylist: true,
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ffmpegLocation: ffmpegPath
        });
        
        res.json({ 
            success: true, 
            message: 'MP3 indirme başarılı',
            title: (typeof output === 'object' && output.title) ? output.title : 'Unknown',
            format: 'mp3'
        });
        
    } catch (error) {
        console.error('MP3 indirme hatası:', error);
        res.status(500).json({ 
            error: 'MP3 indirme başarısız', 
            message: error.message 
        });
    }
});

// Download MP4 endpoint for web
app.post('/download-mp4', async (req, res) => {
    try {
        const { url, quality = 'best' } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'URL gerekli' });
        }

        console.log('MP4 indirme başlatılıyor:', url);
        
        // youtube-dl-exec kullanarak MP4 indirme
        const output = await youtubedl(url, {
            format: quality === 'best' ? 'best[ext=mp4]' : `worst[height<=${quality}][ext=mp4]`,
            output: '%(title)s.%(ext)s',
            restrictFilenames: true,
            noPlaylist: true,
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ffmpegLocation: ffmpegPath
        });
        
        res.json({ 
            success: true, 
            message: 'MP4 indirme başarılı',
            title: (typeof output === 'object' && output.title) ? output.title : 'Unknown',
            format: 'mp4',
            quality: quality
        });
        
    } catch (error) {
        console.error('MP4 indirme hatası:', error);
        res.status(500).json({ 
            error: 'MP4 indirme başarısız', 
            message: error.message 
        });
    }
});

// Video bilgilerini getir
app.post('/api/video-info', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'URL gerekli' });
        }

        try {
            const info = await youtubedl(url, {
                dumpSingleJson: true,
                noPlaylist: true,
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            });

            const videoDetails = {
                title: info.title || 'Unknown',
                thumbnail: info.thumbnail || '',
                duration: info.duration || 0,
                author: info.uploader || 'Unknown',
                viewCount: info.view_count || 0
            };

            return res.json(videoDetails);
        } catch (e) {
            return res.status(500).json({ error: 'Video bilgisi alınamadı' });
        }
    } catch (error) {
        console.error('Video bilgisi alınırken hata:', error);
        res.status(500).json({ error: 'Video bilgisi alınamadı' });
    }
});

// MP3 indirme (mobil uygulama için streaming)
app.post('/api/download-mp3', async (req, res) => {
    try {
        const { url } = req.body;
        if (!url) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        // Başlık almak için hızlı info çekelim (dosya adı için)
        let title = 'audio';
        try {
            const info = await youtubedl(url, {
                dumpSingleJson: true,
                noPlaylist: true,
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            });
            title = (info.title || 'audio')
                .replace(/[^a-zA-Z0-9\s\-_]/g, '') // Sadece alfanumerik karakterler
                .replace(/\s+/g, '_')
                .substring(0, 50); // Daha kısa dosya adı
        } catch (_) {}

        res.setHeader('Content-Type', 'audio/mpeg');
        res.setHeader('Content-Disposition', `attachment; filename="${title}.mp3"`);

        // MP3 indirme için spawn kullan
        const ytDlpProcess = spawn('yt-dlp', [
            url,
            '--extract-audio',
            '--audio-format', 'mp3',
            '--audio-quality', '192K',
            '--output', '-',
            '--restrict-filenames',
            '--no-playlist',
            '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            '--ffmpeg-location', ffmpegPath
        ]);

        ytDlpProcess.stdout.pipe(res);
        ytDlpProcess.stderr.on('data', (data) => {
            console.log('yt-dlp stderr:', data.toString());
        });
        ytDlpProcess.on('error', (err) => {
            console.error('MP3 indirme hata (spawn):', err);
            if (!res.headersSent) res.status(500).json({ error: 'MP3 indirilemedi' });
        });
        ytDlpProcess.on('close', (code) => {
            if (code !== 0) {
                console.error('MP3 indirme süreç kodu:', code);
            }
        });

    } catch (error) {
        console.error('MP3 indirme hatası:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'MP3 indirilemedi' });
        }
    }
});

// MP4 indirme (mobil uygulama için streaming)
app.post('/api/download-mp4', async (req, res) => {
    try {
        const { url, quality = 'highest' } = req.body;
        if (!url) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        // Başlık almak için hızlı info çekelim (dosya adı için)
        let title = 'video';
        try {
            const info = await youtubedl(url, {
                dumpSingleJson: true,
                noPlaylist: true,
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            });
            title = (info.title || 'video')
                .replace(/[^a-zA-Z0-9\s\-_]/g, '') // Sadece alfanumerik karakterler
                .replace(/\s+/g, '_')
                .substring(0, 50); // Daha kısa dosya adı
        } catch (_) {}

        res.setHeader('Content-Type', 'video/mp4');
        res.setHeader('Content-Disposition', `attachment; filename="${title}.mp4"`);

        // Format seçimi: mp4 öncelikli
        let format = 'best[ext=mp4]/bestvideo[ext=mp4]+bestaudio/best';
        if (quality && quality !== 'highest') {
            // belirli yükseklik tercih ediliyorsa
            format = `bestvideo[ext=mp4][height<=${quality}]+bestaudio/best[ext=mp4]`;
        }

        // MP4 indirme için spawn kullan
        const ytDlpProcess = spawn('yt-dlp', [
            url,
            '--format', format,
            '--output', '-',
            '--restrict-filenames',
            '--no-playlist',
            '--merge-output-format', 'mp4',
            '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            '--ffmpeg-location', ffmpegPath
        ]);

        ytDlpProcess.stdout.pipe(res);
        ytDlpProcess.stderr.on('data', (data) => {
            console.log('yt-dlp stderr:', data.toString());
        });
        ytDlpProcess.on('error', (err) => {
            console.error('MP4 indirme hata (spawn):', err);
            if (!res.headersSent) res.status(500).json({ error: 'MP4 indirilemedi' });
        });
        ytDlpProcess.on('close', (code) => {
            if (code !== 0) {
                console.error('MP4 indirme süreç kodu:', code);
            }
        });

    } catch (error) {
        console.error('MP4 indirme hatası:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'MP4 indirilemedi' });
        }
    }
});

// Mevcut kaliteler
app.post('/api/formats', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url || !ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        const info = await ytdl.getInfo(url, ytdlOptions);
        const formats = info.formats
            .filter(format => format.hasVideo && format.hasAudio)
            .map(format => ({
                quality: format.qualityLabel,
                container: format.container,
                size: format.contentLength
            }));

        res.json(formats);
    } catch (error) {
        console.error('Format bilgisi alınırken hata:', error);
        res.status(500).json({ error: 'Format bilgisi alınamadı' });
    }
});

// YouTube arama önerileri
app.get('/api/search-suggestions', async (req, res) => {
    try {
        const { q } = req.query;
        
        if (!q || q.length < 2) {
            return res.json([]);
        }

        console.log('Gerçek YouTube önerileri getiriliyor:', q);

        // YouTube'dan gerçek arama sonuçları al
        const searchResults = await YouTube.search(q, { limit: 10 });
        
        const suggestions = [];
        
        if (searchResults && searchResults.length > 0) {
            // Gerçek video başlıklarını öneri olarak kullan
            searchResults.forEach(video => {
                if (video.title && suggestions.length < 8) {
                    // Video başlığını temizle ve kısalt
                    let cleanTitle = video.title
                        .replace(/[\[\](){}]/g, '') // Parantezleri kaldır
                        .replace(/\s+/g, ' ') // Çoklu boşlukları tek boşluk yap
                        .trim();
                    
                    // Çok uzun başlıkları kısalt
                    if (cleanTitle.length > 50) {
                        cleanTitle = cleanTitle.substring(0, 50) + '...';
                    }
                    
                    // Aynı başlık yoksa ekle
                    if (!suggestions.includes(cleanTitle)) {
                        suggestions.push(cleanTitle);
                    }
                }
            });
        }
        
        // Eğer hiç sonuç yoksa kullanıcının yazdığını ekle
        if (suggestions.length === 0) {
            suggestions.push(q);
        }

        console.log('Gerçek YouTube önerileri:', suggestions);
        res.json(suggestions);
    } catch (error) {
        console.error('YouTube öneri hatası:', error);
        // Hata durumunda sadece kullanıcının yazdığını döndür
        res.json([q]);
    }
});

// YouTube arama
app.post('/api/search', async (req, res) => {
    try {
        const { query } = req.body;
        
        if (!query) {
            return res.status(400).json({ error: 'Arama sorgusu gerekli' });
        }

        console.log('YouTube arama yapılıyor:', query);

        // YouTube Search API kullanarak arama
        const searchResults = await YouTube.search(query, { limit: 20 });

        if (!searchResults || searchResults.length === 0) {
            console.log('Arama sonucu bulunamadı');
            return res.json([]);
        }

        // Sonuçları formatla
        const formattedResults = searchResults.map(video => {
            // viewCount'u sayısal değere çevir
            let viewCount = 0;
            if (video.viewCount) {
                // String içindeki sayısal olmayan karakterleri temizle
                const cleanViewCount = video.viewCount.toString().replace(/[^0-9]/g, '');
                viewCount = parseInt(cleanViewCount) || 0;
            }
            
            return {
                id: video.id,
                title: video.title,
                channel: video.channel?.name || video.channel,
                duration: video.duration?.text || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.uploadedAt || '',
                thumbnail: video.thumbnail?.url || '',
                url: video.url || `https://www.youtube.com/watch?v=${video.id}`
            };
        });

        console.log('YouTube arama sonuçları:', formattedResults.length, 'video bulundu');
        console.log('İlk sonuç örneği:', formattedResults[0]);

        res.json(formattedResults);
    } catch (error) {
        console.error('YouTube arama hatası:', error.message);
        res.status(500).json({ error: 'YouTube arama hatası: ' + error.message });
    }
});



app.listen(PORT, '0.0.0.0', () => {
    console.log(`Sunucu http://localhost:${PORT} adresinde çalışıyor`);
    console.log(`Ağ erişimi: http://192.168.1.14:${PORT}`);
});