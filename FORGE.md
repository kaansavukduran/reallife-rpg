# RealLife RPG Forge kontrol noktası

Tek hedef depo: **kaansavukduran/reallife-rpg**. Çalışma dalı: `main`.
Bu dosya sonraki geliştirme turunun başlangıç noktasıdır; bitmiş uygulamayı her tur yeniden kurma.
Diğer depolar ve onların otomasyonları bu Forge'un kapsamı dışındadır.

## Çalışma kilidi

- Durum: ACTIVE
- Sahip / tur kimliği: forge-f101-atlas-joints
- Başlangıç (UTC): 2026-11-09T15:17:14.204848+00:00
- Geçerlilik sonu (UTC): 2026-11-09T17:45:20.142171+00:00
- Otomasyon: **RealLife RPG Forge**; etkin; her saat; `Europe/Istanbul`.
- Kurulum geri okuması: bulut çalışma ortamı ve `/workspace` seçimi devralındı. Yapılmış işin kanıtı aşağıdaki kaynak SHA/CI/sürüm ve eklemeli günlükte bulunur; etkin plan tek başına geliştirme kanıtı değildir.

Çalışmaya başlamadan güncel uzak `main`, açık PR'lar, Actions ve bu dosyayı oku. Kirli çalışma ağacını veya kullanıcının değişikliklerini ezme.
Aktif, süresi dolmamış başka sahipli kilitte kod değiştirme; sonraki tura bırak.
Kod değiştirecek tur, 90 dakikalık kilidini önce bu dosyaya yazıp normal fast-forward push ile alır. Eşzamanlı push reddedilirse yeniden oku; diğer kilidin üstüne yazma.
Uzun turda kendi kilidini süresi dolmadan yenile. Süresi dolmuş kilitte önce sahip turun hâlâ çalışıp çalışmadığını ve yeni commitleri incele.
Tur sonunda sonucu ve tam sonraki adımı kaydet, kendi kilidini IDLE yap. Force push, başkasının commitini geri alma ve veri silme yok.

## Son kabul edilmiş uygulama

- Kod: `355effd11b946c9b406177a6722dbe8a01619771`.
- [v0.1.0-build.6](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.6), [CI 42637586068](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42637586068): Windows, macOS, Linux, Android, web ve publish başarılı; Pages hesap ayarı olmadığı için atlandı.
- Yeni çekirdek: 0–100 sürüklemeli temel XP ve tik anı ödül kaydı, ders/ünite ve tek görev motoruna bağlı spor/ders programları, saat/süre ve sonradan Yapıldı düzeltmesi, resmî USDA 8.789 besin/20 bileşen, g/kg/gram çubuğu/öğün tekrarları ve gün/hafta kayıt aritmetiği; kullanıcı dallı hayat/pasif ağaç ve gerçek oranlı haftalık değerlendirme.
- Aion varsayılan logo/pembe-mavi tema, dört karakter ve ayrı uygulama içi logo seçimi, fare/bölgesel dokunma tepkisi; görünür OpenDyslexic ve boy/kg/isteğe bağlı yetişkin BKİ referansı. Ayrıntılı hareket duruşu/eklem görseli F101'de açık; canlı AI/uzman sertifikası iddiası yok.
- 222 Flutter + 5 Python testi, temiz analiz/biçim; üç web smoke, gerçek Canvas fare/klavye ile 73 XP ve kalıcılık, seçilen ana dal, telefon/%200/azaltılmış hareket geçti. Veri biçimi 6 / life 4 eski 1–5 yedekleri okur.
- Altı paket + SHA256SUMS yayımlandı; kaynak tag/CI SHA eşleşti, altı indirme SHA-256 ile doğrulandı. Kaynak ZIP/tam Git geçmişi özel Drive'a yüklendi ve ikisi de geri indirilerek SHA-256/ZIP CRC/git bundle verify geçti; sürüm klasöründeki altı paket + kaynak ZIP + release tagli tam bundle geri indirilip sekiz SHA-256 eşleşti. Kapanış günlüğünde makbuz var.

## Ürün yönü

Gerçek hayatta kendini RPG karakteri gibi geliştir: herkes için Türkçe, kolay kullanılabilir, ayrıntılı özelleştirilebilir ve eğlenceli bir uygulama.
Windows, macOS, Linux ve Android APK ana hedeflerdir. Önceki Günlük Görevler özellikleri ve eski yedek uyumluluğu korunur.
Karakter, meslek, beceri, sağlık, proje, görev, alışkanlık ve deneyim kayıtları tek bir gelişim hikâyesinde birleşir.
AI ölçümü kanıt, yöntem ve ölçüt sürümü gösterir; bir görev tiki veya model yorumu gerçek uzmanlık belgesi sayılmaz.
İlk açılışa kişiye özel isim, görev, rutin, sağlık verisi veya yapılmış iş ekleme. Görevler ancak gerçek kullanıcı işaretiyle tamamlanır.

Son kullanıcı düzeltmeleri:

- Gün ve Görevler ekranında kartları fareyle tutup yukarı/aşağı taşı; telefonda uzun basma ile taşı. Manuel sıra kalıcıdır; saat sırası ayrı tercihtir.
- Hızlı ekleme ve editörde saat görünürdür. Klavyeyle 24 saat biçimi, değiştirme ve kaldırma; not/adım/tik geçmişini koruma gerekir.
- Arayüz ölçeğinin ana kontrolü sabit yüzde düğmeleri değil, sağa/sola sürüklenen yatay çubuktur; %1 adım ve canlı yüzde/örnek görünüm gerekir. Bu düzeltme bekleyen otomasyona bırakılmadan uygulanır.
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
| F100 | DONE | Çekirdeğe yeni kullanıcı kapsamı bağlandı: 76 hareket, resmî USDA 8.789 besin/20 bileşen, ders/ünite, spor-ders canonical Günlük Görevler takvimi/saat/süre, öğün tekrarları/g-kg/gram çubuğu, günlük-haftalık aritmetik, boy/kg/yetişkin referansı; Aion marka/tema/logo, görünür OpenDyslexic, kullanıcı dallı hayat/pasif ağaç ve bölgesel karakter/fare etkileşimi. 0–100 temel XP çubuğu ve tik anında ödül anlık görüntüsü; yalnız sağ Yapıldı ve türetilmiş süresi geçti; gerçek görev oranıyla haftalık değerlendirme. 222 Flutter/5 Python/3 browser smoke ve temiz analiz geçti; kod `355effd`, CI `42637586068` ve `v0.1.0-build.6` doğrulandı. Kaynak ZIP/tam Git bundle geri okuması SHA/CRC/verify geçti; altı paket/kaynak ZIP/release tagli bundle özel sürüm klasöründen geri indirildi, sekiz SHA-256 ve ZIP/APK CRC + tam bundle verify geçti; makbuz günlükte. |
| F110 | ACTIVE | Kullanıcı çubuk gövdeli yöntemi reddetti. Dört karakter kendi tam gövdeli cartoon tarzında, ardışık PNG/WebP kareleri/sprite atlası ile çizilir; yüze sonradan çubuk gövde ekleme yok. Hazır Aion Pet kaynağını incele; koleksiyonu değiştirme/etkinleştirme/silme. Boşta, tepki, okuma/ders, beslenme ve sporla ilgili kareler; dört karakter seçimi, telefon/%200, duraklat/kare seçimi, azaltılmış hareket, kalıcılık ve 0 kozmetik XP. Bütün hareketler için doğru kare hazır olmadan aynı genel animasyonu teknik gösterim diye sunma. |
| F111 | TODO | Besin seçicide ilk ekranda 8.789 satır yok: Meyve/Sebze/Baklagil/Tahıl/Kuruyemiş/Süt-Yumurta/Et-Balık vb. kategori → besin → çiğ/pişmiş/biçim hiyerarşisi. Geri/kırıntı yolu ve kategori içi arama; Türkçe kısa ad ve özgün kaynak ayrıntısı, mevcut g/kg/matriks/veri korunur. |
| F112 | TODO | Spor ekranında kas grubuna tıklanınca o kası çalıştıran alternatifler. İzole ve bileşik (çok eklemli) ayrımı, ana/yardımcı kas, ekipman filtreleri ve kullanıcı hareket eklemesi; mevcut 76 kayıt ve program/set geçmişi korunur. Sınırlı kataloğu tüm dünyadaki hareketler bitmiş gibi sunma. |
| F114 | ACTIVE | Elle besin eklerken gereksiz Yedim kutusunu kaldır; bugün/geçmiş yeni kayıt yendi, gelecek kayıt plan. Sonraki listede tik görünür ve değiştirilebilir; eski kaydın durumu ve otomatik şablonlar korunur, besin XP üretmez. |
| F115 | ACTIVE | Tüm Görevler kartında sağda doğrudan Yapıldı tiki, açık tik tarihi ve geçmiş gün düzeltmesi; karta basma düzenleme olarak kalır. Fare/klavye/telefon, yinelenen ve tek seferlik görev, kayıt/yeniden açılış ve Gün ekranıyla ortak tamamlanma/XP kaydı doğrulanır. Gelecek güne tik yok, ayar/zaman geçişi XP yaratmaz. |
| F113 | TODO | Ayarlar geniş yan menü ve telefon çekmecesindeki seçeneklerin en sonunda, normal kaydırma ve klavye ile erişilir. Önceki saat/sıra/kayıt ve kısayollar korunur. |
| F101 | ACTIVE | Önceki çubuk rig yaklaşımı yeni kullanıcı talimatıyla ürün kabulünden çıkarıldı; yalnız atlas kesim düzeltmesi yapılmıştı: 12 gerçek sprite sınırı/çene noktası, tek atlas/korunan oran, çene etrafında fare dönüşü, temiz uygulama içi logo ve oturan reverse pec deck; 236 Flutter testi + anlamlı eski grid mutasyonu ve tarayıcı/telefon kanıtı geçti. Yeni kaynak SHA/CI/sürüm makbuzu bekliyor. Kalan: yatar/eğilen ailelerin kadrajı ve harekete özel kurulum/duruş; daha çok hareket/ekipman, mevcut aile animasyonlarının ayrıntısı, isteğe bağlı haftalık kas hacmi görünümü. Basitleştirilmiş karakter çizimini uzman doğrulaması veya bütün egzersizler tamamlandı diye sunma. Kullanıcı programı/gerçek geçmiş ayrımını ve bilinmeyen kg/enerjiyi koru. |
| F102 | TODO | Besin Matriksi entegrasyonunu ilerlet: 8.789 resmî besin/20 bileşen ve seçili gün öğün şablonları tamamlandı. Daha geniş bileşen kapsamı, tarif/porsiyon ve karşılaştırma; mevcut tekrarları ve gram kaydırıcısını yeniden yapma; lisansı belirsiz IFCT verisini yeniden ekleme. İlk 362/20 aktarımı bütün Besin Matriksi uygulaması değildir. Eksik ve sıfır, çiğ ve pişmiş ayrımı sürsün. |
| F103 | TODO | Eski ekranların TR/EN çevirisini merkezi kaynaklara taşı; mevcut eski TR akışları tam İngilizce diye sunma. Yeni dil, yazı boyutu/font, açık/koyu/sistem/yüksek kontrast ve gerçek %200 korunur. Ürün standardındaki güncelleme bölümü ve imza doğrulayan güncelleyici ile Linux AppImage/deb henüz yok; ayrı dar kabul işleriyle ilerlet, iki gerçek paketle yükseltme kanıtı olmadan kapatma. |
| H030 | BLOCKED | GitHub Pages hesap ayarı: bağlı GitHub uygulaması POST /repos/kaansavukduran/reallife-rpg/pages için 403 Resource not accessible by integration döndürdü. Kullanıcı Settings → Pages → Source: GitHub Actions seçmeli. Kod yayını hazır; ayar yoksa pages işi açık bildirimle atlanır, web artefaktı ve yerel paketler korunur. Yayın URL’si canlı doğrulanmadan başarılı deme. |
| F010 | TODO | Kaydırmalı ölçek/%1/tam yüzde/sıfırla alt işi tamamlandı; 176 Flutter testi ve gerçek tarayıcı fare kontrolü geçti, dört platformun v0.1.0-build.4 paketleri yayımlandı. RGB/önceki-yeni renk ve diğer sayısal ayarlar tamamlanmadı. Hassas görünüm kontrolü: arayüz ölçeği için kaydırıcı (%5 adım) + tam yüzdeyi doğrudan yazma + sıfırla. Köşe gibi sayısal görünüm değerlerinde doğrudan giriş ve güvenli sınırlar. Renk seçiciye RGB alanları ve önceki/yeni renk karşılaştırması ekle. Klavye/fare/telefon/yüksek ölçek, geçersiz değer ve yeniden açılış testleri geçsin. |
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

## En son ek istekler

- Görev XP’si: eski üç sabit düğme yerine 0–100/birer XP adımlı yatay kaydırıcı. Eski 10/20/35 göçü; gerçek fare, Home/End/ok ve hızlı tekrar. Tik anındaki temel ödül kalıcıdır; sonradan çubuğu değiştirmek eski XP’yi değiştirmez. 0 kendi ödülünü kapatır.
- Görev durumu: solda Yapılamadı düğmesi yok; sağda Yapıldı 👍. Saat/süre geçmesi yalnız türetilmiş durumdur, tik veya XP yazmaz; eski gün sonradan işaretlenebilir.
- Ağaç: kullanıcı kök/ana dal seçer, döngü reddedilir; hayat işareti öz beyandır, pasif seviye gerçek görev temel XP’sinden açılır. Karakter fare/dokunma tepkisi kozmetiktir; azaltılmış hareket korunur.
- Dersler: manuel ders adı, seçilen ünite sayısı, isteğe bağlı ünite adları, gerçek kullanıcı işaretiyle ünite ilerlemesi; ders ekleme veya zamanın geçmesi XP/tamamlama üretmez.
- Marka: logo Aion aksolotl, varsayılan yeni kurulum teması Aion pembe tonları ve mavi ikincil vurgu; mevcut özel temayı sıfırlama.
- Disleksi: OpenDyslexic yalnız gelişmiş okuma alanında saklı kalmaz, mevcut Yazı stili seçeneklerinde de görünür; Türkçe kapsamı, bağımsız yazı boyutu ve kalıcılık korunur.

## Yeni kullanıcı kapsamı · Spor, beslenme ve karakterler

Öncelik: kas/ekipman filtreli genişletilebilir hareket kütüphanesi (reverse pec deck dahil), ana/yardımcı kas haritası, hareketin kendisine uygun animasyon; manuel haftalık alt/üst veya başka program, set×tekrar/ağırlık ve gerçek antrenman kaydı. Kardiyo türü/süre/hız/eğim ve açık yöntemli tahmini kalori. Besin Matriksi kaynak lisansları korunarak günlük beslenme/gram/makro kaydı. Kişisel programı herkese zorunlu veya tamamlanmış veri olarak ekleme.

Ana sayfada varsayılan ana karakter açıkça Aion’dur; yeni kayıt `aion` kimliğiyle başlar. Ana kahraman kartından yol arkadaşı seçimi açılır, diğer karakteri seçmek mümkün kalır ve kayıtlı seçim varsayılana zorla döndürülmez.

Gönderilen karakter referansları: pembe/mavi laboratuvar önlüklü Aion, halesi isteğe bağlı krem koyun, mor izli gri kurt ve turuncu Baykuş Ömer. Uygulamada seçilebilir; seçilen karakter hareketi yapar, beslenmede yaban mersini yer. Hareket animasyonu ile ana/yardımcı kas haritası birlikte, duraklat/azaltılmış hareket desteğiyle gösterilir. Gönderilen 2D referansları 3D model/uzman teknik gösterim diye sunma; tüm olası hareketlerin tamamlandığını iddia etme.

Yeni/değişen akışlar merkezi TR/EN, kalıcı dil seçimi; ilk destekli cihaz dili, aksi TR. Yeni kullanıcı standartları: bağımsız yazı ölçeği, %80–200 arayüz ölçeğinde %5 kaydırıcı adımı + tam sayı girişi ve görünür taşma/kaydırma. Kayıt/yedek göçünü koru. Her kod push sonrası kaynak ZIP + Git bundle Drive proje klasörüne yedeklenir; release dosyaları/notları da sürüm klasörüne, geri okuma yapılır; erişim yoksa bekliyor olarak açık kaydet. İmza/Apple/gerçek cihaz engellerini tamamlandı sayma.

## Tam sonraki Forge

**Yeni kullanıcı düzeltmesi önce gelir: çubuk/eklemli gövde reddedildi. F110 tam gövdeli ardışık resim animasyonu.** Hazır Aion kaynağı ChatGPT Pet koleksiyonudur; koleksiyondan salt okunur al, etkin peti veya kaydı değiştirme. Kullanıcının son tam gövdeli dört karakter referansı kabul yönüdür. Önce bu yöntemi normal girişte Aion/koyun/kurt/baykuşa bağla; eskisini hizalamayı bitmiş ürün gibi yayımlama. Sonra F111 besin kategorisi → besin → biçim; F112 kas grubu → izole/bileşik alternatif hareket; F113 Ayarlar'ın menü sonunda olması. Hepsi yeni kabul maddelerinde ayrı izlenir. Ders/XP/program/veri/önceki kuyruk korunur.

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
