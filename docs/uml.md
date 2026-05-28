# Diagram UML Kinetra

Dokumen ini merangkum diagram UML utama untuk proyek Kinetra. Diagram ditulis dengan Mermaid agar dapat dirender langsung oleh GitHub, GitLab, dan banyak editor Markdown.

## Ringkasan Arsitektur

Kinetra adalah aplikasi mobile Flutter untuk workout assistant dengan deteksi pose real-time. Aplikasi berjalan di perangkat pengguna, memakai Firebase Auth untuk autentikasi, Cloud Firestore untuk data aplikasi, dan Google ML Kit untuk pose detection.

Struktur kode utama:

- `lib/features/`: layar dan widget per fitur.
- `lib/core/`: router, provider Riverpod, tema, konstanta, utilitas, dan widget bersama.
- `lib/domain/`: entity dan interface repository.
- `lib/data/`: model Firestore dan implementasi repository.
- `lib/logic/`: strategi penghitung repetisi per latihan.
- `lib/services/`: wrapper kamera dan pose detector.

## 1. Component Diagram

```mermaid
flowchart LR
    subgraph Device["Mobile Device"]
        subgraph App["Flutter App"]
            Main["main.dart / KinetraApp"]
            Features["features/*\nPresentation Screens"]
            Core["core\nRouter, Providers, Theme, Utils"]
            Domain["domain\nEntities + Repository Interfaces"]
            Data["data\nFirestore Models + Repository Impl"]
            Logic["logic\nExerciseLogic Strategies"]
            Services["services\nCameraService + PoseDetectorService"]
        end
    end

    FirebaseAuth["Firebase Auth"]
    Firestore["Cloud Firestore"]
    MLKit["Google ML Kit Pose Detection"]
    Camera["Device Camera"]

    Main --> Core
    Core --> Features
    Core --> Domain
    Core --> Data
    Features --> Core
    Features --> Domain
    Features --> Logic
    Features --> Services
    Data -. implements .-> Domain
    Data --> FirebaseAuth
    Data --> Firestore
    Services --> Camera
    Services --> MLKit
```

## 2. Class Diagram - Domain, Repository, dan Logic

```mermaid
classDiagram
    direction LR

    class UserEntity {
        +String userId
        +String nama
        +String email
        +bool isBiodataCompleted
    }

    class BiodataEntity {
        +String biodataId
        +String userId
        +String jenisKelamin
        +int usia
        +TargetLatihan targetLatihan
        +DateTime updatedAt
    }

    class LatihanEntity {
        +String latihanId
        +String namaLatihan
        +String kategoriLatihan
        +String deskripsi
        +int targetRepetisi
        +int targetDurasi
        +String targetLatihan
        +bool isActive
    }

    class RiwayatEntity {
        +String riwayatId
        +String userId
        +String sesiId
        +DateTime tanggalLatihan
        +String namaLatihan
        +int hasilRepetisi
        +int durasiLatihan
        +double? kaloriEstimasi
        +String? feedbackAkhir
    }

    class WorkoutSession {
        +String sesiId
        +String latihanId
        +String namaLatihan
        +int repetitions
        +int durationSeconds
        +String feedbackAkhir
        +double kaloriEstimasi
    }

    class TargetLatihan {
        <<enumeration>>
        kebugaran
        massaOtot
        kelincahan
    }

    class AuthRepository {
        <<interface>>
        +authStateChanges()
        +currentUser
        +signIn(email, password)
        +signUp(nama, email, password)
        +signOut()
    }

    class UserRepository {
        <<interface>>
        +watchUser(userId)
        +getUser(userId)
    }

    class BiodataRepository {
        <<interface>>
        +watchBiodata(userId)
        +saveBiodata(userId, jenisKelamin, usia, targetLatihan)
    }

    class LatihanRepository {
        <<interface>>
        +watchAllActive()
        +watchByTarget(targetLatihan)
        +getById(latihanId)
    }

    class RiwayatRepository {
        <<interface>>
        +watchByUser(userId)
        +getById(riwayatId)
        +saveSession(userId, session)
    }

    class AuthRepositoryImpl
    class UserRepositoryImpl
    class BiodataRepositoryImpl
    class LatihanRepositoryImpl
    class RiwayatRepositoryImpl

    class UserModel {
        +fromFirestore(doc)
        +toFirestore()
        +toEntity()
    }

    class BiodataModel {
        +fromFirestore(doc)
        +toFirestore()
        +toEntity()
    }

    class LatihanModel {
        +fromFirestore(doc)
        +toEntity()
    }

    class RiwayatModel {
        +fromFirestore(doc)
        +toFirestore()
        +toEntity()
    }

    class ExerciseLogic {
        <<interface>>
        +int repCount
        +String feedback
        +String status
        +bool isPoseValid
        +processPose(pose)
        +reset()
    }

    class ExerciseLogicFactory {
        +fromLatihanId(latihanId)
    }

    class PushUpLogic
    class SquatLogic
    class JumpingJackLogic
    class HighKneeLogic
    class MountainClimberLogic
    class SitUpLogic
    class LungeLogic
    class SkaterJumpLogic
    class BurpeeLogic

    UserEntity "1" --> "0..1" BiodataEntity : completes
    UserEntity "1" --> "0..*" RiwayatEntity : owns
    LatihanEntity "1" --> "0..*" WorkoutSession : selected for
    WorkoutSession "1" --> "0..1" RiwayatEntity : persisted as
    BiodataEntity --> TargetLatihan

    AuthRepositoryImpl ..|> AuthRepository
    UserRepositoryImpl ..|> UserRepository
    BiodataRepositoryImpl ..|> BiodataRepository
    LatihanRepositoryImpl ..|> LatihanRepository
    RiwayatRepositoryImpl ..|> RiwayatRepository

    UserModel ..> UserEntity : toEntity
    BiodataModel ..> BiodataEntity : toEntity
    LatihanModel ..> LatihanEntity : toEntity
    RiwayatModel ..> RiwayatEntity : toEntity

    ExerciseLogicFactory ..> ExerciseLogic : creates
    PushUpLogic ..|> ExerciseLogic
    SquatLogic ..|> ExerciseLogic
    JumpingJackLogic ..|> ExerciseLogic
    HighKneeLogic ..|> ExerciseLogic
    MountainClimberLogic ..|> ExerciseLogic
    SitUpLogic ..|> ExerciseLogic
    LungeLogic ..|> ExerciseLogic
    SkaterJumpLogic ..|> ExerciseLogic
    BurpeeLogic ..|> ExerciseLogic
```

## 3. Sequence Diagram - Alur Deteksi Workout

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant WorkoutList as WorkoutListScreen
    participant Router as GoRouter
    participant Detection as DetectionScreen
    participant LatihanRepo as LatihanRepository
    participant Camera as CameraService
    participant PoseService as PoseDetectorService
    participant Logic as ExerciseLogic
    participant RiwayatRepo as RiwayatRepository
    participant Firestore as Cloud Firestore
    participant Result as ResultScreen

    User->>WorkoutList: Pilih latihan
    WorkoutList->>Router: Buka /detection/:latihanId
    Router->>Detection: Buat DetectionScreen(latihanId)
    Detection->>LatihanRepo: getById(latihanId)
    LatihanRepo->>Firestore: Query koleksi latihan
    Firestore-->>LatihanRepo: Data latihan
    LatihanRepo-->>Detection: LatihanEntity
    Detection->>Logic: ExerciseLogicFactory.fromLatihanId(latihanId)
    Detection->>Camera: initialize(useFrontCamera: true)
    Detection->>PoseService: initialize()
    Detection->>Detection: Countdown 5 detik
    Detection->>Camera: startImageStream(callback)

    loop Setiap frame kamera
        Camera-->>Detection: CameraImage
        Detection->>PoseService: processCameraImage(image, rotation, isFrontCamera)
        PoseService-->>Detection: Pose?
        Detection->>Logic: processPose(pose)
        Logic-->>Detection: repCount, feedback, isPoseValid
        Detection-->>User: Update overlay, repetisi, feedback
    end

    User->>Detection: Selesai
    Detection->>Camera: stopImageStream()
    Detection->>Detection: Buat WorkoutSession
    opt Pengguna masih login
        Detection->>RiwayatRepo: saveSession(userId, session)
        RiwayatRepo->>Firestore: Set dokumen riwayatLatihan
        Firestore-->>RiwayatRepo: OK
    end
    Detection->>Router: pushReplacement(/result, extra: session)
    Router->>Result: Tampilkan hasil sesi
```

## 4. Activity Diagram - Guard Navigasi

```mermaid
flowchart TD
    Start([Aplikasi dibuka]) --> Init[Firebase initialize dan ProviderScope]
    Init --> Splash[/SplashScreen/]
    Splash --> AuthLoading{Auth state loading?}
    AuthLoading -->|Ya| Splash
    AuthLoading -->|Tidak| HasUser{User login?}
    HasUser -->|Tidak| Login[/Login atau Register/]
    Login --> AuthAction{Login/Register sukses?}
    AuthAction -->|Tidak| Login
    AuthAction -->|Ya| UserDocLoading{User doc loading?}
    HasUser -->|Ya| UserDocLoading
    UserDocLoading -->|Ya| Splash
    UserDocLoading -->|Tidak| BiodataDone{Biodata lengkap?}
    BiodataDone -->|Tidak| Biodata[/BiodataScreen/]
    Biodata --> SaveBiodata[Simpan biodata dan update user]
    SaveBiodata --> Home[/HomeScreen/]
    BiodataDone -->|Ya| Home
    Home --> AppRoutes[Home, Workouts, Detection, History, Profile]
```

## 5. State Machine Diagram - Siklus Sesi Workout

```mermaid
stateDiagram-v2
    [*] --> LoadingExercise
    LoadingExercise --> RequestCameraPermission
    RequestCameraPermission --> PermissionDenied: ditolak
    RequestCameraPermission --> InitializingCamera: diizinkan
    PermissionDenied --> [*]
    InitializingCamera --> Countdown: kamera dan pose detector siap
    Countdown --> Streaming: countdown selesai
    Streaming --> ProcessingFrame: frame kamera masuk
    ProcessingFrame --> Streaming: repCount dan feedback diperbarui
    Streaming --> Finishing: pengguna menekan selesai
    Finishing --> PersistingHistory: user login
    Finishing --> ShowingResult: user null atau save gagal
    PersistingHistory --> ShowingResult
    ShowingResult --> [*]
```

## 6. Deployment Diagram

```mermaid
flowchart LR
    subgraph Phone["Perangkat Pengguna"]
        FlutterApp["Kinetra Flutter App"]
        CameraHardware["Camera Hardware"]
        OnDeviceML["On-device ML Kit Pose Detector"]
    end

    subgraph Firebase["Firebase Project"]
        Auth["Firebase Auth"]
        DB["Cloud Firestore"]
        Rules["Firestore Security Rules"]
    end

    subgraph Admin["Admin / Developer"]
        SeedTool["tool/seed_latihan.dart\natau seed_latihan_admin.mjs"]
        FirebaseConsole["Firebase Console"]
    end

    FlutterApp --> CameraHardware
    FlutterApp --> OnDeviceML
    FlutterApp --> Auth
    FlutterApp --> DB
    DB --> Rules
    SeedTool --> DB
    FirebaseConsole --> DB
```

## 7. Use Case Diagram

```mermaid
flowchart LR
    Member["Pengguna"]

    Register(("Register"))
    Login(("Login"))
    CompleteBiodata(("Lengkapi Biodata"))
    ViewRecommendation(("Lihat Rekomendasi"))
    BrowseWorkout(("Lihat Daftar Latihan"))
    RunDetection(("Mulai Deteksi Pose"))
    SaveHistory(("Simpan Riwayat"))
    ViewHistory(("Lihat Riwayat"))
    ViewProfile(("Lihat Profil"))
    Logout(("Logout"))

    Member --> Register
    Member --> Login
    Member --> CompleteBiodata
    Member --> ViewRecommendation
    Member --> BrowseWorkout
    Member --> RunDetection
    Member --> ViewHistory
    Member --> ViewProfile
    Member --> Logout

    RunDetection --> SaveHistory
    CompleteBiodata --> ViewRecommendation
```

## Catatan Data Firestore

| Koleksi | Sumber kode | Peran |
| --- | --- | --- |
| `users` | `FirestoreCollections.users` | Profil dasar pengguna dan status biodata. |
| `biodata` | `FirestoreCollections.biodata` | Data onboarding: jenis kelamin, usia, target latihan. |
| `latihan` | `FirestoreCollections.latihan` | Katalog latihan aktif yang dibaca aplikasi. |
| `riwayatLatihan` | `FirestoreCollections.riwayatLatihan` | Hasil sesi workout pengguna. |

Aturan akses Firestore mengikuti kepemilikan `userId`: pengguna hanya dapat membaca dan mengubah dokumen miliknya sendiri, sedangkan koleksi `latihan` hanya dapat dibaca oleh pengguna terautentikasi.
