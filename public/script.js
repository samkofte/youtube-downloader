class YouTubeDownloader {
    constructor() {
        this.initializeElements();
        this.bindEvents();
        this.currentVideoUrl = '';
    }

    initializeElements() {
        this.urlInput = document.getElementById('urlInput');
        this.getInfoBtn = document.getElementById('getInfoBtn');
        this.searchInput = document.getElementById('searchInput');
        this.searchBtn = document.getElementById('searchBtn');
        this.searchSuggestions = document.getElementById('searchSuggestions');
        this.searchResults = document.getElementById('searchResults');
        this.searchResultsList = document.getElementById('searchResultsList');
        this.loadingSpinner = document.getElementById('loadingSpinner');
        this.videoInfo = document.getElementById('videoInfo');
        this.thumbnail = document.getElementById('thumbnail');
        this.videoTitle = document.getElementById('videoTitle');
        this.videoAuthor = document.getElementById('videoAuthor');
        this.videoDuration = document.getElementById('videoDuration');
        this.videoViews = document.getElementById('videoViews');
        this.downloadMp3 = document.getElementById('downloadMp3');
        this.downloadMp4 = document.getElementById('downloadMp4');
        this.qualitySelect = document.getElementById('qualitySelect');
        this.downloadProgress = document.getElementById('downloadProgress');
        this.progressText = document.getElementById('progressText');
        this.progressFill = document.getElementById('progressFill');
        this.errorMessage = document.getElementById('errorMessage');
        this.errorText = document.getElementById('errorText');
        
        this.currentSuggestionIndex = -1;
        this.searchTimeout = null;
    }

    bindEvents() {
        this.getInfoBtn.addEventListener('click', () => this.getVideoInfo());
        this.searchBtn.addEventListener('click', () => this.searchVideos());
        this.downloadMp3.addEventListener('click', () => this.downloadAudio());
        this.downloadMp4.addEventListener('click', () => this.downloadVideo());
        
        this.urlInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.getVideoInfo();
            }
        });
        
        this.searchInput.addEventListener('input', (e) => {
            this.handleSearchInput(e.target.value);
        });
        
        this.searchInput.addEventListener('keydown', (e) => {
            this.handleSearchKeydown(e);
        });
        
        this.searchInput.addEventListener('blur', () => {
            setTimeout(() => {
                this.hideSuggestions();
            }, 200);
        });
        
        this.searchInput.addEventListener('focus', () => {
            if (this.searchInput.value.length >= 2) {
                this.showSuggestions();
            }
        });
        
        document.addEventListener('click', (e) => {
            if (!e.target.closest('.search-input-wrapper')) {
                this.hideSuggestions();
            }
        });
    }

    showLoading() {
        this.loadingSpinner.classList.remove('hidden');
        this.videoInfo.classList.add('hidden');
        this.errorMessage.classList.add('hidden');
        this.downloadProgress.classList.add('hidden');
    }

    hideLoading() {
        this.loadingSpinner.classList.add('hidden');
    }

    showError(message, type = 'error') {
        this.errorText.textContent = message;
        this.errorMessage.classList.remove('hidden');
        
        // Add success or error styling
        if (type === 'success') {
            this.errorMessage.style.backgroundColor = '#d4edda';
            this.errorMessage.style.color = '#155724';
            this.errorMessage.style.borderColor = '#c3e6cb';
        } else {
            this.errorMessage.style.backgroundColor = '#f8d7da';
            this.errorMessage.style.color = '#721c24';
            this.errorMessage.style.borderColor = '#f5c6cb';
        }
        
        this.hideLoading();
        
        // Auto hide success messages
        if (type === 'success') {
            setTimeout(() => {
                this.hideError();
            }, 5000);
        }
    }

    hideError() {
        this.errorMessage.classList.add('hidden');
    }

    formatDuration(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        
        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        return `${minutes}:${secs.toString().padStart(2, '0')}`;
    }

    formatViews(views) {
        if (views >= 1000000) {
            return `${(views / 1000000).toFixed(1)}M görüntülenme`;
        } else if (views >= 1000) {
            return `${(views / 1000).toFixed(1)}K görüntülenme`;
        }
        return `${views} görüntülenme`;
    }

    async getVideoInfo() {
        const url = this.urlInput.value.trim();
        
        if (!url) {
            this.showError('Lütfen bir YouTube URL\'si girin');
            return;
        }

        if (!this.isValidYouTubeUrl(url)) {
            this.showError('Geçersiz YouTube URL\'si');
            return;
        }

        this.showLoading();
        this.hideError();
        this.currentVideoUrl = url;

        try {
            const response = await fetch('/api/video-info', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url })
            });

            const data = await response.json();

            if (!response.ok) {
                throw new Error(data.error || 'Video bilgisi alınamadı');
            }

            await this.displayVideoInfo(data);
        } catch (error) {
            console.error('Video bilgisi alma hatası:', error);
            this.showError(error.message || 'Video bilgisi alınırken bir hata oluştu');
        } finally {
            this.hideLoading();
        }
    }

    async displayVideoInfo(videoData) {
        this.thumbnail.src = videoData.thumbnail;
        this.videoTitle.textContent = videoData.title;
        this.videoAuthor.textContent = `Kanal: ${videoData.author}`;
        this.videoDuration.textContent = `Süre: ${this.formatDuration(videoData.duration)}`;
        this.videoViews.textContent = this.formatViews(videoData.viewCount);
        
        // Mevcut kaliteleri yükle
        await this.loadAvailableQualities();
        
        this.videoInfo.classList.remove('hidden');
    }

    async loadAvailableQualities() {
        try {
            const response = await fetch('/api/formats', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url: this.currentVideoUrl })
            });

            if (response.ok) {
                const formats = await response.json();
                this.updateQualityOptions(formats);
            }
        } catch (error) {
            console.error('Kalite bilgisi alınamadı:', error);
            // Hata durumunda varsayılan seçenekleri koru
        }
    }

    updateQualityOptions(formats) {
        // Mevcut seçenekleri temizle
        this.qualitySelect.innerHTML = '';
        
        // En yüksek kalite seçeneğini ekle
        const highestOption = document.createElement('option');
        highestOption.value = 'highest';
        highestOption.textContent = 'En Yüksek Kalite';
        this.qualitySelect.appendChild(highestOption);
        
        // Mevcut kaliteleri ekle
        const uniqueQualities = [...new Set(formats.map(f => f.quality).filter(q => q))];
        const sortedQualities = uniqueQualities.sort((a, b) => {
            const aNum = parseInt(a) || 0;
            const bNum = parseInt(b) || 0;
            return bNum - aNum;
        });
        
        sortedQualities.forEach(quality => {
            const option = document.createElement('option');
            option.value = quality;
            option.textContent = quality;
            this.qualitySelect.appendChild(option);
        });
        
        // Eğer hiç kalite bulunamazsa varsayılan seçenekleri ekle
        if (sortedQualities.length === 0) {
            ['720p', '480p', '360p'].forEach(quality => {
                const option = document.createElement('option');
                option.value = quality;
                option.textContent = quality;
                this.qualitySelect.appendChild(option);
            });
        }
    }

    isValidYouTubeUrl(url) {
        const youtubeRegex = /^(https?\:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+/;
        return youtubeRegex.test(url);
    }

    showDownloadProgress(type) {
        this.progressText.innerHTML = `<i class="fas fa-download"></i> ${type}`;
        this.downloadProgress.classList.remove('hidden');
        this.progressFill.style.width = '0%';
        
        // Simulated progress with better animation
        let progress = 0;
        const interval = setInterval(() => {
            const increment = Math.random() * 12 + 3; // 3-15 arası artış
            progress += increment;
            if (progress >= 85) {
                progress = 85;
                clearInterval(interval);
            }
            this.progressFill.style.width = `${progress}%`;
            
            // Progress yüzdesini göster
            if (progress < 85) {
                this.progressText.innerHTML = `<i class="fas fa-download"></i> ${type} - %${Math.round(progress)}`;
            }
        }, 400);

        return interval;
    }

    hideDownloadProgress() {
        this.progressFill.style.width = '100%';
        this.progressText.innerHTML = '<i class="fas fa-check-circle"></i> İndirme tamamlandı! %100';
        
        // Başarı animasyonu için renk değişimi
        this.progressFill.style.background = 'linear-gradient(90deg, #4caf50, #66bb6a)';
        
        setTimeout(() => {
            this.downloadProgress.classList.add('hidden');
            // Rengi eski haline döndür
            this.progressFill.style.background = 'linear-gradient(90deg, #2196f3, #21cbf3, #4caf50)';
        }, 3000);
    }

    async downloadAudio() {
        if (!this.currentVideoUrl) {
            this.showError('Önce video bilgisini alın');
            return;
        }

        this.hideError();
        const progressInterval = this.showDownloadProgress('MP3');

        try {
            const response = await fetch('/download-mp3', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ url: this.currentVideoUrl })
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'MP3 indirilemedi');
            }

            // Complete progress
            clearInterval(progressInterval);
            this.progressFill.style.width = '100%';
            this.progressText.textContent = `MP3 indirme başarılı: ${result.title}`;

            setTimeout(() => {
                this.hideDownloadProgress();
                this.showError(`MP3 indirme tamamlandı: ${result.title}`, 'success');
            }, 1000);

        } catch (error) {
            clearInterval(progressInterval);
            console.error('MP3 indirme hatası:', error);
            this.showError(error.message || 'MP3 indirme sırasında bir hata oluştu');
            this.hideDownloadProgress();
        }
    }

    async downloadVideo() {
        if (!this.currentVideoUrl) {
            this.showError('Önce video bilgisini alın');
            return;
        }

        this.hideError();
        const quality = this.qualitySelect.value;
        const progressInterval = this.showDownloadProgress('MP4');

        try {
            const response = await fetch('/download-mp4', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ 
                    url: this.currentVideoUrl,
                    quality: quality
                })
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || 'MP4 indirilemedi');
            }

            // Complete progress
            clearInterval(progressInterval);
            this.progressFill.style.width = '100%';
            this.progressText.textContent = `MP4 indirme başarılı: ${result.title}`;

            setTimeout(() => {
                this.hideDownloadProgress();
                this.showError(`MP4 indirme tamamlandı: ${result.title} (${result.quality})`, 'success');
            }, 1000);

        } catch (error) {
            clearInterval(progressInterval);
            console.error('MP4 indirme hatası:', error);
            this.showError(error.message || 'MP4 indirme sırasında bir hata oluştu');
            this.hideDownloadProgress();
        }
    }

    async searchVideos() {
        const query = this.searchInput.value.trim();
        
        if (!query) {
            this.showError('Lütfen bir arama terimi girin');
            return;
        }
        
        this.searchBtn.disabled = true;
        this.searchBtn.textContent = 'Aranıyor...';
        
        try {
            const response = await fetch('/api/search', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ query })
            });
            
            console.log('Search request sent for:', query);
            console.log('Response status:', response.status);
            
            const data = await response.json();
            console.log('Search response data:', data);
            
            if (!response.ok) {
                throw new Error(data.error || 'Arama hatası');
            }
            
            this.displaySearchResults(data);
            
        } catch (error) {
            console.error('Arama hatası:', error);
            this.showError(error.message || 'Arama yapılırken bir hata oluştu');
        } finally {
            this.searchBtn.disabled = false;
            this.searchBtn.textContent = 'Ara';
        }
    }
    
    displaySearchResults(results) {
        console.log('displaySearchResults called with:', results);
        console.log('searchResults element:', this.searchResults);
        console.log('searchResultsList element:', this.searchResultsList);
        
        this.searchResults.classList.remove('hidden');
        this.searchResultsList.innerHTML = '';
        
        if (results.length === 0) {
            this.searchResultsList.innerHTML = '<p>Sonuç bulunamadı</p>';
            return;
        }
        
        results.forEach(video => {
            const videoElement = document.createElement('div');
            videoElement.className = 'search-result-item';
            videoElement.innerHTML = `
                <img src="${video.thumbnail}" alt="${video.title}" class="search-thumbnail">
                <div class="search-info">
                    <h4 class="search-title">${video.title}</h4>
                    <p class="search-channel">${video.channel}</p>
                    <div class="search-meta">
                        <span class="search-duration">${video.duration}</span>
                        ${video.viewCount ? `<span class="search-views">${this.formatViews(parseInt(video.viewCount) || 0)}</span>` : ''}
                    </div>
                </div>
                <div class="search-actions">
                    <button class="download-btn download-mp3-btn" data-url="${video.url}">
                        <i class="fas fa-music"></i> MP3
                    </button>
                    <button class="download-btn download-mp4-btn" data-url="${video.url}">
                        <i class="fas fa-video"></i> MP4
                    </button>
                </div>
            `;
            
            const mp3Btn = videoElement.querySelector('.download-mp3-btn');
            const mp4Btn = videoElement.querySelector('.download-mp4-btn');
            
            mp3Btn.addEventListener('click', () => {
                this.downloadAudioDirect(video.url, video.title);
            });
            
            mp4Btn.addEventListener('click', () => {
                this.downloadVideoDirect(video.url, video.title);
            });
            
            this.searchResultsList.appendChild(videoElement);
        });
    }
     
     handleSearchInput(value) {
         clearTimeout(this.searchTimeout);
         
         if (value.length < 2) {
             this.hideSuggestions();
             return;
         }
         
         this.searchTimeout = setTimeout(() => {
             this.fetchSuggestions(value);
         }, 300);
     }
     
     async fetchSuggestions(query) {
         try {
             const response = await fetch(`/api/search-suggestions?q=${encodeURIComponent(query)}`);
             const suggestions = await response.json();
             
             if (suggestions.length > 0) {
                 this.displaySuggestions(suggestions);
             } else {
                 this.hideSuggestions();
             }
         } catch (error) {
             console.error('Öneri alma hatası:', error);
             this.hideSuggestions();
         }
     }
     
     displaySuggestions(suggestions) {
         this.searchSuggestions.innerHTML = '';
         this.currentSuggestionIndex = -1;
         
         suggestions.forEach((suggestion, index) => {
             const suggestionElement = document.createElement('div');
             suggestionElement.className = 'search-suggestion-item';
             suggestionElement.innerHTML = `
                 <i class="fas fa-search search-icon"></i>
                 <span class="search-suggestion-text">${suggestion}</span>
             `;
             
             suggestionElement.addEventListener('click', () => {
                 this.selectSuggestion(suggestion);
             });
             
             this.searchSuggestions.appendChild(suggestionElement);
         });
         
         this.showSuggestions();
     }
     
     selectSuggestion(suggestion) {
         this.searchInput.value = suggestion;
         this.hideSuggestions();
         this.searchVideos();
     }
     
     showSuggestions() {
         this.searchSuggestions.style.display = 'block';
     }
     
     hideSuggestions() {
         this.searchSuggestions.style.display = 'none';
         this.currentSuggestionIndex = -1;
     }
     
     handleSearchKeydown(e) {
         const suggestions = this.searchSuggestions.querySelectorAll('.search-suggestion-item');
         
         if (e.key === 'ArrowDown') {
             e.preventDefault();
             this.currentSuggestionIndex = Math.min(this.currentSuggestionIndex + 1, suggestions.length - 1);
             this.highlightSuggestion(suggestions);
         } else if (e.key === 'ArrowUp') {
             e.preventDefault();
             this.currentSuggestionIndex = Math.max(this.currentSuggestionIndex - 1, -1);
             this.highlightSuggestion(suggestions);
         } else if (e.key === 'Enter') {
             e.preventDefault();
             if (this.currentSuggestionIndex >= 0 && suggestions[this.currentSuggestionIndex]) {
                 const suggestionText = suggestions[this.currentSuggestionIndex].querySelector('.search-suggestion-text').textContent;
                 this.selectSuggestion(suggestionText);
             } else {
                 this.searchVideos();
             }
         } else if (e.key === 'Escape') {
             this.hideSuggestions();
         }
     }
     
     highlightSuggestion(suggestions) {
          suggestions.forEach((suggestion, index) => {
              suggestion.classList.toggle('highlighted', index === this.currentSuggestionIndex);
          });
      }
      
      async downloadAudioDirect(url, title) {
          if (!this.isValidYouTubeUrl(url)) {
              this.showError('Geçersiz YouTube URL');
              return;
          }
          
          this.hideError();
          const progressInterval = this.showDownloadProgress(`"${title}" MP3 indiriliyor...`);
          
          try {
              const response = await fetch('/api/download-mp3', {
                  method: 'POST',
                  headers: {
                      'Content-Type': 'application/json'
                  },
                  body: JSON.stringify({ url })
              });

              if (!response.ok) {
                  const errorData = await response.json();
                  throw new Error(errorData.error || 'MP3 indirilemedi');
              }

              // Complete progress
              clearInterval(progressInterval);
              this.hideDownloadProgress();

              // Create download link
              const blob = await response.blob();
              const downloadUrl = window.URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = downloadUrl;
              // Türkçe karakterleri destekleyen dosya adı temizleme
              const cleanTitle = title
                  .replace(/[<>:"/\\|?*]/g, '') // Dosya sisteminde yasak karakterleri kaldır
                  .replace(/\s+/g, '_') // Boşlukları alt çizgi ile değiştir
                  .substring(0, 100); // Dosya adını 100 karakterle sınırla
              a.download = `${cleanTitle}.mp3`;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              window.URL.revokeObjectURL(downloadUrl);



          } catch (error) {
              clearInterval(progressInterval);
              console.error('MP3 indirme hatası:', error);
              this.showError(error.message || 'MP3 indirme sırasında bir hata oluştu');
              this.hideDownloadProgress();
          }
      }
      
      async downloadVideoDirect(url, title) {
          if (!this.isValidYouTubeUrl(url)) {
              this.showError('Geçersiz YouTube URL');
              return;
          }
          
          this.hideError();
          const progressInterval = this.showDownloadProgress(`"${title}" MP4 indiriliyor...`);
          
          try {
              const response = await fetch('/api/download-mp4', {
                  method: 'POST',
                  headers: {
                      'Content-Type': 'application/json'
                  },
                  body: JSON.stringify({ 
                      url: url,
                      quality: 'highest'
                  })
              });

              if (!response.ok) {
                  const errorData = await response.json();
                  throw new Error(errorData.error || 'MP4 indirilemedi');
              }

              // Complete progress
              clearInterval(progressInterval);
              this.hideDownloadProgress();

              // Create download link
              const blob = await response.blob();
              const downloadUrl = window.URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = downloadUrl;
              // Türkçe karakterleri destekleyen dosya adı temizleme
              const cleanTitle = title
                  .replace(/[<>:"/\\|?*]/g, '') // Dosya sisteminde yasak karakterleri kaldır
                  .replace(/\s+/g, '_') // Boşlukları alt çizgi ile değiştir
                  .substring(0, 100); // Dosya adını 100 karakterle sınırla
              a.download = `${cleanTitle}.mp4`;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              window.URL.revokeObjectURL(downloadUrl);



          } catch (error) {
              clearInterval(progressInterval);
              console.error('MP4 indirme hatası:', error);
              this.showError(error.message || 'MP4 indirme sırasında bir hata oluştu');
              this.hideDownloadProgress();
          }
      }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new YouTubeDownloader();
});