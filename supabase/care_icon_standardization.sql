-- Manual care-icon standardization for an authorized environment.
-- Do not run automatically. Review the preflight query first and retain its result.
-- Existing recovery, running, diet, and checkup rows are updated in place, so their
-- dog_care_icons relationships remain attached to the same care_icon_id values.

-- Preflight: records outside the six supported keys require a human mapping decision.
select ci.id, ci.name, ci.icon_key, count(dci.dog_id) as assigned_dog_count
from public.care_icons ci
left join public.dog_care_icons dci on dci.care_icon_id = ci.id
group by ci.id, ci.name, ci.icon_key
having ci.icon_key not in ('recovery', 'limit_running', 'special_diet', 'vision_sensitivity', 'hearing_sensitivity', 'regular_checkup')
order by ci.name;

begin;

-- Four established keys retain their IDs and every existing dog assignment.
update public.care_icons set name = 'İyileşme Süreci', description = 'Tedavi süreci devam ediyor.' where icon_key = 'recovery';
update public.care_icons set name = 'Koşmayı Sınırla', description = 'Eklem, kalp veya solunum hassasiyeti nedeniyle koşmasını teşvik etmeyin.' where icon_key = 'limit_running';
update public.care_icons set name = 'Özel Beslenme', description = 'Veterinerin belirlediği beslenme düzeni var; izinsiz yiyecek vermeyin.' where icon_key = 'special_diet';
update public.care_icons set name = 'Düzenli Kontrol', description = 'Periyodik veteriner kontrolü gerekiyor.' where icon_key = 'regular_checkup';

-- New semantics are inserted with stable development IDs. They receive no implicit assignments.
insert into public.care_icons (id, name, icon_key, description) values
  ('20000000-0000-4000-8000-000000000005', 'Görme Hassasiyeti', 'vision_sensitivity', 'Çevreyi algılamakta zorlanabilir. Yavaş ve sakin yaklaşın.'),
  ('20000000-0000-4000-8000-000000000006', 'İşitme Hassasiyeti', 'hearing_sensitivity', 'Sesleri daha az algılar. Ani hareketlerden kaçının.')
on conflict (id) do update set name = excluded.name, icon_key = excluded.icon_key, description = excluded.description;

-- Validation: exactly the supported keys are expected. Do not commit if the
-- preflight query returned unmatched assigned records that need a manual mapping.
select id, name, icon_key, description from public.care_icons order by icon_key;

commit;
