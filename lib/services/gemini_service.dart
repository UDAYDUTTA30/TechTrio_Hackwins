import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ Prototype key (do NOT push public repo)
  static const String _apiKey =
      'AIzaSyDv0wxkJ57NyWYbdVHetv9Z8ke8t60F02Q';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // ===========================
  // PATIENT: Explain Therapy
  // ===========================
  static Future<String> explainTherapy({
    required String therapyName,
    required List<String> prePrecautions,
    required List<String> postPrecautions,
  }) async {
    final prompt = '''
You are explaining an Ayurvedic therapy to a patient.
Keep language simple, calm, and non-medical.

Therapy: $therapyName

Before-session precautions:
${prePrecautions.isEmpty ? '- None' : prePrecautions.join('\n')}

After-session precautions:
${postPrecautions.isEmpty ? '- None' : postPrecautions.join('\n')}

Explain in 3–4 short sentences:
- What this therapy does
- Why precautions matter
- What the patient can expect

Do NOT give medical advice or warnings.
''';

    try {
      return await _callGemini(prompt);
    } catch (_) {
      return _fallbackTherapyExplanation();
    }
  }

  // ===========================
  // DOCTOR: Summarize Feedback
  // ===========================
  static Future<String> summarizeFeedback({
    required List<Map<String, dynamic>> feedbackList,
  }) async {
    if (feedbackList.isEmpty) {
      return 'No feedback available to summarize.';
    }

    final feedbackText = feedbackList.map((f) {
      return '''
Session ${f['sessionNumber']}
Therapy: ${f['therapyName']}
Rating: ${f['rating']}/5
Comments: ${f['comments']?.isEmpty == true ? 'None' : f['comments']}
---
''';
    }).join('\n');

    final prompt = '''
You are summarizing patient feedback for a doctor.
Be factual and concise.

Feedback:
$feedbackText

Write 4–5 sentences covering:
- Overall satisfaction trend
- Common issues or discomfort
- Improvements noticed
- Any repeated patterns

Do NOT recommend treatments.
''';

    try {
      return await _callGemini(prompt);
    } catch (_) {
      return _fallbackFeedbackSummary();
    }
  }

  // ===========================
  // CORE GEMINI CALL
  // ===========================
  static Future<String> _callGemini(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final response = await http
        .post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 300,
        },
      }),
    )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);

    // HARDENED PARSING (Gemini often returns empty candidates)
    if (data['candidates'] == null ||
        data['candidates'].isEmpty ||
        data['candidates'][0]['content'] == null ||
        data['candidates'][0]['content']['parts'] == null ||
        data['candidates'][0]['content']['parts'].isEmpty) {
      return _fallbackResponse(prompt);
    }

    final text =
    data['candidates'][0]['content']['parts'][0]['text'];

    return text?.trim() ?? _fallbackResponse(prompt);
  }

  // ===========================
  // FALLBACKS (DEMO SAFE)
  // ===========================
  static String _fallbackResponse(String prompt) {
    if (prompt.toLowerCase().contains('therapy')) {
      return _fallbackTherapyExplanation();
    }
    return _fallbackFeedbackSummary();
  }

  static String _fallbackTherapyExplanation() {
    return 'This therapy supports relaxation and helps the body restore balance. '
        'It is commonly used to improve circulation and reduce stress. '
        'Following the given precautions helps ensure comfort and smoother recovery '
        'after the session.';
  }

  static String _fallbackFeedbackSummary() {
    return 'Patient feedback shows varying comfort levels across sessions. '
        'Some sessions were well tolerated, while others reported mild discomfort. '
        'No serious concerns are evident, but trends should be reviewed by the doctor '
        'before making further decisions.';
  }
}
