# RealLife RPG Forge geçmişi

Bu günlük eklemelidir. Eski tur ve test kanıtlarını silme; yanlış/eski kaydın yanına düzeltme ekle. Güncel kuyruk ve kilit için kökteki `FORGE.md` yetkilidir.

## Kurulum · 9 Kasım 2026

- Kullanıcı saatlik Forge düzeninin bu proje için de kurulmasını istedi. Eski görev uygulamasının Forge'u ayrı tutuldu; başka otomasyon değiştirilmedi.
- Güncel uzak `main`: `da584069e95ecacc4088d51a80beb656ea00a251`.
- [CI 42603763674](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42603763674): başarı; Windows, macOS, Linux, Android, web ve publish.
- [v0.1.0-build.3](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.3): altı uygulama paketi + SHA256SUMS, kaynak kod SHA'sıyla eşleşiyor.
- Başlangıç kanıtı: 171 Flutter ve 5 Python testi, temiz analiz, native açılış/yeniden açılış ve web akışı kontrolleri. Canlı AI ve fiziksel cihaz kabulü henüz yapılmadı.
- Yeni çalışma: kanıtlı başlangıç, çakışma kilidi, sınırlı geliştirme kuyruğu, yayın/raporlama/bitiş kuralları ve sonraki F010 işi tanımlandı. Bu belge kurulumu yeni uygulama özelliği veya yeni platform derlemesi değildir.
- Sonraki adım: F010 hassas görünüm kontrolü, RGB ve önceki/yeni renk önizlemesi.
