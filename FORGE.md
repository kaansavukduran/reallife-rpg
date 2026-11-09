# RealLife RPG Forge kontrol noktası

Tek hedef depo: **kaansavukduran/reallife-rpg**. Çalışma dalı: `main`.
Bu dosya sonraki geliştirme turunun başlangıç noktasıdır; bitmiş uygulamayı her tur yeniden kurma.
Diğer depolar ve onların otomasyonları bu Forge'un kapsamı dışındadır.

## Çalışma kilidi

- Durum: IDLE
- Sahip / tur kimliği: yok
- Başlangıç (UTC): yok
- Geçerlilik sonu (UTC): yok
- Otomasyon: kurulum sürüyor

Çalışmaya başlamadan güncel uzak `main`, açık PR'lar, Actions ve bu dosyayı oku. Kirli çalışma ağacını veya kullanıcının değişikliklerini ezme.
Aktif, süresi dolmamış başka sahipli kilitte kod değiştirme; sonraki tura bırak.
Kod değiştirecek tur, 90 dakikalık kilidini önce bu dosyaya yazıp normal fast-forward push ile alır. Eşzamanlı push reddedilirse yeniden oku; diğer kilidin üstüne yazma.
Uzun turda kendi kilidini süresi dolmadan yenile. Süresi dolmuş kilitte önce sahip turun hâlâ çalışıp çalışmadığını ve yeni commitleri incele.
Tur sonunda sonucu ve tam sonraki adımı kaydet, kendi kilidini IDLE yap. Force push, başkasının commitini geri alma ve veri silme yok.

## Ürün yönü

Gerçek hayatta kendini RPG karakteri gibi geliştir: herkes için Türkçe, kolay kullanılabilir, ayrıntılı özelleştirilebilir ve eğlenceli bir uygulama.
Windows, macOS, Linux ve Android APK ana hedeflerdir. Önceki Günlük Görevler özellikleri ve eski yedek uyumluluğu korunur.
Karakter, meslek, beceri, sağlık, proje, görev, alışkanlık ve deneyim kayıtları tek bir gelişim hikâyesinde birleşir.
AI ölçümü kanıt, yöntem ve ölçüt sürümü gösterir; bir görev tiki veya model yorumu gerçek uzmanlık belgesi sayılmaz.
İlk açılışa kişiye özel isim, görev, rutin, sağlık verisi veya yapılmış iş ekleme. Görevler ancak gerçek kullanıcı işaretiyle tamamlanır.

Son kullanıcı düzeltmeleri:

- Gün ve Görevler ekranında kartları fareyle tutup yukarı/aşağı taşı; telefonda uzun basma ile taşı. Manuel sıra kalıcıdır; saat sırası ayrı tercihtir.
- Hızlı ekleme ve editörde saat görünürdür. Klavyeyle 24 saat biçimi, değiştirme ve kaldırma; not/adım/tik geçmişini koruma gerekir.
- Özelleştirme birkaç hazır temayla sınırlı kalmaz: gerçek renk seçici, ayrı renkler ve ayrıntılı görünüm tercihleri gerekir.
- Oyunlaştırma gerçek ilerlemeye dayanır. Ayar değiştirme, zamanın geçmesi veya boş kayıt XP üretmez. Cesaretlendiren dil, okunurluk ve azaltılmış hareket korunur.

## Doğrulanmış başlangıç

- Son doğrulanmış uygulama kodu: `da584069e95ecacc4088d51a80beb656ea00a251`.
- Sürüm: [v0.1.0-build.3](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.3).
- [Actions 42603763674](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42603763674): başarılı. Windows, macOS, Linux, Android, web ve publish işleri geçti.
- 171 Flutter testi, 5 Python servis testi; temiz `flutter analyze`.
- Masaüstlerinde derleme ve açılış kontrolü; Linux'ta gerçek dosya/yeniden açılış, Android emülatöründe özel klasör/yeniden açılış kontrolü geçti.
- Web'de görev, sağlık kaydı, renk seçimi, JSON dışa/içe aktarma ve yenileme sonrası kalıcılık kontrolü geçti. Renk kontrolünün tarayıcı testinde erişilebilir eylem, fare yollarında Flutter pointer testleri kullanıldı; bunları aynı kanıt gibi sunma.
- Releases: EXE, Windows ZIP, DMG, macOS ZIP, Linux tar.gz, önizleme APK ve SHA256SUMS; kaynak SHA eşleşti.
- SDK: Flutter 3.47.9 / Dart 3.13.7. Mevcut ortam yolu `/workspace/toolchains/flutter/bin`; başka ortamda varlığını kontrol et.

Bu kayıt, daha sonraki kod değişiklikleri için test kanıtı değildir. Yalnız belge/kilit commit'i atılması da yeni uygulama derlemesi sayılmaz.

## Forge kuyruğu ve kabul ölçütleri

Durumlar: TODO / ACTIVE / DONE / BLOCKED. DONE yalnız uygulanmış ve ilgili kabul kontrolü geçmiş iş için kullanılır. Bir engel diğer ilerletilebilir işleri durdurmaz.

| Kimlik | Durum | Somut iş ve kabul ölçütü |
| --- | --- | --- |
| F000 | DONE | İlk RPG sürümü, önceki görev motoru, fareyle sıralama, saat girişi ve ayrıntılı temel renk seçici; yukarıdaki kod/CI/sürüm kanıtları. |
| F010 | TODO | Hassas görünüm kontrolü: arayüz ölçeği için kaydırıcı + yüzdeyi doğrudan yazma + %1 adım + sıfırla. Köşe gibi sayısal görünüm değerlerinde doğrudan giriş ve güvenli sınırlar. Renk seçiciye RGB alanları ve önceki/yeni renk karşılaştırması ekle. Klavye/fare/telefon/yüksek ölçek, geçersiz değer ve yeniden açılış testleri geçsin. |
| F020 | TODO | Paleti tamamla: arka plan geçişinin iki ucu ve XP/ilerleme rengi ayrı ayarlanabilsin; açık/koyu tercih net olsun. Kayıtlı özel tema oluşturma/yeniden seçme ve görünüm yedeğini taşıma ekle. Eski ayarlar açılsın, görev verisi değişmesin, iptal/sıfırlama geri alınabilir olsun. |
| F030 | TODO | Okunurluk ve erişilebilirlik: tüm özel paletlerde yazı, düğme, kart ve arka plan kontrastını kontrol et; görünmez metin/sıfırla düğmesi bırakma. Web semantik tıklama ile gerçek pointer yollarını ayrı kontrol et. Görev sıralamasına klavye erişimi ekle; filtrelenmiş/görünmeyen görevlerin yerleri ve geçmişi korunsun. |
| F040 | TODO | Görev/proje kullanımını genişlet: metin arama, yaşam alanı/proje filtreleri ve açık öncelik yönetimi. Filtre altında manuel sıra ve geri alma doğru kalsın; saat ekleme/değiştirme/kaldırma not, adım ve tikleri bozmasın. Eski yedek göçü ve tüm görev özellikleri korunsun. |
| F050 | TODO | Beceri ölçümünü genişlet: kullanıcı kendi öğrenme alanı/hedefini tanımlayabilsin; uygulamalı kanıtlar, ölçüt sürümü ve değerlendirme geçmişi buna bağlansın. Sabit üç kısa testi kapsamlı uzmanlık ölçümü gibi gösterme. Adaptif soru/uygulama altyapısını sağlayıcı yokken açıkça kapalı tut; anahtarsız sahte AI sonucu üretme. Canlı sağlayıcı ve uzman karşılaştırması yoksa kalite doğrulamasını ayrı açık bırak. |
| F060 | TODO | Meslek ve karakter gelişimini derinleştir: kullanıcı seçimiyle beceri yolları/alt hedefler ve isteğe bağlı başlangıç görevleri; ilk listeye otomatik görev ekleme. Özgün vektörel karakter/yol arkadaşı çeşitleri ve kısa gerçek tamamlama tepkileri. Meslek niyeti, emek sayısı ve ölçülen beceri ayrı görülsün; oyun modu kapalıyken sade kullanım korunsun. |
| F070 | TODO | Sağlık/alışkanlık alanlarını kullanıcı tanımlı hedeflerle zenginleştir: günlük kayıtlarda bilinmeyen değeri sıfır sayma; kişisel gözlemi tıbbi tanı/stat yapma. Tarihli eğilim görünümü ve kullanıcı tanımlı izleyiciler kalıcı ve yedeklenebilir olsun. Sağlık veya ayar kaydından XP doğmasın. |
| F080 | TODO | Android sistem dosya seçicisini gerçek emülatör UI'sıyla uçtan uca doğrula: dışa aktar, seçerek geri al, Türkçe metin, iptal ve bozuk yedekte mevcut veri korunması. MethodChannel ve özel klasör testlerini gerçek seçici kanıtı yerine kullanma. İlgili CI kontrolünü kur ve kaynak SHA'sını kaydet. |
| F090 | TODO | Son kabul: yukarıdaki işler için masaüstü/telefon/yüksek ölçek ve gerçek fare/klavye kontrolleri; eski yedekler, yeniden açılış ve veri kaybı korumaları; dört platformun yeni SHA'da başarılı paketleri; README/özellik eşlemesi/sürüm notları yalnız fiilen yapılanları anlatsın. |
| H010 | BLOCKED | Kalıcı Android dağıtım imzası ve mağaza yayını: kullanıcıya ait güvenli anahtar/secret ve dağıtım tercihleri yapılandırılmadı. Mevcut APK geliştirme imzalı önizlemedir. Sırrı kaynak koda, günlüğe veya artefakta koyma; bir başka reponun izin hatasını bu repo için kanıt sayma. |
| H020 | BLOCKED | Canlı AI kalitesi ve gerçek cihazda son kullanıcı kabulü: sağlayıcı anahtarı/uzman örneklemi ve fiziksel cihaz sonuçları henüz yok. Test doubles, emülatör veya CI açılışı bunları tamamlamış sayılmaz. |

## Tam sonraki Forge

**F010:** `AppSettings` / `Appearance`, `SettingsPage` ve `AppearanceSettings` üzerinden hassas ölçek girişini uygula; renk seçicide RGB ve önceki/yeni rengi tamamla.
Önce mevcut ayar ve UI testlerini oku, değişikliği dar kapsamlı tut. Eski yedek ve ayarları açmayı koru. İlgili testleri çalıştır; yeni davranış gerçekten doğrulanınca F010'u kapat.

## Her turda çalışma ve yayın

1. Güncel uzak dal, bu dosya, açık PR/Actions ve yerel değişiklikleri kontrol et; kilit al. Son kullanıcı talimatı bu dosyadan üstündür.
2. Kuyruktaki ilk ilerletilebilir işi seç. Küçük somut bir parçayı uygula; yalnız plan veya eksik listesi yazarak kod işini tamamlandı sayma. Kullanıcının sınırlandırılmış kuyruğuna ilgisiz ürün/kapsam ekleme.
3. İlgili anlamlı testleri ve zorunlu analiz/biçim kontrollerini çalıştır. Kontroller geçtikten sonra yeni değişiklik veya gerçek şüphe olmadan aynı testleri sonsuz tekrar etme. Gerekirse yeni davranışın kontrolünün hatayı yakaladığını dar bir mutasyonla göster ve mutasyonu geri al.
4. Kendi değişikliğini normal commit/push ile kaydet. Eşzamanlı uzak değişiklikte yeniden oku; kullanıcı işini ezme. Kod değişikliğinin Actions sonucunu izle, hatayı ilgili logdan düzelt.
5. Dört platform geçmeden yayın yok. Mevcut `release.yml` ana dalda numaralı ön sürüm üretir; eski sürümleri/tagleri silme veya taşıma. Mağaza yayını veya kalıcı imza varmış gibi sunma. Releases varlıklarını ve kaynak SHA'yı doğrula.
6. Bu dosyada fiilen biten, kalan, engel ve tek sonraki adımı güncelle; `docs/FORGE_LOG.md` sonuna kısa kanıt kaydı ekle; kendi kilidini kaldır.
7. Kullanıcıya yalnız somut yeni gelişmeyi, önemli yeni engeli veya kapanışı kısa Türkçe bildir. Aynı kapsamı/indirme listesini her tur baştan anlatma; ilerlemesiz rutin bildirim gönderme.

## Bitiş ve gerçek engeller

F010–F090 kabul ölçütleri gerçek kanıtla kapanınca yalnız bu RealLife RPG otomasyonunu durdur, son sürümü ve açık insan kabulü/imza sınırlarını bildir.
İlerletilebilir iş kalmaz ve yalnız kullanıcı kimliği, secret, gerçek cihaz veya erişim gerektiren engeller kalırsa bunları açıkça kaydet; tamamlandı deme. Kullanıcıya somut gereksinimi bildirip yalnız kendi otomasyonunu duraklat; aynı değişmemiş engeli saatlerce yeniden deneme.
Diğer projelerin otomasyonlarını değiştirme. Ortam/erişim yoksa başarı veya kesintisiz çalışma iddiasında bulunma.
