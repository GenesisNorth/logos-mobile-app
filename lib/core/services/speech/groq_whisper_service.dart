import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// Free cloud speech service using Groq's high-speed Whisper Large V3.
/// Capable of transcribing biblical recitation audio in ~300ms with vocabulary biasing.
class GroqWhisperService {
  final http.Client _client;

  GroqWhisperService({http.Client? client}) : _client = client ?? http.Client();

  static const _groqEndpoint = 'https://api.groq.com/openai/v1/audio/transcriptions';

  /// Whether Groq Whisper is configured via environment / build define.
  static bool get isAvailable => AppConfig.hasGroq;

  /// Transcribes an audio file using Groq's free Whisper Large V3.
  /// An optional [scripturePrompt] can be passed to bias the model toward
  /// proper biblical phrasing and archaic names.
  Future<String?> transcribe(
    File audioFile, {
    String? scripturePrompt,
  }) async {
    const apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_groqEndpoint))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-large-v3'
        ..fields['response_format'] = 'json'
        ..fields['temperature'] = '0.0';

      if (scripturePrompt != null && scripturePrompt.isNotEmpty) {
        request.fields['prompt'] = scripturePrompt;
      }

      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String?;
        debugPrint('[GroqWhisper] Transcribed in cloud: "$text"');
        return text;
      } else {
        debugPrint('[GroqWhisper] API error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[GroqWhisper] Request exception: $e');
      return null;
    }
  }
}
