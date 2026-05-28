# Kinetra

Smart workout assistant dengan deteksi pose real-time menggunakan Google ML Kit.

## Setup

### 1. Flutter

```bash
flutter pub get
```

### 2. Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project Firebase Anda dan platform Android (`com.example.kinetra`).

Salin `android/app/google-services.json` dari Firebase Console (atau hasil `flutterfire configure`).  
File contoh: [`android/app/google-services.json.example`](android/app/google-services.json.example).  
Build Gradle memakai plugin Google Services hanya jika file tersebut ada.

Deploy rules Firestore:

```bash
firebase deploy --only firestore:rules
```

### 3. Seed data latihan

Import 9 dokumen ke koleksi `latihan` di Firestore. Data referensi ada di [`tool/seed_latihan.dart`](tool/seed_latihan.dart).

Aplikasi juga memakai fallback lokal jika koleksi kosong.

### 4. Jalankan

```bash
flutter run
```

## Fitur

- Firebase Auth (login/register/logout)
- Biodata & rekomendasi latihan
- Deteksi pose ML Kit (Push Up & Squat penuh)
- Riwayat latihan di Firestore
- UI dark mode sporty

## Struktur

- `lib/features/` — UI per fitur
- `lib/domain/` — entities & repository interfaces
- `lib/data/` — implementasi Firestore
- `lib/logic/` — counter repetisi per latihan
- `lib/services/` — kamera & pose detector

## Dokumentasi

- [Diagram UML](docs/uml.md) — use case, activity per use case, class, dan sequence per use case, termasuk integrasi ML Kit, Firebase Authentication, dan Firebase Firestore.
