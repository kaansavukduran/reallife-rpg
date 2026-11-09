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
