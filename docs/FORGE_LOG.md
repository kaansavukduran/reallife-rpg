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

- Yayın öncesi düzeltme: ilk CI web smoke, dialog çıkışından önce kayıt varmış gibi okuduğu için zamanlama yarışıyla durdu; uygulama/yerel akış kayıtları çalıştı. Test artık sabit gecikme yerine gerçek localStorage durumunu bekliyor. Bu başarısız turdan Release üretilmedi.
- Kullanıcının ana sayfa düzeltmesi: yeni kullanıcı için açık `aion` varsayılanı ve ana kartta karakter adı + doğrudan “Yol arkadaşını değiştir” eylemi. Diğer kayıtlı karakterler korunur.
- `80873282d09544445d85f492144a157db1d54ed6` kaynak ZIP/Git bundle özel Drive proje klasörüne yüklendi; uzak dosyalar geri indirildi, byte/SHA-256 eşleşmesi, ZIP CRC ve git bundle verify geçti. Sonraki kod push için ayrıca yedek makbuzu alınır.

## Kullanıcı kapsamı · görev XP’si, ders/program, besin tekrarları ve hayat ağacı · 9 Kasım 2026

- Aion varsayılanı ve pembe/mavi marka/kurulum simgeleri; dört ayrı uygulama içi logo seçimi, mevcut Yazı stili seçeneklerinde OpenDyslexic. Eski karakter/tema ve JSON verileri korunur.
- Ders/isteğe bağlı ünite adları/gerçek ünite tikleri; spor ve ders kaynaklarının mevcut görev motoruyla atomik bağı. Seçilen hafta günleri, 24 saat girişi ve isteğe bağlı dakika aralığı. Silme/sonlandırma eski tikleri korur; iki bağımsız takvim doğrusu veya yinelenen otomatik görev yaratılmaz.
- Son düzeltme uygulanmıştır: solda Yapılamadı düğmesi yok; sağda Yapıldı başparmağı var. Süre dolması yalnız türetilmiş durumu/değerlendirmeyi değiştirir, dosya/tik/XP yazmaz. Ertesi gün eski tarihe tik konması günlük ve haftalık sonuçları yeniden hesaplar.
- Zorluk artık 0–100 arasında birer XP adımlı çubuk. Eski 10/20/35 değerleri göç eder; 0 kendi ödülünü kapatır. Ödül temel XP’si tik anında saklanır; sonraki görev ayarı geçmiş ödülü değiştirmez. Gerçek tarayıcı hızlı ok tuşlarında kayıp adım buldu; odak düğümünde ardışık değer tutularak düzeltildi ve kare arası pump gerektirmeyen regresyon testi eklendi.
- Resmî USDA SR28 arşivi yeniden alınıp SHA-256 `8308fd1d224ef1e5331093748007180da01a7ac713cbac6a1f5bc2a03e1ee70a` ile doğrulandı; 8.789 besin ve 20 bileşen birimleri ham kaynaktan derlendi. Referans seçki çevirileri korunur, değerler yalnız resmî kaynaktandır. Hassas g/kg, gram çubuğu, seçili günlerde öğün birleşimi tekrarı; yendi otomatik olmaz, değiştirme/atlama anlık görüntüleri korunur. Gün/hafta besin − brüt egzersiz aritmetiği eksik veri kapsamı gösterir, gerçek TDEE/kalori açığı sayılmaz.
- Boy/kg ve açık yetişkin BKİ referansı; kullanıcı kök/ana dal seçebilen hayat ve pasif ağaçlar, döngü/çapraz ağaç reddi, silerken çocukları koruma, gerçek görev temel XP’siyle alan seviyesi ve üst dal gereksinimi. Haftalık 0–10 puan gerçek uygun görev oranıdır; rastgele olan 10 banttaki üçer destekleyici mesajdır. Besin/kilo puanlanmaz. Seçili karakterin mutlu/nötr/düşünceli yüzleri, uygulama genelinde fareye bakış ve bölgesel sonlu dokunma tepkisi; azaltılmış hareket, kozmetik 0 XP korunur.
- Yerel kanıt: temiz analiz/biçim/diff, eski yedekler ve 222 Flutter testi; 5 Python servis testi. Ek alan testleri süre/gece yarısı, zaman geçişinde yazmama, geçmiş tik düzeltme, atomik rutin ve tekillik, öğün projeksiyonu/atlama, ağaç döngüsü ve gerçek XP; TR/EN, telefon/%200, font, kayıt/yeniden açılış.
- Tarayıcı: üç smoke akışı geçti. Eski görev/sağlık/HEX/JSON roundtrip ve gerçek ölçek faresi; hareket/kas/gram/yenen/ders/ünite/BKİ/TR-EN; semantik kapalı gerçek Canvas fare + Home/End/hızlı oklarla 73 XP ve fareyi izleyen karakter, semantik ana dal seçimi/yeniden açılış. Semantik form eylemleri ve gerçek pointer kanıtları ayrı tutuldu; sentetik fill yerine gerçek klavye girdisi kullanıldı.
- Bu kayıt henüz yeni GitHub paketlerinin başarı kanıtı değildir. Kod SHA’sı, Actions/Release ve özel Drive ZIP/bundle/Release geri okuma makbuzu kod push sonrasında ayrı satırda eklenecek. Pages GET hâlâ 404; önceki ayar açma POST isteği 403 olduğundan hesap sahibinin tek seferlik Pages seçimi açık engeldir.

### Yayın ve yedek kapanış makbuzu

- Uygulama kaynak SHA: `355effd11b946c9b406177a6722dbe8a01619771`. [CI 42637586068](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42637586068): Windows/macOS/Linux/Android/web/publish başarılı; Pages hesap ayarı olmadığı için açıkça skipped. Önceki başarısız CI 42620533259'dan sürüm üretilmedi.
- [v0.1.0-build.6](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.6) ön sürümü aynı SHA'ya bağlı. Altı numaralı platform paketi + SHA256SUMS `uploaded`; altı dosya GitHub'dan indirilip checksum ile doğrulandı. Eski v3/v4 sürüm ve tagler korundu. Android test imzalı, masaüstü paketleri dağıtım imzasız; mağaza veya kalıcı imza yayını yapılmadı.
- 222 Flutter testi, 5 Python testi, temiz analiz/biçim/diff; üç browser smoke. Hızlı klavye tekrarını da içeren gerçek Canvas fare/Home/End/oklarla 73 XP; kayıt/yeniden açılış, kullanıcı ana dalı, telefon/%200/azaltılmış hareket ve eski yedekler geçti. Canlı AI, fiziksel cihaz kabulü ve Android gerçek dosya seçicisi tamamlandı sayılmaz.
- Özel Drive proje klasörü: kaynak ZIP `12.911.316` byte, SHA-256 `3db43f3d7626225567a253e386283067be5a56aacba01d77e6db4925edd89647`; kod push anındaki tam geçmiş bundle `15.631.967` byte, SHA-256 `2b41f10419b543aa96bcb7cb3d85adfa71fef7fba42ab3c26195d5262535060e`. İkisi geri indirilip SHA/ZIP CRC/git bundle verify ile doğrulandı.
- `Sürümler/v0.1.0-build.6`: altı paket, kaynak ZIP, v6 tagini de içeren tam geçmiş bundle, checksum, notlar, kaynak/sürüm/CI metadata ve manifest gerçek dosyalardır. Kaynak ve altı paket ile bundle Drive'dan geri indirildi: sekiz SHA-256 eşleşti, ZIP/APK CRC ve tam bundle verify geçti. Release bundle SHA-256 `d9b35a27c316ddaceb6b786332e9c412a9b54dff3a321f9146002e0612bfdbc3`. Klasör listelemesinde tüm dosyalar shared:false; geri okuma makbuzu ayrıca yüklendi. Özel bağlantılar genel depoya yazılmadı.
- F100 çekirdek kabulü kapandı. F010–F090 ve F101–F103'ün kalan kabul işleri açık olduğu için yalnız bu projenin Forge otomasyonu durdurulmadı; başka proje/otomasyon değiştirilmedi. Kendi `manual-fitness-companions` kilidi bırakıldı. Bu kapanış yalnız belge değişikliğidir, yeni uygulama derlemesi değildir.
- Tek sonraki dar iş: F101'de yeni ifade atlasının baş/boyun/gövde birleşimini ve hareket poz yerleşimini görsel olarak düzeltmek; dört karakterde mutlu/nötr/düşünceli, gerçek kare, telefon ve azaltılmış hareket kanıtını korumak. Tamamlanmış XP/ölçek çubuğu, ders ve besin çekirdeği yeniden kurulmaz.

## F101 · sabit çene eklemi ve gerçek portre sınırları · 9 Kasım 2026

- Güncel uzak main/açık PR/Actions ve iki Forge dosyası canlı okundu; temiz yerel dal uzak main ile aynıydı. `forge-f101-atlas-joints` kilidi koddan önce normal push ile alındı. Başka repo veya otomasyon değiştirilmedi.
- Asıl hata ölçüldü: 1254×1254 ifade atlasındaki resimler 3×4 eşit hücrelere oturmuyor; eski kesim sonraki satırın kulak/yün parçasını alabiliyor, çene/yüz merkezi ve ölçek ifade değişince kayıyordu. Kaynak PNG'lere dokunmadan on iki gerçek portre sınırı, opak çene ve gerçek göz bölgeleri tanımlandı. Oran korunur, tüm ifadeler tek atlası paylaşır, baş çene ekleminden döner; dokunma sınırı ve ayrı uygulama içi logolar aynı haritayı kullanır. Reverse pec deck oturuşunda diz/ayak yerleşimi düzeltildi.
- 236 Flutter testi geçti; temiz analiz/biçim/diff. Yeni testler gerçek asset/painter pikseli, çene-bağlantı sürekliliği, göz konumu, komşu parçanın bağlı bileşeni ve iki pozdaki gerçek resim farkını kontrol eder. Eski grid kesimi kontrollü mutasyonda testi bozdu, kaynak anında geri kondu ve test tekrar geçti. Varsayılan veri/tik/XP ve kalıcı karakter, azaltılmış hareket kontrolleri korundu.
- Dört karakter × üç ifade için boşta/okuma/reverse kapalı/açık gerçek renderer dökümleri görsel incelendi. Tarayıcıda dört karakter seçimi ve duraklatılmış resim karesi; 390×844 telefonda gerçek %200/yatay-dikey kaydırma ve azaltılmış harekette sabit portre geçti. Mevcut gerçek Canvas fare/Home/End/hızlı oklarla 73 XP, fare bakışı, kullanıcı ana dalı ve yeniden açılış smoke da geçti. Yalnız tercihler hazırlanmış test fixture'ıdır; görev/tik/yapılmış antrenman eklenmedi.
- Kaynak SHA/Actions/Release/Drive makbuzu kod push sonrası eklenecek; önceki v6'nın başarısı bu kod için yeni platform kanıtı sayılmaz. F101'in yatar/eğilen ailelerinde kadraj ve diğer hareket ayrıntıları açık; bütün egzersizlerin uzman doğrulaması iddia edilmez.

### F101 · web kapısındaki odak düzeltmesi

- `b901a5ffa9af3bb67a9df570700702d0ab7a7439`, CI `42648096287`: Windows/macOS/Linux/Android başarılı; web'de `wellness_smoke.cjs:69` boy/kilo kaydını beklerken zaman aşımına uğradı. Publish/Pages atlandı; bu turdan v7 sürümü yayımlanmadı. İş logu GitHub bağlayıcısından canlı okundu; doğrudan log blob indirmesi 403 verdiği için erişilebilir bağlayıcı kullanıldı.
- Klavye alanına yalnız DOM odağı vermek yerine fiziksel tıklama + iki çizim karesi sonrasında gerçek tuşlarla girilir; alanın yazılan değeri koruduğu ve model kaydı ayrı doğrulanır. Başarısızlıkta yalnız boş tarayıcıdaki sentetik test değerleri ve ekran kaydedilir. Workflow hata ekranlarını saklar. Kontrol atlanmadı, yanlış değer kabul edilmedi; yerel spor/besin/ders/boy-kilo/TR-EN/yeniden açılış smoke yeniden geçti.
- b901 kod push yedeği de korundu: kaynak ZIP SHA-256 `589ef97db1350e4d3f01116e90f1448b3d4f81414c4d5db5826e04d5b3fe3431`, tam Git bundle `6a4f455255175c4d39a9da969283cb542074202d45bdb7621059978f7eea88f0`; özel Drive'dan ikisi geri indirilip SHA/ZIP CRC/bundle verify geçti. Yeni kod push'unun ayrıca yedek ve CI makbuzu alınacak.
