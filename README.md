# SONNO Çəkiliş Sistemi — Deploy təlimatı

Bu qovluqda 3 fayl var:
- `index.html` — bütün sayt (müştəri hissəsi + admin panel)
- `schema.sql` — Supabase verilənlər bazası quruluşu
- `README.md` — bu təlimat

Aşağıdakı addımları ardıcıl edin. Cəmi ~15-20 dəqiqə çəkir.

---

## 1-ci addım — Supabase layihəsi

1. https://supabase.com → **New project**
2. Layihəyə ad verin (məs. `sonno-cekilis`), güclü verilənlər bazası parolu qoyun, region seçin (Frankfurt ən yaxınıdır) → **Create**
3. Layihə hazır olandan sonra, sol menyudan **SQL Editor** → **New query**
4. Bu qovluqdakı `schema.sql` faylının **bütün** məzmununu kopyalayıb yapışdırın → **Run**
   - Bu, bütün cədvəlləri, təhlükəsizlik qaydalarını (RLS) və 1 nümunə kampaniya yaradacaq.
5. Sol menyudan **Authentication → Users → Add user**
   - Email: öz admin e-poçtunuz (məs. `admin@sonno.az`)
   - Password: güclü bir parol
   - **Auto Confirm User** qutusunu işarələyin
   - **Create user**
   - Bu email/parol ilə sistemin admin panelinə daxil olacaqsınız.
6. Sol menyudan **Settings → API** — bu iki dəyəri kopyalayın:
   - **Project URL** (məs. `https://abcxyz.supabase.co`)
   - **anon public** açarı (uzun bir mətn)

---

## 2-ci addım — kodu konfiqurasiya edin

`index.html` faylını açın, ~170-ci sətir civarında bunu tapın:

```js
const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
```

Öz Project URL və anon public açarınızla əvəz edin, yadda saxlayın.

> **Qeyd:** `anon public` açarı brauzerdə görünəcək — bu normaldır və təhlükəsizdir, çünki bütün giriş qaydaları (RLS) verilənlər bazası tərəfində qorunur. **Heç vaxt** `service_role` açarını bura yazmayın.

---

## 3-cü addım — GitHub-a yükləyin

Öz kompüterinizdə (və ya GitHub-un veb interfeysində "Add file → Upload files" ilə):

```bash
mkdir sonno-cekilis && cd sonno-cekilis
# index.html və schema.sql fayllarını bu qovluğa qoyun
git init
git add .
git commit -m "SONNO çəkiliş sistemi"
git branch -M main
git remote add origin https://github.com/İSTİFADƏÇİ_ADINIZ/sonno-cekilis.git
git push -u origin main
```

(GitHub-da əvvəlcə boş bir repository yaradın: github.com → **New repository**)

---

## 4-cü addım — Vercel-ə deploy edin

1. https://vercel.com → **Add New → Project**
2. GitHub hesabınızı qoşun (ilk dəfədirsə) → `sonno-cekilis` repository-sini seçin → **Import**
3. Framework Preset: **Other** (statik HTML, əlavə build lazım deyil)
4. **Deploy** düyməsinə basın
5. ~30 saniyə sonra sizə bir domen veriləcək: `sonno-cekilis.vercel.app`

Bundan sonra sayt **daim işləyəcək** — siz kompüteri bağlasanız belə.

### Öz domeninizi bağlamaq (sonno.az)
Vercel layihəsində **Settings → Domains → Add** → `sonno.az` yazın → Vercel sizə DNS qeydləri verəcək → onları domen provayderinizin panelində (məs. hostinq şirkəti) əlavə edin.

---

## 5-ci addım — test edin

1. `https://sonno-cekilis.vercel.app` açın → kampaniya linkinə klikləyin → test qeydiyyatı aparın
2. `https://sonno-cekilis.vercel.app/#/admin` → admin e-poçt/parolunuzla daxil olun → qeydiyyatı görməlisiniz
3. QR kodu admin paneldən yükləyib telefonla skan edin — **bu dəfə işləyəcək**, çünki artıq real, daimi bir ünvana yönləndirir.

---

## Sonra nə etmək olar (tövsiyələr)

- **Domen:** `sonno.az`-ı Vercel-ə bağlayın ki, QR kodlar həmişəlik `sonno.az/#/campaign/...` formatında qalsın.
- **Yeni admin istifadəçilər:** Supabase → Authentication → Users-dən əlavə edə bilərsiniz.
- **Ehtiyat nüsxə:** Supabase avtomatik gündəlik backup edir (Settings → Database → Backups).
- **Nəzarət:** Supabase Dashboard-da Table Editor vasitəsilə bütün məlumatları birbaşa görə/redaktə edə bilərsiniz.
- Sistemin böyüməsi (SMS bildirişi, 1C/POS inteqrasiyası və s.) üçün əlavə inkişaf lazımdır — hazırkı versiya əsas axını tam əhatə edir.
