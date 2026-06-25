-- 행복 나눔 공원 (Happy Sharing Park) 스키마
-- Supabase Auth: auth.users 와 연동

-- ---------------------------------------------------------------------------
-- 1. 회원 프로필 (auth.users 확장)
-- 기존 public.users(타 앱)와 분리 — auth.users 전용
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 2. 운동장 시설 (4종)
-- ---------------------------------------------------------------------------
create table if not exists public.facilities (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('soccer', 'futsal', 'basketball', 'badminton')),
  name text not null,
  description text,
  price_per_2h integer not null check (price_per_2h >= 0),
  image_url text,
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 3. 운동장 운영 시간 (요일별 — 2시간 슬롯 생성용)
-- ---------------------------------------------------------------------------
create table if not exists public.facility_operating_hours (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  open_time time not null,
  close_time time not null,
  is_closed boolean not null default false,
  unique (facility_id, day_of_week)
);

-- ---------------------------------------------------------------------------
-- 4. 공원 휴무일
-- ---------------------------------------------------------------------------
create table if not exists public.park_holidays (
  id uuid primary key default gen_random_uuid(),
  holiday_date date not null unique,
  reason text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 5. 결제 (운동장·자전거 공통)
-- ---------------------------------------------------------------------------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  amount integer not null check (amount >= 0),
  payment_type text not null check (payment_type in ('field', 'bike', 'bike_extra')),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'cancelled', 'refunded')),
  pg_provider text,
  pg_transaction_id text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 6. 운동장 예약 (2시간 단위)
-- ---------------------------------------------------------------------------
create table if not exists public.field_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  facility_id uuid not null references public.facilities(id) on delete restrict,
  booking_date date not null,
  slot_start time not null,
  slot_end time not null,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'cancelled', 'completed', 'no_show')),
  payment_id uuid references public.payments(id) on delete set null,
  total_amount integer not null check (total_amount >= 0),
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  constraint field_bookings_slot_check check (slot_end > slot_start),
  unique (facility_id, booking_date, slot_start)
);

create index if not exists field_bookings_user_idx on public.field_bookings (user_id);
create index if not exists field_bookings_date_idx on public.field_bookings (booking_date);

-- ---------------------------------------------------------------------------
-- 7. 자전거 종류 (3종)
-- ---------------------------------------------------------------------------
create table if not exists public.bikes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('single', 'tandem', 'kids')),
  name text not null,
  description text,
  price_30min integer not null check (price_30min >= 0),
  price_per_10min_extra integer not null check (price_per_10min_extra >= 0),
  stock_total integer not null default 0 check (stock_total >= 0),
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. 자전거 대여 (30분 기본 + 초과 10분 단위)
-- ---------------------------------------------------------------------------
create table if not exists public.bike_rentals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  bike_id uuid not null references public.bikes(id) on delete restrict,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_minutes integer check (duration_minutes is null or duration_minutes >= 0),
  base_amount integer not null default 0 check (base_amount >= 0),
  extra_amount integer not null default 0 check (extra_amount >= 0),
  total_amount integer not null default 0 check (total_amount >= 0),
  status text not null default 'active'
    check (status in ('active', 'returned', 'cancelled')),
  payment_id uuid references public.payments(id) on delete set null,
  extra_payment_id uuid references public.payments(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists bike_rentals_user_idx on public.bike_rentals (user_id);
create index if not exists bike_rentals_status_idx on public.bike_rentals (status);

-- ---------------------------------------------------------------------------
-- 9. 후기
-- ---------------------------------------------------------------------------
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('field', 'bike')),
  field_booking_id uuid references public.field_bookings(id) on delete set null,
  bike_rental_id uuid references public.bike_rentals(id) on delete set null,
  rating smallint not null check (rating between 1 and 5),
  content text not null,
  image_urls text[] default '{}',
  is_visible boolean not null default true,
  created_at timestamptz not null default now(),
  constraint reviews_target_check check (
    (target_type = 'field' and field_booking_id is not null and bike_rental_id is null)
    or (target_type = 'bike' and bike_rental_id is not null and field_booking_id is null)
  )
);

create index if not exists reviews_target_idx on public.reviews (target_type, created_at desc);

-- ---------------------------------------------------------------------------
-- 10. 고객센터 — 공지
-- ---------------------------------------------------------------------------
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  is_pinned boolean not null default false,
  is_published boolean not null default true,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 11. 고객센터 — FAQ (AI RAG 문서 원본으로도 사용)
-- ---------------------------------------------------------------------------
create table if not exists public.faqs (
  id uuid primary key default gen_random_uuid(),
  category text not null default 'general',
  question text not null,
  answer text not null,
  sort_order smallint not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 12. 고객센터 — 1:1 문의
-- ---------------------------------------------------------------------------
create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null default 'general',
  title text not null,
  content text not null,
  status text not null default 'open'
    check (status in ('open', 'answered', 'closed')),
  admin_reply text,
  replied_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists inquiries_user_idx on public.inquiries (user_id);

-- ---------------------------------------------------------------------------
-- 13. RLS 활성화 (정책은 앱 단계에서 추가)
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.facilities enable row level security;
alter table public.facility_operating_hours enable row level security;
alter table public.park_holidays enable row level security;
alter table public.payments enable row level security;
alter table public.field_bookings enable row level security;
alter table public.bikes enable row level security;
alter table public.bike_rentals enable row level security;
alter table public.reviews enable row level security;
alter table public.notices enable row level security;
alter table public.faqs enable row level security;
alter table public.inquiries enable row level security;

-- ---------------------------------------------------------------------------
-- 14. 시드 데이터 — 시설·자전거·FAQ
-- ---------------------------------------------------------------------------
insert into public.facilities (code, name, description, price_per_2h, sort_order) values
  ('soccer', '축구장', '11인제 축구장', 80000, 1),
  ('futsal', '풋살장', '5인제 풋살장', 50000, 2),
  ('basketball', '농구장', '풀코트 농구장', 40000, 3),
  ('badminton', '배드민턴장', '복식 2코트', 30000, 4)
on conflict (code) do nothing;

insert into public.bikes (code, name, description, price_30min, price_per_10min_extra, stock_total, sort_order) values
  ('single', '두발자전거 1인용', '성인 1인용', 3000, 1000, 20, 1),
  ('tandem', '두발자전거 2인용', '2인 동승', 5000, 1500, 10, 2),
  ('kids', '유아용 네발자전거', '보조바퀴 유아용', 2000, 500, 15, 3)
on conflict (code) do nothing;

insert into public.faqs (category, question, answer, sort_order) values
  ('field', '운동장은 몇 시간 단위로 예약하나요?', '모든 운동장은 2시간 단위로 예약·결제됩니다.', 1),
  ('bike', '자전거 요금은 어떻게 되나요?', '기본 30분 요금 결제 후, 30분 초과 시 10분 단위로 추가 요금이 부과됩니다.', 2),
  ('general', '행복 나눔 공원 운영시간은?', '시설별 운영시간은 예약 페이지에서 확인할 수 있습니다.', 3)
on conflict do nothing;
