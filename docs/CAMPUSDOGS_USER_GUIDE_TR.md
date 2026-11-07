# CampusDogs Kullanım Kılavuzu

Bu kılavuz iPhone uygulamasını kullanan üyeler ve web tabanlı yönetim panelini kullanan yöneticiler içindir. Ekran adları uygulamadaki mevcut Türkçe etiketlerle verilmiştir.

> **Önemli:** Haritada görünen veri, köpeğin son kaydedilen konumudur. Canlı ve sürekli GPS takibi değildir. Bluetooth bölümü de bu aşamada gerçek tasma araması değil, simüle edilmiş bir demo akışıdır.

# Bölüm A — iOS uygulaması

## A.1 Uygulamayı kurma ve açma

Kaynak kodda App Store veya TestFlight yayınına ait doğrulanmış bir dağıtım ayarı bulunmamaktadır. Mevcut proje, Xcode ile iPhone'a ya da simülatöre çalıştırılacak biçimde yapılandırılmıştır.

1. Xcode'da `apps/ios/CampusDogs.xcodeproj` projesini açın.
2. Geliştirici bilgisayarında yerel Supabase yapılandırmasının tanımlı olduğundan emin olun. Bu yapılandırmadaki değerleri paylaşmayın.
3. Hedef cihaz olarak bir iPhone veya uygun iPhone Simulator seçin.
4. Xcode'dan çalıştırın; uygulama ana ekranda **Campus Dogs** adıyla görünür.
5. Fiziksel iPhone'da konum güncelleme işlevi kullanıldığında Apple'ın konum izni isteği görülebilir. Projede Bluetooth izin açıklaması tanımlı olsa da mevcut tarama `MockBluetoothScanner` ile simüle edildiğinden gerçek Bluetooth taraması başlatmaz ve bu akışın Bluetooth izni istemesi beklenmez.

Xcode projesinde otomatik imzalama açık görünmektedir. Kullanılan Apple geliştirici hesabının ücretsiz **Personal Team** olup olmadığı kaynak kodundan doğrulanamaz. Eğer ücretsiz Personal Team kullanılıyorsa Apple'ın geliştirme amaçlı imzası yaklaşık yedi gün sonra yenileme gerektirebilir; uygulamayı tekrar Xcode'dan kurmak gerekebilir. Kurumsal/ücretli geliştirici hesabı için süre ve dağıtım yöntemi farklı olabilir.

### Uygulama açılmıyorsa

| Belirti | Olası neden | Yapılacaklar |
| --- | --- | --- |
| “Yapılandırma gerekli” ekranı | Yerel Supabase yapılandırması uygulama paketine girmemiştir. | Teknik sorumlu, yerel yapılandırmayı ve Xcode build ayarlarını kontrol etmelidir. Anahtar değerlerini sohbet veya sunumda paylaşmayın. |
| Köpek listesi yüklenmiyor | İnternet yok veya arka uç erişilemez. | İnterneti kontrol edin, uygulamayı tekrar açın veya ekrandaki **Tekrar dene** seçeneğini kullanın. |
| iPhone uygulamayı doğrulamıyor/açamıyor | İmzalama ya da cihaz güven ayarı sorunu olabilir. | Xcode'dan yeniden kurun; gerekirse cihazın VPN ve aygıt yönetimi ayarlarını teknik sorumlu ile kontrol edin. |

## A.2 Ana ekran

Ana ekranda dört kart bulunur:

- **Köpekler:** Aktif köpeklerin listesine gider.
- **Harita:** Son konumu yayınlanmış köpekleri gösterir.
- **Bluetooth:** Demo tarama ve tek seferlik konum güncelleme akışını açar.
- **Duyurular:** Yönetici tarafından yayımlanmış duyuruları listeler.

Alt ekranların sağ üstündeki ev simgesi, ana ekrana dönmek içindir.

## A.3 Köpekleri görüntüleme

1. Ana ekrandan **Köpekler** kartına dokunun.
2. Açılan listede yalnızca aktif köpekler görünür.
3. Bir köpeğin kartına dokunun.
4. Profilde fotoğraf, ad, cinsiyet (varsa), **Yaş**, güncel sağlık durumu ve kamuya açık bakım bilgileri görünür.
5. Profilin üstündeki sekmelerden **Bilgiler**, **Sağlık Geçmişi** ve **Konum** alanlarına geçin.

### Yaş bilgisini anlama

Yaş, köpeğin mevcut tahmini doğum tarihinden takvim hesabıyla hesaplanır. Bir yaşından küçükse “8 aylık” gibi; daha büyükse “3 yaş 4 ay” veya tam yıl olduğunda “3 yaş” olarak görünür. Doğum tarihi yoksa yaş bilgisi gösterilmez.

### Sağlık durumu

Güncel durum; **Normal**, **Gözlem Altında**, **Tedavi Altında** veya **İyileşiyor** olabilir. Bu bilgi yaklaşım ve bakım uyarılarıyla birlikte değerlendirilmelidir. Ayrıntılı geçmişte yalnızca yöneticinin üyelere açık yaptığı kayıtlar listelenir.

## A.4 Bakım ikonlarını anlama

Köpek profilindeki **Bakım uyarıları** kartında bulunan bir ikona dokunursanız adı ve açıklaması açılır.

| İkon | Kullanıcı için anlamı |
| --- | --- |
| İyileşme Süreci | Köpek tedavi/toparlanma sürecinde olabilir; sakin davranın. |
| Koşmayı Sınırla | Köpeği koşturmaya veya yorucu oyuna teşvik etmeyin. |
| Özel Beslenme | İzinsiz yiyecek vermeyin. |
| Görme Hassasiyeti | Yavaş ve sakince yaklaşın. |
| İşitme Hassasiyeti | Ani ses ve hareketlerden kaçının. |
| Düzenli Kontrol | Periyodik veteriner kontrolü gerekebilir. |
| Diğer | İkonun kendi açıklamasını okuyun; özel bir bakım notu olabilir. |

Bu ikonlar teşhis koymak için değil, günlük yaklaşım ve bakım konusunda farkındalık oluşturmak için kullanılır.

## A.5 Köpek konumlarını görüntüleme

### Genel harita

1. Ana ekrandan **Harita** kartına dokunun.
2. Harita, son konumu bulunan aktif köpekleri pati işaretiyle gösterir.
3. Bir işarete veya ekranın altındaki köpek kartına dokunarak köpeği seçin.
4. Seçilen köpeğin adı ve son güncelleme zamanı altta görünür.
5. Harita üzerindeki iki parmak hareketiyle veya sistem harita hareketleriyle gezin; **Yenile** ile veriyi yeniden çekin.

### Köpek profilinden konum

1. Köpek profiline girin.
2. **Konum** sekmesini açın.
3. Kayıt varsa küçük harita ve **Son görülme** zamanı görünür.
4. **Haritada Görüntüle** düğmesiyle genel haritada o köpeğe odaklanın.

Konum yoksa bu bir hata olmak zorunda değildir: o köpek için henüz bir son konum kaydı yayınlanmamış olabilir.

## A.6 Gözlem bildirimi gönderme

Bir köpek profili açıkken **Gözlem Bildir** düğmesine dokunun. Form doğrudan ilgili köpeği seçili açar. Bu ekrana, uygulamanın normal akışında köpek profili üzerinden ulaşılır.

1. **Köpek** alanında doğru köpeğin seçili olduğundan emin olun.
2. **Sorun türü** listesinden uygun seçeneği seçin: **Topallama**, **Yaralanma**, **Halsizlik**, **Davranış Değişikliği** veya **Diğer**.
3. **Açıklama** alanına gözleminizi yazın. Alan zorunludur ve en fazla 4.000 karakter kabul eder.
4. Önem derecesini seçin:
   - **Düşük:** Acil olmayan, takip edilmesi yararlı durum.
   - **Orta:** Yönetici tarafından yakın zamanda değerlendirilmesi gereken durum.
   - **Yüksek:** Daha hızlı dikkat gerektiren gözlem. Acil hayati durumlarda yalnızca uygulamaya güvenmeyin; doğrudan yetkili/veteriner acil hattına haber verin.
5. **Bildirimi Gönder** düğmesine dokunun.
6. Başarılı olduğunda “Bildiriminiz iletildi!” ekranı görünür.

Bu sürümde form; adınızı, üyelik hesabınızı veya cihaz konumunuzu kaydetmez. Fotoğraf ekleme desteği yoktur. Yönetici bildirimi görür, inceleme durumunu değiştirir ve çözüm notu ekleyebilir; bu iç yönetim notları üyeye gösterilmez.

## A.7 Duyuruları görüntüleme

1. Ana ekrandan **Duyurular** kartına dokunun.
2. Yalnızca yöneticinin yayımladığı duyurular görünür.
3. Bir duyuruya dokunarak başlık, yayın tarihi ve tam metni okuyun.
4. Listeyi aşağı çekerek yenileyebilirsiniz.

Taslak veya yayından kaldırılmış duyurular iPhone uygulamasında görünmez.

## A.8 Bluetooth ve konum güncelleme demosu

Bu bölüm sunum/demo amaçlıdır; gerçek Bluetooth tasması algılamaz.

1. Ana ekrandan **Bluetooth** kartına dokunun.
2. **Taramayı Başlat** düğmesine dokunun.
3. Kısa süre sonra simüle edilmiş algılanan köpek kartları listelenir.
4. Bir köpeği seçin.
5. Köpeğin yanındaysanız telefonun konumunu kaydetmek için **Konum Güncellemesini Tamamla** düğmesine dokunun.
6. Konum iznine onay verin. Başarılı olursa **Konumu Görüntüle** ile son kaydı açın.

Bu işlem sürekli takip başlatmaz. Telefonun o andaki konumunu bir kez alır ve seçili köpeğin son konum kaydını güncellemeye çalışır. Simülatörde Apple'ın simüle edilmiş konumunu seçmek, telefon konumu olarak kullanılabilir; sonuç yine arka uç ve konum iznine bağlıdır.

## A.9 İzinler ve iOS sorun giderme

| Durum | Ne anlama gelir? | Çözüm |
| --- | --- | --- |
| “Konum servisleri kapalı” | iPhone genel konum servisleri kapalı. | Ayarlar → Gizlilik ve Güvenlik → Konum Servisleri'nden açın. |
| “Konum izni verilmedi” | Campus Dogs uygulamasına konum izni yok. | Ayarlar → Campus Dogs → Konum bölümünden uygulama kullanımında izne izin verin. |
| “Geçerli konum alınamadı” | Core Location o anda uygun konum üretemedi. | Açık alanda tekrar deneyin; simülatörde konum simülasyonunu kontrol edin. |
| Bluetooth ekranı cihaz bulmuyor | Bu sürüm gerçek cihaz taramaz; demo taramasının tamamlanmasını bekleyin. | **Taramayı Başlat**a yeniden dokunun ve aktif köpek kaydı olduğundan emin olun. |
| Bildirim gönderilemiyor | İnternet veya Supabase erişimi kesilmiş olabilir. | İnterneti kontrol edin, açıklamanın boş olmadığını doğrulayın ve yeniden deneyin. |

# Bölüm B — Yönetim Paneli

## B.1 Panele erişim ve giriş

1. Teknik sorumlunun verdiği yönetim paneli adresini tarayıcıda açın. Yerel geliştirmede bu genellikle Vite'ın verdiği yerel adrestir; canlı Vercel adresi bu belgeden doğrulanmış değildir.
2. **E-posta** ve **Parola** alanlarına size tanımlanmış yönetici hesabının bilgilerini girin.
3. **Giriş yap** düğmesine basın.

Giriş iki aşamada denetlenir: Supabase e-posta/parola doğrulaması ve yönetici yetkisi. Doğru parolaya sahip ama yönetici rolü olmayan hesap panelden çıkarılır.

| Sorun | Çözüm |
| --- | --- |
| “E-posta veya parola doğrulanamadı.” | Hesap bilgisini kontrol edin; yeni hesap veya parola işlemi için yetkili sistem sorumlusuna başvurun. |
| “Bu hesap yönetici erişimine sahip değil.” | Hesap giriş yapabiliyor fakat `admin_users` yönetici kaydı yoktur. Sistem sorumlusu doğru yetkilendirmeyi yapmalıdır. |
| “Yapılandırma gerekli” | Panelin yerel Supabase yapılandırması eksiktir. Anahtarları paylaşmadan teknik sorumluya iletin. |

## B.2 Dashboard

Dashboard'ta şu kartlar bulunur:

- **Aktif köpek**
- **Gözlem altında**
- **Tedavi altında**
- **İyileşiyor**
- **Yeni Gözlem Bildirimleri**

Karttaki sayıya tıklamak, ilgili köpek veya bildirim listesini uygun sıralama/filtreyle açar. Bu kartlar hızlı durum özeti verir; ayrıntılı müdahale ilgili sayfada yapılır.

## B.3 Köpek yönetimi

### Listeyi kullanma

1. Sol menüden **Köpekler**i açın.
2. Tabloyu **Ad**, **Sağlık** veya **Durum** başlığına basarak artan/azalan sıralayın.
3. Bir köpeğin ayrıntısı için **Yönet** bağlantısına basın.

Mevcut ekranda serbest metin arama kutusu yoktur. Dashboard kartından gelindiğinde sağlık/aktiflik filtresi uygulanabilir.

### Yeni köpek ekleme

1. **+ Köpek ekle**ye basın.
2. Adı girin; isteğe bağlı olarak JPEG, PNG veya WebP fotoğrafı seçin. Dosya en fazla 5 MB olmalıdır.
3. Cinsiyet, tahmini doğum tarihi, sağlık durumu, açıklama ve **Herkese açık bakım bilgisi** alanlarını doldurun.
4. Köpeğin uygulamada görünmesini istiyorsanız **Aktif** işaretini açık bırakın.
5. **Kaydet**e basın.

Fotoğraflı kayıtta köpek bilgisi önce kaydedilir, fotoğraf yüklenir, sonra fotoğraf yolu profile bağlanır. Fotoğraf aşaması başarısız olsa bile ekrandaki mesajı okuyun; köpek kaydı oluşmuş olabilir. Gereksiz tekrar kayıt oluşturmadan ilgili profilden yeniden deneyin.

### Var olan köpeği düzenleme

1. **Yönet** ile profili açın.
2. Gerekli alanları değiştirin.
3. Tarih alanını boş bırakmak istiyorsanız boş bırakın; sistem SQL `NULL` olarak kaydeder. Geçerli tarih `YYYY-AA-GG` biçimindedir.
4. Yeni fotoğraf seçebilir veya mevcut fotoğraf için **Fotoğrafı kaldır** kutusunu işaretleyebilirsiniz.
5. **Kaydet**e basın.

Köpeği silme düğmesi mevcut ekranda yoktur; **Aktif** işaretini kaldırmak köpeği pasif yapar. Pasif köpek üye uygulamasının aktif listesinden çıkar.

## B.4 Köpek Haritası

1. Sol menüden **Köpek Haritası**nı açın.
2. Soldaki listeden bir köpeği seçin.
3. Haritada sürükleyerek gezin; `+` ve `−` düğmeleriyle yakınlaştırın/uzaklaştırın. Dokunmatik ekranda sıkıştırma hareketi de desteklenir.
4. Pati işaretine veya listedeki köpeğe tıklayarak seçimi değiştirin.
5. Alt ayrıntıda köpeğin adı, koordinatın metin görünümü ve **Yayınlanma zamanı** bulunur.

Konum bilgisi olmayan köpek listede görünse de haritada işaretlenmez. Aynı koordinattaki birden fazla köpek, okunabilirlik için ekranda çevresel olarak ayrıştırılır; gerçek kayıt konumları değişmez.

## B.5 Tasma yönetimi

Bu ekran bir **kayıt ve atama yönetimi** ekranıdır; gerçek Bluetooth bağlantısı sağlamaz.

### Tasma kaydetme veya düzenleme

1. **Tasmalar** sayfasında **+ Tasma kaydet**e basın.
2. Benzersiz **Donanım tanımlayıcısı**nı girin.
3. Varsa **Reklam tanımlayıcısı**nı girin.
4. Kullanılacak tasma için **Etkin** seçeneğini açık bırakın.
5. **Kaydet**e basın.

### Köpeğe tasma atama

1. Sayfadaki atama formunda köpeği seçin.
2. Etkin tasma listesinden tasma seçin.
3. **Etkin atama yap**a basın.

Bir köpeğin ve bir tasmanın aynı anda yalnızca bir etkin ataması olabilir. Atamayı bitirmek için kayıt kartındaki **Atamayı kaldır** düğmesini kullanın.

## B.6 Bakım ikonları

### İkon Kütüphanesi

1. **Bakım İkonları** sayfasını açın; varsayılan sekme **İkon Kütüphanesi**dir.
2. Mevcut kartlarda ikon, görünen ad ve Türkçe açıklama görünür.
3. Yeni bir kayıt eklemek için **+ İkon ekle**yi kullanın.
4. Var olan kaydı değiştirmek için **Düzenle**ye basın.
5. Görünen ad, görsel kategori ve açıklamayı düzenleyip **Kaydet**e basın.

Teknik ikon anahtarları yöneticiye gösterilmez. Standart görsel kategoriler: İyileşme Süreci, Koşmayı Sınırla, Özel Beslenme, Görme Hassasiyeti, İşitme Hassasiyeti ve Düzenli Kontrol'dür. Özel/mevcut anahtarlar **Mevcut özel kategori** olarak korunur ve diğer görseliyle gösterilir.

### Köpek Bakım İkonları

1. **Köpek Bakım İkonları** sekmesine geçin.
2. Soldaki listeden köpeği seçin.
3. İlgili ikon kutularını işaretleyin veya işareti kaldırın.
4. **Değişiklikleri kaydet**e basın.

Köpeğe atanan ikonlar hem yönetici köpek profilinde hem de iOS köpek profilinde aynı anlamla görünür.

## B.7 Sağlık ve tedavi kayıtları

### Güncel sağlık durumunu değiştirme

1. **Sağlık & Tedavi Kayıtları** sayfasını açın.
2. **Mevcut Sağlık Durumları** sekmesinde aktif köpeği bulun.
3. **Mevcut durum** listesinden Normal, Gözlem altında, Tedavi altında veya İyileşiyor seçin.

Seçim yapıldığında kayıt güncellenir ve Dashboard sayıları buna göre değişebilir.

### Sağlık geçmişi ekleme/düzenleme/silme

1. **Sağlık Geçmişi** sekmesine geçin.
2. İsterseniz **Köpeğe göre filtrele** listesinden bir köpek seçin.
3. Yeni kayıt için **+ Kayıt ekle**ye basın; düzenleme için kayıt kartındaki **Düzenle**yi kullanın.
4. Köpek, kayıt türü/durum, başlık, açıklama ve tarih alanlarını doldurun.
5. iOS kullanıcılarının görmesini istiyorsanız **Üyelere açık bilgi** kutusunu işaretleyin.
6. **Kaydet**e basın.

Bir kaydı silmek için **Sil**e basın ve açılan onay penceresinde **Kalıcı olarak sil**i seçin. Bu işlem geri alınamaz; köpek profili ve diğer kayıtlar silinmez.

## B.8 Gözlem Bildirimleri

1. **Gözlem Bildirimleri**ni açın.
2. Tabloyu **Köpek**, **Kategori**, **Önem**, **Tarih** veya **Durum** başlığıyla sıralayın.
3. Bir satırdaki **İncele** düğmesine basın.
4. Bildirim açıklamasını okuyun, durum seçin ve gerekirse **Çözüm notu** yazın.
5. **Güncelle**ye basın.

Durumlar şunlardır:

- **Yeni:** Henüz ele alınmamış bildirim.
- **İnceleniyor:** Yönetici değerlendirmeye başlamış.
- **Çözüldü:** Gerekli işlem tamamlanmış olarak işaretlenmiş.
- **Kapatıldı:** Bildirim kapatılmış; örneğin yinelenen veya işlem gerektirmeyen kayıt olabilir.

Önem dereceleri **Düşük**, **Orta**, **Yüksek**tir. Bildirimler kimlik bilgisi içermeyen üye bildirimleridir; yönetim durumu ve çözüm notu üye uygulamasında gösterilmez.

## B.9 Duyurular

### Yeni duyuru oluşturma

1. **Duyurular** sayfasını açın.
2. **+ Duyuru oluştur**a basın.
3. Başlık ve açıklamayı girin.
4. Hemen iOS'ta görünmesini istiyorsanız **Hemen yayınla**yı işaretleyin.
5. **Kaydet**e basın.

### Yayın durumu ve silme

- **Yayınla:** Taslak duyuruyu üye uygulamasında görünür yapar.
- **Yayından kaldır:** Duyuruyu silmez; iOS listesinden gizler ve taslak gibi tutar.
- **Sil:** Duyuruyu kalıcı olarak kaldırır. Onay penceresindeki **Kalıcı olarak sil** işlemi geri alınamaz.

Mevcut arayüzde yayımlanmış veya taslak duyurunun başlık/metnini sonradan düzenlemek için bir düzenleme formu bulunmaz. Metin yanlışsa, dikkatli davranın: gerekirse duyuruyu yayından kaldırıp doğru metinle yeni bir duyuru oluşturun veya yanlış duyuruyu kalıcı silin.

## B.10 Sık yapılan yönetim işleri

### 1. Yeni köpek eklemek

1. **Köpekler → + Köpek ekle**.
2. Zorunlu ad alanını ve gerekli kamuya açık bilgileri doldurun.
3. Fotoğraf seçilecekse tür ve 5 MB sınırını kontrol edin.
4. **Kaydet**e basın; gerekirse profilden bakım ikonu atayın.

### 2. Sağlık durumunu güncellemek

1. **Sağlık & Tedavi Kayıtları → Mevcut Sağlık Durumları**.
2. Köpeğin satırındaki durum listesinden yeni durumu seçin.
3. Geçmişe açıklamalı bir olay eklemek istiyorsanız ayrıca **Sağlık Geçmişi → + Kayıt ekle** kullanın.

### 3. Bakım ikonu atamak

1. **Bakım İkonları → Köpek Bakım İkonları**.
2. Köpeği seçin.
3. Uygun ikonları seçin.
4. **Değişiklikleri kaydet**e basın.

### 4. Gelen gözlemi incelemek

1. Dashboard'taki **Yeni Gözlem Bildirimleri** kartına veya **Gözlem Bildirimleri** menüsüne basın.
2. Satırdaki **İncele**yi açın.
3. Durumu **İnceleniyor** yapın; sonuçlandığında çözüm notu ile **Çözüldü** veya uygun durumda **Kapatıldı** seçin.
4. **Güncelle**ye basın.

### 5. Son konumu güncellemek (demo akışı)

Yönetim panelinde doğrudan koordinat girme/güncelleme formu yoktur. Kaynakta desteklenen güncelleme yolu iOS'ta Bluetooth demo akışındaki tek seferlik telefon konumu yayınlamadır. Bu işlem gerçek tasma takibi anlamına gelmez.

### 6. Duyuru yayımlamak

1. **Duyurular → + Duyuru oluştur**.
2. Başlık ve açıklamayı yazın.
3. **Hemen yayınla**yı işaretleyip kaydedin; veya taslak kaydedip karttaki **Yayınla** düğmesini kullanın.

### 7. Yanlış duyuruyu silmek

1. İlgili duyuru kartında **Sil**e basın.
2. Başlığı kontrol edin.
3. Geri alınamayacağını doğruladıktan sonra **Kalıcı olarak sil**e basın.

## Yönetici için genel dikkat noktaları

- Üyeye gösterilecek bilgi ile iç yönetim bilgisini ayırın. Sağlık kaydında **Üyelere açık bilgi** seçeneğini bilinçli kullanın.
- Duyuru silme ve sağlık kaydı silme geri alınamaz.
- Gerçek kişisel veya hassas konum bilgisini gereksiz yere yazmayın/paylaşmayın.
- Parola, yayınlanabilir anahtar veya herhangi bir sunucu anahtarını ekran görüntülerine, sunum dosyalarına veya bildirim açıklamalarına koymayın.
- Tasma sayfasındaki kayıtlar gerçek Bluetooth bağlantısının kanıtı değildir; donanım entegrasyonu ayrı bir sonraki aşamadır.
