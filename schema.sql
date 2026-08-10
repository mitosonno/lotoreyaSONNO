-- =========================================================================
-- SONNO Müştəri Hədiyyə Çəkilişi — Supabase verilənlər bazası quruluşu
-- Bunu Supabase layihənizdə: SQL Editor → New query → yapışdırın → Run
-- =========================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- CAMPAIGNS
create table campaigns (
  id           uuid primary key default gen_random_uuid(),
  slug         text unique not null,
  name         text not null,
  description  text default '',
  start_date   date,
  end_date     date,
  draw_date    timestamptz not null,
  status       text not null default 'Hazırlanır',
  prizes       jsonb not null default '[]',
  created_at   timestamptz default now()
);

-- ----------------------------------------------------------------- PRODUCTS
create table products (
  id   uuid primary key default gen_random_uuid(),
  name text not null
);

-- ------------------------------------------------------------ REGISTRATIONS
create table registrations (
  id             uuid primary key default gen_random_uuid(),
  campaign_id    uuid references campaigns(id) on delete cascade,
  first_name     text not null,
  last_name      text not null,
  phone          text not null,
  city           text not null,
  store          text not null,
  purchase_date  date not null,
  items          jsonb not null default '[]',
  total_amount   numeric not null,
  dup_hash       text unique not null,   -- eyni alışın təkrar qeydiyyatının qarşısını DB səviyyəsində alır
  created_at     timestamptz default now()
);

-- ----------------------------------------------------------------- TICKETS
create table tickets (
  id               uuid primary key default gen_random_uuid(),
  ticket_code      text unique not null,   -- SONNO-26-XXXXX (unikallıq DB səviyyəsində təmin olunur)
  campaign_id      uuid references campaigns(id) on delete cascade,
  registration_id  uuid references registrations(id) on delete cascade,
  status           text not null default 'Aktiv'   -- Aktiv | Qalib | İstifadə olunub | Ləğv edilib
);

-- ----------------------------------------------------------------- WINNERS
create table winners (
  id               uuid primary key default gen_random_uuid(),
  campaign_id      uuid references campaigns(id) on delete cascade,
  prize_id         text,
  prize_name       text,
  prize_order      int,
  ticket_id        uuid references tickets(id),
  ticket_code      text,
  registration_id  uuid references registrations(id),
  draw_time        timestamptz default now()
);

-- ----------------------------------------------------- PUBLIC WINNERS VIEW
-- Qaliblər səhifəsi bu görünüşdən oxuyur — ad/telefon artıq DB səviyyəsində
-- maskalanıb, ona görə tam məlumat heç vaxt brauzerə çatmır.
create view winners_public as
select
  w.id, w.campaign_id, w.prize_name, w.prize_order, w.ticket_code, w.draw_time,
  left(r.first_name,1) || '***' as first_name_masked,
  left(r.last_name,1)  || '***' as last_name_masked,
  '+994 ** *** ** ' || right(regexp_replace(r.phone,'[^0-9]','','g'),2) as phone_masked
from winners w
join registrations r on r.id = w.registration_id;

grant select on winners_public to anon, authenticated;

-- =========================================================================
-- ROW LEVEL SECURITY
-- Qayda: açıq (public) məlumat hər kəsə oxunur; müştəri məlumatları (ad,
-- telefon, alış detalları) YALNIZ giriş etmiş admin tərəfindən oxuna bilər.
-- Müştəri formunun özü isə YALNIZ yazmaq (insert) hüququna malikdir —
-- öz yazdığı sətri belə geri oxuya bilmir, çünki tickets/reg cavabı onsuz
-- da brauzerdə (client tərəfdə) formalaşdırılıb göstərilir.
-- =========================================================================

alter table campaigns     enable row level security;
alter table products      enable row level security;
alter table registrations enable row level security;
alter table tickets       enable row level security;
alter table winners       enable row level security;

-- Kampaniyalar: hər kəs oxuya bilər (səhifə açılışı üçün), yalnız admin yaza bilər
create policy "campaigns_public_read"  on campaigns for select using (true);
create policy "campaigns_admin_write"  on campaigns for insert with check (auth.role() = 'authenticated');
create policy "campaigns_admin_update" on campaigns for update using (auth.role() = 'authenticated');
create policy "campaigns_admin_delete" on campaigns for delete using (auth.role() = 'authenticated');

-- Məhsul kataloqu: hər kəs oxuya bilər, yalnız admin yaza bilər
create policy "products_public_read"  on products for select using (true);
create policy "products_admin_write"  on products for insert with check (auth.role() = 'authenticated');
create policy "products_admin_delete" on products for delete using (auth.role() = 'authenticated');

-- Qeydiyyatlar: hər kəs YAZA bilər (öz qeydiyyatını göndərmək üçün),
-- YALNIZ admin oxuya bilər (telefon/ad kimi həssas sahələr qorunur)
create policy "registrations_public_insert" on registrations for insert with check (true);
create policy "registrations_admin_read"    on registrations for select using (auth.role() = 'authenticated');

-- Biletlər: hər kəs YAZA bilər (qeydiyyat zamanı bilet yaradılır),
-- YALNIZ admin oxuya və dəyişə bilər (məs. çəkiliş zamanı status dəyişimi)
create policy "tickets_public_insert" on tickets for insert with check (true);
create policy "tickets_admin_read"    on tickets for select using (auth.role() = 'authenticated');
create policy "tickets_admin_update"  on tickets for update using (auth.role() = 'authenticated');

-- Qaliblər: tam məlumat yalnız admin üçün (ictimai səhifə winners_public-dən oxuyur)
create policy "winners_admin_read"  on winners for select using (auth.role() = 'authenticated');
create policy "winners_admin_write" on winners for insert with check (auth.role() = 'authenticated');

-- =========================================================================
-- Nümunə başlanğıc data (istəyə bağlı — silə bilərsiniz)
-- =========================================================================
insert into products (name) values
  ('Stul'),('Divan'),('Kreslo'),('Masa'),('Şkaf'),('Mətbəx mebeli'),('Yataq dəsti'),('Aksesuar');

insert into campaigns (slug, name, description, start_date, end_date, draw_date, status, prizes)
values (
  '2026-yay', 'SONNO 2026 Yay Kampaniyası',
  'SONNO-dan məhsul alın, çekiliş biletinizi qazanın və möhtəşəm hədiyyələr qazanmaq şansı əldə edin.',
  current_date, current_date + interval '30 days', now() + interval '32 days',
  'Aktiv',
  '[
    {"id":"pz1","name":"iPhone 17 Pro","description":"256GB, bütün rənglərdə","image":"","quantity":1,"value":"2600 AZN","winnerCount":1,"order":1},
    {"id":"pz2","name":"SONNO Divan Dəsti","description":"Seçdiyiniz kolleksiyadan","image":"","quantity":1,"value":"3200 AZN","winnerCount":1,"order":2},
    {"id":"pz3","name":"500 AZN Alış Kuponu","description":"İstənilən SONNO mağazasında","image":"","quantity":5,"value":"500 AZN","winnerCount":5,"order":3}
  ]'::jsonb
);

-- =========================================================================
-- SONRAKI ADIM: admin girişi üçün istifadəçi yaradın
-- Supabase Dashboard → Authentication → Users → "Add user" →
--   Email: sizin admin e-poçtunuz, Password: güclü parol,
--   "Auto Confirm User" işarəsini aktivləşdirin.
-- Bu email/parol ilə sistemin admin panelinə daxil olacaqsınız.
-- =========================================================================
