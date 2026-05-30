# Suarasa

Suarasa adalah prototype aplikasi Flutter untuk membantu aksesibilitas pengguna tunanetra, tunarungu, dan tunawicara. Aplikasi ini menggabungkan kamera, perintah suara, text-to-speech, haptic feedback, dan Gemini Vision untuk membuat interaksi dasar yang lebih mudah diakses.

Project ini masih berada pada tahap MVP/prototype GDG. Fitur yang ada ditujukan untuk demonstrasi alur utama, validasi ide, dan pengembangan lanjutan.

## Latar Belakang

Pengguna dengan kebutuhan aksesibilitas sering memerlukan cara interaksi yang tidak bergantung penuh pada tampilan visual atau tombol. Suarasa mencoba menyediakan pengalaman yang lebih adaptif:

- pengguna tunanetra dapat meminta bantuan analisis lingkungan dan pencarian objek,
- pengguna tunarungu/tunawicara dapat mencoba mode baca gestur bahasa isyarat berbasis kamera,
- aplikasi membacakan hasil AI menggunakan text-to-speech,
- fitur utama dapat dipanggil lewat perintah suara dan shake gesture.

## Fitur Utama

- **Voice command otomatis**
  - Saat masuk HomePage, aplikasi menyapa pengguna dengan TTS.
  - Setelah TTS selesai, aplikasi mulai mendengarkan perintah suara.
  - Listener tidak berjalan saat TTS sedang berbicara agar tidak saling bentrok.

- **Perintah suara yang didukung**
  - `analisis sekitar`
  - `arahkan jalan`
  - `lihat sekitar`
  - `cari <objek>` seperti `cari kacamata`, `cari dompet`, `cari botol minum`
  - `baca isyarat`
  - `kamera depan`
  - `kamera belakang`
  - `berhenti`

- **Pencarian objek dinamis**
  - Parser tidak membatasi jenis objek.
  - Contoh: `tolong carikan botol minum` akan mencari target `botol minum`.

- **Shake gesture**
  - Shake 1x: mulai mendengarkan perintah.
  - Shake 2x: langsung menjalankan analisis sekitar.

- **Gemini Vision**
  - Navigasi tunanetra berbasis analisis kamera.
  - Pencarian objek berdasarkan target dari input/voice command.
  - Baca bahasa isyarat dari frame kamera.

- **Text-to-speech**
  - Membacakan instruksi, hasil AI, dan pesan error penting.

- **Kamera depan dan belakang**
  - Mendukung switch kamera.
  - Mode baca isyarat mencoba memakai kamera depan.

- **UI modern dan responsif**
  - Card gradient.
  - Rounded corner.
  - Shadow lembut.
  - Layout responsif untuk Android kecil, Android besar, dan web.

## Tech Stack

- Flutter
- Dart
- Riverpod
- GoRouter
- Camera
- Speech to Text
- Flutter TTS
- Sensors Plus
- Vibration
- Dio
- Gemini Vision API

## Struktur Folder Singkat

```text
lib/
  core/
    constants/       # Warna dan konstanta aplikasi
    providers/       # Riverpod provider untuk aksesibilitas, mode vision, voice command
    router/          # Konfigurasi route aplikasi
    services/        # CameraService, GeminiVisionService, TextToSpeechService, VoiceCommandService
    theme/           # Theme aplikasi
    widgets/         # Reusable widget seperti CustomCard dan AccessibleButton
  features/
    home/            # Halaman utama dan integrasi fitur MVP
    onboarding/      # Halaman onboarding
    selector/        # Halaman kalibrasi akses
    splash/          # Splash screen
```

## Permission Android

Aplikasi membutuhkan permission berikut:

- Camera: untuk preview kamera, analisis lingkungan, pencarian objek, dan baca isyarat.
- Microphone: untuk voice command.
- Internet: untuk request ke Gemini Vision API.
- Vibration: untuk haptic feedback.

Permission utama didefinisikan di:

```text
android/app/src/main/AndroidManifest.xml
```

## Setup Project

1. Pastikan Flutter SDK sudah terpasang.

2. Clone atau buka project ini.

3. Ambil dependency:

```bash
flutter pub get
```

4. Pastikan Android device atau emulator tersedia:

```bash
flutter devices
```

## Gemini API Key

Suarasa memakai Gemini Vision API untuk analisis gambar. Untuk development, API key diberikan lewat `--dart-define`.

Langkah umum:

1. Buka Google AI Studio:

```text
https://aistudio.google.com/
```

2. Login dengan akun Google.

3. Buat API key Gemini.

4. Jalankan aplikasi dengan parameter:

```bash
--dart-define=GEMINI_API_KEY=API_KEY_ANDA
```

Jangan commit API key ke GitHub, `.env`, README, source code, screenshot terminal, atau file konfigurasi publik. Untuk production, gunakan pendekatan yang lebih aman seperti backend proxy atau secret management.

## Menjalankan di Android

Lihat daftar device:

```bash
flutter devices
```

Jalankan aplikasi:

```bash
flutter run -d DEVICE_ID --dart-define=GEMINI_API_KEY=API_KEY_ANDA
```

Contoh tanpa device id jika hanya ada satu perangkat:

```bash
flutter run --dart-define=GEMINI_API_KEY=API_KEY_ANDA
```

## Build APK Debug

```bash
flutter build apk --debug --dart-define=GEMINI_API_KEY=API_KEY_ANDA
```

Output APK debug biasanya ada di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Status Build Android

Build Android debug sudah berhasil pada environment pengembangan project ini.

Catatan: mungkin masih muncul warning Gradle/Kotlin dari dependency Flutter. Selama output akhirnya `BUILD SUCCESSFUL`, warning tersebut belum memblokir build MVP.

## Status MVP dan Batasan

- Mode bahasa isyarat masih berbasis single-frame image, belum real-time video detection.
- Navigasi tunanetra masih berbasis analisis kamera dan prompt AI, bukan sensor jarak fisik.
- Pencarian objek belum berjalan terus-menerus; pengguna perlu memicu analisis lewat voice command, tombol, atau shake gesture.
- Akurasi Gemini Vision bergantung pada kualitas kamera, pencahayaan, koneksi internet, dan posisi objek/gestur.
- Aplikasi ini belum menggantikan alat bantu mobilitas atau pendamping manusia dalam situasi berisiko tinggi.

## Roadmap

- Continuous object search mode.
- Real-time sign language recognition.
- Offline fallback untuk command dasar.
- Better obstacle warning dengan sensor tambahan atau model khusus.
- Multilingual support.
- Penyempurnaan UX tunanetra berbasis audio-first dan haptic-first.
- Logging dan telemetry development yang lebih rapi.

## Referensi Flutter

Jika baru pertama kali memakai Flutter:

- [Dokumentasi Flutter](https://docs.flutter.dev/)
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
