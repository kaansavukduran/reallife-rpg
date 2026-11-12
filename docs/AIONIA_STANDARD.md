# RealLife RPG · AIONIA v1.1 uygulama kaydı

Normatif kaynak: [AIONIA Evrensel Dijital Ürün, Tasarım ve Kalite Standartları](https://docs.google.com/document/d/16jj2cwbm8SiVWqDy3N3dzqxTlLoK7JR2_aH6hl4noWY/edit), v1.1, 12 Kasım 2026 tarihinde canlı okundu. Belgenin 11. bölümü önceki Godot/pixel art merkezli kapsamı geçersiz kılar. Son kullanıcı talimatı önceliklidir.

## Ürün, kullanıcı ve bağlam

RealLife RPG; günlük görev, alışkanlık, ders, spor ve beslenme kayıtlarını isteğe bağlı RPG ilerlemesiyle birleştiren kişisel uygulamadır. Temel vaat: **Bugün yapacağını seç, gerçekten yaptığında işaretle, ilerlemeni kaybetmeden devam et.** Görev sayısı uzmanlık, sağlık kaydı tanı, puan da sertifika değildir. Yapılmamış iş otomatik tamamlanmaz.

Hedef bağlamlar: Türkçe veya İngilizce kullanan yeni/deneyimli kullanıcı, klavyeyle masaüstü kullanımı, telefonda dokunma, büyütülmüş metin ve düşük dijital okuryazarlık. Tüm yaşlar/engeller/cihazlar için doğrulanmış uygunluk iddiası yoktur. Gerçek kullanıcı çalışmaları ve yardımcı teknoloji kabulü açık işlerdir.

Teknoloji: mevcut Flutter/Dart; Windows, macOS, Linux, Android ve tarayıcı. `TaskController` → değişmez `TaskData` → mevcut platform depoları. Yeni framework, motor, bağımlılık veya veri şeması eklenmedi. Eski JSON göçleri ve kullanıcı tercihleri korunur.

## Önce çalışan temel deneyim

1. Maceram'da Yeni görev ile kullanıcı kendi görevini ekler; ilk açılışa örnek kişisel görev yazılmaz.
2. Bugünkü görevler karakter görselinden önce görünür. Kutu tamamlar, görev adı editörü açar. İlk dört satır manuel sırada kalır; daha uzun liste açık sayımla Gün'e yönlenir.
3. İşaretlenen görev kaybolmaz. Klavye odağı aynı kutuda kalır; Space tekrar kaldırabilir. Tamamlandı/Bekliyor metni renk dışı durum bilgisidir.
4. Geri al yalnız o görevin o günkü işaretini ve özgün ödülünü geri getirir. Başka görevler, geçmiş günler, başlık/not/XP ayarı korunur. Daha yeni tik/adım değişikliği veya silinen görev için eski geri alma reddedilir.
5. Mevcut kayıt kuyruğu ve hata bandı kullanılır. Bildirim “işaretlendi” der; diske yazma başarısızken “kaydedildi” demez. Yeniden açılış ve hata sonrası yeniden kayıt test edilir.

## Görsel kimlik ve bileşen kararları

Marka adı RealLife RPG olarak kalır. Mevcut Aion pembe/mavi teması, açık/koyu/yüksek kontrast ve özel palet tercihleri korunur. Yeni kart mevcut Material/`LifeCard`, tema renkleri ve yazı hiyerarşisini kullanır. Görev kontrolleri en az 48 mantıksal piksel dokunma hedefi taşır; uzun adlar sarılır. Animasyon veya yalnız renk üzerinden zorunlu bilgi verilmez. Mevcut %200 arayüz tercihi dar ekranda küçültülmez; 360 mantıksal piksel tabanı nedeniyle yatay kaydırma gerekebilir. Bu tur tam WCAG yeniden akış uygunluğu iddiası değildir.

AIONIA evreni/pixel art bu verimlilik akışına zorla eklenmez. Bu sürüm karakter veya logo üretmez, yeniden tasarlamaz. [Resmî referans klasörü](https://drive.google.com/drive/folders/1CXbBM41DUkPYJwyuKTdcsmW2UmjKBE95) ve 00_BAŞLA okuması, dosya adındaki “canonical” ifadesinin sanat onayı olmadığını belirtir. Fragaria çileği kesin logo olarak doğrulanmamıştır; Tavşan Emre için yalnız pafta listelenmiştir. Onaysız varyantlar kesin kanon kabul edilmez. Mevcut karakter dosyaları bu değişiklikte korunur.

## Güvenlik, mahremiyet ve sürdürülebilirlik

Görev/sağlık verisi mevcut cihaz deposundadır; tarayıcıda origin'e özgü localStorage kullanılır. Bu alan uçtan uca şifreli kasa değildir ve site verileri silinebilir; JSON yedeği gerekir. Bu tur yeni telemetri, uzak servis veya izin eklemez. Tarayıcıda gözlenen varsayılan Google CanvasKit/Roboto istekleri kaldırılır: renderer aynı origin'deki `canvaskit/` dizininden, Roboto uygulama varlıklarından yüklenir. Bu, önceden ziyaret edilmemiş sitenin internet olmadan açıldığı veya tüm Unicode karakterlerinin çevrimdışı desteklendiği anlamına gelmez. İsteğe bağlı AI servisi farklı bir akıştır: `AI_API_URL` yapılandırması ve sağlayıcı gerekir; gönderilen çalışma örneği uzak sağlayıcıya gidebilir. Bu tur canlı AI veya tüm ürün güvenlik denetimi kanıtı değildir.

Geri alma tüm veri anlık görüntüsünü geri yüklemez; dar kapsamlı güncelleme veri kaybı riskini azaltır. Şema, kilitli bağımlılıklar ve mevcut platform kayıt mekanizması değiştirilmez. Ana sayfa kodu küçük bir `TodayTaskCard` bileşenine ayrılmıştır; metinler merkezi TR/EN kaynağındadır. Kaynak/artefaktlarda secret veya kişisel test verisi bulunmamalıdır.

Performans kapsamı: görev önizlemesi en çok dört satır oluşturur; tüm liste Gün ekranındadır. Ölçülmemiş FPS, bellek, pil, zayıf bağlantı performansı veya hızlanma oranı raporlanmaz. Büyük animasyon paketlerinin maliyeti ve düşük donanım ölçümü sonraki çalışmalardır.

## Kabul ve kalan işler

Test kanıtı, kaynak SHA ve gerçek dağıtım sonucu [FORGE_LOG.md](FORGE_LOG.md) son kaydına yazılır. PASS yalnız o kayıtta çalıştırılan kapsam içindir; bütün AIONIA standardına veya WCAG 2.2 AA'ya uyumluluk ilanı değildir.

- Test hedefleri: boş başlangıç → gerçek editörden ekleme → fare/Space/dokunma → geri alma → yeniden açılış; özgün ödül ve bağımsız düzenleme korunması; telefon %200 ve uzun ad; etiket/kontrast/dokunma hedefi; kayıt hatası; eski testlerin regresyonu.
- Açık: eski görev editörü ve bazı ekranların tam İngilizce çevirisi; tüm özel paletlerde kontrast; ekran okuyucuyla gerçek cihaz kabulü; imzalı mağaza dağıtımı; düşük donanım/ağ ölçümleri; kapsamlı güvenlik incelemesi. Bunlar NOT TESTED veya FORGE'daki mevcut durumlarıyla kalır.
- Otomatik Forge kullanıcının önceki durdurma emriyle kapalıdır. Bu elle başlatılmış geliştirme otomasyonu etkinleştirmez. Önceki çalışma ağacındaki yarım shrug değişiklikleri ayrı korunur.


## v41 gerçek sonuçlar · 2026-11-12

Kaynak `45f594b7a1697566258f0c57fb3555ba8f422343` · [CI 43229878892](https://github.com/kaansavukduran/reallife-rpg/actions/runs/43229878892) · [Release/Latest v0.1.0-build.41](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.41).

| Kontrol | Sonuç | Kapsam / sınır |
| --- | --- | --- |
| Görev ekle → işaretle → geri al → yeniden aç | PASS | Gerçek editör, ayrı Canvas fare ve Tab/Space, tarayıcı dokunma; özgün ödül/zaman ve diğer düzenlemeler korunur. |
| Otomatik test / analiz / biçim | PASS | 518 Flutter, 138 dosya biçim, temiz analiz, 5 servis/7 indeks Python. |
| Tarayıcı regresyonları | PASS | Beş smoke; TR/EN ana sayfa, 390 px ve %200/OpenDyslexic/azaltılmış hareket; %200'de mevcut yatay kaydırma sınırı korunur. |
| Yeni kartın erişilebilirlik kontrolleri | PASS | 48×48 ayrı semantik hedef, etiket/kontrast/Android dokunma hedefi yönergeleri. Tam WCAG veya gerçek ekran okuyucu kabulü değildir. |
| Varsayılan görev akışında mahremiyet | PASS | Üç bağlamda 0 uzak origin isteği; font/renderer yereldir. Kapsamlı güvenlik denetimi değildir. |
| Kayıt hatası ve toparlanma | PASS | Simüle dolu depoda görünür hata; sonraki kayıt ve yeniden açılış doğrulandı. |
| Derleme / yayın / içerik bütünlüğü | PASS | Dört platform + web/publish; altı checksum, dört arşivde 99 kaynak dosyası; normal Latest/tag/kaynak SHA eşleşir. |
| Android APK imzası | PASS | Resmî Google apksig 8.9.2; v40 ve v41 geçerli v2 imzalı önizlemelerdir. Kalıcı dağıtım imzası değildir. |
| Android v40 → v41 doğrudan yükseltme | FAIL | Sertifikalar farklıdır. Önce v40'tan JSON yedeği alıp dosyayı doğrula; kaldırma veriyi siler. Release notuna uyarı eklendi. H010 açık. |
| Tam İngilizce görev editörü | FAIL | Bazı etiket ve düğmeler hâlâ Türkçe; F103 tek sonraki dar iş. Ana sayfa çevirisiyle karıştırılmaz. |
| Fiziksel cihaz / gerçek ekran okuyucu / tüm özel paletler | NOT TESTED | Emülatör ve semantik testler bu kabulün yerine geçmez. |
| Kapsamlı güvenlik / düşük donanım, pil, bellek ve zayıf ağ ölçümleri | NOT TESTED | Ölçülmemiş hız/FPS veya evrensel kullanılabilirlik iddiası yoktur. |
| Canlı GitHub Pages | NOT TESTED | H030 hesap ayarı nedeniyle iş skipped; yalnız yerel alt dizin başlangıcı doğrulandı. |

Bu sürüm ilk çalışan akışın kalite alt işidir. Diğer Forge kabul ölçütleri ve kullanıcı onayı gerektiren varlıklar açık kalır; otomatik Forge kapalıdır.
