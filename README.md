# Circle OLEXTY — Static + Supabase

Website komunitas murni **HTML5 + CSS3 + JavaScript vanilla**. Hosting target Netlify Drop; Auth, database, dan Storage menggunakan Supabase. Tidak ada Express, Node backend, React, Next, localStorage, atau sessionStorage buatan aplikasi. Supabase Auth SDK mengelola sesi login.

## Isi project
- `index.html`: beranda dengan hero/banner, profil, tim, member, event + countdown, galeri lightbox, link sosial.
- `login.html`, `register.html`: autentikasi Supabase.
- `profile.html`: edit profil, avatar, privasi ID Free Fire, ganti password.
- `admin.html`: dashboard tab dan CRUD konten.
- `css/style.css`, `css/admin.css`: tema dark gaming oranye, responsive.
- `js/supabase-config.js`: konfigurasi project.
- `js/auth.js`, `js/main.js`, `js/profile.js`, `js/admin.js`: logic vanilla JS.
- `data/db.json`: fallback demo.
- `data/setup.sql`: schema, trigger, RLS, bucket Storage.
- `netlify.toml`: publish folder root + header.

## 1. Setup Supabase
1. Buat project gratis di https://supabase.com/dashboard.
2. Buka **Project Settings → API** (nama menu bisa berbeda di dashboard terbaru). Salin **Project URL** dan **publishable/anon key**. Jangan pernah gunakan `service_role` key di frontend.
3. Edit `js/supabase-config.js`, ganti:
   ```js
   const SUPABASE_URL = "ISI_URL_SUPABASE_KAMU";
   const SUPABASE_ANON_KEY = "ISI_ANON_KEY_SUPABASE_KAMU";
   ```
4. Buka SQL Editor di Supabase, tempel seluruh `data/setup.sql`, lalu Run.
5. Untuk upload, script SQL membuat bucket `uploads` publik dengan batas 20 MB. Kebijakan upload hanya untuk user terautentikasi; penghapusan file dibatasi admin.
6. Buat akun lewat `register.html`, konfirmasi email jika diwajibkan. Jadikan admin lewat SQL Editor, ganti email contoh:
   ```sql
   update public.profiles
   set role = 'admin'
   where id = (select id from auth.users where email = 'EMAIL_ADMIN_KAMU');
   ```
   Jangan pernah membuka pilihan role admin di formulir registrasi.

## 2. Jalankan / preview
- Dengan Supabase belum disetel, `index.html` mencoba mengambil `data/db.json` untuk menampilkan demo.
- Cara paling stabil untuk mengetes file statis sebelum deploy adalah VS Code Live Server atau `python -m http.server 8080`, lalu buka `http://localhost:8080`. Double-click `index.html` juga dapat menampilkan HTML, tetapi `fetch("data/db.json")` umumnya diblokir oleh browser untuk `file://`; jadi fallback JSON tidak dijamin berjalan dengan double-click. Auth dan upload Supabase memerlukan konfigurasi dan koneksi internet.

## 3. Deploy Netlify Drop
1. Pastikan `index.html` berada di root folder `circle-freefire`.
2. Buka https://app.netlify.com/drop.
3. Drag & drop folder `circle-freefire` (atau ZIP yang sudah diekstrak).
4. Setelah mendapat URL Netlify, tambahkan domain di Supabase **Authentication → URL Configuration → Site URL / Redirect URLs** jika dibutuhkan.
5. Tes daftar, verifikasi email, login, profil, upload, dan admin.

Untuk update, drag folder terbaru ke Netlify lagi atau hubungkan repository GitHub.

## Keamanan penting
- `anon/publishable key` memang boleh berada di browser; keselamatan berasal dari RLS. Jangan pernah mempublikasikan `service_role` key.
- RLS di `data/setup.sql` membatasi query profil penuh untuk pengguna login/admin; halaman member showcase sebaiknya memakai view `public_member_showcase`. Jika ingin menampilkan member ke pengunjung tanpa login, perlu policy/view yang sesuai dan jangan pernah membuka email atau data sensitif.
- Role admin tidak boleh diubah oleh user biasa. RLS melindungi perubahan role; promosi admin pertama dilakukan lewat SQL.
- Untuk produksi, pertimbangkan kebijakan email verification, rate limiting, Content Security Policy, dan audit policy RLS.
- Netlify static hosting tidak menjalankan backend; semua otorisasi harus enforced oleh Supabase RLS, bukan hanya menyembunyikan tab admin.
