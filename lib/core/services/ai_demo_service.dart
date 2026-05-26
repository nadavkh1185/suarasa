class AiDemoResult {
  const AiDemoResult({
    required this.title,
    required this.message,
    required this.hapticPattern,
  });

  final String title;
  final String message;
  final List<int> hapticPattern;
}

class AiDemoService {
  const AiDemoService();

  AiDemoResult understandCommand(String text) {
    final lower = text.toLowerCase();

    if (_hasAny(lower, ['kamera', 'foto', 'lihat', 'gambar', 'sekitar'])) {
      return const AiDemoResult(
        title: 'AI mengarah ke kamera',
        message:
            'Saya akan membuka bantuan visual, mengambil gambar demo, lalu membacakan ringkasan lingkungan.',
        hapticPattern: [0, 90, 80, 180],
      );
    }

    if (_hasAny(lower, ['rekam', 'video'])) {
      return const AiDemoResult(
        title: 'AI mengarah ke rekam video',
        message:
            'Saya akan menyiapkan rekaman singkat untuk menangkap kondisi sekitar sebagai bukti demo.',
        hapticPattern: [0, 180, 80, 180],
      );
    }

    if (_hasAny(lower, ['menu', 'utama', 'beranda'])) {
      return const AiDemoResult(
        title: 'AI memilih menu utama',
        message:
            'Kamu berada di menu utama. Semua bantuan suara, visual, dan haptic sudah siap.',
        hapticPattern: [0, 80],
      );
    }

    if (_hasAny(lower, ['bantuan', 'tolong', 'darurat'])) {
      return const AiDemoResult(
        title: 'AI membaca sebagai kebutuhan bantuan',
        message:
            'Saya menandai ini sebagai permintaan bantuan dan memberi pola getaran peringatan.',
        hapticPattern: [0, 240, 120, 240, 120, 240],
      );
    }

    return const AiDemoResult(
      title: 'AI siap membantu',
      message:
          'Saya mendengar perintahnya. Untuk demo, coba ucapkan: buka kamera, rekam video, atau bantuan.',
      hapticPattern: [0, 70, 70, 70],
    );
  }

  AiDemoResult describeScene({required bool hasCameraFrame}) {
    return AiDemoResult(
      title: hasCameraFrame ? 'Analisis visual AI demo' : 'Simulasi visual AI',
      message: hasCameraFrame
          ? 'Kamera aktif. AI demo menyiapkan deskripsi objek besar, arah gerak, dan teks yang terlihat.'
          : 'Kamera belum aktif. Demo memakai mode simulasi untuk menjelaskan lingkungan di depan pengguna.',
      hapticPattern: const [0, 120, 90, 120],
    );
  }

  bool _hasAny(String source, List<String> words) {
    return words.any(source.contains);
  }
}
