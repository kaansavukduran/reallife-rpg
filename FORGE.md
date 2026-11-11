# RealLife RPG Forge kontrol noktası

Tek hedef depo: **kaansavukduran/reallife-rpg**. Çalışma dalı: `main`.
Bu dosya sonraki geliştirme turunun başlangıç noktasıdır; bitmiş uygulamayı her tur yeniden kurma.
Diğer depolar ve onların otomasyonları bu Forge'un kapsamı dışındadır.

## Çalışma kilidi

- Durum: IDLE
- Sahip / tur kimliği: —
- Başlangıç (UTC): —
- Geçerlilik sonu (UTC): —
- Otomasyon: **RealLife RPG Forge**; etkin; her saat; `Europe/Istanbul`.
- Kurulum geri okuması: bulut çalışma ortamı ve `/workspace` seçimi devralındı. Yapılmış işin kanıtı aşağıdaki kaynak SHA/CI/sürüm ve eklemeli günlükte bulunur; etkin plan tek başına geliştirme kanıtı değildir.

Çalışmaya başlamadan güncel uzak `main`, açık PR'lar, Actions ve bu dosyayı oku. Kirli çalışma ağacını veya kullanıcının değişikliklerini ezme.
Aktif, süresi dolmamış başka sahipli kilitte kod değiştirme; sonraki tura bırak.
Kod değiştirecek tur, 90 dakikalık kilidini önce bu dosyaya yazıp normal fast-forward push ile alır. Eşzamanlı push reddedilirse yeniden oku; diğer kilidin üstüne yazma.
Uzun turda kendi kilidini süresi dolmadan yenile. Süresi dolmuş kilitte önce sahip turun hâlâ çalışıp çalışmadığını ve yeni commitleri incele.
Tur sonunda sonucu ve tam sonraki adımı kaydet, kendi kilidini IDLE yap. Force push, başkasının commitini geri alma ve veri silme yok.


## Son doğrulanmış dağıtım

- Kod `d9ad4cdb4e98e37bb05731dd401170ed83387347`; [v0.1.0-build.40](https://github.com/kaansavukduran/reallife-rpg/releases/tag/v0.1.0-build.40) ve [CI 42954234482](https://github.com/kaansavukduran/reallife-rpg/actions/runs/42954234482). Windows/macOS/Linux/Android/web/publish başarılı; Pages H030 nedeniyle skipped. Normal Release/Latest ve tag aynı kaynak SHA'da.
- Düz kol kablo çekiş: dört özgün paftadan ayrı sekizer tam gövde çizim (32), yalnız straight_arm_pull/kablo. İki mavi kavramalı bağlantılı yeşil tutamak, yüksek sabit makaraya bağlı gergin kabloyla omuzlardan kalçaya doğru indirilip kontrollü geri döner. Gövde/ayak/mat/makara sabittir; baykuş doğal kanat uçları/yuvarlak tüy gövdesi/kısa talon ayaklarını, kurt insansı iki ayaklı anatomisini korur. Diğer klipler ve eski kayıtlar ayrı korunur; kozmetik hareket XP üretmez.
- 512 Flutter, temiz analiz/135 dosyada biçim, beş servis/yedi indeks Python ve dört Chromium smoke geçti. 11 yeni test sekiz ayrı poz/alfa/kenarı, orta mavi bağlantının bölebildiği yeşil boya bölgelerini ve iki mavi kavramayı izler. Tutamak >130 piksel iner/>110 çıkar, başlangıca göre >35 piksel geriye yaklaşır; her iniş adımı >8/çıkış >20 kaynak piksel, bar boyu farkı <15. Kablo boyunca dokuz iç noktada gri çizim örneği aranır; yedi piksellik örnek toleransı otomatik topoloji/teknik sertifika değildir. Baş üstü ve ayak tabanı y hizası, mat sol/alt ve makara sağ/alt sınırı farkları en fazla üç; makara üst dış çizgisi farkı en fazla dört kaynak pikseldir. TR/EN, telefon-%200/OpenDyslexic, gerçek fare/klavye, duraklat/azaltılmış hareket ve kayıt/yeniden açılış geçti. Eşit tam hücreler kullanılır; gövde parçaları kaydırılmaz. Çizimler şematiktir, uzman teknik onayı değildir.
- Altı paket checksum'u, kaynak/tag/Latest SHA ve dört arşivde 92 kayıtlı atlas + iki eski baş/ifade atlası (94 PNG), iki besin dosyası eşleşti. Kaynak ZIP/tam Git ve 12 sürüm dosyası SHA/ZIP CRC/git bundle verify ile yerelde doğrulandı; önceki 88 atlas hash'i ve eski sürümler korundu. Drive H040 bekliyor, yeni aktarım denenmedi. Önceki ortam yedeklerinin bağlı olmaması notu sürer. Kapanış belge commitidir.

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
| F110 | DONE | Tam gövdeli dört karakterin PNG kare motoru: hazır 73 kareli Aion Pet kaynağı ve dört ayrı 32 hücreli eylem atlası; 16 yön Aion / 8 yön diğerleri, okuma/yaban mersini/tepki/boşta. Çubuk gövde kodu kaldırıldı; sabit çizim hücresi ve zemin, sürüklenerek bakış taklidi yok. Yalnız dambıl curl ve makine reverse pec deck eşleşmelerine özel spor kareleri; diğer aile/ekipman açık bekliyor metniyle boşta durur. Telefon/%200, duraklat/kare, azaltılmış hareket, seçim/yeniden açılış ve 0 kozmetik XP geçti. 242 Flutter/5 Python/4 browser, temiz analiz; `94a9816`, CI11 ve v0.1.0-build.11/Drive makbuzu doğrulandı. Daha çok egzersiz karesi F101. |
| F116 | DONE | Odak ve Yaşam atlası masaüstü yan menü/telefon çekmecesinden kaldırıldı; eski kayıt/JSON alanları ve iç sayfalar korundu. Yeni kullanıcı talimatıdır; menüye geri ekleme. CI13/v13 ve özel Drive geri okuma makbuzu doğrulandı. |
| F117 | DONE | Sol menü fareyle sürükle, telefonda uzun bas, Ctrl+↑/↓ ve ekran okuyucu taşıma eylemleriyle sıralanır. Bu cihaza özgü kalıcı sıra; yalnız menü sırasını sıfırla; Ayarlar sürüklenmez ve altta sabit. Gizli Karakter yuvası, eski ayarlar ve kullanıcı verisi korunur. Hızlı ayar yazımları sıraya alındı. TR/EN, disleksi fontu/telefon-%200, gerçek fare/dokunma/klavye ve yeniden açılış testleri geçti; CI13/v13 ve özel Drive geri okuma makbuzu doğrulandı. |
| F118 | DONE | Accursed Wise Wolf kullanıcı T-pose paftası Drive’dan salt okunur incelendi; dört ayaklı görünüm reddedildi. 32 tam gövde kare iki ayaklı insansı chibi olarak yeniden üretildi, mor sağ kol izi korundu, arka plan image_gen ile temizlendi. Gerçek renderer ve tarayıcıda incelendi; CI13/v13 ve özel Drive geri okuma makbuzu doğrulandı. Daha fazla harekete özgü kare F101’de açık. |
| F119 | DONE | Kullanıcı GitHub içinde son sürümün görünmesini istedi. Doğrulanmış v12 ön sürümden normal Release/Latest görünümüne alındı; kaynak ve paketler aynı. İlk görünürlük düzeltmesi v12’de doğrulandı; şu an /releases/latest gerçek API okumasıyla v40’a gider. Yayın akışı tüm kapılar geçince --latest ile normal Release üretir; eski sürümler korunur, açık ürün işleri tamamlandı sayılmaz. Yeni kod CI13 ve normal Release/Latest v13 olarak doğrulandı; paket/Drive makbuzları tamam. |
| F111 | ACTIVE | 16 grup → 1.930 besin ailesi → biçim/çiğ/pişmiş filtreleri uygulandı; ilk ekranda 8.789 satır yok. Badem/ceviz ve somon/ton balığı ayrı besinlerdir, genel USDA başlığının biçimleri diye birleşmez. Kırıntı/geri, kategori içi TR/EN arama ve ayrı kaynak ayrıntısı; tüm besin kimlikleri/değerleri/g-kg/matriks/eski kayıtlar korundu. TR/EN ve telefon/%200 gerçek ekleme yolu geçti. Altı ana et ailesinde 1.976 kaydı 30 Türkçe/İngilizce parça/ürün grubuyla daraltma ve parça adına iki dilde arama uygulandı; 246 Flutter, CI12/v12 ve Drive geri okuma makbuzu doğrulandı. Altı ana ailenin 1.976 varyantına kısa TR/EN başlıklar, açık yağ/deri/kemik/hazırlama özellikleri ve NDB kodu eklendi; tam kaynak açıklaması açılır. Eski öğün anlık görüntüleri ve kullanıcı adları değiştirilmez. 255 Flutter/7 indeks Python/5 servis testi, gerçek Chromium fare/klavye/kaynak/yeniden açılış ve temiz analiz-biçim geçti; CI14/v14/Latest/özel Drive geri okuma makbuzu doğrulandı. Kalan: diğer aile/kaynak adları ve ayrıntılı alt kesim çevirileri; hepsi Türkçeleşti diye kapatma. |
| F112 | DONE | Ön/arka haritada 19 kasa dokun → 7 mevcut ekipmanı OR ile çoklu filtrele → izole/bileşik/statik/kardiyo → 78 adlandırılmış alternatif + kullanıcı hareketleri. Her kasın ana hedef alternatifi var; bel ekstansiyon makinesi ve bird dog eklendi. Yeni kuvvet hareketi 3×12, set/tekrar altında ayrı azalt/artır ve doğrudan sayı; normal kütüphaneden mevcut/yeni program-güne kalıcı ekleme ve canonical görev bağı. Eski tekrar/yük/geçmiş korunur; ayar/tıklama XP üretmez. TR/EN, gerçek harita faresi, telefon/%200 ve yeniden okuma testleri, CI11/v11/Drive doğrulandı. Sınırlı kataloğu dünyadaki tüm hareketler diye sunma; genişletme F101. |
| F114 | DONE | Elle besin eklerken gereksiz Yedim kutusunu kaldır; bugün/geçmiş yeni kayıt yendi, gelecek kayıt plan. Sonraki listede tik görünür ve değiştirilebilir; eski kaydın durumu ve otomatik şablonlar korunur, besin XP üretmez. |
| F115 | DONE | Tüm Görevler kartında sağda doğrudan Yapıldı tiki, açık tik tarihi ve geçmiş gün düzeltmesi; karta basma düzenleme olarak kalır. Fare/klavye/telefon, yinelenen ve tek seferlik görev, kayıt/yeniden açılış ve Gün ekranıyla ortak tamamlanma/XP kaydı doğrulanır. Gelecek güne tik yok, ayar/zaman geçişi XP yaratmaz. |
| F113 | DONE | Ayarlar geniş yan menü ve telefon çekmecesinin en altında sabitlendi; kaydırılabilir diğer seçenekler ve eski kısayol/sekme indeksleri korundu. 242 Flutter ve mevcut tarayıcı/fare/yeniden açılış akışları, CI11/v11/Drive makbuzu doğrulandı. |
| F101 | ACTIVE | Curl, reverse pec deck, üç göğüs presi, şınav, pec deck, kablo/dambıl açış, face pull, makine/dambıl/halter omuz pres, üç yana açış, dambıl öne kaldırış, lat pulldown, serbest/destekli barfiks ve kablo/makine/tek kol dambıl/halter/direnç bandı kürek ve düz kol kablo çekiş klipleri hazır. Düz kol kablo çekiş: dört özgün paftadan ayrı sekizer tam gövde çizim (32), yalnız straight_arm_pull/kablo. İki mavi kavramalı bağlantılı yeşil tutamak, yüksek sabit makaraya bağlı gergin kabloyla omuzlardan kalçaya doğru indirilip kontrollü geri döner. Gövde/ayak/mat/makara sabittir; baykuş doğal kanat uçları/yuvarlak tüy gövdesi/kısa talon ayaklarını, kurt insansı iki ayaklı anatomisini korur. Diğer klipler ve eski kayıtlar ayrı korunur; kozmetik hareket XP üretmez. 512 test/CI40/v40/Latest ve yerel yedekler doğrulandı; Drive H040 bekliyor. Diğer çiftler açık; sıradaki shrug/dambıl. Her yeni animasyonda doğrudan özgün pafta kullan. Şematik çizim uzman teknik onayı veya tüm hareketlerin tamamlanması değildir. |
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

- Menüdeki diğer öğeler kullanıcı tarafından sürüklenerek sıralanır, Ayarlar altta sabittir. Kurt paftadaki iki ayaklı insansı chibi anatomisini korur. Kullanıcının somut Latest görünürlüğü talebi doğrultusunda başarılı yayınlar artık normal Release/Latest olur; eski genel Forge şablonundaki ön sürüm ifadesi bu isteği geri almaz. Mağaza/kalıcı imza yayını yoktur.

- Son kullanıcı düzeltmesi: Odak ve Yaşam atlası masaüstü yan menü/telefon çekmecesinde gösterilmez. Eski kayıtlar, yedek alanları ve iç sayfalar korunur; sonraki Forge turunda bu seçenekleri menüye geri ekleme.

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

**Yedek aktarım sınırı:** Bağlayıcı tek dosyada 100 MiB kabul eder. Daha büyük Git bundle/APK gibi yedekleri özgün yerel dosyayı koruyarak 64 MiB parçalara ayır; manifestte özgün ad/byte/SHA-256, parça adları/sırası/byte/SHA-256 ve birleştirme yönergesi bulunur. Her parçayı özel Drive’dan geri indirip birleştir; tam dosya SHA ve Git bundle verify veya APK/ZIP CRC geçmeden yedeği tamamlandı sayma. GitHub Releases paketleri tek dosya olarak korunur; bu yalnız özel yedek aktarımıdır.

## Tam sonraki Forge

**Tek sonraki iş: F101, `shrug` / `Equipment.dumbbell` / `Motion.shrug` için dört karaktere paftaya bağlı tam gövde kareleri (Dambıl shrug).** Düz kol kablo çekiş 32 çizimle uygulandı; 512 test/CI40/v40/Latest doğrulandı. Her elde ayrı dambıl, sabit ayak/gövde ve dirsek açısı korunarak omuz kuşağının kontrollü yükselip alçalmasına özel çizimler gerekir; curl veya öne kaldırış klibini kullanma. Baykuş doğal kanat ucu kayışları/yuvarlak tüy gövdesi/kısa ayaklarla, kurt insansı iki ayaklı anatomiyle özgün paftasını korusun. Her yeni animasyonda doğrudan özgün pafta kullan; F101 ve diğer açık işler tamamlanmış sayılmaz. Kullanıcı verileri ve 0 kozmetik XP korunur.

**H040 — özel sürüm yedeği için onay engeli:** 2026-11-10 v24 aktarımında otomatik onay incelemesi, özel checksum/sürüm dosyalarının Drive hedefine aktarımı için açık kullanıcı yetkisi doğrulanamadığı gerekçesiyle yüklemeyi reddetti. Mevcut FORGE yedek talimatı, paylaşılmayan sürüm klasörü ve doğru ebeveyn kontrolüyle yapılan aynı aktarım denemesi de reddedildi; alternatif aktarım yolu kullanılmadı. V24 kaynak ZIP/tam Git Drive yedeği doğrulandı; sürüm yedeğinde önceki altı dosya geri okundu. Kalan dokuz dosya ve son makbuz açık onay olmadan yeniden yüklenmez. Özgün dosyalar/parçalar/manifest ve aktarım kimlikleri yerel reallife-backups altında korunur; son tam doğrulanmış sürüm yedeği v23'tür. Yalnız RealLife RPG/Sürümler/v0.1.0-build.24 özel klasörüne bu sürümün kalan yedeğini aktarma onayı gerekir. Uygulama geliştirmesindeki ilerletilebilir işler bu engelden bağımsız sürer; tüm Forge tamamlanmadı. V25–v34 kaynak ZIP/tam Git ve sürüm dosyaları yerelde bütünlük doğrulamasıyla hazırlandı; mevcut H040 yetki engeli aşılmadı ve yeni Drive aktarımı denenmedi.

**2026-11-10 ortam geri dönüşü:** Kesilen cable-row turu aynı sahipli kilitle güncel main/PR/Actions/dosyalar yeniden okunarak sürdürüldü ve kilit normal push ile yenilendi. /workspace boş geldi; önceki yerel yedek/dedup makbuzu/SDK/taslaklar bu oturuma bağlı değil. Eski yerel yedeklerin bütünlüğü bu turda tekrar doğrulanmadı; önceki Git geçmişi/tagler ve eski GitHub Releases silinmedi veya taşınmadı. V35 için kaynak ZIP/tam Git ve 12 sürüm dosyası yeni ortamda doğrulandı. Drive aktarımı H040 nedeniyle denenmedi; önceki v24 onayı yerine geçmez.

## Her turda çalışma ve yayın

1. Güncel uzak dal, bu dosya, açık PR/Actions ve yerel değişiklikleri kontrol et; kilit al. Son kullanıcı talimatı bu dosyadan üstündür.
2. Kuyruktaki ilk ilerletilebilir işi seç. Küçük somut bir parçayı uygula; yalnız plan veya eksik listesi yazarak kod işini tamamlandı sayma. Kullanıcının sınırlandırılmış kuyruğuna ilgisiz ürün/kapsam ekleme.
3. İlgili anlamlı testleri ve zorunlu analiz/biçim kontrollerini çalıştır. Kontroller geçtikten sonra yeni değişiklik veya gerçek şüphe olmadan aynı testleri sonsuz tekrar etme. Gerekirse yeni davranışın kontrolünün hatayı yakaladığını dar bir mutasyonla göster ve mutasyonu geri al.
4. Kendi değişikliğini normal commit/push ile kaydet. Eşzamanlı uzak değişiklikte yeniden oku; kullanıcı işini ezme. Kod değişikliğinin Actions sonucunu izle, hatayı ilgili logdan düzelt.
5. Dört platform geçmeden yayın yok. Mevcut `release.yml` ana dalda son somut kullanıcı isteğine göre numaralı Release/Latest üretir; eski sürümleri/tagleri silme veya taşıma. Mağaza yayını veya kalıcı imza varmış gibi sunma. Releases varlıklarını ve kaynak SHA'yı doğrula.
6. Bu dosyada fiilen biten, kalan, engel ve tek sonraki adımı güncelle; `docs/FORGE_LOG.md` sonuna kısa kanıt kaydı ekle; kendi kilidini kaldır.
7. Kullanıcıya yalnız somut yeni gelişmeyi, önemli yeni engeli veya kapanışı kısa Türkçe bildir. Aynı kapsamı/indirme listesini her tur baştan anlatma; ilerlemesiz rutin bildirim gönderme.

## Bitiş ve gerçek engeller

F010–F090 kabul ölçütleri gerçek kanıtla kapanınca yalnız bu RealLife RPG otomasyonunu durdur, son sürümü ve açık insan kabulü/imza sınırlarını bildir.
İlerletilebilir iş kalmaz ve yalnız kullanıcı kimliği, secret, gerçek cihaz veya erişim gerektiren engeller kalırsa bunları açıkça kaydet; tamamlandı deme. Kullanıcıya somut gereksinimi bildirip yalnız kendi otomasyonunu duraklat; aynı değişmemiş engeli saatlerce yeniden deneme.
Diğer projelerin otomasyonlarını değiştirme. Ortam/erişim yoksa başarı veya kesintisiz çalışma iddiasında bulunma.
