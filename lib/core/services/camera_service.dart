import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;

  CameraController? get controller => _controller;
  bool get isReady => _controller?.value.isInitialized ?? false;
  bool get isRecordingVideo => _controller?.value.isRecordingVideo ?? false;
  bool get hasMultipleCameras => _cameras.length > 1;
  CameraLensDirection? get lensDirection =>
      _cameras.isEmpty ? null : _cameras[_selectedCameraIndex].lensDirection;

  String get cameraLabel {
    final direction = lensDirection;
    if (direction == CameraLensDirection.front) return 'Kamera depan';
    if (direction == CameraLensDirection.back) return 'Kamera belakang';
    return 'Kamera';
  }

  Future<void> initialize({bool preferFront = false}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_camera', 'Kamera tidak tersedia di perangkat ini.');
    }

    _selectedCameraIndex = _preferredCameraIndex(preferFront: preferFront);
    await _startController(_cameras[_selectedCameraIndex]);
  }

  Future<void> switchCamera() async {
    if (_cameras.isEmpty) {
      await initialize();
      return;
    }
    if (_cameras.length == 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startController(_cameras[_selectedCameraIndex]);
  }

  Future<void> useLens(CameraLensDirection direction) async {
    if (_cameras.isEmpty) {
      await initialize(preferFront: direction == CameraLensDirection.front);
    }

    final index = _cameras.indexWhere((camera) => camera.lensDirection == direction);
    if (index == -1 || index == _selectedCameraIndex) return;

    _selectedCameraIndex = index;
    await _startController(_cameras[_selectedCameraIndex]);
  }

  Future<XFile> captureImage() async {
    final activeController = _controller;
    if (activeController == null || !activeController.value.isInitialized) {
      throw CameraException('camera_not_ready', 'Kamera belum siap.');
    }
    if (activeController.value.isTakingPicture) {
      throw CameraException('camera_busy', 'Kamera sedang mengambil gambar.');
    }
    return activeController.takePicture();
  }

  Future<XFile> startOrStopVideo() async {
    final activeController = _controller;
    if (activeController == null || !activeController.value.isInitialized) {
      throw CameraException('camera_not_ready', 'Kamera belum siap.');
    }

    if (activeController.value.isRecordingVideo) {
      return activeController.stopVideoRecording();
    }

    await activeController.startVideoRecording();
    throw CameraException('recording_started', 'Rekaman video dimulai.');
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  int _preferredCameraIndex({required bool preferFront}) {
    final preferredDirection =
        preferFront ? CameraLensDirection.front : CameraLensDirection.back;
    final preferredIndex =
        _cameras.indexWhere((camera) => camera.lensDirection == preferredDirection);
    return preferredIndex == -1 ? 0 : preferredIndex;
  }

  Future<void> _startController(CameraDescription camera) async {
    await _controller?.dispose();

    final nextController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    _controller = nextController;
    await nextController.initialize();
  }
}
