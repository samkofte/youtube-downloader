const express = require('express');
const ytdl = require('@distube/ytdl-core');
const youtubedl = require('youtube-dl-exec');
const cors = require('cors');
const path = require('path');
const youtubeSearch = require('youtube-search-api');

// YouTube bot korumasını aşmak için gelişmiş agent ayarları
const agent = ytdl.createAgent([], {
    localAddress: undefined,
    family: 0,
    hints: 0,
    lookup: undefined
});

// Ek ytdl seçenekleri
const ytdlOptions = {
    agent: agent,
    requestOptions: {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
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
        const searchResults = await youtubeSearch.GetListByKeyword('trending', false, parseInt(maxResults));
        
        if (!searchResults || !searchResults.items || searchResults.items.length === 0) {
            console.log('Trending video bulunamadı');
            return res.json({ videos: [] });
        }
        
        // Sonuçları formatla
        const formattedResults = searchResults.items.map(video => {
            let viewCount = 0;
            if (video.viewCount) {
                const cleanViewCount = video.viewCount.toString().replace(/[^0-9]/g, '');
                viewCount = parseInt(cleanViewCount) || 0;
            }
            
            return {
                id: video.id,
                title: video.title,
                channel: video.channelTitle,
                duration: video.length?.simpleText || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.publishedAt || '',
                thumbnail: video.thumbnail?.thumbnails?.[video.thumbnail.thumbnails.length - 1]?.url || video.thumbnail?.thumbnails?.[0]?.url || '',
                url: `https://www.youtube.com/watch?v=${video.id}`
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
        
        const searchResults = await youtubeSearch.GetListByKeyword(q, false, parseInt(maxResults));
        
        if (!searchResults || !searchResults.items || searchResults.items.length === 0) {
            console.log('Arama sonucu bulunamadı');
            return res.json({ videos: [] });
        }
        
        const formattedResults = searchResults.items.map(video => {
            let viewCount = 0;
            if (video.viewCount) {
                const cleanViewCount = video.viewCount.toString().replace(/[^0-9]/g, '');
                viewCount = parseInt(cleanViewCount) || 0;
            }
            
            return {
                id: video.id,
                title: video.title,
                channel: video.channelTitle,
                duration: video.length?.simpleText || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.publishedAt || '',
                thumbnail: video.thumbnail?.thumbnails?.[video.thumbnail.thumbnails.length - 1]?.url || video.thumbnail?.thumbnails?.[0]?.url || '',
                url: `https://www.youtube.com/watch?v=${video.id}`
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
        
        const searchResults = await youtubeSearch.GetListByKeyword(q, false, 8);
        
        const suggestions = [];
        
        if (searchResults && searchResults.items) {
            searchResults.items.forEach(video => {
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

// Get video info for download (Flutter will handle actual download)
app.post('/video-info', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url || !ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        try {
            // Video bilgilerini al
            const info = await ytdl.getInfo(url, ytdlOptions);
            const videoDetails = {
                title: info.videoDetails.title,
                duration: info.videoDetails.lengthSeconds,
                thumbnail: info.videoDetails.thumbnails[0]?.url,
                author: info.videoDetails.author.name,
                viewCount: info.videoDetails.viewCount,
                uploadDate: info.videoDetails.uploadDate,
                description: info.videoDetails.description?.substring(0, 500),
                videoId: info.videoDetails.videoId,
                url: url,
                available: true
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

// Download MP3 endpoint (deprecated - use Flutter download)
app.post('/download-mp3', async (req, res) => {
    res.status(410).json({ 
        error: 'Bu endpoint artık kullanılmıyor', 
        message: 'Lütfen /video-info endpoint\'ini kullanın ve indirme işlemini Flutter tarafında yapın' 
    });
});

// Download MP4 endpoint
app.post('/download-mp4', async (req, res) => {
    try {
        const { url, quality = 'highest' } = req.body;
        
        if (!url || !ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        const info = await ytdl.getInfo(url, ytdlOptions);
        const title = info.videoDetails.title
            .replace(/[<>:"/\\|?*]/g, '')
            .replace(/\s+/g, '_')
            .substring(0, 100);
        
        res.header('Content-Disposition', `attachment; filename="${title}.mp4"`);
        res.header('Content-Type', 'video/mp4');
        
        let downloadOptions;
        
        if (quality === 'highest') {
            const formats = info.formats
                .filter(format => format.hasVideo && format.hasAudio && format.container === 'mp4')
                .sort((a, b) => {
                    const aHeight = parseInt(a.qualityLabel) || 0;
                    const bHeight = parseInt(b.qualityLabel) || 0;
                    return bHeight - aHeight;
                });
            
            if (formats.length > 0) {
                downloadOptions = {
                    format: formats[0]
                };
            } else {
                downloadOptions = {
                    filter: format => format.hasVideo && format.hasAudio,
                    quality: 'highestvideo'
                };
            }
        } else {
            downloadOptions = {
                filter: format => format.hasVideo && format.hasAudio && 
                    (format.qualityLabel === quality || format.quality === quality),
                quality: quality
            };
        }
        
        downloadOptions = { ...ytdlOptions, ...downloadOptions };
        ytdl(url, downloadOptions).pipe(res);
        
    } catch (error) {
        console.error('MP4 indirme hatası:', error);
        res.status(500).json({ error: 'MP4 indirilemedi' });
    }
});

// Video bilgilerini getir
app.post('/api/video-info', async (req, res) => {
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
            viewCount: info.videoDetails.viewCount
        };

        res.json(videoDetails);
    } catch (error) {
        console.error('Video bilgisi alınırken hata:', error);
        res.status(500).json({ error: 'Video bilgisi alınamadı' });
    }
});

// MP3 indirme
app.post('/api/download-mp3', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url || !ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        const info = await ytdl.getInfo(url, ytdlOptions);
        // Türkçe karakterleri destekleyen dosya adı temizleme
        const title = info.videoDetails.title
            .replace(/[<>:"/\\|?*]/g, '') // Dosya sisteminde yasak karakterleri kaldır
            .replace(/\s+/g, '_') // Boşlukları alt çizgi ile değiştir
            .substring(0, 100); // Dosya adını 100 karakterle sınırla
        
        res.header('Content-Disposition', `attachment; filename="${title}.mp3"`);
        res.header('Content-Type', 'audio/mpeg');
        
        ytdl(url, {
            ...ytdlOptions,
            filter: 'audioonly',
            quality: 'highestaudio'
        }).pipe(res);
        
    } catch (error) {
        console.error('MP3 indirme hatası:', error);
        res.status(500).json({ error: 'MP3 indirilemedi' });
    }
});

// MP4 indirme
app.post('/api/download-mp4', async (req, res) => {
    try {
        const { url, quality = 'highest' } = req.body;
        
        if (!url || !ytdl.validateURL(url)) {
            return res.status(400).json({ error: 'Geçersiz YouTube URL' });
        }

        const info = await ytdl.getInfo(url, { agent });
        // Türkçe karakterleri destekleyen dosya adı temizleme
        const title = info.videoDetails.title
            .replace(/[<>:"/\\|?*]/g, '') // Dosya sisteminde yasak karakterleri kaldır
            .replace(/\s+/g, '_') // Boşlukları alt çizgi ile değiştir
            .substring(0, 100); // Dosya adını 100 karakterle sınırla
        
        res.header('Content-Disposition', `attachment; filename="${title}.mp4"`);
        res.header('Content-Type', 'video/mp4');
        
        // Kalite seçim mantığını iyileştir
        let downloadOptions;
        
        if (quality === 'highest') {
            // En yüksek kaliteyi garantilemek için önce mevcut formatları kontrol et
            const formats = info.formats
                .filter(format => format.hasVideo && format.hasAudio && format.container === 'mp4')
                .sort((a, b) => {
                    const aHeight = parseInt(a.qualityLabel) || 0;
                    const bHeight = parseInt(b.qualityLabel) || 0;
                    return bHeight - aHeight;
                });
            
            if (formats.length > 0) {
                downloadOptions = {
                    format: formats[0]
                };
            } else {
                // Fallback: en yüksek kaliteli video + ses ayrı ayrı
                downloadOptions = {
                    filter: format => format.hasVideo && format.hasAudio,
                    quality: 'highestvideo'
                };
            }
        } else {
            // Spesifik kalite seçimi
            downloadOptions = {
                filter: format => format.hasVideo && format.hasAudio && 
                    (format.qualityLabel === quality || format.quality === quality),
                quality: quality
            };
        }
        
        ytdl(url, downloadOptions).pipe(res);
        
    } catch (error) {
        console.error('MP4 indirme hatası:', error);
        res.status(500).json({ error: 'MP4 indirilemedi' });
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
        const searchResults = await youtubeSearch.GetListByKeyword(q, false, 10);
        
        const suggestions = [];
        
        if (searchResults && searchResults.items) {
            // Gerçek video başlıklarını öneri olarak kullan
            searchResults.items.forEach(video => {
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
        const searchResults = await youtubeSearch.GetListByKeyword(query, false, 20);

        if (!searchResults || !searchResults.items || searchResults.items.length === 0) {
            console.log('Arama sonucu bulunamadı');
            return res.json([]);
        }

        // Sonuçları formatla
        const formattedResults = searchResults.items.map(video => {
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
                channel: video.channelTitle,
                duration: video.length?.simpleText || 'Bilinmiyor',
                viewCount: viewCount,
                publishedAt: video.publishedAt || '',
                thumbnail: video.thumbnail?.thumbnails?.[video.thumbnail.thumbnails.length - 1]?.url || video.thumbnail?.thumbnails?.[0]?.url || '',
                url: `https://www.youtube.com/watch?v=${video.id}`
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



app.listen(PORT, () => {
    console.log(`Sunucu http://localhost:${PORT} adresinde çalışıyor`);
});