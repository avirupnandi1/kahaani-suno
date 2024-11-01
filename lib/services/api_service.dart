import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String geminiApiKey;
  final String elevenLabsApiKey;

  // ElevenLabs voice IDs (you can replace with your preferred voice)
  // Some sample voice IDs from ElevenLabs:
  // 21m00Tcm4TlvDq8ikWAM - Rachel
  // D38z5RcWu1voky8WS1ja - Domi
  // MF3mGyEYCl7XYWbV9V6O - Bella
  // TxGEqnHWrfWFTfGW9XjX - Josh
  static const String defaultVoiceId = 'TxGEqnHWrfWFTfGW9XjX';

  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String elevenLabsApiUrl =
      'https://api.elevenlabs.io/v1/text-to-speech';

  final String voiceId;

  ApiService({
    required this.geminiApiKey,
    required this.elevenLabsApiKey,
    String? voiceId,
  }) : voiceId = voiceId ?? defaultVoiceId;

  Future<Map<String, String>> generateStory(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''Generate a creative short story based on this prompt: $prompt. 
                        Format the response with:
                        Title: [Story Title]
                        [Story Content]
                        Make the story between 100-200 words.'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.8,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        // Parse the generated text to separate title and story
        final lines = generatedText.split('\n');
        String title = '';
        String story = '';

        // More robust title extraction
        for (var line in lines) {
          if (line.trim().toLowerCase().startsWith('title:')) {
            title = line
                .replaceAll(RegExp(r'title:', caseSensitive: false), '')
                .trim();
            break;
          }
        }

        // If no title found, use first line as title
        if (title.isEmpty && lines.isNotEmpty) {
          title = lines[0].trim();
          story = lines.sublist(1).join('\n').trim();
        } else {
          // Remove title line and join the rest
          story = lines
              .where((line) => !line.trim().toLowerCase().startsWith('title:'))
              .join('\n')
              .trim();
        }
        title = title.replaceAll(RegExp(r'^(\*+)|(\*+)$'), '').trim();
        // Ensure we have both title and story
        if (title.isEmpty) title = "Untitled Story";
        if (story.isEmpty) story = "Story generation failed. Please try again.";

        return {
          'title': title,
          'story': story,
        };
      } else {
        print('Gemini API Error: ${response.body}');
        throw Exception(
            'Failed to generate story (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Story Generation Error: $e');
      throw Exception('Error generating story: $e');
    }
  }

  Future<List<int>> convertToSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$elevenLabsApiUrl/$voiceId'),
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': elevenLabsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.5,
            'style': 0.5,
            'use_speaker_boost': true
          },
        }),
      );

      if (response.statusCode == 200) {
        // Return the audio bytes directly
        return response.bodyBytes;
      } else {
        print('ElevenLabs API Error: ${response.body}');
        throw Exception(
            'Failed to convert text to speech (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Text-to-Speech Error: $e');
      throw Exception('Error converting text to speech: $e');
    }
  }
}
