-- Manual, development-fixture-only content refresh. Do not execute automatically.
-- Each statement targets a stable seed UUID and its exact previous fixture text,
-- so it cannot overwrite a user-created record with the same identifier alone.

update public.dogs set
  description = 'Kampüsün ana giriş ve merkezi bahçe çevresinde sık görülen, insanlara alışık sakin bir köpektir.',
  public_care_info = 'Özel bir bakım gereksinimi bulunmuyor; temiz su ve uygun mama desteği yeterlidir.'
where id = '10000000-0000-4000-8000-000000000001'
  and description = 'Geliştirme ortamı için örnek kampüs köpeği.';

update public.dogs set
  description = 'Kütüphane ve öğrenci merkezi çevresinde görülen, meraklı ancak sakin yaklaşımı seven genç bir köpektir.',
  public_care_info = 'Yürüyüşü gözlem altındadır. Lütfen koşturmayın ve olağan dışı bir durum fark ederseniz bildirim gönderin.'
where id = '10000000-0000-4000-8000-000000000002'
  and description = 'Geliştirme ortamı için örnek kampüs köpeği.';

update public.dogs set
  description = 'Fen fakültesi bahçesinde dinlenmeyi seven, kampüsün uzun süredir tanınan sakinlerinden biridir.',
  public_care_info = 'Kontrol sürecinde dinlenmeye ihtiyacı olabilir. Nazik yaklaşın ve yoğun hareketten kaçınmasına yardımcı olun.'
where id = '10000000-0000-4000-8000-000000000003'
  and description = 'Geliştirme ortamı için örnek kampüs köpeği.';

update public.care_icons set name = 'İyileşme Süreci', icon_key = 'recovery', description = 'Tedavi süreci devam ediyor.'
where id = '20000000-0000-4000-8000-000000000001'
  and icon_key = 'recovery';

update public.care_icons set name = 'Koşmayı Sınırla', icon_key = 'limit_running', description = 'Eklem, kalp veya solunum hassasiyeti nedeniyle koşmasını teşvik etmeyin.'
where id = '20000000-0000-4000-8000-000000000002'
  and icon_key = 'limit_running';

update public.care_icons set name = 'Özel Beslenme', icon_key = 'special_diet', description = 'Veterinerin belirlediği beslenme düzeni var; izinsiz yiyecek vermeyin.'
where id = '20000000-0000-4000-8000-000000000003'
  and icon_key = 'special_diet';

update public.care_icons set name = 'Düzenli Kontrol', icon_key = 'regular_checkup', description = 'Periyodik veteriner kontrolü gerekiyor.'
where id = '20000000-0000-4000-8000-000000000004'
  and icon_key = 'regular_checkup';

update public.announcements set
  title = 'Boncuk’un kontrolü tamamlandı',
  body = 'Boncuk’un planlanan veteriner kontrolü tamamlandı. İyileşme döneminde dinlenmesine alan tanımanız ve yoğun hareketten kaçınmanız rica olunur.'
where id = '30000000-0000-4000-8000-000000000001'
  and title = 'Boncuk’un veteriner süreci tamamlandı'
  and body = 'Boncuk’un planlanan veteriner kontrolü tamamlandı. Kampüs içinde sakin yaklaşımınızı sürdürmeniz rica olunur.';

update public.announcements set
  body = 'Kampüsümüzdeki mama ve su kaplarının günlük kontrolleri düzenli olarak yapılmaktadır. Eksik veya kirli kap fark ederseniz yönetim ekibine bildirim gönderebilirsiniz.'
where id = '30000000-0000-4000-8000-000000000002'
  and title = 'Kampüs hayvan bakım hatırlatması'
  and body = 'Kampüs dostlarına uygun olmayan yiyecek vermeyin; güncel bakım simgelerini köpek profillerinden inceleyin.';

update public.health_records set
  title = 'Rutin sağlık kontrolü',
  description = 'Duman’ın genel durumu ve iştahı rutin kontrolde normal değerlendirildi.'
where id = '40000000-0000-4000-8000-000000000001'
  and title = 'Rutin gelişim kontrolü'
  and description = 'Geliştirme verisi: kamuya açık rutin kontrol kaydı.';

update public.health_records set
  title = 'Yürüyüş gözlemi',
  description = 'Tarçın’ın sol arka ayağını koruyarak yürüdüğüne ilişkin gözlem için takip süreci başlatıldı.'
where id = '40000000-0000-4000-8000-000000000002'
  and title = 'Gözlem dönemi'
  and description = 'Geliştirme verisi: kamuya açık gözlem bilgisi.';

update public.health_records set
  title = 'Kontrol takibi',
  description = 'Boncuk için planlanan takip kontrolünün tarihi bakım ekibi tarafından izleniyor.'
where id = '40000000-0000-4000-8000-000000000003'
  and title = 'Yönetici görünürlük testi'
  and description = 'Geliştirme verisi: yalnızca RLS görünürlük testi için özel kayıttır.';

update public.admin_notes set
  body = 'Tarçın için iletilen yürüyüş gözlemi veteriner kontrolü kapsamında değerlendirilmek üzere takip listesine alındı.'
where id = '50000000-0000-4000-8000-000000000001'
  and body = 'Geliştirme verisi: yalnızca yönetici notu görünürlük testi.';
