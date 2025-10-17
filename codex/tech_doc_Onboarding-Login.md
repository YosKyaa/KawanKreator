PROMPT MASTER — FLUTTER

Kopi-paste ke Codex/CodeGPT sebagai satu pesan.
Sesudah itu unggah 2 gambar referensi (screenshot onboarding & auth) ke sesi Codex agar ia “melihat” gaya visualnya. Jika tidak bisa mengunggah gambar, berikan link/paths file dan jelaskan palet warna + spacing seperti di prompt ini.

🎯 Konteks & Target

Bangunkan modul Onboarding → Setup Cepat (opsional) → Auth (Google, Magic Link, Email+Password) → Guest Mode → Dashboard skeleton untuk aplikasi mobile Flutter (Dart) bernama KawanKreator.

Fitur minimum yang harus jadi & berjalan end-to-end:

Onboarding (2–3 slide + Skip)

Setup Preferensi 60 detik (opsional bisa di-skip)

pilih niche (chips), platform utama (Instagram/TikTok), target posting/minggu (slider)

Auth

Google Sign-In (utama), Magic Link (passwordless via email), Email + Password (opsional)

Forgot Password + OTP/Link flow (dengan timer Resend & batas resend 60 detik, max 5x/jam)

Guest Mode (Masuk sebagai Tamu)

bisa masuk Dashboard terbatas (local only, tanpa simpan ke server)

semua aksi simpan/ekspor memunculkan gate “Daftar dengan Google”

Dashboard skeleton (Quick Wins)

CTA utama: “Buat Rencana Minggu Ini”

Widget minimal: Today’s Plan, Calendar Peek (7 hari), Idea Suggestions (dummy/placeholder)

Bottom navigation: Dashboard | Planner | Rate Card | Profile

🧱 Teknis yang harus dipakai

Flutter 3.x, Dart

State management: Riverpod (preferred) atau Provider

Routing: go_router

Auth: Supabase Auth (Google + Magic Link + Email/Password)

Storage lokal: shared_preferences (untuk guest & preferences)

Design system: Buat theme.dart yang memuat token brand

Warna primer oranye #FF6A00, sekunder krem #F6E9D9, hitam #1A1A1A, putih #FFFFFF

Font: Poppins (regular/semibold/bold)

Corner radius besar (16–24), tombol tinggi min 48dp, spacing 8/16/24

Overlay gelap 40–60% di teks di atas foto (aksesibilitas)

A11y: Kontras WCAG, ukuran target sentuh ≥48dp, Semantics di tombol penting

Analitik (stub): Buat analytics.dart dengan fungsi logEvent(name, params) (dummy)

📂 Struktur Proyek (wajib buat file & folder berikut)
lib/
  main.dart
  theme.dart
  app_router.dart

  modules/
    onboarding/
      onboarding_page.dart
      preference_setup_page.dart

    auth/
      login_page.dart
      signup_page.dart
      otp_page.dart
      forgot_password_page.dart
      auth_controller.dart    // Riverpod Notifier untuk auth state
      auth_service.dart       // wrapper Supabase: signInWithGoogle, signInWithMagicLink, signUpWithEmail, signInWithEmail, signOut

    dashboard/
      dashboard_page.dart
      widgets/
        todays_plan_card.dart
        calendar_peek.dart
        idea_suggestions.dart

    planner/
      planner_page.dart

    ratecard/
      ratecard_page.dart

    profile/
      profile_page.dart

  services/
    preferences_service.dart  // simpan niche/platform/target ke shared_prefs
    guard.dart                // redirect guard (guest vs logged-in)
    analytics.dart            // stub logger

  widgets/
    kk_button.dart
    kk_textfield.dart
    otp_input.dart
    empty_state.dart

🧭 Alur Navigasi

Splash → cek isFirstOpen & authState

Jika pertama kali → Onboarding

Jika sudah login → Dashboard

Jika belum login → Login

Onboarding (2–3 slide) → Skip atau Mulai → Preference Setup (opsional, tombol “Lewati” & “Simpan & Lanjutkan”)

Auth screen: tombol besar “Lanjut dengan Google” (primary), Magic Link, Email+Password (opsional).

Tombol “Masuk sebagai Tamu” → set isGuest=true, arahkan ke Dashboard (fitur dibatasi).

Gate di aksi simpan/ekspor (guest) → modal “Simpan progres? Daftar 10 detik dengan Google.”

🔐 Flow Auth (dengan Supabase)

Google Sign-In: pakai supabase_flutter → auth.signInWithIdToken (mobile guide)

Magic Link: input email → auth.signInWithOtp(email) → OTP page (6 digit) atau deep link (boleh disiapkan keduanya)

Timer resend 60s, max 5x/jam per IP/email.

Email+Password: auth.signUp(email,password) + auto login.

Forgot Password: auth.resetPasswordForEmail → verifikasi code → set password baru → auto login.

✅ Checklist 10 Usability Heuristics (HARUS DIIMPLEMENT)

Visibility of system status:

loader/skeleton di semua aksi network; toast/snackbar sukses/gagal; indikator countdown resend OTP.

Match between system & real world:

label & istilah: “Jadwalkan”, “Rate Card”, “Ide Konten”, bukan istilah teknis.

User control & freedom:

tombol Skip onboarding + setup; Back jelas; Undo 5 detik saat ubah preferensi.

Consistency & standards:

bottom nav konsisten; style tombol primer/sekunder konsisten.

Error prevention:

validasi real-time email/password; batas resend OTP; konfirmasi sebelum keluar tanpa simpan.

Recognition rather than recall:

empty state edukatif + contoh teks; placeholder di login/sign-up.

Flexibility & efficiency:

Google (SSO) satu ketuk; autofill OTP (paste) + auto-advance; remember email terakhir.

Aesthetic & minimalist:

satu CTA utama per layar; copy pendek; gunakan gambar/overlay agar teks terbaca.

Help users with errors:

pesan error manusiawi (bukan kode); link “Butuh bantuan?” (stub).

Help & documentation:

Help & FAQ stub di Profile; tooltip pertama kali.

🖼️ Acuan Visual (penting)

Ambil gaya dari screenshot onboarding & auth yang saya unggah (oranye dominan, foto di kiri/kanan, tombol bulat besar, pager dots).

Heading tebal, subtext pendek; tombol utama oranye; chip pilihan seperti di desain.

🧪 Acceptance Criteria

Onboarding 3 slide + Skip → Preference Setup (opsional) → Auth/Guest → Dashboard.

Google Sign-In bekerja (stub kalau belum ada config), Magic Link & Email+Password punya form & flow lengkap, ada OTP page dengan timer & resend.

Guest bisa masuk Dashboard; saat mencoba simpan/ekspor, muncul gate konversi.

Semua tombol ≥48dp; teks kontras aman; ada Semantics.

Kode tersusun seperti struktur di atas; gunakan Riverpod + go_router.

Sertakan dummy analytics pemanggilan logEvent di titik penting (onboarding_complete, auth_google_success, magiclink_sent, otp_verified, guest_entered, dashboard_seen).