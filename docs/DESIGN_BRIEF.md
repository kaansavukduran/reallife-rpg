# RealLife RPG · Tasarım özeti · AIONIA v1.2

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

Mevcut Flutter `Theme`/`ColorScheme` kullanılır: yüzey ve yazı renkleri, primary vurgu, error hata rengi; Material ikon ailesi, mevcut köşe tercihi ve tipografi. Roboto ve kullanıcı seçerse OpenDyslexic paket kaynaklarından gelir. Tek kullanım için yeni bileşen çatısı kurulmaz.

Form aralıkları 6/8/12/16/20 mantıksal piksel; tarih satırı dar alanda dikey yerleşir ve tam tarihi sarar. Uzun alan başlıkları kısaltılıp isteğe bağlılık yardımcı metne taşınır. Normal/odak/basılı/devre dışı durumları platform bileşenlerini izler; hatalarda metin ve renk birlikte kullanılır. Hata alanına kaydırma azaltılmış harekette anlıktır; aksi durumda 180 ms geri bildirimdir.

## Platform ve kabul kapsamı

Telefon için tek sütun/scrollable form; masaüstünde okunabilir modal genişliği. Tarih/saat alt pencereleri yerelleştirilir ve saat 24 saat biçimindedir. Klavye açılması, büyütülmüş yazı, iki dil, açık/koyu tema, iptal, alan hatası ve tekrar/kayıt geçmişi kontrolleri bu alt işin kabulüdür. Sonuçlar [AIONIA_STANDARD.md](AIONIA_STANDARD.md) ve [FORGE_LOG.md](FORGE_LOG.md) içinde kaynak SHA ile kaydedilir.

**Açık v1.2 açığı:** genel `InterfaceScale` dar ekranda %200 arayüz büyütmesinde 360 mantıksal piksel tabanı ve yatay kaydırma kullanır. Sıradan form/metin akışında bu v1.2 yeniden akış kabulünü karşılamaz; çalışıyor görünmesi tam uyum değildir. %200 yazı boyutu ile %200 tüm arayüz büyütmesi ayrı testlerdir. Fiziksel ekran okuyucu, tüm özel paletler, tablet/katlanabilir cihaz ve zayıf donanım/ağ kabulü açık kalır.

Bu ürünün temel deneyimi kişisel görev/kayıt uygulamasıdır; yeni hareket/kamera oyunu yapılmaz. Oyunlara özgü gamepad/joystick kontrol şeması bu form işine dayatılmaz; mevcut fare/klavye/dokunma korunur.

## İncelenebilir ekranlar

v41 [Maceram masaüstü](screenshots/aionia-task-done.png) ve [telefon](screenshots/aionia-phone.png) önceki referanstır. Bu turun gerçek Chromium ekranları: [editör masaüstü](screenshots/task-editor-desktop-en.png), [telefon %200 yazı](screenshots/task-editor-phone-large-en.png), [ad hatası ve erişilebilir eylemler](screenshots/task-editor-error-large-en.png), [büyük yazıda saat hataları](screenshots/task-time-error-large-en.png). Kaydırılan formun ekranda yalnız bir bölümü görünür; eylemler sabittir. Önceki ekran görüntüsü yeni davranışın testi sayılmaz.
