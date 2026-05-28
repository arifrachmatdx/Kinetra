# Diagram UML Kinetra

Dokumen ini berisi empat diagram UML utama untuk proyek Kinetra:

1. Use Case Diagram
2. Activity Diagram
3. Class Diagram
4. Sequence Diagram

Diagram dibuat dengan Mermaid agar dapat dirender langsung di Markdown. Selain pengguna aplikasi, diagram juga melibatkan teknologi eksternal yang digunakan proyek: Google ML Kit, Firebase Authentication, dan Firebase Firestore.

## 1. Use Case Diagram

Use Case Diagram berikut menampilkan use case inti sesuai kebutuhan aplikasi Kinetra. Detail validasi, kondisi gagal, fallback data, dan percabangan teknis dijelaskan pada Activity Diagram dan Sequence Diagram.

```mermaid
flowchart LR
    Pengguna["<<actor>>\nPengguna"]
    FirebaseAuth["<<actor>>\nFirebase Authentication"]
    Firestore["<<actor>>\nFirebase Firestore"]
    MLKit["<<actor>>\nGoogle ML Kit\nPose Detection"]

    subgraph Sistem["Sistem Kinetra"]
        UCLogin(("Login"))
        UCRegister(("Register"))
        UCLogout(("Logout"))
        UCBiodata(("Mengisi Biodata"))
        UCProfile(("Melihat Profil"))
        UCRecommendation(("Melihat Rekomendasi Latihan"))
        UCChooseWorkout(("Memilih Latihan"))
        UCStartWorkout(("Memulai Latihan"))
        UCDetectMovement(("Mendeteksi Gerakan"))
        UCResult(("Melihat Hasil Latihan"))
        UCHistory(("Melihat Riwayat Latihan"))
    end

    Pengguna --> UCLogin
    Pengguna --> UCRegister
    Pengguna --> UCLogout
    Pengguna --> UCBiodata
    Pengguna --> UCProfile
    Pengguna --> UCRecommendation
    Pengguna --> UCChooseWorkout
    Pengguna --> UCStartWorkout
    Pengguna --> UCDetectMovement
    Pengguna --> UCResult
    Pengguna --> UCHistory

    FirebaseAuth --> UCLogin
    FirebaseAuth --> UCRegister
    FirebaseAuth --> UCLogout

    Firestore --> UCBiodata
    Firestore --> UCProfile
    Firestore --> UCRecommendation
    Firestore --> UCChooseWorkout
    Firestore --> UCResult
    Firestore --> UCHistory

    MLKit --> UCDetectMovement

    UCRecommendation --> UCChooseWorkout
    UCChooseWorkout --> UCStartWorkout
    UCStartWorkout --> UCDetectMovement
    UCDetectMovement --> UCResult
    UCResult --> UCHistory
```

## 2. Activity Diagram

Activity Diagram berikut disesuaikan dengan 11 use case pada Use Case Diagram. Decision node ditulis dengan bentuk diamond `{...}` untuk memperjelas kondisi berhasil/gagal, data tersedia/tidak tersedia, izin kamera, dan loop proses deteksi gerakan.

### 2.1 Activity Diagram - Login

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenLogin[Buka halaman Login]
        FillLogin[Isi email dan password]
        SubmitLogin[Tekan tombol Login]
        FixCredential[Perbaiki email/password]
        ReceiveLoginResult[Terima hasil login]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        ValidateInput{Input valid?}
        CallSignIn[Panggil AuthRepository.signIn]
        LoginSuccess{Login Firebase berhasil?}
        UserDocExists{Dokumen users tersedia?}
        CreateDefaultUser[Buat profil default]
        BiodataComplete{Biodata lengkap?}
        GoBiodata[Arahkan ke BiodataScreen]
        GoHome[Arahkan ke HomeScreen]
        ShowValidationError[Tampilkan error validasi]
        ShowLoginError[Tampilkan error login]
    end
    subgraph Auth["Firebase Authentication"]
        VerifyCredential[Validasi email/password]
        ReturnUid[Kembalikan UID pengguna]
    end
    subgraph DB["Firebase Firestore"]
        ReadUser[Baca users/uid]
        SaveDefaultUser[Simpan profil default]
    end

    Start --> OpenLogin --> FillLogin --> SubmitLogin --> ValidateInput
    ValidateInput -->|Tidak| ShowValidationError --> FixCredential --> FillLogin
    ValidateInput -->|Ya| CallSignIn --> VerifyCredential --> LoginSuccess
    LoginSuccess -->|Tidak| ShowLoginError --> FixCredential --> FillLogin
    LoginSuccess -->|Ya| ReturnUid --> ReadUser --> UserDocExists
    UserDocExists -->|Tidak| CreateDefaultUser --> SaveDefaultUser --> BiodataComplete
    UserDocExists -->|Ya| BiodataComplete
    BiodataComplete -->|Tidak| GoBiodata --> ReceiveLoginResult --> End([Selesai])
    BiodataComplete -->|Ya| GoHome --> ReceiveLoginResult --> End
```

### 2.2 Activity Diagram - Register

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenRegister[Buka halaman Register]
        FillRegister[Isi nama, email, dan password]
        SubmitRegister[Tekan tombol Register]
        FixInput[Perbaiki data register]
        ReceiveRegisterResult[Terima hasil register]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        ValidateRegister{Input register valid?}
        CallSignUp[Panggil AuthRepository.signUp]
        RegisterSuccess{Registrasi Firebase berhasil?}
        BuildUserModel[Buat UserModel dengan biodata belum lengkap]
        SaveUserSuccess{Profil tersimpan di Firestore?}
        GoBiodata[Arahkan ke BiodataScreen]
        ShowValidationError[Tampilkan error validasi]
        ShowRegisterError[Tampilkan error register]
        ShowSaveError[Tampilkan error simpan profil]
    end
    subgraph Auth["Firebase Authentication"]
        CreateAccount[Buat akun email/password]
        ReturnUid[Kembalikan UID pengguna]
    end
    subgraph DB["Firebase Firestore"]
        SaveUser[Simpan dokumen users/uid]
    end

    Start --> OpenRegister --> FillRegister --> SubmitRegister --> ValidateRegister
    ValidateRegister -->|Tidak| ShowValidationError --> FixInput --> FillRegister
    ValidateRegister -->|Ya| CallSignUp --> CreateAccount --> RegisterSuccess
    RegisterSuccess -->|Tidak| ShowRegisterError --> FixInput --> FillRegister
    RegisterSuccess -->|Ya| ReturnUid --> BuildUserModel --> SaveUser --> SaveUserSuccess
    SaveUserSuccess -->|Tidak| ShowSaveError --> ReceiveRegisterResult --> End([Selesai])
    SaveUserSuccess -->|Ya| GoBiodata --> ReceiveRegisterResult --> End
```

### 2.3 Activity Diagram - Logout

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenProfile[Buka halaman Profil]
        TapLogout[Tekan tombol Logout]
        ConfirmLogout{Yakin logout?}
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        StayProfile[Tetap di ProfileScreen]
        CallSignOut[Panggil AuthRepository.signOut]
        LogoutSuccess{Logout berhasil?}
        ClearState[Perbarui authState dan route guard]
        GoLogin[Arahkan ke LoginScreen]
        ShowLogoutError[Tampilkan error logout]
    end
    subgraph Auth["Firebase Authentication"]
        EndSession[Akhiri sesi autentikasi]
        EmitNull[Emit authState null]
    end

    Start --> OpenProfile --> TapLogout --> ConfirmLogout
    ConfirmLogout -->|Tidak| StayProfile --> End([Selesai])
    ConfirmLogout -->|Ya| CallSignOut --> EndSession --> LogoutSuccess
    LogoutSuccess -->|Tidak| ShowLogoutError --> StayProfile --> End
    LogoutSuccess -->|Ya| EmitNull --> ClearState --> GoLogin --> End
```

### 2.4 Activity Diagram - Mengisi Biodata

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenBiodata[Buka BiodataScreen]
        FillBiodata[Isi jenis kelamin, usia, dan target latihan]
        SubmitBiodata[Tekan Simpan]
        FixBiodata[Perbaiki biodata]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        ValidateBiodata{Form biodata valid?}
        AgeValid{Usia valid?}
        TargetSelected{Target latihan dipilih?}
        CallSave[Panggil BiodataRepository.saveBiodata]
        SaveSuccess{Simpan Firestore berhasil?}
        RefreshUserDoc[Refresh currentUserDocProvider]
        GoHome[Arahkan ke HomeScreen]
        ShowError[Tampilkan pesan error]
    end
    subgraph DB["Firebase Firestore"]
        WriteBiodata[Simpan dokumen biodata]
        UpdateUser[Update users.isBiodataCompleted]
    end

    Start --> OpenBiodata --> FillBiodata --> SubmitBiodata --> ValidateBiodata
    ValidateBiodata -->|Tidak| ShowError --> FixBiodata --> FillBiodata
    ValidateBiodata -->|Ya| AgeValid
    AgeValid -->|Tidak| ShowError --> FixBiodata
    AgeValid -->|Ya| TargetSelected
    TargetSelected -->|Tidak| ShowError --> FixBiodata
    TargetSelected -->|Ya| CallSave --> WriteBiodata --> UpdateUser --> SaveSuccess
    SaveSuccess -->|Tidak| ShowError --> FixBiodata
    SaveSuccess -->|Ya| RefreshUserDoc --> GoHome --> End([Selesai])
```

### 2.5 Activity Diagram - Melihat Profil

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenProfile[Buka ProfileScreen]
        ViewProfile[Lihat nama, email, dan biodata]
        CompleteBiodata[Pilih lengkapi biodata]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        CurrentUserAvailable{currentUser tersedia?}
        WatchUser[Watch currentUserDocProvider]
        UserDocAvailable{Dokumen user tersedia?}
        WatchBiodata[Watch biodataProvider]
        BiodataAvailable{Biodata tersedia?}
        RenderFullProfile[Tampilkan profil lengkap]
        RenderPartialProfile[Tampilkan profil tanpa biodata]
        RedirectLogin[Arahkan ke LoginScreen]
        ShowProfileError[Tampilkan error profil]
    end
    subgraph Auth["Firebase Authentication"]
        ProvideUid[Menyediakan UID pengguna]
    end
    subgraph DB["Firebase Firestore"]
        ReadUser[Baca dokumen users]
        ReadBiodata[Baca dokumen biodata]
    end

    Start --> OpenProfile --> ProvideUid --> CurrentUserAvailable
    CurrentUserAvailable -->|Tidak| RedirectLogin --> End([Selesai])
    CurrentUserAvailable -->|Ya| WatchUser --> ReadUser --> UserDocAvailable
    UserDocAvailable -->|Tidak| ShowProfileError --> End
    UserDocAvailable -->|Ya| WatchBiodata --> ReadBiodata --> BiodataAvailable
    BiodataAvailable -->|Ya| RenderFullProfile --> ViewProfile --> End
    BiodataAvailable -->|Tidak| RenderPartialProfile --> CompleteBiodata --> End
```

### 2.6 Activity Diagram - Melihat Rekomendasi Latihan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenHome[Buka HomeScreen]
        ViewRecommendation[Lihat rekomendasi latihan]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        WatchBiodata[Watch biodataProvider]
        BiodataAvailable{Biodata tersedia?}
        ReadTarget[Ambil targetLatihan]
        WatchRecommendation[Watch recommendationProvider]
        RecommendationAvailable{Data rekomendasi tersedia?}
        UseAllActive[Gunakan semua latihan aktif]
        UseLocalSeed[Gunakan LocalLatihanSeed]
        RenderRecommendation[Tampilkan kartu rekomendasi]
    end
    subgraph DB["Firebase Firestore"]
        ReadBiodata[Baca koleksi biodata]
        QueryByTarget[Query latihan by targetLatihan]
        QueryAllActive[Query semua latihan aktif]
    end

    Start --> OpenHome --> WatchBiodata --> ReadBiodata --> BiodataAvailable
    BiodataAvailable -->|Ya| ReadTarget --> WatchRecommendation --> QueryByTarget --> RecommendationAvailable
    BiodataAvailable -->|Tidak| UseAllActive --> QueryAllActive --> RecommendationAvailable
    RecommendationAvailable -->|Ya| RenderRecommendation --> ViewRecommendation --> End([Selesai])
    RecommendationAvailable -->|Tidak| UseLocalSeed --> RenderRecommendation --> ViewRecommendation --> End
```

### 2.7 Activity Diagram - Memilih Latihan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenWorkoutList[Buka daftar latihan atau rekomendasi]
        BrowseWorkout[Lihat pilihan latihan]
        SelectWorkout[Pilih latihan]
        RetryLoad[Muat ulang daftar]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        LoadWorkoutList[Muat latihanListProvider]
        WorkoutState{Status data latihan?}
        RenderLoading[Tampilkan loading]
        ListEmpty{Daftar latihan kosong?}
        UseLocalSeed[Gunakan LocalLatihanSeed]
        RenderWorkoutList[Tampilkan daftar latihan]
        StoreSelectedWorkout[Simpan latihanId terpilih]
        GoStartWorkout[Arahkan ke halaman memulai latihan]
        ShowError[Tampilkan error]
    end
    subgraph DB["Firebase Firestore"]
        QueryWorkout[Query latihan aktif]
    end

    Start --> OpenWorkoutList --> LoadWorkoutList --> QueryWorkout --> WorkoutState
    WorkoutState -->|Loading| RenderLoading --> LoadWorkoutList
    WorkoutState -->|Error| ShowError --> RetryLoad --> LoadWorkoutList
    WorkoutState -->|Data| ListEmpty
    ListEmpty -->|Ya| UseLocalSeed --> RenderWorkoutList
    ListEmpty -->|Tidak| RenderWorkoutList
    RenderWorkoutList --> BrowseWorkout --> SelectWorkout --> StoreSelectedWorkout --> GoStartWorkout --> End([Selesai])
```

### 2.8 Activity Diagram - Memulai Latihan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        EnterDetection[Buka halaman latihan]
        PermissionDecision{Izin kamera diberikan?}
        OpenSettings[Buka pengaturan aplikasi]
        WaitCountdown[Tunggu countdown]
        StartMoving[Mulai bergerak]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        LoadWorkoutDetail[Ambil detail latihan]
        WorkoutFound{Latihan ditemukan?}
        UseLocalWorkout[Gunakan LocalLatihanSeed]
        CalculateTarget[Hitung target personal]
        RequestPermission[Minta izin kamera]
        InitCamera[Inisialisasi CameraService]
        CameraReady{Kamera siap?}
        InitPoseDetector[Inisialisasi PoseDetectorService]
        DetectorReady{Pose detector siap?}
        CreateLogic[Buat ExerciseLogic sesuai latihanId]
        StartCountdown[Mulai countdown 5 detik]
        CountdownDone{Countdown selesai?}
        StartStream[Mulai image stream]
        ShowPermissionError[Tampilkan error izin kamera]
        ShowInitError[Tampilkan error inisialisasi]
    end
    subgraph DB["Firebase Firestore"]
        ReadWorkout[Baca data latihan]
        ReadBiodata[Baca biodata pengguna]
    end
    subgraph MLKit["Google ML Kit"]
        PrepareDetector[Siapkan PoseDetector mode stream]
    end

    Start --> EnterDetection --> LoadWorkoutDetail --> ReadWorkout --> WorkoutFound
    WorkoutFound -->|Tidak| UseLocalWorkout --> ReadBiodata
    WorkoutFound -->|Ya| ReadBiodata
    ReadBiodata --> CalculateTarget --> RequestPermission --> PermissionDecision
    PermissionDecision -->|Tidak| ShowPermissionError --> OpenSettings --> End([Selesai])
    PermissionDecision -->|Ya| InitCamera --> CameraReady
    CameraReady -->|Tidak| ShowInitError --> End
    CameraReady -->|Ya| InitPoseDetector --> PrepareDetector --> DetectorReady
    DetectorReady -->|Tidak| ShowInitError --> End
    DetectorReady -->|Ya| CreateLogic --> StartCountdown --> WaitCountdown --> CountdownDone
    CountdownDone -->|Tidak| StartCountdown
    CountdownDone -->|Ya| StartStream --> StartMoving --> End
```

### 2.9 Activity Diagram - Mendeteksi Gerakan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        MoveBody[Lakukan gerakan di depan kamera]
        AdjustPose[Perbaiki posisi tubuh]
        SeeFeedback[Lihat overlay, repetisi, dan feedback]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        ReceiveFrame[Terima CameraImage]
        WorkoutRunning{Workout masih berjalan?}
        ProcessingBusy{Frame lain sedang diproses?}
        ThrottleOk{Jarak frame minimal 80 ms?}
        ComputeRotation[Hitung rotasi kamera]
        ConvertInput[Konversi CameraImage ke InputImage]
        ConversionOk{Konversi berhasil?}
        ProcessPoseResult[Terima Pose dari ML Kit]
        PoseAvailable{Pose terdeteksi?}
        LandmarksVisible{Landmark wajib terlihat?}
        CalculateAngle[Hitung sudut dengan PoseMath]
        ValidRep{Gerakan membentuk repetisi valid?}
        IncrementRep[Tambah repCount]
        UpdateFeedback[Update feedback dan status]
        RenderOverlay[Render PosePainter]
        SkipFrame[Lewati frame]
    end
    subgraph MLKit["Google ML Kit"]
        DetectPose[Proses InputImage]
        ReturnPose[Kembalikan Pose]
    end

    Start --> MoveBody --> ReceiveFrame --> WorkoutRunning
    WorkoutRunning -->|Tidak| End([Selesai])
    WorkoutRunning -->|Ya| ProcessingBusy
    ProcessingBusy -->|Ya| SkipFrame --> ReceiveFrame
    ProcessingBusy -->|Tidak| ThrottleOk
    ThrottleOk -->|Tidak| SkipFrame --> ReceiveFrame
    ThrottleOk -->|Ya| ComputeRotation --> ConvertInput --> ConversionOk
    ConversionOk -->|Tidak| UpdateFeedback --> AdjustPose --> MoveBody
    ConversionOk -->|Ya| DetectPose --> ReturnPose --> ProcessPoseResult --> PoseAvailable
    PoseAvailable -->|Tidak| UpdateFeedback --> AdjustPose --> MoveBody
    PoseAvailable -->|Ya| LandmarksVisible
    LandmarksVisible -->|Tidak| UpdateFeedback --> AdjustPose --> MoveBody
    LandmarksVisible -->|Ya| CalculateAngle --> ValidRep
    ValidRep -->|Ya| IncrementRep --> UpdateFeedback --> RenderOverlay --> SeeFeedback --> ReceiveFrame
    ValidRep -->|Tidak| UpdateFeedback --> RenderOverlay --> SeeFeedback --> ReceiveFrame
```

### 2.10 Activity Diagram - Melihat Hasil Latihan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        TapFinish[Tekan tombol selesai]
        ViewResult[Lihat hasil repetisi, durasi, kalori, dan feedback]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        StopStream[Hentikan image stream]
        StreamStopped{Stream berhenti?}
        StopTimer[Stop stopwatch]
        BuildSession[Buat WorkoutSession]
        EstimateCalories[Hitung estimasi kalori]
        UserLoggedIn{User login?}
        SaveHistory[Panggil RiwayatRepository.saveSession]
        SaveSuccess{Riwayat tersimpan?}
        GoResult[Arahkan ke ResultScreen]
        ContinueWithoutSave[Lanjut tampilkan hasil tanpa menyimpan]
    end
    subgraph Auth["Firebase Authentication"]
        ReadCurrentUser[Baca currentUser]
    end
    subgraph DB["Firebase Firestore"]
        WriteHistory[Simpan dokumen riwayatLatihan]
    end

    Start --> TapFinish --> StopStream --> StreamStopped
    StreamStopped -->|Tidak| ContinueWithoutSave --> GoResult --> ViewResult --> End([Selesai])
    StreamStopped -->|Ya| StopTimer --> BuildSession --> EstimateCalories --> ReadCurrentUser --> UserLoggedIn
    UserLoggedIn -->|Tidak| GoResult --> ViewResult --> End
    UserLoggedIn -->|Ya| SaveHistory --> WriteHistory --> SaveSuccess
    SaveSuccess -->|Ya| GoResult --> ViewResult --> End
    SaveSuccess -->|Tidak| ContinueWithoutSave --> GoResult --> ViewResult --> End
```

### 2.11 Activity Diagram - Melihat Riwayat Latihan

```mermaid
flowchart TD
    Start([Mulai])
    subgraph User["Pengguna"]
        OpenHistory[Buka HistoryScreen]
        SelectHistory[Pilih riwayat latihan]
        ViewHistoryDetail[Lihat detail riwayat]
        RetryLoad[Muat ulang riwayat]
    end
    subgraph App["Aplikasi Flutter Kinetra"]
        WatchHistory[Watch historyProvider]
        HistoryState{Status data riwayat?}
        RenderLoading[Tampilkan loading]
        RenderList[Tampilkan daftar riwayat]
        HistoryEmpty{Riwayat kosong?}
        RenderEmpty[Tampilkan state kosong]
        NavigateDetail[Navigasi ke HistoryDetailScreen]
        LoadDetail[Ambil detail riwayat]
        DetailFound{Detail ditemukan?}
        RenderDetail[Tampilkan detail riwayat]
        ShowError[Tampilkan error]
    end
    subgraph DB["Firebase Firestore"]
        QueryHistory[Query riwayatLatihan by userId]
        ReadHistoryDoc[Baca dokumen riwayatLatihan/id]
    end

    Start --> OpenHistory --> WatchHistory --> QueryHistory --> HistoryState
    HistoryState -->|Loading| RenderLoading --> WatchHistory
    HistoryState -->|Error| ShowError --> RetryLoad --> WatchHistory
    HistoryState -->|Data| HistoryEmpty
    HistoryEmpty -->|Ya| RenderEmpty --> End([Selesai])
    HistoryEmpty -->|Tidak| RenderList --> SelectHistory --> NavigateDetail --> LoadDetail --> ReadHistoryDoc --> DetailFound
    DetailFound -->|Tidak| ShowError --> End
    DetailFound -->|Ya| RenderDetail --> ViewHistoryDetail --> End
```

## 3. Class Diagram

Class Diagram berikut memakai nama class, atribut, dan fungsi yang sesuai dengan kode proyek. Diagram tetap dibuat ringkas dengan hanya menampilkan bagian yang paling penting.

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

    class AuthRepository {
        <<interface>>
        +Stream<User?> authStateChanges()
        +User? currentUser
        +Future<UserEntity> signIn(String email, String password)
        +Future<UserEntity> signUp(String nama, String email, String password)
        +Future<void> signOut()
    }

    class UserRepository {
        <<interface>>
        +Stream<UserEntity?> watchUser(String userId)
        +Future<UserEntity?> getUser(String userId)
    }

    class BiodataRepository {
        <<interface>>
        +Stream<BiodataEntity?> watchBiodata(String userId)
        +Future<void> saveBiodata(String userId, String jenisKelamin, int usia, TargetLatihan targetLatihan)
    }

    class LatihanRepository {
        <<interface>>
        +Stream<List<LatihanEntity>> watchAllActive()
        +Stream<List<LatihanEntity>> watchByTarget(String targetLatihan)
        +Future<LatihanEntity?> getById(String latihanId)
    }

    class RiwayatRepository {
        <<interface>>
        +Stream<List<RiwayatEntity>> watchByUser(String userId)
        +Future<RiwayatEntity?> getById(String riwayatId)
        +Future<void> saveSession(String userId, WorkoutSession session)
    }

    class DetectionScreen {
        +String latihanId
        -_beginWorkout()
        -_finishWorkout()
    }

    class CameraService {
        +CameraController? controller
        +bool isInitialized
        +bool isFrontCamera
        +int sensorOrientation
        +Future<void> initialize(bool useFrontCamera)
        +Future<void> startImageStream(Function onImage)
        +Future<void> stopImageStream()
        +Future<void> dispose()
    }

    class PoseDetectorService {
        +bool isProcessing
        +Future<void> initialize()
        +Future<Pose?> processCameraImage(CameraImage image, int rotation, bool isFrontCamera)
        +Future<void> dispose()
    }

    class ExerciseLogic {
        <<interface>>
        +int repCount
        +String feedback
        +String status
        +bool isPoseValid
        +void processPose(Pose? pose)
        +void reset()
    }

    UserEntity "1" --> "0..1" BiodataEntity : memiliki
    UserEntity "1" --> "0..*" RiwayatEntity : memiliki
    LatihanEntity "1" --> "0..*" WorkoutSession : dipilih pada
    WorkoutSession "1" --> "0..1" RiwayatEntity : disimpan sebagai

    DetectionScreen --> CameraService : streaming kamera
    DetectionScreen --> PoseDetectorService : deteksi pose
    DetectionScreen --> ExerciseLogic : hitung gerakan
    DetectionScreen --> WorkoutSession : membuat hasil sesi
    DetectionScreen --> LatihanRepository : memuat latihan
    DetectionScreen --> RiwayatRepository : simpan riwayat
    AuthRepository --> UserEntity : autentikasi
    UserRepository --> UserEntity : data profil
    BiodataRepository --> BiodataEntity : data biodata
    LatihanRepository --> LatihanEntity : data latihan
    RiwayatRepository --> RiwayatEntity : data riwayat
```

## 4. Sequence Diagram

Sequence Diagram berikut disesuaikan dengan 11 use case pada Use Case Diagram. Diagram memakai blok `alt`, `else`, `opt`, dan `loop` untuk memperlihatkan kondisi sukses/gagal, data kosong, proses berulang, dan percabangan sistem.

### 4.1 Sequence Diagram - Login

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Login as LoginScreen
    participant AuthRepo as AuthRepositoryImpl
    participant FirebaseAuth as Firebase Authentication
    participant Firestore as Firebase Firestore
    participant Router as GoRouter

    User->>Login: Isi email dan password
    User->>Login: Tekan Login
    Login->>Login: Validasi input
    alt Input tidak valid
        Login-->>User: Tampilkan error validasi
    else Input valid
        Login->>AuthRepo: signIn(email, password)
        AuthRepo->>FirebaseAuth: signInWithEmailAndPassword(email, password)
        alt Login gagal
            FirebaseAuth-->>AuthRepo: FirebaseAuthException
            AuthRepo-->>Login: Error login
            Login-->>User: Tampilkan pesan error
        else Login berhasil
            FirebaseAuth-->>AuthRepo: UserCredential(uid)
            AuthRepo->>Firestore: get users/{uid}
            alt Dokumen user belum ada
                Firestore-->>AuthRepo: not found
                AuthRepo->>Firestore: set users/{uid} default
                Firestore-->>AuthRepo: OK
            else Dokumen user ada
                Firestore-->>AuthRepo: User profile
            end
            AuthRepo-->>Login: UserEntity
            Login->>Router: Trigger route guard
            alt Biodata belum lengkap
                Router-->>User: Tampilkan BiodataScreen
            else Biodata sudah lengkap
                Router-->>User: Tampilkan HomeScreen
            end
        end
    end
```

### 4.2 Sequence Diagram - Register

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Register as RegisterScreen
    participant AuthRepo as AuthRepositoryImpl
    participant FirebaseAuth as Firebase Authentication
    participant Firestore as Firebase Firestore
    participant Router as GoRouter

    User->>Register: Isi nama, email, password
    User->>Register: Tekan Register
    Register->>Register: Validasi input
    alt Input tidak valid
        Register-->>User: Tampilkan error validasi
    else Input valid
        Register->>AuthRepo: signUp(nama, email, password)
        AuthRepo->>FirebaseAuth: createUserWithEmailAndPassword(email, password)
        alt Registrasi gagal
            FirebaseAuth-->>AuthRepo: FirebaseAuthException
            AuthRepo-->>Register: Error registrasi
            Register-->>User: Tampilkan pesan error
        else Registrasi berhasil
            FirebaseAuth-->>AuthRepo: UserCredential(uid)
            AuthRepo->>Firestore: set users/{uid}
            alt Simpan profil gagal
                Firestore-->>AuthRepo: Error
                AuthRepo-->>Register: Error penyimpanan profil
                Register-->>User: Tampilkan pesan error
            else Profil tersimpan
                Firestore-->>AuthRepo: OK
                AuthRepo-->>Register: UserEntity
                Register->>Router: Redirect ke /biodata
                Router-->>User: Tampilkan BiodataScreen
            end
        end
    end
```

### 4.3 Sequence Diagram - Logout

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Profile as ProfileScreen
    participant AuthRepo as AuthRepositoryImpl
    participant FirebaseAuth as Firebase Authentication
    participant Router as GoRouter

    User->>Profile: Tekan Logout
    Profile-->>User: Tampilkan konfirmasi
    alt Pengguna membatalkan
        User-->>Profile: Batal
        Profile-->>User: Tetap di ProfileScreen
    else Pengguna menyetujui
        User-->>Profile: Ya, logout
        Profile->>AuthRepo: signOut()
        AuthRepo->>FirebaseAuth: signOut()
        alt Logout gagal
            FirebaseAuth-->>AuthRepo: Error
            AuthRepo-->>Profile: Error logout
            Profile-->>User: Tampilkan pesan error
        else Logout berhasil
            FirebaseAuth-->>AuthRepo: OK
            FirebaseAuth-->>Router: authStateChanges() = null
            Router-->>User: Redirect ke LoginScreen
        end
    end
```

### 4.4 Sequence Diagram - Mengisi Biodata

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Biodata as BiodataScreen
    participant BiodataRepo as BiodataRepositoryImpl
    participant Firestore as Firebase Firestore
    participant Router as GoRouter

    User->>Biodata: Isi biodata dan target latihan
    User->>Biodata: Tekan Simpan
    Biodata->>Biodata: Validasi form
    alt Form tidak valid
        Biodata-->>User: Tampilkan error input
    else Form valid
        Biodata->>BiodataRepo: saveBiodata(userId, jenisKelamin, usia, targetLatihan)
        BiodataRepo->>Firestore: set biodata/{biodataId}
        alt Gagal menyimpan biodata
            Firestore-->>BiodataRepo: Error
            BiodataRepo-->>Biodata: Error
            Biodata-->>User: Tampilkan error simpan
        else Biodata tersimpan
            Firestore-->>BiodataRepo: OK
            BiodataRepo->>Firestore: update users/{userId}.isBiodataCompleted = true
            Firestore-->>BiodataRepo: OK
            BiodataRepo-->>Biodata: OK
            Biodata->>Router: Trigger route guard
            Router-->>User: Tampilkan HomeScreen
        end
    end
```

### 4.5 Sequence Diagram - Melihat Profil

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Profile as ProfileScreen
    participant FirebaseAuth as Firebase Authentication
    participant Providers as Riverpod Providers
    participant UserRepo as UserRepositoryImpl
    participant BiodataRepo as BiodataRepositoryImpl
    participant Firestore as Firebase Firestore
    participant Router as GoRouter

    User->>Profile: Buka ProfileScreen
    Profile->>FirebaseAuth: currentUser.uid
    alt User tidak login
        FirebaseAuth-->>Profile: null
        Profile->>Router: Redirect ke /login
    else User login
        FirebaseAuth-->>Profile: UID pengguna
        Profile->>Providers: watch currentUserDocProvider
        Providers->>UserRepo: watchUser(uid)
        UserRepo->>Firestore: snapshots users/{uid}
        alt User profile tidak ditemukan
            Firestore-->>UserRepo: null
            Providers-->>Profile: Data user kosong
            Profile-->>User: Tampilkan error profil
        else User profile ditemukan
            Firestore-->>UserRepo: UserEntity
            Profile->>Providers: watch biodataProvider
            Providers->>BiodataRepo: watchBiodata(uid)
            BiodataRepo->>Firestore: snapshots biodata where userId
            alt Biodata belum ada
                Firestore-->>BiodataRepo: null
                Providers-->>Profile: UserEntity tanpa biodata
                Profile-->>User: Tampilkan profil parsial dan CTA lengkapi biodata
            else Biodata ada
                Firestore-->>BiodataRepo: BiodataEntity
                Providers-->>Profile: Data profil lengkap
                Profile-->>User: Tampilkan profil lengkap
            end
        end
    end
```

### 4.6 Sequence Diagram - Melihat Rekomendasi Latihan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Home as HomeScreen
    participant Providers as Riverpod Providers
    participant BiodataRepo as BiodataRepositoryImpl
    participant LatihanRepo as LatihanRepositoryImpl
    participant Firestore as Firebase Firestore
    participant LocalSeed as LocalLatihanSeed

    User->>Home: Buka HomeScreen
    Home->>Providers: watch biodataProvider
    Providers->>BiodataRepo: watchBiodata(userId)
    BiodataRepo->>Firestore: snapshots biodata where userId
    alt Biodata belum ada
        Firestore-->>BiodataRepo: null
        Providers->>LatihanRepo: watchAllActive()
    else Biodata ada
        Firestore-->>BiodataRepo: BiodataEntity
        Providers->>LatihanRepo: watchByTarget(targetLatihan)
    end
    LatihanRepo->>Firestore: snapshots latihan
    alt Firestore kosong/error
        Firestore-->>LatihanRepo: kosong/error
        Providers->>LocalSeed: all()
        LocalSeed-->>Providers: List latihan fallback
    else Firestore ada data
        Firestore-->>LatihanRepo: List LatihanEntity
        LatihanRepo-->>Providers: Rekomendasi latihan
    end
    Providers-->>Home: AsyncValue<List<LatihanEntity>>
    Home-->>User: Tampilkan rekomendasi
```

### 4.7 Sequence Diagram - Memilih Latihan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant WorkoutList as WorkoutListScreen
    participant Providers as Riverpod Providers
    participant LatihanRepo as LatihanRepositoryImpl
    participant Firestore as Firebase Firestore
    participant LocalSeed as LocalLatihanSeed
    participant Router as GoRouter

    User->>WorkoutList: Buka daftar/rekomendasi latihan
    WorkoutList->>Providers: watch latihanListProvider atau recommendationProvider
    Providers->>LatihanRepo: watchAllActive() atau watchByTarget()
    LatihanRepo->>Firestore: snapshots latihan
    alt Loading
        Providers-->>WorkoutList: AsyncLoading
        WorkoutList-->>User: Tampilkan loading
    else Error atau data kosong
        Firestore-->>LatihanRepo: error/kosong
        Providers->>LocalSeed: all()
        LocalSeed-->>Providers: List latihan fallback
        Providers-->>WorkoutList: Data fallback
    else Data tersedia
        Firestore-->>LatihanRepo: List LatihanEntity
        LatihanRepo-->>Providers: List latihan
    end
    Providers-->>WorkoutList: AsyncValue<List<LatihanEntity>>
    WorkoutList-->>User: Tampilkan pilihan latihan
    User->>WorkoutList: Pilih latihan
    WorkoutList->>Router: push /detection/:latihanId
```

### 4.8 Sequence Diagram - Memulai Latihan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Detection as DetectionScreen
    participant LatihanRepo as LatihanRepositoryImpl
    participant Firestore as Firebase Firestore
    participant LocalSeed as LocalLatihanSeed
    participant Permission as PermissionHandler
    participant Camera as CameraService
    participant MLKit as Google ML Kit PoseDetector
    participant Factory as ExerciseLogicFactory

    User->>Detection: Masuk ke halaman latihan
    Detection->>LatihanRepo: getById(latihanId)
    LatihanRepo->>Firestore: query latihan
    alt Latihan tidak ditemukan di Firestore
        Firestore-->>LatihanRepo: null
        Detection->>LocalSeed: Cari latihanId
        LocalSeed-->>Detection: LatihanEntity fallback
    else Latihan ditemukan
        Firestore-->>LatihanRepo: LatihanEntity
        LatihanRepo-->>Detection: Detail latihan
    end
    Detection->>Detection: Hitung target personal dari biodata
    Detection->>Factory: fromLatihanId(latihanId)
    Factory-->>Detection: ExerciseLogic
    Detection->>Permission: request camera
    alt Izin kamera ditolak
        Permission-->>Detection: denied
        Detection-->>User: Tampilkan tombol buka pengaturan
    else Izin kamera diberikan
        Permission-->>Detection: granted
        Detection->>Camera: initialize(useFrontCamera: true)
        alt Kamera gagal dibuka
            Camera-->>Detection: CameraException
            Detection-->>User: Tampilkan snackbar error
        else Kamera siap
            Camera-->>Detection: Kamera siap
            Detection->>MLKit: initialize PoseDetector stream mode
            MLKit-->>Detection: PoseDetector siap
            loop Countdown 5 detik
                Detection-->>User: Update angka countdown
            end
            Detection->>Camera: startImageStream(callback)
        end
    end
```

### 4.9 Sequence Diagram - Mendeteksi Gerakan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Camera as CameraService
    participant Detection as DetectionScreen
    participant PoseService as PoseDetectorService
    participant MLKit as Google ML Kit PoseDetector
    participant Logic as ExerciseLogic
    participant PoseMath as PoseMath
    participant Overlay as PosePainter

    User->>Camera: Bergerak di depan kamera
    loop Selama workoutStarted = true
        Camera-->>Detection: CameraImage frame
        alt PoseService masih memproses frame lain
            Detection-->>Camera: Skip frame
        else Frame boleh diproses
            Detection->>PoseService: computeRotation(...)
            Detection->>PoseService: processCameraImage(image, rotation, isFrontCamera)
            PoseService->>PoseService: Convert CameraImage ke InputImage
            alt Konversi gagal
                PoseService-->>Detection: null
                Detection-->>User: Feedback pose tidak terdeteksi
            else Konversi berhasil
                PoseService->>MLKit: processImage(inputImage)
                alt ML Kit tidak menemukan pose
                    MLKit-->>PoseService: empty list
                    PoseService-->>Detection: null
                    Detection->>Logic: processPose(null)
                    Logic-->>Detection: feedback pose tidak terdeteksi
                    Detection-->>User: Minta pengguna atur posisi
                else ML Kit menemukan pose
                    MLKit-->>PoseService: List<Pose>
                    PoseService-->>Detection: Pose pertama
                    Detection->>Logic: processPose(pose)
                    Logic->>PoseMath: isVisible() dan angle()
                    alt Gerakan valid
                        PoseMath-->>Logic: Landmark dan sudut valid
                        Logic-->>Detection: repCount bertambah, feedback positif
                    else Gerakan belum valid
                        PoseMath-->>Logic: Landmark/sudut belum sesuai
                        Logic-->>Detection: feedback koreksi gerakan
                    end
                    Detection->>Overlay: Update pose dan validasi
                    Overlay-->>User: Render skeleton, repetisi, dan feedback
                end
            end
        end
    end
```

### 4.10 Sequence Diagram - Melihat Hasil Latihan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant Detection as DetectionScreen
    participant Camera as CameraService
    participant Calories as CalorieEstimator
    participant Auth as Firebase Authentication
    participant RiwayatRepo as RiwayatRepositoryImpl
    participant Firestore as Firebase Firestore
    participant Router as GoRouter
    participant Result as ResultScreen

    User->>Detection: Tekan selesai
    Detection->>Camera: stopImageStream()
    alt Stream gagal berhenti
        Camera-->>Detection: Error
        Detection-->>User: Cleanup terbaik dan lanjut ke hasil
    else Stream berhenti
        Camera-->>Detection: OK
    end
    Detection->>Detection: Stop stopwatch dan baca repCount
    Detection->>Calories: estimate(latihanId, reps, duration)
    Calories-->>Detection: kaloriEstimasi
    Detection->>Detection: Buat WorkoutSession
    Detection->>Auth: currentUser
    alt User tidak login atau offline
        Auth-->>Detection: null
        Detection->>Router: pushReplacement(/result, session)
    else User login
        Auth-->>Detection: uid
        Detection->>RiwayatRepo: saveSession(userId, session)
        RiwayatRepo->>Firestore: set riwayatLatihan/{riwayatId}
        alt Simpan Firestore gagal
            Firestore-->>RiwayatRepo: Error
            RiwayatRepo-->>Detection: Error
            Detection->>Router: pushReplacement(/result, session)
        else Simpan Firestore berhasil
            Firestore-->>RiwayatRepo: OK
            RiwayatRepo-->>Detection: OK
            Detection->>Router: pushReplacement(/result, session)
        end
    end
    Router->>Result: Tampilkan ResultScreen
    Result-->>User: Repetisi, durasi, kalori, feedback
```

### 4.11 Sequence Diagram - Melihat Riwayat Latihan

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant History as HistoryScreen
    participant Providers as Riverpod Providers
    participant RiwayatRepo as RiwayatRepositoryImpl
    participant Firestore as Firebase Firestore
    participant Router as GoRouter
    participant Detail as HistoryDetailScreen

    User->>History: Buka HistoryScreen
    History->>Providers: watch historyProvider
    Providers->>RiwayatRepo: watchByUser(userId)
    RiwayatRepo->>Firestore: snapshots riwayatLatihan where userId
    alt Loading
        Providers-->>History: AsyncLoading
        History-->>User: Tampilkan loading
    else Error
        Firestore-->>RiwayatRepo: Error
        Providers-->>History: AsyncError
        History-->>User: Tampilkan error dan opsi reload
    else Data tersedia
        Firestore-->>RiwayatRepo: List RiwayatEntity
        RiwayatRepo-->>Providers: List riwayat terurut
        Providers-->>History: AsyncData
        alt Riwayat kosong
            History-->>User: Tampilkan state kosong
        else Riwayat ada
            History-->>User: Tampilkan daftar riwayat
            User->>History: Pilih riwayat
            History->>Router: push /history/:id
            Router->>Detail: Buat HistoryDetailScreen(id)
            Detail->>RiwayatRepo: getById(riwayatId)
            RiwayatRepo->>Firestore: get riwayatLatihan/{id}
            alt Detail tidak ditemukan
                Firestore-->>RiwayatRepo: not found
                Detail-->>User: Tampilkan error detail
            else Detail ditemukan
                Firestore-->>RiwayatRepo: RiwayatEntity
                RiwayatRepo-->>Detail: Detail riwayat
                Detail-->>User: Tampilkan detail
            end
        end
    end
```

## Catatan Teknologi Eksternal

| Teknologi | Peran dalam sistem |
| --- | --- |
| Firebase Authentication | Mengelola registrasi, login, logout, dan status autentikasi pengguna. |
| Firebase Firestore | Menyimpan profil pengguna, biodata, katalog latihan, dan riwayat latihan. |
| Google ML Kit Pose Detection | Mendeteksi landmark tubuh dari frame kamera untuk dihitung oleh `ExerciseLogic`. |
