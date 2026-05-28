import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/calorie_estimator.dart';
import 'package:kinetra/core/utils/duration_formatter.dart';
import 'package:kinetra/data/datasources/local_latihan_seed.dart';
import 'package:kinetra/domain/entities/workout_session.dart';
import 'package:kinetra/features/detection/widgets/countdown_overlay.dart';
import 'package:kinetra/features/detection/widgets/pose_painter.dart';
import 'package:kinetra/logic/exercise_logic.dart';
import 'package:kinetra/logic/exercise_logic_factory.dart';
import 'package:kinetra/services/camera_service.dart';
import 'package:kinetra/services/pose_detector_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class DetectionScreen extends ConsumerStatefulWidget {
  const DetectionScreen({super.key, required this.latihanId});

  final String latihanId;

  @override
  ConsumerState<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends ConsumerState<DetectionScreen> {
  final _cameraService = CameraService();
  final _poseService = PoseDetectorService();
  late ExerciseLogic _logic;

  Pose? _currentPose;
  Size _imageSize = Size.zero;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  int _countdown = 5;
  bool _workoutStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  String _namaLatihan = '';
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _logic = ExerciseLogicFactory.fromLatihanId(widget.latihanId);
    _loadLatihanName();
    _initCamera();
    _startCountdown();
  }

  Future<void> _loadLatihanName() async {
    final fromRepo =
        await ref.read(latihanRepositoryProvider).getById(widget.latihanId);
    final local = LocalLatihanSeed.all().where((l) => l.latihanId == widget.latihanId);
    if (mounted) {
      setState(() {
        _namaLatihan = fromRepo?.namaLatihan ??
            (local.isNotEmpty ? local.first.namaLatihan : widget.latihanId);
      });
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    try {
      await _poseService.initialize();
      await _cameraService.initialize(useFrontCamera: false);
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        await _beginWorkout();
        return false;
      }
      return true;
    });
  }

  Future<void> _beginWorkout() async {
    if (!_cameraReady) return;
    setState(() => _workoutStarted = true);
    _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    final rotation = _poseService.computeRotation(
      sensorOrientation: _cameraService.sensorOrientation,
      deviceOrientation: DeviceOrientation.portraitUp,
      isFrontCamera: _cameraService.isFrontCamera,
    );

    await _cameraService.startImageStream((image) async {
      if (!_workoutStarted || _poseService.isProcessing) return;

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final pose = await _poseService.processCameraImage(
        image,
        rotation: rotation,
        isFrontCamera: _cameraService.isFrontCamera,
      );

      _logic.processPose(pose);

      if (mounted) {
        setState(() {
          _currentPose = pose;
        });
      }
    });
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    await _cameraService.stopImageStream();

    final durationSeconds = _stopwatch.elapsed.inSeconds;
    final session = WorkoutSession(
      sesiId: const Uuid().v4(),
      latihanId: widget.latihanId,
      namaLatihan: _namaLatihan.isEmpty ? widget.latihanId : _namaLatihan,
      repetitions: _logic.repCount,
      durationSeconds: durationSeconds,
      feedbackAkhir: _logic.feedback,
      kaloriEstimasi: CalorieEstimator.estimate(
        latihanId: widget.latihanId,
        repetitions: _logic.repCount,
        durationSeconds: durationSeconds,
      ),
    );

    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      try {
        await ref.read(riwayatRepositoryProvider).saveSession(user.uid, session);
      } catch (_) {
        // Result screen still shown; user may be offline
      }
    }

    if (mounted) {
      context.pushReplacement(AppRoutes.result, extra: session);
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    _cameraService.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Izin kamera diperlukan untuk deteksi pose',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _cameraService.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraReady && controller != null)
            CameraPreview(controller)
          else
            const Center(child: CircularProgressIndicator()),
          if (_workoutStarted && _imageSize != Size.zero)
            CustomPaint(
              painter: PosePainter(
                pose: _currentPose,
                imageSize: _imageSize,
                isFrontCamera: _cameraService.isFrontCamera,
                isValid: _logic.isPoseValid,
              ),
            ),
          if (!_workoutStarted && _countdown >= 0)
            CountdownOverlay(count: _countdown),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                const Spacer(),
                _tipsBanner(),
                _bottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              _namaLatihan.isEmpty ? 'Latihan' : _namaLatihan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _tipsBanner() {
    if (_workoutStarted) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accentCyan, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Posisikan kamera dari samping, pastikan full body terlihat',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    if (!_workoutStarted) return const SizedBox(height: 24);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('Timer', DurationFormatter.mmSs(_stopwatch.elapsed)),
              _stat('Repetisi', '${_logic.repCount}'),
              _stat('Status', _logic.status),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _logic.feedback,
              key: ValueKey(_logic.feedback),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _logic.isPoseValid ? AppColors.poseValid : AppColors.poseInvalid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
