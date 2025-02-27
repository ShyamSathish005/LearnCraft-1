import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash', // Use a supported model (confirmed from Quick Start guide)
    apiKey: 'AIzaSyCDGana6U0f7kre53WTFFYxayPlYAcVAJA', // Your actual API key (already provided)
  );

  /// Retrieves a response from the Gemini API for a given prompt.
  Future<String> getGeminiResponse(String prompt) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Gemini-specific debug message for sending prompt
      debugPrint("Gemini: Sending prompt - '$prompt'");
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String generatedText = response.text!.trim(); // Trim to remove unwanted whitespace
        // Gemini-specific debug message for receiving response
        debugPrint("Gemini: Received response - '$generatedText'");
        await saveChatHistory(prompt, generatedText, user.uid);
        return generatedText;
      } else {
        throw Exception("No response received from Gemini");
      }
    } catch (e) {
      // Gemini-specific debug message for errors, including stack trace for web
      debugPrint("Gemini Error: $e");
      return "Error: $e";
    }
  }

  /// Saves chat history (user message and bot response) to Firestore.
  Future<void> saveChatHistory(String userMessage, String botResponse, String userId) async {
    try {
      debugPrint("Attempting to save chat history for userId: $userId");
      await _firestore.collection('chats').doc(userId).collection('messages').add({
        'userMessage': userMessage.trim(),
        'botResponse': botResponse.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      });
      debugPrint("Chat history saved successfully for userId: $userId");
    } catch (e) {
      debugPrint("Failed to save chat history: $e");
      throw Exception("Failed to save chat history: $e");
    }
  }

  /// Retrieves a stream of chat history from Firestore, ordered by timestamp descending.
  Stream<QuerySnapshot> getChatHistory() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return _firestore.collection('chats').doc(user.uid).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}