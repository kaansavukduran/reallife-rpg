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

`interface_scale_control_test.dart` gerçek fareyi iki yönde sürükler, rayın yer değiştirmediğini, eski sabit değerlere kısıtlanmadığını, kayıt/yeniden açılışı, %137 girişini, hatalı değerleri ve 360/1600 pikselde sınırları kontrol eder. Dar ekranda seçilen gerçek ölçek korunur, gerekirse görünür yatay kaydırma sunulur; işletim sisteminin metin ölçeği de uygulanır.


## Spor / beslenme / karakter entegrasyonu

`test/domain/wellness_test.dart`: 78 hareketin kimlik/kas/serileştirme kontrolü; manuel planın geçmiş/XP üretmemesi; ACSM eğim yüzdesi ve MET hesabı; bilinmeyen kg; program/yük değişiminde geçmiş antrenman anlık görüntüsü; gram ve eksik/gerçek sıfır ayrımı; biçim 3→4 göçü, bozuk/çift kimlikli verinin reddi.

`test/ui/wellness_test.dart`: ana uygulama girişinden örnek plan, tek gerçek set/tekrar, öğün miktarı ve yenen ayrımı, karakter seçimi ve kalıcılık, cihaz EN/varsayılan TR/kalıcı tercih, bağımsız metin boyutu ve OpenDyslexic, üç yeni ekranda gerçek %200 + dar ekran + azaltılmış hareket, reverse pec deck kas etiketleri ve duraklatma. Formlar denetleyicilerini dialog çıkış geçişi tamamlandıktan sonra bırakır.

`tool/wellness_smoke.cjs`: normal web girişinde hareket arama/karakter kare değişimi/kas haritası, USDA besin arama/gram/yenen kaydı, TR/EN ve yeniden açılış. Flutter web semantik eylemleri ile mevcut `browser_smoke.cjs` gerçek pointer ölçek testi farklı kanıtlardır.

8.789 doğrudan resmî USDA SR28 besini ve 20 besin bileşeni aktarılır; IFCT değerleri veya tahminleri yoktur. Kaynak SHA ve türetme politikası `docs/sources/NUTRITION_SOURCE.json` içinde. Tüm Besin Matriksi uygulaması veya tüm egzersizlerin/uzmanlık ölçümünün tamamlandığı iddia edilmez.

## Program, ağaç, XP ve değerlendirme

- `task_xp_test.dart`: bütün 101 değer/0 sınırı, eski 10/20/35 göçü, bozuk değer reddi, gerçek fare + Home/End/ok tuşları, kaydet/düzenle/iptal. Temel XP tik anında dondurulur; görev XP’sini sonradan değiştirmek geçmiş puanı üretmez.
- `planning_tree_review_test.dart`: süre aralığı/gece yarısı, zaman geçişinin dosya/XP yazmaması, ertesi gün geçmiş tiki ile puan düzeltme; kaynak ve canonical görev atomik bağlantısı/tekrarsızlık/geçmiş; öğün şablonu/yenen ayrımı/tekil ezme/atlama; ağaç döngüsü ve çapraz dal reddi, silerken çocukların korunması, gerçek görev XP’si ve üst dal şartıyla pasif açılma.
- `study_health_test.dart`: ders/ünite/names/tik kalıcılığı, hızlı ardışık işaretler; boy/kg ve açık yetişkin referansı; yeni sayfalarda TR/EN + telefon + %200. `planning_nutrition_test.dart`: 150,5 g ↔ 0,1505 kg hassasiyeti ve tekrarlı birleşik öğünün yapılmış sayılmaması.
- `tree_pet_test.dart`: gerçek fareyle uygulama genelinde baş/gövde/göz yönelimi, bölgesel dokunuş, azaltılmış hareket, 0 XP ve karakterden bağımsız logo.
- `progress_smoke.cjs`: semantik açık düğüm/ana dal seçimi ve tekrar açılışı; semantik kapalı gerçek Canvas fare/klavye ile XP çubuğu ve karakter takibi. Semantik DOM aralıklarının normalleştirilmiş değerlerini gerçek fareyle karıştırmaz.

Gün özeti besin eksi brüt egzersiz tahmininin kayıt aritmetiğidir, TDEE veya gerçek kilo kaybı hesabı değildir. Yetişkin BKİ referansı tanı değildir. Haftalık puan yalnız tamamlanan/süresi geçen plan oranıdır; metnin değişmesi puanı değiştirmez. Pasif seviyeler beceri sertifikası değildir. Kurulum simgesi Aion’dur; uygulama içindeki logo dört karakterden seçilir.

## F101 · tam gövdeli çizgi film kareleri

`companion_sprites.dart` bütün çizilmiş PNG hücresini sabit hedef dikdörtgene yerleştirir. Aion Pet kaynağı ve diğer tam gövde atlasları korunur. Bakış yönü çizilmiş bir kareyi seçer; karakterin gövdesi fare konumuna taşınmaz. Dambıl curl ve makine reverse pec deck dışında, `chest_press` + makine, `bench_press` + halter ve `incline_press` + dambıl çiftlerinin her biri için sekiz kareli ayrı klip vardır. Dört karakterin her birine ayrı satır ayrılır; kurt insansı iki ayaklı anatomisini korur. Sırt desteği arkada, ayaklar platformda ve kollar öne itiş/dönüş pozlarıyla gösterilir. Bench press sırtüstü düz bankta, halter göğsün üzerinde yukarı/dönüş pozlarıyla çizilir. Eğimli presin yeni 32 karesinde eğimli sırt desteği ve iki ayrı dambıl vardır; düz bank/halter resmi tekrar kullanılmaz. Önizleme şeridi yalnız hazır klipleri gösterir; kardiyo programları/kütüphanesi korunur. Diğer hareket/ekipman çiftleri açıkça bekliyor kalır.

`chest_press_test.dart`, `bench_press_test.dart` ve `incline_press_test.dart` üç klibin toplam 96 hücresinin gerçek piksellerini, alfa/sınır boşluğunu, kesilmeyen el ve ayakları, zemin hizasını, ayrı çizimleri ve yanlış harekete klip atanmamasını denetler. TR/EN, telefon/%200/OpenDyslexic, Home/End, duraklat, azaltılmış hareket, kayıt/yeniden açılış ve 0 XP kontrolü vardır. `RPG_CAPTURE_CHEST=1 flutter test test/ui/chest_press_test.dart` gerçek painter başlangıç/itiş karşılaştırmasını üretir; `RPG_CAPTURE_INCLINE=1 flutter test test/ui/incline_press_test.dart` eğimli pres çıktısını üretir. `companion_smoke.cjs` dört karakterin sekiz kareli önizlemesini ve normal Spor kütüphanesindeki göğüs presine gerçek fareyle geçişi; halterle bench press ve eğimli dambıl presi için ayrı klipleri, şınav için bekliyor mesajını, telefon ve eski kayıt kontrollerini doğrular. Şematik karakterler uzman teknik onayı değildir; diğer hareketlerin özel kareleri F101'de açık kalır.

## Tam gövde kareleri ve dallanan seçiciler

`companion_portrait_test.dart` artık kaldırılan çubuk gövdenin eklemlerini değil, gerçek PNG hücrelerini, alt gövde/transparan alanı, farklı çizilmiş pozların gerçek renderer pikselini ve yön atlasını denetler. `food_browser_test.dart` tüm 8.789 kimliğin gruplarını ve TR/EN/telefon %200 kategori → besin → biçim → gram/kayıt yolunu; `exercise_browser_test.dart` 19 kas grubunu, gerçek harita faresini, birden fazla ekipmanın OR filtresini, 3×12 sayaçlarını ve kalıcı programa eklemeyi denetler. Farklı ekipman için aynı spor resmi teknik örnek diye kullanılmaz.

Şınav: dört karakter için ayrı 4×2 PNG atlası (32 kare), doğrudan özgün paftalar temel alındı. Aion solungaç/kuyruk/önlük; baykuş kanatları; koyun yün/toynakları; kurt mor kol izi korunur. Baykuş kanat presi çizgi film uyarlamasıdır. push_up + vücut ağırlığı haricinde bu klip atanmaz.

Pec deck: dört ayrı 4×2 atlas, yalnız pec_deck/makine, önizleme ve normal Spor ayrıntısı. Alfa/kenar/zemin, TR/EN, telefon-%200, klavye/duraklat/yeniden açılış kontrolleri pec_deck_test.dart içindedir. Yeni kareler doğrudan özgün paftalardan üretildi.

Kablo göğüs açış: dört karakterin özgün paftalarına dayalı ayrı 4×2 atlaslar (32 kare). Yalnız cable_fly/kablo eşleşmesinde, önizleme ve Spor ayrıntısında oynar; pedli makine klibiyle karışmaz. Kablo tutacakları göğüs önünde birleşir; baykuş kanatları çizgi film uyarlamasıdır.

Dambıl ters açış: dört karakter için özgün paftalardan üretilen ayrı sekizer kare (32). Oturarak öne eğilme varyantı, iki ayrı dambıl ve yalnız reverse_dumbbell_fly/dambıl eşleşmesi; makine reverse pec deck ayrı kalır. TR/EN açıklama, önizleme, normal Spor ekranı ve kare kontrolleri birlikte çalışır. Eksik veya yanlış ekipmanda eski makine resmi yerine boşta kareleri gösterilir.

Kablo face pull: dört özgün karakter paftasına göre ayrı sekizer kare (32). Tek yüksek makara ve iki uçlu ip yüzün iki yanına çekilir; yalnız face_pull/kablo eşleşmesi. Makine/dambıl ters açış klipleri ayrıdır; yanlış ekipman veya eksik atlas boşta görünür. TR/EN açıklama, önizleme, normal Spor ekranı ve kare kontrolleri ortak kareleri kullanır.

Makinede omuz pres: dört özgün karakter paftasına göre ayrı sekizer kare (32). Dik sırt desteği ve sabit ayaklarla iki makine tutacağı omuz hizasından baş üzerine itilir; yalnız shoulder_press/makine eşleşmesi. Göğüs pres ve diğer omuz pres ekipmanları ayrı kalır. Önizleme, normal Spor ekranı, TR/EN açıklama, kare çubuğu ve azaltılmış hareket desteklenir. Baykuş kanatlarıyla çizgi film uyarlamasıdır.

Dambıl omuz pres: dört özgün karakter paftasına göre ayrı sekizer tam gövde kare (32). Dik sırt desteği ve iki bağımsız dambıl; yalnız shoulder_dumbbell/dambıl eşleşmesi. Makine ve eğimli göğüs pres kareleri ayrı kalır. Baykuş tüylü kanat uçları ve kavrama kayışlarıyla çizgi film uyarlamasıdır. TR/EN açıklama, normal Spor ekranı, önizleme, kare çubuğu ve azaltılmış hareket korunur.

Halter omuz pres: dört özgün karakter paftasına göre ayrı sekizer ayakta tam gövde kare (32). Tek bağlantılı halter barı üst göğüsten baş üzerine çıkar; yalnız overhead_barbell/halter eşleşmesi. Dambıl ve makine klipleri ayrıdır. Türkçe başlık, TR/EN açıklama, normal Spor ekranı, önizleme, kare çubuğu ve azaltılmış hareket korunur. Baykuş kanat uçlarıyla çizgi film uyarlamasıdır.

Halter karelerinde şeffaf kenar boşlukları sabit kaynak pencereleriyle hizalanır; karakterin tamamı görünür ve hedef çizim kutusu kareler arasında yer değiştirmez.

Yana açış makinesi: dört özgün karakter paftasına göre ayrı sekizer tam gövde kare (32). Dik otururken iki yeşil dirsek pedi üst kollarla yana ve omuz hizasına doğru yükselir; baş üstüne pres yapılmaz. Yalnız lateral_machine/makine eşleşmesi bu atlası yükler; dambıl/kablo yana açışları ve diğer aileler ayrı kalır. Baykuş insan eli yerine tüylü kanatlarıyla çizgi film uyarlamasıdır. TR/EN açıklama, önizleme, normal Spor ekranı, duraklat/kare/klavye ve azaltılmış hareket korunur; animasyon XP üretmez.

Dambıl yana açış: dört özgün karakter paftasına dayalı ayrı sekizer ayakta tam gövde kare (32). İki bağımsız dambıl hafif bükülü kollarla yanlardan omuz hizasına doğru yükselir; makine, oturak veya baş üstüne pres yoktur. Yalnız lateral_dumbbell/dambıl eşleşmesi bu klibi yükler. Baykuş tüylü kanat uçlarına bağlı kavrama kayışlarıyla çizgi film uyarlamasıdır. TR/EN açıklama, önizleme, normal Spor ekranı, kare çubuğu/klavye, duraklat ve azaltılmış hareket korunur; animasyon XP üretmez.

Desteklenmeyen hareket ailesinde Aion'un yanlışlıkla okuma karesi göstermesi de düzeltildi; gerçek boşta karesi seçilir, normal kitap okuma korunur.

Kablo yana açış: dört özgün karakter paftasına dayalı ayrı sekizer tek kollu tam gövde kare (32). Sağ kol, tek yeşil tutacağı karşı kalça önünden yana ve omuz hizasına kaldırır; kablo sabit alçak makaraya bağlıdır. Ayaklar ve makine tabanı ayrı ayrı sabit kalır. Yalnız lateral_cable/kablo eşleşmesi bu klibi yükler; dambıl ve makine yana açışları ayrı kalır. Baykuş tüylü kanat ucunda kavrama kayışı kullanır. TR/EN açıklama, normal Spor ekranı, önizleme, kare çubuğu/klavye, duraklat ve azaltılmış hareket korunur; animasyon XP üretmez. Bu çizim sağ tarafı gösterir; diğer taraf sırayla uygulanır ve teknik uzman onayı değildir.

Dambıl öne kaldırış: dört özgün karakter paftasına dayalı ayrı sekizer tam gövde kare (32). Sağa bakan sabit yan/üç çeyrek görünümde iki bağımsız yeşil dambıl uyluk önünden öne/omuz hizasına yükselir. Yalnız front_raise/dambıl eşleşmesi yükler; yana açış, curl ve pres klipleri ayrıdır. Baykuş tüylü kanat uçlarında kavrama kayışı kullanır. Aion ve koyunda kaynak pencereleri yalnız şeffaf payı kırpar; sabit hedef kutusu ve bütün gövde korunur. TR/EN açıklama, normal Spor ekranı, önizleme/kare çubuğu/klavye, duraklat, azaltılmış hareket ve 0 kozmetik XP korunur. Şematik çizim teknik uzman onayı değildir.

Lat pulldown / sırt çekiş: dört özgün karakter paftasına dayalı ayrı sekizer oturarak tam gövde kare (32). Üst makaraya bağlı tek yeşil bar, geniş kavramayla göğsün önüne doğru aşağı çekilir; makine ve karakterin oturuşu sabittir. Yalnız lat_pulldown/makine eşleşmesi bu klibi yükler; barfiks, face pull ve omuz pres ayrıdır. Baykuş tüylü kanat uçlarındaki kayışlarla uyarlanır, insan eli kullanılmaz. TR/EN açıklama, Spor ayrıntısı, önizleme/kare çubuğu, Home/End/ok, duraklat ve azaltılmış hareket korunur. Alfa, barın aşağı hareketi/orta bağlantısı, ayrı ayak-makine hizası ve kalıcılık doğrulanır; animasyon XP üretmez. Şematik çizim uzman teknik onayı değildir.

Barfiks: dört özgün karakter paftasından ayrı sekizer tam gövde kare (32). Sabit yeşil barda vücut yükselir, çene barı geçer ve kontrollü alçalır; makinede lat pulldown kareleri kullanılmaz. Yalnız pull_up/vücut ağırlığı eşleşmesi yüklenir; destekli makine barfiksi ayrı kalır. Baykuş tüylü kanat uçlarında kayış kullanır. Spor ayrıntısı ve yol arkadaşı önizlemesinde TR/EN açıklama, kare çubuğu, Home/End/ok, duraklat ve azaltılmış hareket korunur. Alfa/kenar, bar-sehpa hizası ve bağımsız gövde yükselişi test edilir; gövde parçaları/hedef kutusu kaydırılmaz. Kayıtlar korunur, animasyon XP üretmez. Şematik çizim uzman teknik onayı değildir. Aion inişinde çizilmiş ikinci poz bir kez daha gösterilerek dokuz aşamalı döngünün son/ilk sıçraması azaltılır; gövde taşınmaz veya ara resim uydurulmaz.

Destekli barfiks: dört özgün karakter paftasından ayrı sekizer tam gövde çizim (32). Sabit yeşil bar ve gri makine tabanı karşısında mavi destek pedi karakterle birlikte yükselip alçalır; görünür ağırlık bloğu ve destek rayı serbest barfiksten ayrıdır. Yalnız assisted_pull_up/makine eşleşmesi yüklenir; serbest barfiks ve lat pulldown klipleri korunur. Baykuş tüylü kanat uçlarında kayış ve ayak destekli duruş kullanır; kurt iki ayaklıdır. TR/EN açıklama, Spor ayrıntısı/önizleme, kare çubuğu, Home/End/ok, duraklat ve azaltılmış hareket desteklenir. Ped/gövde hareketi ile sabit bar/makine hizası ayrı test edilir; hedef kutusu/gövde parçaları kaydırılmaz. Eski kayıtlar korunur ve animasyon XP üretmez. Şematik çizim uzman teknik onayı değildir.

Oturarak kablo kürek: dört özgün karakter paftasından ayrı sekizer tam gövde çizim (32), yalnız cable_row/kablo eşleşmesinde. Sabit oturuş/ayak desteği karşısında yeşil V tutamak karına doğru yatay çekilir ve geri uzatılır; alt makara/kablo görünür. Barfiks ve lat pulldown ayrı kalır. Baykuş doğal tüylü kanat uçlarında gri kavrama kayışı kullanır; kurt insansı iki ayaklıdır. Spor ayrıntısı/önizleme, TR/EN, kare çubuğu, Home/End/ok, duraklat ve azaltılmış hareket desteklenir. Tutamağın yatay gidiş/dönüşü, sabit taban ve ayak hizası ayrı test edilir; hedef kutusu/gövde parçaları kaydırılmaz. Eski kayıtlar korunur ve animasyon XP üretmez. Şematik çizim uzman teknik onayı değildir.

Göğüs destekli kürek: dört özgün karakter paftasından ayrı sekizer tam gövde çizim (32), yalnız machine_row/makine eşleşmesinde. Göğüs öndeki sabit mavi pede dayanır; iki ayrı yeşil tutamak gri makine kollarıyla kaburgalara doğru çekilir ve kontrollü geri uzatılır. Kablo kürek ve düşey çekişler ayrı kalır. Baykuş tüylü kanat uçlarında kayış, kurt insansı iki ayaklı gövde kullanır. TR/EN, Spor ayrıntısı/önizleme, kare çubuğu, Home/End/ok, duraklat ve azaltılmış hareket desteklenir. Ayrı kavramalar, pedin açıkta kalan üst kenarı, taban ve ayaklar bağımsız kontrol edilir; hedef kutusu/gövde parçaları kaydırılmaz. Eski kayıtlar ve 0 kozmetik XP korunur. Şematik çizim uzman teknik onayı değildir.
