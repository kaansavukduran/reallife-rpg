# RealLife RPG · Tasarım özeti · AIONIA v1.4

**Ana vaat:** Bugün yapacağını seç, gerçekten yaptığında işaretle, kaydını koruyarak devam et.

| Karar | Projeye uygulanışı |
| --- | --- |
| Kullanıcı | Türkçe/İngilizce kullanan yeni veya deneyimli kullanıcı; düşük dijital okuryazarlık ve büyütülmüş yazı ihtiyacı gözetilir. Evrensel uygunluk iddiası yoktur. |
| Ana görev | Maceram → Yeni görev → adı/isteğe bağlı ayrıntılar/tekrar → Ekle → kullanıcı işareti → Geri al veya sonraki gün devam. |
| Cihazlar | Flutter ile Windows/macOS/Linux/Android ve tarayıcı; klavye/fare/dokunma. Fiziksel cihaz kabulü ayrı kayıt gerektirir. |
| Ton | Cesaretlendiren ve açık; gecikme veya ayar değiştirme başarı sayılmaz. |
| Üç tasarım sıfatı | Sıcak, anlaşılır, dengeli. |
| Üç kaçınılan kalıp | Aynı eylemi farklı isimlerle sunmak; hatayı alanından uzakta göstermek; işlevden kopuk kart/animasyon/dekorasyon eklemek. |
| Marka/evren | RealLife RPG ürün kimliği korunur. AIONIA kalite standardıdır; isteğe bağlı RPG ve mevcut karakterler ürünün bağlamına aittir. Yeni onaysız karakter/logo veya lore eklenmez. |

## Akış ve bilgi hiyerarşisi

Maceram'da birincil eylem Yeni görev; görev editöründe Ekle/Kaydet, ikincil eylem İptal. Silme editörün birincil eylemine karıştırılmaz. Ad zorunlu; not, adımlar, saat ve süre isteğe bağlıdır. Günlük, belirli günler ve tek sefer aynı tekrar alanında kalır. Menü isimleri veya ana gezinme bu tur kökten değiştirilmez.

Hata alanın yanında açıklanır; ilk hatalı kontrol odaklanıp görünür alana getirilir. Başlık/not/adımlar hata ve alt tarih/saat pencereleri boyunca taslakta korunur. İptal taslağı atar; geçerli Ekle/Kaydet'e kadar görev verisi ve XP değişmez. Tarih biçimi arayüz dilini izler; kullanıcı metni çevrilmez ve kayıt biçimi değişmez.

## Görsel bileşenler ve durumlar

Mevcut Flutter `Theme`/`ColorScheme` kullanılır: yüzey ve yazı renkleri, primary vurgu, error hata rengi; Material ikon ailesi, mevcut köşe tercihi ve tipografi. Yeni kurulum koyu tema ve Flutter platform sistem tipografisi kullanır; Windows/macOS/Android/Linux platform aileleri korunur, web renderer gerektiğinde paketli Roboto’ya düşer. Web’de işletim sisteminin tüm font dosyalarına erişildiği iddia edilmez. Kullanıcı isterse serif/mono/OpenDyslexic seçer; tema seçimi okuma/hareket tercihlerini silmez. Açık/sistem/ön ayar ve eski özel seçimler kalıcıdır. Tek kullanım için yeni bileşen çatısı kurulmaz.

Form aralıkları 6/8/12/16/20 mantıksal piksel; tarih satırı dar alanda dikey yerleşir ve tam tarihi sarar. Uzun alan başlıkları kısaltılıp isteğe bağlılık yardımcı metne taşınır. Normal/odak/basılı/devre dışı durumları platform bileşenlerini izler; hatalarda metin ve renk birlikte kullanılır. Hata alanına kaydırma azaltılmış harekette anlıktır; aksi durumda 180 ms geri bildirimdir.

## Platform ve kabul kapsamı

Telefon için tek sütun/scrollable form; masaüstünde okunabilir modal genişliği. Tarih/saat alt pencereleri yerelleştirilir ve saat 24 saat biçimindedir. Klavye açılması, büyütülmüş yazı, iki dil, açık/koyu tema, iptal, alan hatası ve tekrar/kayıt geçmişi kontrolleri bu alt işin kabulüdür. Sonuçlar [AIONIA_STANDARD.md](AIONIA_STANDARD.md) ve [FORGE_LOG.md](FORGE_LOG.md) içinde kaynak SHA ile kaydedilir.

**v1.4 yeniden akış kararı:** genel yatay sanal tuval kaldırıldı. %200 fiziksel arayüz ölçeği korunarak gerçek dar mantıksal genişliğe yerleşilir; XP/görev etiketleri ve hızlı eylemler sarılır. Alan yeterliyse form eylemleri görünürdür; çok kısa pencerede bütün form kaydırılır. Dar/kısa pencerede alt gezinme yerine mevcut çekmece kullanılır; isim/sıra ve sabit Ayarlar korunur. Tarih/saat dar alanda yazılabilir form, yeterli alanda takvim/kadran kullanır. Besin seçimi dar alanda tam ekran; g/kg eş ölçülü kontrollerle sarılır. Gerçekten iki boyutlu matriksler kendi içinde kayabilir; sıradan form/metin için kök yatay kaydırma yoktur. %200 yazı ile %200 tüm arayüz ayrı test edilir. Fiziksel yardımcı teknoloji, tüm paletler, tablet/katlanabilir cihaz ve düşük donanım kabulü açık kalır.

Bu ürünün temel deneyimi kişisel görev/kayıt uygulamasıdır; yeni hareket/kamera oyunu yapılmaz. Oyunlara özgü gamepad/joystick kontrol şeması bu form işine dayatılmaz; mevcut fare/klavye/dokunma korunur.

## İncelenebilir ekranlar

v41 [Maceram masaüstü](screenshots/aionia-task-done.png) ve [telefon](screenshots/aionia-phone.png) önceki referanstır. Bu turun gerçek Chromium ekranları: [editör masaüstü](screenshots/task-editor-desktop-en.png), [telefon %200 yazı](screenshots/task-editor-phone-large-en.png), [ad hatası ve erişilebilir eylemler](screenshots/task-editor-error-large-en.png), [büyük yazıda saat hataları](screenshots/task-time-error-large-en.png). Kaydırılan formun ekranda yalnız bir bölümü görünür; yeterli yükseklikte eylemler görünür kalır. Önceki ekran görüntüsü yeni davranışın testi sayılmaz.


İstenen norm v1.4’tür; 12 Kasım canlı kaynak başlığı v1.5 olmuştur. Yeni geometrik tutarlılık maddesi de mevcut Material ikon/kenar/spacing ailesiyle gözetilir. Kontrol tercihi kullanıcıya uygunluk sırasıyla soruldu; yanıt gelene kadar dokunma + klavye/fare korunur, ek gamepad geliştirmesi kesinleşmiş sayılmaz. Oyun yükleme referansı genel görev uygulamasına kopyalanmaz; yeni Fragaria logosu icat edilmez.


v1.4 gerçek Chromium incelemesi: [yeni kurulum koyu tema](screenshots/aionia43-default-dark-phone.png), [ayarlar %200](screenshots/aionia43-settings-ui200.png), [masaüstü %200](screenshots/aionia43-desktop-ui200.png), [telefon %200](screenshots/aionia43-phone-ui200.png), [alan hatası](screenshots/aionia43-error-ui200.png), [saat formu](screenshots/aionia43-time-ui200.png). Bu görüntüler son SafeArea sarmalaması öncesi, sıfır OS inset'li tarayıcıdan alınmıştır; son güvenli alan ayrıca widget regresyonunda doğrulandı. Maceram açıkken Gün yanlış etkin gösterilmez; dar alanda alt gezinme gizlenince sistemin alt/yan güvenli alanı korunur.
