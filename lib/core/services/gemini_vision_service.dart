import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

enum GeminiVisionMode {
  navigation,
  objectSearch,
  signLanguage,
}

class GeminiVisionResult {
  const GeminiVisionResult({
    required this.mode,
    required this.text,
  });

  final GeminiVisionMode mode;
  final String text;

  bool get isUrgent {
    final lower = text.toLowerCase();
    return lower.contains('berhenti') ||
        lower.contains('bahaya') ||
        lower.contains('terlalu dekat') ||
        lower.contains('awas');
  }
}

class GeminiVisionService {
  GeminiVisionService({
    Dio? dio,
    String? apiKey,
    String? model,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _model = model ?? const String.fromEnvironment(
          'GEMINI_MODEL',
          defaultValue: 'gemini-2.5-flash',
        );

  final Dio _dio;
  final String _apiKey;
  final String _model;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<GeminiVisionResult> analyzeNavigation(XFile image) {
    return _analyzeImage(
      image: image,
      mode: GeminiVisionMode.navigation,
      prompt: _navigationPrompt,
    );
  }

  Future<GeminiVisionResult> searchObject({
    required XFile image,
    required String target,
  }) {
    final cleanedTarget = target.trim().isEmpty ? 'benda yang dicari' : target.trim();
    return _analyzeImage(
      image: image,
      mode: GeminiVisionMode.objectSearch,
      prompt: _objectSearchPrompt(cleanedTarget),
    );
  }

  Future<GeminiVisionResult> readSignLanguage(XFile image) {
    return _analyzeImage(
      image: image,
      mode: GeminiVisionMode.signLanguage,
      prompt: _signLanguagePrompt,
    );
  }

  Future<GeminiVisionResult> _analyzeImage({
    required XFile image,
    required GeminiVisionMode mode,
    required String prompt,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'GEMINI_API_KEY belum diatur. Jalankan dengan --dart-define=GEMINI_API_KEY=API_KEY_ANDA.',
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'topP': 0.8,
            'maxOutputTokens': 180,
          },
        },
      );

      final text = _extractText(response.data);
      if (text == null || text.trim().isEmpty) {
        throw StateError('Gemini tidak mengembalikan teks analisis.');
      }

      return GeminiVisionResult(mode: mode, text: text.trim());
    } on DioException catch (error) {
      final message = error.response?.data is Map
          ? (error.response?.data as Map)['error']?.toString()
          : error.message;
      throw StateError('Gemini gagal menganalisis gambar: ${message ?? 'koneksi bermasalah'}');
    }
  }

  String? _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    return parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
  }

  static const String _navigationPrompt = '''
Kamu adalah asisten navigasi untuk pengguna tunanetra. Analisis gambar dari kamera.
Jawab dalam Bahasa Indonesia yang singkat, jelas, dan instruksional.
Prioritaskan keselamatan dan hindari jawaban umum.
Sebutkan objek yang berpotensi ditabrak, posisinya relatif terhadap pengguna: depan, kiri, kanan, bawah, atau atas.
Berikan satu instruksi gerak sederhana: berhenti, maju pelan, geser kiri, geser kanan, atau belok sedikit.
Jika ada objek dekat di depan, mulai jawaban dengan peringatan tegas seperti: "Berhenti, ada kursi di depan."
Jika area terlihat aman, katakan "Maju pelan" dan sebutkan hal yang perlu diwaspadai.
Maksimal 3 kalimat.
''';

  static String _objectSearchPrompt(String target) => '''
User sedang mencari objek bernama $target.
Analisis gambar dan jelaskan posisi, arah, dan jarak objek relatif terhadap pengguna.
Jika objek terlihat, sebutkan posisi relatifnya: kiri, kanan, tengah, atas, bawah, dekat, atau jauh.
Berikan instruksi sederhana untuk mengarahkan kamera atau berjalan.
Jika tidak terlihat, katakan "$target tidak terlihat" dan sarankan arah memindai perlahan.
Jawab singkat dalam Bahasa Indonesia. Maksimal 3 kalimat.
''';

  static const String _signLanguagePrompt = '''
Kamu membantu menerjemahkan gestur bahasa isyarat dari gambar.
Analisis posisi tangan, wajah, dan konteks.
Jika dapat dikenali, ubah menjadi kalimat Bahasa Indonesia yang natural dan singkat.
Jika tidak yakin, katakan "Gestur belum jelas, ulangi dengan tangan terlihat penuh dan pencahayaan lebih baik."
Jangan mengarang jika gestur tidak jelas.
Maksimal 2 kalimat.
''';
}
