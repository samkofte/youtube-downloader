# YouTube Downloader API

A simple YouTube downloader API built with Node.js and Express.

## Features

- Search YouTube videos
- Get trending videos
- Download MP3 audio files
- Download MP4 video files
- Get video information
- Search suggestions

## Local Development

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

The API will be available at `http://localhost:3001`

## Deploy to Render.com

### Method 1: Using render.yaml (Recommended)

1. Fork or clone this repository to your GitHub account
2. Go to [Render.com](https://render.com) and sign up/login
3. Click "New" → "Web Service"
4. Connect your GitHub repository
5. Render will automatically detect the `render.yaml` file and configure the service
6. Click "Create Web Service"

### Method 2: Manual Setup

1. Go to [Render.com](https://render.com) and sign up/login
2. Click "New" → "Web Service"
3. Connect your GitHub repository
4. Configure the following settings:
   - **Name**: youtube-api (or any name you prefer)
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free (or choose your preferred plan)
5. Add environment variables (optional):
   - `NODE_ENV`: production
6. Click "Create Web Service"

### Environment Variables

The following environment variables are supported:
- `PORT`: Server port (automatically set by Render)
- `NODE_ENV`: Environment mode (development/production)

## API Endpoints

- `GET /health` - Health check
- `GET /trending` - Get trending videos
- `GET /search?q=query` - Search videos
- `POST /info` - Get video information
- `GET /suggestions?q=query` - Get search suggestions
- `POST /download-mp3` - Download MP3
- `POST /download-mp4` - Download MP4

## Dependencies

- express: Web framework
- @distube/ytdl-core: YouTube downloader
- cors: Cross-origin resource sharing
- youtube-search-api: YouTube search functionality

---

## 📋 İçindekiler

- [✨ Özellikler](#-özellikler)
- [🚀 Hızlı Başlangıç](#-hızlı-başlangıç)
- [📦 Kurulum](#-kurulum)
- [🎯 Kullanım](#-kullanım)
- [🔧 API Dokümantasyonu](#-api-dokümantasyonu)
- [🏗️ Proje Yapısı](#️-proje-yapısı)
- [🛠️ Teknolojiler](#️-teknolojiler)
- [📸 Ekran Görüntüleri](#-ekran-görüntüleri)
- [🤝 Katkıda Bulunma](#-katkıda-bulunma)
- [⚠️ Yasal Uyarılar](#️-yasal-uyarılar)
- [🐛 Sorun Giderme](#-sorun-giderme)
- [📄 Lisans](#-lisans)

## ✨ Özellikler

<table>
  <tr>
    <td>🎵</td>
    <td><strong>MP3 İndirme</strong></td>
    <td>YouTube videolarını yüksek kaliteli ses dosyası olarak indirin</td>
  </tr>
  <tr>
    <td>🎬</td>
    <td><strong>MP4 İndirme</strong></td>
    <td>Farklı kalite seçenekleriyle (720p, 480p, 360p) video indirme</td>
  </tr>
  <tr>
    <td>🔍</td>
    <td><strong>Video Arama</strong></td>
    <td>YouTube'da video arayın ve doğrudan indirin</td>
  </tr>
  <tr>
    <td>📱</td>
    <td><strong>Responsive Tasarım</strong></td>
    <td>Mobil, tablet ve masaüstü cihazlarda mükemmel çalışır</td>
  </tr>
  <tr>
    <td>⚡</td>
    <td><strong>Hızlı İndirme</strong></td>
    <td>ytdl-core kütüphanesi ile optimize edilmiş indirme performansı</td>
  </tr>
  <tr>
    <td>🎨</td>
    <td><strong>Modern UI</strong></td>
    <td>Kullanıcı dostu, şık ve sezgisel arayüz</td>
  </tr>
  <tr>
    <td>📊</td>
    <td><strong>Detaylı Bilgiler</strong></td>
    <td>Video thumbnail, başlık, süre, görüntülenme sayısı ve kanal bilgileri</td>
  </tr>
  <tr>
    <td>🔄</td>
    <td><strong>Progress Bar</strong></td>
    <td>İndirme ilerlemesini takip edin</td>
  </tr>
  <tr>
    <td>🌍</td>
    <td><strong>Türkçe Destek</strong></td>
    <td>Türkçe karakterleri destekleyen dosya adlandırma</td>
  </tr>
</table>

## 🚀 Hızlı Başlangıç

```bash
# Repository'yi klonlayın
git clone https://github.com/samkofte/youtube-api-js.git

# Proje dizinine gidin
cd youtube-api-js

# Bağımlılıkları yükleyin
npm install

# Uygulamayı başlatın
npm start

# Tarayıcınızda açın
# http://localhost:3001
```

## 📦 Kurulum

### Gereksinimler

- **Node.js** (v14.0.0 veya üzeri) - [İndir](https://nodejs.org/)
- **npm** (Node.js ile birlikte gelir) veya **yarn**
- **Git** (opsiyonel) - [İndir](https://git-scm.com/)

### Detaylı Kurulum Adımları

1. **Repository'yi klonlayın:**
   ```bash
   git clone https://github.com/samkofte/youtube-api-js.git
   cd youtube-api-js
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   npm install
   # veya
   yarn install
   ```

3. **Uygulamayı başlatın:**
   ```bash
   npm start
   # veya
   yarn start
   ```

4. **Tarayıcınızda açın:**
   ```
   http://localhost:3001
   ```

### Docker ile Kurulum (Opsiyonel)

```bash
# Docker image oluşturun
docker build -t youtube-downloader .

# Container'ı çalıştırın
docker run -p 3001:3001 youtube-downloader
```

## 🎯 Kullanım

### 1. URL ile İndirme

1. **YouTube video URL'sini kopyalayın**
   - Örnek: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`

2. **URL'yi giriş alanına yapıştırın**

3. **"Video Bilgisi Al" butonuna tıklayın**

4. **İndirme formatını seçin:**
   - **MP3 için**: "🎵 MP3 İndir" butonuna tıklayın
   - **MP4 için**: Kalite seçin ve "🎬 MP4 İndir" butonuna tıklayın

### 2. Arama ile İndirme

1. **Arama kutusuna video adını yazın**

2. **Arama sonuçlarından istediğiniz videoyu seçin**

3. **Doğrudan MP3 veya MP4 butonlarına tıklayın**

## 🔧 API Dokümantasyonu

### Endpoints

#### `POST /api/video-info`
Video bilgilerini getirir.

**Request:**
```json
{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID"
}
```

**Response:**
```json
{
  "title": "Video Başlığı",
  "duration": "3:45",
  "viewCount": "1,234,567",
  "thumbnail": "https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg",
  "channel": "Kanal Adı",
  "formats": [
    {
      "quality": "720p",
      "container": "mp4",
      "size": "25.6 MB"
    }
  ]
}
```

#### `POST /api/download-mp3`
MP3 formatında ses dosyası indirir.

**Request:**
```json
{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID"
}
```

#### `POST /api/download-mp4`
MP4 formatında video dosyası indirir.

**Request:**
```json
{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "quality": "720p"
}
```

#### `GET /api/search`
YouTube'da video arar.

**Query Parameters:**
- `q`: Arama terimi
- `limit`: Sonuç sayısı (varsayılan: 10)

**Response:**
```json
{
  "results": [
    {
      "id": "VIDEO_ID",
      "title": "Video Başlığı",
      "channel": "Kanal Adı",
      "duration": "3:45",
      "viewCount": "1,234,567",
      "thumbnail": "https://img.youtube.com/vi/VIDEO_ID/hqdefault.jpg",
      "url": "https://www.youtube.com/watch?v=VIDEO_ID"
    }
  ]
}
```

## 🏗️ Proje Yapısı

```
youtube-api-js/
├── 📁 public/                 # Frontend dosyaları
│   ├── 📄 index.html         # Ana HTML dosyası
│   ├── 🎨 style.css          # CSS stilleri
│   └── ⚡ script.js          # Frontend JavaScript
├── 📄 server.js              # Express sunucu
├── 📦 package.json           # Proje bağımlılıkları
├── 🔒 package-lock.json      # Bağımlılık kilidi
├── 📖 README.md              # Proje dokümantasyonu
└── 📄 .gitignore             # Git ignore dosyası
```

## 🛠️ Teknolojiler

### Backend
- **Node.js** - JavaScript runtime
- **Express.js** - Web framework
- **ytdl-core** - YouTube video indirme
- **youtube-search-api** - YouTube arama
- **cors** - Cross-origin resource sharing

### Frontend
- **Vanilla JavaScript** - Dinamik işlevsellik
- **HTML5** - Yapısal markup
- **CSS3** - Modern styling
- **Flexbox/Grid** - Layout sistemi
- **Font Awesome** - İkonlar

### Geliştirme Araçları
- **npm** - Paket yöneticisi
- **Git** - Versiyon kontrolü
- **GitHub** - Repository hosting

## 📸 Ekran Görüntüleri

<div align="center">
  <h3>🖥️ Ana Sayfa</h3>
  <p><em>Modern ve kullanıcı dostu arayüz</em></p>
  
  <h3>🔍 Video Arama</h3>
  <p><em>YouTube'da video arayın ve doğrudan indirin</em></p>
  
  <h3>📱 Mobil Görünüm</h3>
  <p><em>Tüm cihazlarda mükemmel çalışır</em></p>
</div>

## 🤝 Katkıda Bulunma

Katkılarınızı memnuniyetle karşılıyoruz! İşte nasıl katkıda bulunabileceğiniz:

### 1. Fork ve Clone
```bash
# Repository'yi fork edin (GitHub'da)
git clone https://github.com/KULLANICI_ADINIZ/youtube-api-js.git
cd youtube-api-js
```

### 2. Branch Oluşturun
```bash
git checkout -b feature/amazing-feature
```

### 3. Değişikliklerinizi Yapın
- Kod yazın
- Test edin
- Dokümantasyonu güncelleyin

### 4. Commit ve Push
```bash
git add .
git commit -m "feat: Add amazing feature"
git push origin feature/amazing-feature
```

### 5. Pull Request Oluşturun
- GitHub'da Pull Request açın
- Değişikliklerinizi açıklayın
- Review bekleyin

### Katkı Kuralları
- **Kod Stili**: Mevcut kod stilini takip edin
- **Commit Mesajları**: [Conventional Commits](https://www.conventionalcommits.org/) formatını kullanın
- **Testler**: Yeni özellikler için testler ekleyin
- **Dokümantasyon**: README'yi güncel tutun

## ⚠️ Yasal Uyarılar

> **🚨 ÖNEMLİ UYARI**
> 
> Bu uygulama **sadece eğitim ve kişisel kullanım amaçlıdır**. Lütfen aşağıdaki kurallara uyun:

- ✅ **Kendi içeriklerinizi** indirin
- ✅ **Telif hakkı olmayan** içerikleri indirin
- ✅ **Eğitim amaçlı** kullanın
- ❌ **Telif hakkı korumalı** içerikleri ticari amaçla kullanmayın
- ❌ **YouTube'un hizmet şartlarını** ihlal etmeyin
- ❌ **Yasadışı** içerik dağıtımı yapmayın

### Sorumluluk Reddi

Bu yazılımın geliştiricileri, kullanıcıların bu uygulamayı kullanarak yaptığı herhangi bir yasal ihlalden sorumlu değildir. Kullanıcılar, indirdikleri içeriklerin kullanım haklarına sahip olduklarından emin olmalıdır.

## 🐛 Sorun Giderme

### Yaygın Sorunlar ve Çözümleri

<details>
<summary><strong>❌ "Video bilgisi alınamadı" hatası</strong></summary>

**Olası Nedenler:**
- Geçersiz YouTube URL'si
- Video özel veya kısıtlı
- İnternet bağlantısı sorunu
- YouTube'un API değişiklikleri

**Çözümler:**
1. URL'nin doğru olduğundan emin olun
2. Video'nun herkese açık olduğunu kontrol edin
3. İnternet bağlantınızı test edin
4. Farklı bir video deneyin
</details>

<details>
<summary><strong>⬇️ İndirme başlamıyor</strong></summary>

**Olası Nedenler:**
- Tarayıcı pop-up engelleyicisi
- JavaScript devre dışı
- Ağ güvenlik duvarı

**Çözümler:**
1. Pop-up engelleyicisini devre dışı bırakın
2. JavaScript'in etkin olduğundan emin olun
3. Farklı tarayıcı deneyin
4. Güvenlik duvarı ayarlarını kontrol edin
</details>

<details>
<summary><strong>🚀 Sunucu başlatma hatası</strong></summary>

**Olası Nedenler:**
- Port 3001 kullanımda
- Node.js sürümü eski
- Bağımlılıklar eksik

**Çözümler:**
1. Port kullanımını kontrol edin: `netstat -an | findstr :3001`
2. Node.js sürümünü güncelleyin
3. Bağımlılıkları yeniden yükleyin: `npm install`
4. Farklı port kullanın: `PORT=3002 npm start`
</details>

<details>
<summary><strong>📱 Mobil cihazda çalışmıyor</strong></summary>

**Çözümler:**
1. Tarayıcıyı yenileyin
2. Önbelleği temizleyin
3. Farklı tarayıcı deneyin
4. Cihazı yeniden başlatın
</details>

### Hata Raporlama

Sorun yaşıyorsanız, lütfen [GitHub Issues](https://github.com/samkofte/youtube-api-js/issues) sayfasında yeni bir issue açın ve şu bilgileri ekleyin:

- **İşletim Sistemi**: (Windows 10, macOS, Ubuntu, vb.)
- **Tarayıcı**: (Chrome 91, Firefox 89, vb.)
- **Node.js Sürümü**: `node --version`
- **Hata Mesajı**: Tam hata mesajı
- **Adımlar**: Hatayı yeniden oluşturma adımları

## 📊 Performans

- **İndirme Hızı**: Ağ bağlantınıza bağlı olarak optimize edilmiş
- **Bellek Kullanımı**: Düşük bellek tüketimi
- **CPU Kullanımı**: Verimli işlemci kullanımı
- **Desteklenen Formatlar**: MP3 (128kbps-320kbps), MP4 (360p-1080p)

## 🔄 Güncellemeler

### v2.0.0 (Mevcut)
- ✨ Video arama özelliği eklendi
- 🎨 UI/UX iyileştirmeleri
- 📱 Mobil responsive tasarım
- 🔄 Progress bar eklendi
- 🌍 Türkçe karakter desteği
- 🐛 Bug düzeltmeleri

### v1.0.0
- 🎵 MP3 indirme
- 🎬 MP4 indirme
- 📊 Video bilgileri
- 🎨 Temel UI

## 📞 İletişim ve Destek

- **GitHub Issues**: [Sorun Bildirin](https://github.com/samkofte/youtube-api-js/issues)
- **GitHub Discussions**: [Tartışmalara Katılın](https://github.com/samkofte/youtube-api-js/discussions)
- **Email**: [samkofte@example.com](mailto:samkofte@example.com)

## 🌟 Teşekkürler

Bu projeyi mümkün kılan açık kaynak kütüphanelere teşekkürler:

- [ytdl-core](https://github.com/fent/node-ytdl-core) - YouTube video indirme
- [youtube-search-api](https://github.com/vishaldev25/youtube-search-api) - YouTube arama
- [Express.js](https://expressjs.com/) - Web framework
- [Node.js](https://nodejs.org/) - JavaScript runtime

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

```
MIT License

Copyright (c) 2024 samkofte

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">
  <p><strong>⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!</strong></p>
  <p>Made with ❤️ by <a href="https://github.com/samkofte">samkofte</a></p>
  
  <p>
    <a href="#top">🔝 Başa Dön</a>
  </p>
</div>