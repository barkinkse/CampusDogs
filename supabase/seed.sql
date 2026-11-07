-- Campus Dogs development-only dataset. Do not run against production data.
-- Requires migrations 001–004. This script creates no locations, collars, member identities, credentials, or image objects.
insert into public.dogs (id, name, gender, estimated_birth_date, description, public_health_status, public_care_info, is_active) values
('10000000-0000-4000-8000-000000000001','Duman','male','2021-01-01','Kampüsün ana giriş ve merkezi bahçe çevresinde sık görülen, insanlara alışık sakin bir köpektir.','normal','Özel bir bakım gereksinimi bulunmuyor; temiz su ve uygun mama desteği yeterlidir.',true),
('10000000-0000-4000-8000-000000000002','Tarçın','female','2023-03-15','Kütüphane ve öğrenci merkezi çevresinde görülen, meraklı ancak sakin yaklaşımı seven genç bir köpektir.','under_observation','Yürüyüşü gözlem altındadır. Lütfen koşturmayın ve olağan dışı bir durum fark ederseniz bildirim gönderin.',true),
('10000000-0000-4000-8000-000000000003','Boncuk','male','2019-06-20','Fen fakültesi bahçesinde dinlenmeyi seven, kampüsün uzun süredir tanınan sakinlerinden biridir.','recovering','Kontrol sürecinde dinlenmeye ihtiyacı olabilir. Nazik yaklaşın ve yoğun hareketten kaçınmasına yardımcı olun.',true)
on conflict (id) do update set name=excluded.name, gender=excluded.gender, estimated_birth_date=excluded.estimated_birth_date, description=excluded.description, public_health_status=excluded.public_health_status, public_care_info=excluded.public_care_info, is_active=excluded.is_active;

insert into public.care_icons (id, name, icon_key, description) values
('20000000-0000-4000-8000-000000000001','İyileşme Süreci','recovery','Tedavi süreci devam ediyor.'),
('20000000-0000-4000-8000-000000000002','Koşmayı Sınırla','limit_running','Eklem, kalp veya solunum hassasiyeti nedeniyle koşmasını teşvik etmeyin.'),
('20000000-0000-4000-8000-000000000003','Özel Beslenme','special_diet','Veterinerin belirlediği beslenme düzeni var; izinsiz yiyecek vermeyin.'),
('20000000-0000-4000-8000-000000000004','Düzenli Kontrol','regular_checkup','Periyodik veteriner kontrolü gerekiyor.'),
('20000000-0000-4000-8000-000000000005','Görme Hassasiyeti','vision_sensitivity','Çevreyi algılamakta zorlanabilir. Yavaş ve sakin yaklaşın.'),
('20000000-0000-4000-8000-000000000006','İşitme Hassasiyeti','hearing_sensitivity','Sesleri daha az algılar. Ani hareketlerden kaçının.')
on conflict (id) do update set name=excluded.name, icon_key=excluded.icon_key, description=excluded.description;

insert into public.dog_care_icons (dog_id, care_icon_id)
select a.dog_id, i.id from (values
('10000000-0000-4000-8000-000000000001'::uuid,'Düzenli Kontrol'),('10000000-0000-4000-8000-000000000002'::uuid,'Koşmayı Sınırla'),('10000000-0000-4000-8000-000000000002'::uuid,'Özel Beslenme'),('10000000-0000-4000-8000-000000000002'::uuid,'Düzenli Kontrol'),('10000000-0000-4000-8000-000000000003'::uuid,'İyileşme Süreci'),('10000000-0000-4000-8000-000000000003'::uuid,'Düzenli Kontrol')) as a(dog_id, icon_name)
join public.care_icons i on i.name=a.icon_name on conflict (dog_id, care_icon_id) do nothing;

insert into public.announcements (id,title,body,image_path,is_published,published_at) values
('30000000-0000-4000-8000-000000000001','Boncuk’un kontrolü tamamlandı','Boncuk’un planlanan veteriner kontrolü tamamlandı. İyileşme döneminde dinlenmesine alan tanımanız ve yoğun hareketten kaçınmanız rica olunur.',null,true,'2026-11-01T09:00:00Z'),
('30000000-0000-4000-8000-000000000002','Kampüs hayvan bakım hatırlatması','Kampüsümüzdeki mama ve su kaplarının günlük kontrolleri düzenli olarak yapılmaktadır. Eksik veya kirli kap fark ederseniz yönetim ekibine bildirim gönderebilirsiniz.',null,true,'2026-11-02T09:00:00Z')
on conflict (id) do update set title=excluded.title, body=excluded.body, image_path=excluded.image_path, is_published=excluded.is_published, published_at=excluded.published_at;

insert into public.health_records (id,dog_id,title,description,status,is_public,recorded_at) values
('40000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Rutin sağlık kontrolü','Duman’ın genel durumu ve iştahı rutin kontrolde normal değerlendirildi.','normal',true,'2026-10-20T09:00:00Z'),
('40000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','Yürüyüş gözlemi','Tarçın’ın sol arka ayağını koruyarak yürüdüğüne ilişkin gözlem için takip süreci başlatıldı.','under_observation',true,'2026-10-28T09:00:00Z'),
('40000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000003','Kontrol takibi','Boncuk için planlanan takip kontrolünün tarihi bakım ekibi tarafından izleniyor.','recovering',false,'2026-10-30T09:00:00Z')
on conflict (id) do update set dog_id=excluded.dog_id, title=excluded.title, description=excluded.description, status=excluded.status, is_public=excluded.is_public, recorded_at=excluded.recorded_at;

-- These are anonymous development scenarios only; they contain no member identity or contact data.
insert into public.member_reports (id,dog_id,category,description,severity,status,resolution_description,resolved_at,created_at) values
('60000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','Yürüyüş gözlemi','Tarçın’ın kütüphane çevresinde yürürken sol arka ayağına ağırlık vermekte zorlandığını gözlemledim. İlgili bölgenin kontrol edilmesini rica ediyorum.','high','reviewing',null,null,'2026-10-27T13:40:00Z'),
('60000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','Mama ve su kabı','Duman’ın bulunduğu ana giriş yakınındaki su kabının boş olduğunu fark ettim. Kontrol edilmesini rica ederim.','low','resolved','Su kabı temizlenip dolduruldu; alanın günlük kontrol listesine not eklendi.','2026-10-25T11:20:00Z','2026-10-25T10:45:00Z')
on conflict (id) do update set dog_id=excluded.dog_id, category=excluded.category, description=excluded.description, severity=excluded.severity, status=excluded.status, resolution_description=excluded.resolution_description, resolved_at=excluded.resolved_at;

-- Optional private-note fixture: replace ADMIN_USER_UUID with an existing public.admin_users UUID, then uncomment.
-- insert into public.admin_notes (id,dog_id,body,author_id) values ('50000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','Tarçın için iletilen yürüyüş gözlemi veteriner kontrolü kapsamında değerlendirilmek üzere takip listesine alındı.','ADMIN_USER_UUID') on conflict (id) do update set body=excluded.body;
