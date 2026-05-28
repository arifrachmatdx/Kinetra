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
import 'package:kinetra/core/utils/training_target.dart';
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
  final ValueNotifier<Pose?> _poseNotifier = ValueNotifier<Pose?>(null);
  Size _imageSize = Size.zero;
  Size _previewSize = Size.zero;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  int _countdown = 5;
  bool _workoutStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  String _namaLatihan = '';
  Timer? _uiTimer;
  int? _targetReps;
  int? _targetDurasi;
  String _cameraHint = 'Pastikan full body terlihat';
  InputImageRotation _lastRotation = InputImageRotation.rotation0deg;
  DateTime? _lastPoseTick;
  int _lastRepUi = -1;
  String _lastFeedbackUi = '';

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

    final latihan = fromRepo ?? (local.isNotEmpty ? local.first : null);
    if (latihan != null) {
      final biodata = ref.read(biodataProvider).valueOrNull;
      final target = TrainingTargetCalculator.forLatihan(
        latihan: latihan,
        biodata: biodata,
      );
      if (mounted) {
        setState(() {
          _targetReps = target.repetisi;
          _targetDurasi = target.durasiDetik;
          _cameraHint = _hintForLatihan(latihan.latihanId);
        });
      }
    }
  }

  String _hintForLatihan(String latihanId) {
    switch (latihanId) {
      case 'push_up':
      case 'squat':
      case 'sit_up':
        return 'Latihan ini paling akurat dari samping, full body terlihat';
      case 'jumping_jack':
      case 'high_knee':
      case 'mountain_climber':
      case 'lunge':
      case 'skater_jump':
      case 'burpee':
        return 'Hadap kamera, full body terlihat (jaga jarak 2–3 meter)';
      default:
        return 'Pastikan full body terlihat dan pencahayaan cukup';
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
      await _cameraService.initialize(useFrontCamera: true);
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
    _logic.reset();
    _currentPose = null;
    _poseNotifier.value = null;
    _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    await _cameraService.startImageStream((image) async {
      if (!_workoutStarted || _poseService.isProcessing) return;
      final now = DateTime.now();
      if (_lastPoseTick != null &&
          now.difference(_lastPoseTick!).inMilliseconds < 80) {
        return; // throttle pose processing for responsiveness
      }
      _lastPoseTick = now;

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final ps = _cameraService.controller?.value.previewSize;
      if (ps != null) {
        // Keep overlay mapping consistent with what CameraPreview renders.
        _previewSize = Size(ps.width, ps.height);
      } else {
        _previewSize = _imageSize;
      }

      final deviceOrientation =
          _cameraService.controller?.value.deviceOrientation ??
              DeviceOrientation.portraitUp;
      final rotationDeg = _poseService.computeRotation(
        sensorOrientation: _cameraService.sensorOrientation,
        deviceOrientation: deviceOrientation,
        isFrontCamera: _cameraService.isFrontCamera,
      );
      final rotation = _poseService.rotationFromDegrees(rotationDeg);
      _lastRotation = rotation;

      final pose = await _poseService.processCameraImage(
        image,
        rotation: rotationDeg,
        isFrontCamera: _cameraService.isFrontCamera,
      );

      _logic.processPose(pose);
      _poseNotifier.value = pose;

      // Only trigger full UI rebuild when stats change.
      final rep = _logic.repCount;
      final feedback = _logic.feedback;
      if (mounted && (rep != _lastRepUi || feedback != _lastFeedbackUi)) {
        _lastRepUi = rep;
        _lastFeedbackUi = feedback;
        setState(() {});
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
    _poseNotifier.dispose();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.paddingOf(context).top;
          final bottomPadding = MediaQuery.paddingOf(context).bottom;

          // Keep overlays readable across phones/tablets.
          final maxOverlayWidth = constraints.maxWidth >= 700 ? 560.0 : 520.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera fills the whole screen; overlays are drawn on top.
              if (_cameraReady && controller != null)
                Positioned.fill(
                  child: ValueListenableBuilder<Pose?>(
                    valueListenable: _poseNotifier,
                    builder: (context, pose, _) {
                      return _CameraWithOverlay(
                        controller: controller,
                        pose: _workoutStarted ? pose : null,
                        imageSize:
                            _previewSize == Size.zero ? _imageSize : _previewSize,
                        isFrontCamera: _cameraService.isFrontCamera,
                        rotation: _lastRotation,
                        isValid: _logic.isPoseValid,
                      );
                    },
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),

              if (!_workoutStarted && _countdown >= 0)
                CountdownOverlay(count: _countdown),

              // Top bar
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: _topBar(),
                  ),
                ),
              ),

              // Top floating stats / tips
              Positioned(
                left: 0,
                right: 0,
                top: topPadding + 64,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxOverlayWidth),
                        child: _topStatsOverlay(),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom action overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding + 12,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxOverlayWidth),
                        child: _bottomActionsOverlay(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _namaLatihan.isEmpty ? 'Latihan' : _namaLatihan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 42),
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
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentCyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cameraHint,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    if (!_workoutStarted) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Text(
          'Bersiap... latihan akan dimulai setelah countdown',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
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
          if (_targetReps != null || _targetDurasi != null) ...[
            const SizedBox(height: 10),
            Text(
              'Target: ${_targetReps ?? '-'} rep · ${_targetDurasi ?? '-'}s',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
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

  Widget _topStatsOverlay() {
    if (!_workoutStarted) {
      return _tipsBanner();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _stat('Timer', DurationFormatter.mmSs(_stopwatch.elapsed))),
              const SizedBox(width: 10),
              Expanded(child: _stat('Repetisi', '${_logic.repCount}')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Status', _logic.status)),
            ],
          ),
          if (_targetReps != null || _targetDurasi != null) ...[
            const SizedBox(height: 8),
            Text(
              'Target: ${_targetReps ?? '-'} rep · ${_targetDurasi ?? '-'}s',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Widget _bottomActionsOverlay() {
    if (!_workoutStarted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Text(
          'Bersiap... latihan akan dimulai setelah countdown',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return SizedBox(
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CameraPreview169 extends StatelessWidget {
  const _CameraPreview169({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // Render the camera without "zoom" (no crop).
    final previewSize = controller.value.previewSize;
    final previewW = previewSize?.width ?? 1;
    final previewH = previewSize?.height ?? 1;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: previewW,
          height: previewH,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraWithOverlay extends StatelessWidget {
  const _CameraWithOverlay({
    required this.controller,
    required this.pose,
    required this.imageSize,
    required this.isFrontCamera,
    required this.rotation,
    required this.isValid,
  });

  final CameraController controller;
  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;
  final InputImageRotation rotation;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    // Posefit-like: use cover so camera fills the screen (cropped),
    // but keep skeleton in the exact same fitted box so alignment stays correct.
    final previewSize = controller.value.previewSize;
    // In portrait, the camera preview is effectively rotated.
    // Swapping width/height here makes the fitted sizing match what CameraPreview renders.
    final w = previewSize?.height ?? 1;
    final h = previewSize?.width ?? 1;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            if (pose != null && imageSize != Size.zero)
              CustomPaint(
                painter: PosePainter(
                  pose: pose,
                  imageSize: imageSize,
                  isFrontCamera: isFrontCamera,
                  rotation: rotation,
                  fit: BoxFit.cover,
                  isValid: isValid,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
