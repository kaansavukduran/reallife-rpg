# Özellik eşlemesi

Günlük Görevler tabanının tüm kullanıcı özellikleri korunur; aşağıdaki regresyon testleri repoyla birlikte taşınmıştır.

| Eski özellik | Ekran | Doğrulama |
| --- | --- | --- |
| Tekrar, başlangıç ve geçmiş kural dilimleri | Gün / Editör | schedule, task_data, controller |
| Not, zorluk, hatırlatma, adımlar | Gün / Editör | format_v2, controller, UI |
| Sıralama, sonlandırma, silme/geri al | Görevler | controller, UI |
| Geçmiş düzeltme, gelecek gün koruması | Kontrol | controller, task_data, UI |
| XP, seviye, stat, unvan, rozet, harita | Karakter | game, UI |
| Günlük/haftalık görev, altın, konfeti | Gün | quests, UI |
| Temalar, oyun modu, ölçek | Ayarlar | settings, UI |
| Atomik dosya, günlük yedek, bozuk dosya koruması | Depolar | file_task_store |
| İçe/dışa aktarım | Ayarlar | storage, codec, UI |
| Android dosya seçicisi ve özel klasör | Android | kanal testleri, özel klasör emülatör testi |

Yeni domain testleri tüm RPG kayıtlarını yedekle/yeniden aç döngüsünden geçirir; eski biçim 1/2 yedekleri, eksik/gelecek sürümü, geçersiz sağlık verilerini, değişmez koleksiyonları ve task değişiklikleri boyunca veri korunmasını denetler. Sayaç testleri duraklama, geciken zamanlayıcı ve onay gereksinimini denetler.

Yeni ekran testleri 360 ve 1200 pikselde düzen taşmalarını, sağlık kayıtlarını ve oyun modunu kapsar. Python testleri boyut/giriş doğrulaması, anahtar yokluğu, gerçek metinde olmayan kanıt, eksik boyut ve hatalı skorları kapsar.

Gerçek Android dosya seçicisinin kullanıcı etkileşimi, ekran okuyucular ve canlı AI sonuçlarının uzmanlarla karşılaştırılması ayrıca manuel kontrol bekler. CI işinin yapılandırılması başarı kanıtı değildir; Actions sonuçlarını ve Releases paketlerini incele.

## Ayrıntılı özelleştirme ve etkileşim

`test/ui/customization_test.dart`: gerçek fareyle Gün/Görevler kartlarını sürükleme ve yeniden açılışta sıra korunması; gizlenmiş/sonlandırılmış görevlerin konumlarının korunması; 24 saat klavye girişi; yakınlaştırılmış telefonda hızlı saat girişi; saat sıralamasının manuel sırayı bozmaması; geçersiz HEX kodu, renk uygula/vazgeç/sıfırla, telefonda renk alanını sürükleme ve tüm görünüm ayarlarının yeniden açılışta korunması.

Hazır tema seçmek özel görünüm ayarlarını sıfırlar. Özel renkler ve diğer görünüm tercihleri cihazın ayarlar dosyasında saklanır; görev sırası ve saatler görev yedeğine dahildir.

## Kaydırmalı arayüz ölçeği

Ayarlar → Görünüm ve boyut bölümündeki sabit yüzde düğmeleri kaldırıldı. Ölçek %80–%200 arasında yatay çubukla %5 adımlarla seçilir. Yüzde ve boyut örneği sürükleme sırasında değişir; çubuğun imlecin altından kaçmaması için tüm arayüz ölçeği bırakınca uygulanır ve bir kez kaydedilir. Tam yüzde alanı Enter/uygula ile çalışır; geçersiz giriş kaydı değiştirmez, Escape kayıtlı değere döner, sıfırla %100 yapar.

`interface_scale_control_test.dart` gerçek fareyi iki yönde sürükler, rayın yer değiştirmediğini, eski sabit değerlere kısıtlanmadığını, kayıt/yeniden açılışı, %137 girişini, hatalı değerleri ve 360/1600 pikselde sınırları kontrol eder. Dar ekranın güvenli ölçek sınırı ve işletim sisteminin metin boyutu korunur.


## Spor / beslenme / karakter entegrasyonu

`test/domain/wellness_test.dart`: 76 hareketin kimlik/kas/serileştirme kontrolü; manuel planın geçmiş/XP üretmemesi; ACSM eğim yüzdesi ve MET hesabı; bilinmeyen kg; program/yük değişiminde geçmiş antrenman anlık görüntüsü; gram ve eksik/gerçek sıfır ayrımı; biçim 3→4 göçü, bozuk/çift kimlikli verinin reddi.

`test/ui/wellness_test.dart`: ana uygulama girişinden örnek plan, tek gerçek set/tekrar, öğün miktarı ve yenen ayrımı, karakter seçimi ve kalıcılık, cihaz EN/varsayılan TR/kalıcı tercih, bağımsız metin boyutu ve OpenDyslexic, üç yeni ekranda gerçek %200 + dar ekran + azaltılmış hareket, reverse pec deck kas etiketleri ve duraklatma. Formlar denetleyicilerini dialog çıkış geçişi tamamlandıktan sonra bırakır.

`tool/wellness_smoke.cjs`: normal web girişinde hareket arama/karakter kare değişimi/kas haritası, USDA besin arama/gram/yenen kaydı, TR/EN ve yeniden açılış. Flutter web semantik eylemleri ile mevcut `browser_smoke.cjs` gerçek pointer ölçek testi farklı kanıtlardır.

362 doğrudan USDA biçimi ve 20 besin bileşeni aktarılır; IFCT değerleri veya tahminleri yoktur. Kaynak SHA ve türetme politikası `docs/sources/NUTRITION_SOURCE.json` içinde. Tüm Besin Matriksi uygulaması veya tüm egzersizlerin/uzmanlık ölçümünün tamamlandığı iddia edilmez.
