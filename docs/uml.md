# Diagram UML Kinetra

Dokumen ini berisi empat diagram UML utama untuk proyek Kinetra:

1. Use Case Diagram
2. Activity Diagram
3. Class Diagram
4. Sequence Diagram

Diagram dibuat dengan Mermaid agar dapat dirender langsung di Markdown. Selain pengguna aplikasi, diagram juga melibatkan teknologi eksternal yang digunakan proyek: Google ML Kit, Firebase Authentication, dan Firebase Firestore.

## 1. Use Case Diagram

```mermaid
flowchart LR
    Pengguna["<<actor>>\nPengguna"]
    MLKit["<<actor>>\nGoogle ML Kit\nPose Detection"]
    FirebaseAuth["<<actor>>\nFirebase Authentication"]
    Firestore["<<actor>>\nFirebase Firestore"]

    subgraph Sistem["Sistem Kinetra"]
        UCRegister(("Registrasi Akun"))
        UCLogin(("Login"))
        UCLogout(("Logout"))
        UCCompleteBiodata(("Mengisi Biodata"))
        UCRecommendation(("Melihat Rekomendasi Latihan"))
        UCBrowseWorkout(("Melihat Daftar Latihan"))
        UCStartWorkout(("Memulai Sesi Workout"))
        UCPoseDetection(("Mendeteksi Pose Real-time"))
        UCCountRep(("Menghitung Repetisi"))
        UCSaveHistory(("Menyimpan Riwayat Latihan"))
        UCViewHistory(("Melihat Riwayat Latihan"))
        UCViewProfile(("Melihat Profil"))
    end

    Pengguna --> UCRegister
    Pengguna --> UCLogin
    Pengguna --> UCLogout
    Pengguna --> UCCompleteBiodata
    Pengguna --> UCRecommendation
    Pengguna --> UCBrowseWorkout
    Pengguna --> UCStartWorkout
    Pengguna --> UCViewHistory
    Pengguna --> UCViewProfile

    FirebaseAuth --> UCRegister
    FirebaseAuth --> UCLogin
    FirebaseAuth --> UCLogout

    Firestore --> UCCompleteBiodata
    Firestore --> UCRecommendation
    Firestore --> UCBrowseWorkout
    Firestore --> UCSaveHistory
    Firestore --> UCViewHistory
    Firestore --> UCViewProfile

    MLKit --> UCPoseDetection

    UCStartWorkout -. include .-> UCPoseDetection
    UCPoseDetection -. include .-> UCCountRep
    UCStartWorkout -. include .-> UCSaveHistory
    UCCompleteBiodata -. enables .-> UCRecommendation
```

## 2. Activity Diagram

Activity diagram berikut menggambarkan alur utama aplikasi dari autentikasi sampai sesi workout selesai. Swimlane dibuat sebagai subgraph untuk menunjukkan tanggung jawab antara pengguna, aplikasi Flutter, Firebase Authentication, Firebase Firestore, dan Google ML Kit.

```mermaid
flowchart TD
    Start([Mulai])

    subgraph UserLane["Pengguna"]
        OpenApp[Buka aplikasi]
        SubmitAuth[Masukkan email dan password]
        FillBiodata[Isi biodata]
        ChooseWorkout[Pilih latihan]
        MoveBody[Lakukan gerakan workout]
        FinishWorkout[Tekan tombol selesai]
        ViewResult[Lihat hasil latihan]
    end

    subgraph AppLane["Aplikasi Flutter Kinetra"]
        InitApp[Inisialisasi Firebase dan ProviderScope]
        CheckAuth{Status login tersedia?}
        ShowAuth[Tampilkan Login/Register]
        RouteGuard{Biodata lengkap?}
        ShowBiodata[Tampilkan form biodata]
        ShowHome[Tampilkan Home dan rekomendasi]
        LoadWorkout[Ambil data latihan]
        InitCamera[Inisialisasi kamera dan pose detector]
        Countdown[Countdown 5 detik]
        ProcessPose[Proses pose dan update UI]
        BuildSession[Buat WorkoutSession]
        ShowResult[Tampilkan ResultScreen]
    end

    subgraph AuthLane["Firebase Authentication"]
        AuthState[Stream status autentikasi]
        VerifyAccount[Validasi login/register]
        ReturnUser[Kembalikan user UID]
    end

    subgraph FirestoreLane["Firebase Firestore"]
        ReadUserDoc[Baca dokumen users]
        SaveBiodata[Simpan biodata dan update users]
        ReadLatihan[Baca koleksi latihan]
        SaveRiwayat[Simpan riwayatLatihan]
    end

    subgraph MLKitLane["Google ML Kit"]
        DetectPose[Deteksi landmark pose dari CameraImage]
        ReturnPose[Kembalikan objek Pose]
    end

    Start --> OpenApp --> InitApp --> AuthState --> CheckAuth
    CheckAuth -->|Belum login| ShowAuth --> SubmitAuth --> VerifyAccount --> ReturnUser --> ReadUserDoc
    CheckAuth -->|Sudah login| ReadUserDoc
    ReadUserDoc --> RouteGuard
    RouteGuard -->|Belum lengkap| ShowBiodata --> FillBiodata --> SaveBiodata --> ShowHome
    RouteGuard -->|Lengkap| ShowHome
    ShowHome --> ChooseWorkout --> LoadWorkout --> ReadLatihan --> InitCamera --> Countdown
    Countdown --> MoveBody
    MoveBody --> DetectPose --> ReturnPose --> ProcessPose
    ProcessPose --> MoveBody
    MoveBody --> FinishWorkout --> BuildSession --> SaveRiwayat --> ShowResult --> ViewResult
    ViewResult --> End([Selesai])
```

## 3. Class Diagram

Class diagram ini menampilkan entity domain, repository, model Firestore, logic penghitung repetisi, service kamera/ML Kit, serta hubungan class aplikasi dengan teknologi eksternal.

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

    class AuthRepositoryImpl {
        -FirebaseAuth _auth
        -FirebaseFirestore _firestore
        +authStateChanges()
        +signIn(email, password)
        +signUp(nama, email, password)
        +signOut()
    }

    class UserRepositoryImpl {
        -FirebaseFirestore _firestore
        +watchUser(userId)
        +getUser(userId)
    }

    class BiodataRepositoryImpl {
        -FirebaseFirestore _firestore
        +watchBiodata(userId)
        +saveBiodata(userId, jenisKelamin, usia, targetLatihan)
    }

    class LatihanRepositoryImpl {
        -FirebaseFirestore _firestore
        +watchAllActive()
        +watchByTarget(targetLatihan)
        +getById(latihanId)
    }

    class RiwayatRepositoryImpl {
        -FirebaseFirestore _firestore
        +watchByUser(userId)
        +getById(riwayatId)
        +saveSession(userId, session)
    }

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

    class DetectionScreen {
        -CameraService _cameraService
        -PoseDetectorService _poseService
        -ExerciseLogic _logic
        +initState()
        +build(context)
        -_beginWorkout()
        -_finishWorkout()
    }

    class CameraService {
        -CameraController _controller
        +initialize(useFrontCamera)
        +startImageStream(onImage)
        +stopImageStream()
        +dispose()
    }

    class PoseDetectorService {
        -PoseDetector _detector
        -bool _isProcessing
        +initialize()
        +processCameraImage(image, rotation, isFrontCamera)
        +computeRotation(sensorOrientation, deviceOrientation, isFrontCamera)
        +dispose()
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

    class FirebaseAuth {
        <<external>>
        +authStateChanges()
        +signInWithEmailAndPassword()
        +createUserWithEmailAndPassword()
        +signOut()
    }

    class FirebaseFirestore {
        <<external>>
        +collection(name)
    }

    class PoseDetector {
        <<external ML Kit>>
        +processImage(inputImage)
        +close()
    }

    class CameraController {
        <<external camera plugin>>
        +initialize()
        +startImageStream()
        +stopImageStream()
    }

    UserEntity "1" --> "0..1" BiodataEntity : memiliki
    UserEntity "1" --> "0..*" RiwayatEntity : memiliki
    LatihanEntity "1" --> "0..*" WorkoutSession : dipilih pada
    WorkoutSession "1" --> "0..1" RiwayatEntity : disimpan sebagai
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

    AuthRepositoryImpl --> FirebaseAuth
    AuthRepositoryImpl --> FirebaseFirestore
    UserRepositoryImpl --> FirebaseFirestore
    BiodataRepositoryImpl --> FirebaseFirestore
    LatihanRepositoryImpl --> FirebaseFirestore
    RiwayatRepositoryImpl --> FirebaseFirestore

    DetectionScreen --> CameraService
    DetectionScreen --> PoseDetectorService
    DetectionScreen --> ExerciseLogic
    DetectionScreen --> WorkoutSession
    CameraService --> CameraController
    PoseDetectorService --> PoseDetector
    ExerciseLogicFactory ..> ExerciseLogic : membuat

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

## 4. Sequence Diagram

Sequence diagram berikut menggambarkan alur lengkap dari pengguna login, aplikasi membaca data dari Firebase, pengguna menjalankan deteksi pose dengan ML Kit, lalu hasil workout disimpan ke Firestore.

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant App as Flutter App
    participant AuthRepo as AuthRepositoryImpl
    participant FirebaseAuth as Firebase Authentication
    participant Firestore as Firebase Firestore
    participant Router as GoRouter
    participant Detection as DetectionScreen
    participant Camera as CameraService
    participant MLKit as Google ML Kit PoseDetector
    participant Logic as ExerciseLogic
    participant RiwayatRepo as RiwayatRepositoryImpl
    participant Result as ResultScreen

    User->>App: Buka aplikasi
    App->>AuthRepo: authStateChanges()
    AuthRepo->>FirebaseAuth: Dengarkan status autentikasi
    FirebaseAuth-->>AuthRepo: User? / null
    AuthRepo-->>App: Status autentikasi

    alt Belum login
        App-->>User: Tampilkan Login/Register
        User->>App: Submit email dan password
        App->>AuthRepo: signIn() atau signUp()
        AuthRepo->>FirebaseAuth: Validasi akun
        FirebaseAuth-->>AuthRepo: UID pengguna
        AuthRepo->>Firestore: Buat/baca dokumen users
        Firestore-->>AuthRepo: User profile
        AuthRepo-->>App: UserEntity
    end

    App->>Firestore: Baca users/{uid} dan biodata
    Firestore-->>App: Status biodata
    App->>Router: Evaluasi route guard

    alt Biodata belum lengkap
        Router-->>User: Tampilkan BiodataScreen
        User->>App: Simpan biodata
        App->>Firestore: Simpan biodata dan update users.isBiodataCompleted
        Firestore-->>App: OK
    end

    Router-->>User: Tampilkan HomeScreen
    User->>App: Pilih latihan
    App->>Firestore: Ambil data latihan
    Firestore-->>App: LatihanEntity
    App->>Router: Navigasi ke /detection/:latihanId
    Router->>Detection: Buat DetectionScreen

    Detection->>Camera: initialize(useFrontCamera: true)
    Camera-->>Detection: Kamera siap
    Detection->>MLKit: Inisialisasi PoseDetector mode stream
    MLKit-->>Detection: PoseDetector siap
    Detection-->>User: Countdown 5 detik
    Detection->>Camera: startImageStream()

    loop Setiap frame kamera
        Camera-->>Detection: CameraImage
        Detection->>MLKit: processImage(InputImage)
        MLKit-->>Detection: Pose?
        Detection->>Logic: processPose(pose)
        Logic-->>Detection: repCount, feedback, isPoseValid
        Detection-->>User: Update overlay pose, repetisi, dan feedback
    end

    User->>Detection: Selesai workout
    Detection->>Camera: stopImageStream()
    Detection->>Detection: Buat WorkoutSession
    Detection->>RiwayatRepo: saveSession(userId, session)
    RiwayatRepo->>Firestore: Simpan dokumen riwayatLatihan
    Firestore-->>RiwayatRepo: OK
    RiwayatRepo-->>Detection: OK
    Detection->>Router: pushReplacement(/result, session)
    Router->>Result: Tampilkan ResultScreen
    Result-->>User: Hasil repetisi, durasi, kalori, feedback
```

## Catatan Teknologi Eksternal

| Teknologi | Peran dalam sistem |
| --- | --- |
| Firebase Authentication | Mengelola registrasi, login, logout, dan status autentikasi pengguna. |
| Firebase Firestore | Menyimpan profil pengguna, biodata, katalog latihan, dan riwayat latihan. |
| Google ML Kit Pose Detection | Mendeteksi landmark tubuh dari frame kamera untuk dihitung oleh `ExerciseLogic`. |
