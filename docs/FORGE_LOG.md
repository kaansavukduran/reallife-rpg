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

- Saatlik **RealLife RPG Forge** otomasyonu oluşturuldu ve yeniden okunarak etkin olduğu doğrulandı; zaman dilimi Europe/Istanbul, çalışma ortamı mevcut bulut ortamından devralındı. İlk çalıştırma sonucu henüz yok. Diğer otomasyonlarda değişiklik yapılmadı.

## Manuel öncelikli düzeltme · 9 Kasım 2026 · Sürüklemeli ölçek

- Kullanıcı sabit ölçek düğmeleri yerine yatay sürükleme çubuğunu açıkça istedi; otomasyon turu beklenmeden bu alt iş uygulandı.
- Sabit yüzde seçenekleri kaldırıldı. %80–%200 arası %1 adımlı çubuk, canlı yüzde/boyut örneği, tam yüzde girişi, doğrulama/Escape ve %100 sıfırlama eklendi. Tam arayüz ölçeği sürükleme bitince uygulanarak rayın yer değiştirmesi ve her pointer hareketinde dosya yazma önlendi.
- 176 Flutter testi ve temiz analiz; gerçek pointer ile iki yönlü sürükleme, ray sabitliği, ara yüzde, %137, kayıt/yeniden açılış, sınırlar ve dar ekran doğrulandı. Tarayıcı smoke kontrolüne tam ray üzerinden normal fare sürüklemesi eklendi; erişilebilir normalleştirilmiş thumb eylemiyle karıştırılmadı.
- Güncel dört platform CI/yayın sonucu bu kayıt yazıldığında bekleniyor; önceki sürüm kanıtı yeni paket başarısı sayılmadı. Sonuç geldikten sonra kaynak SHA/CI/sürüm makbuzu eklenecek.
- F010'un RGB ve diğer sayısal ayar parçaları açık kalıyor; tüm F010 tamamlandı sayılmadı.

### Ölçek düzeltmesinin yayın makbuzu

- Uygulama kodu: `8f41bd27be6068d141295f1d23ecaf18b24a5bf8`.
- [CI 42610769842](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42610769842): altı iş başarılı; masaüstü açılışları, Android emülatörü ve web fare/kayıt/yedek kontrolleri geçti.
- [v0.1.0-build.4](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.4): EXE, Windows ZIP, DMG, macOS ZIP, Linux tar.gz, APK ve SHA256SUMS `uploaded`; kaynak SHA aynı. Önceki bekleyen CI kaydı bu makbuzla kapandı.
- Manuel kilit bırakıldı. Sonraki Forge F010'un kalan RGB/önceki-yeni renk ve diğer sayısal görünüm ayarlarından devam edecek; yeni ölçek çubuğu tamamlanmış alt iştir. Bu kapanış yalnız belge değişikliğidir.


## Spor, beslenme, referans karakterler ve web yayın akışı · 9 Kasım 2026

- Kullanıcının yeni kapsamı önceliklendirilerek yalnız bu repo değiştirildi. Günlük Görevler ve Besin Matriksi salt okunur referanslardır; diğer otomasyonlar değiştirilmedi. Çalışma kilidi `manual-fitness-companions`.
- 76 hareket, kas/ekipman arama ve filtre, ana/yardımcı kas haritası, elle hareket tanımı; program/gün/sıra/set/tekrar/yük/dinlenme; yalnız işaretlenen gerçek setler ve anlık görüntülü tarihli kayıt. Sekiz kardiyo türü, gerçek süre/hız/eğim, isteğe bağlı kg, açık ACSM/MET yöntemi ve bilinmeyen kalori ayrımı.
- USDA seçkisinden 362 biçim/20 bileşen; gram, öğün planı, ayrı yenen işareti, manuel besin/hedef ve günlük matriks/kapsama. IFCT aktarılmadı; kaynak dosya/commit/SHA ve MIT/CC0/OFL bildirimleri korundu. Özel kişisel program veya sağlık verisi gömülmedi.
- Kullanıcı referanslarından Aion/koyun/kurt/Baykuş Ömer seçimi; paylaşılan 2D eklemli karakter, hareket ailesi/alet sahnesi, yaban mersini/okuma; oynat/duraklat/aşama ve azaltılmış hareket. Bunlar 3D modeller veya uzman doğrulamalı eksiksiz teknik gösterim değildir.
- Biçim 4 / life 2, eski biçim 1/2/3 göçü ve daha eski uygulamanın yeni veriyi reddetmesi için sürüm kapısı. TR/EN merkezi yeni akışlar, cihaz dili/varsayılan TR/kalıcı tercih, bağımsız yazı boyutu ve Türkçe kapsamı doğrulanmış özgün OpenDyslexic OTF. UI ölçeği yeni kullanıcı standardıyla %5 çubuk adımı, %137 gibi tam girdi, hazır ölçekler ve gerçek %200/yatay kaydırma.
- Yerel kanıt: 193 Flutter testi, 5 Python HTTP/puan doğrulama testi, temiz analiz ve biçim; tarayıcıda mevcut görev/sağlık/fareyle ölçek/HEX/JSON roundtrip ve yeni hareket kare değişimi/USDA öğünü/yenen ayrımı/TR-EN/yeniden açılış. Form kapanışında erken controller dispose gerilemesi testle yakalanıp route.completed beklenerek giderildi.
- GitHub Pages workflow hazırlandı. Hesap ayarını açma API’si 403 verdi; yalnız kullanıcı hesabındaki tek seferlik Pages seçimi açık. Yayımlanmış web varmış gibi sunulmadı.
- Kaynak SHA, güncel dört platform CI/Release ve Drive makbuzları kod push sonrasında eklenecek. Bu satır henüz yeni paket/yayın başarısı değildir.
