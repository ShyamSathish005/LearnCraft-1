import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash', // Use a supported model (confirmed from Quick Start guide)
    apiKey: 'YOUR_VALID_GEMINI_API_KEY_HERE', // Replace with your actual API key
  );

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
        String generatedText = response.text!;
        // Gemini-specific debug message for receiving response
        debugPrint("Gemini: Received response - '$generatedText'");
        await saveChatHistory(prompt, generatedText, user.uid);
        return generatedText;
      } else {
        throw Exception("No response received from Gemini");
      }
    } catch (e) {
      // Gemini-specific debug message for errors
      debugPrint("Gemini Error: $e");
      return "Error: $e";
    }
  }

  Future<void> saveChatHistory(String userMessage, String botResponse, String userId) async {
    try {
      // No Gemini-specific debug here, as this is Firestore-related
      await _firestore.collection('chats').doc(userId).collection('messages').add({
        'userMessage': userMessage,
        'botResponse': botResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      debugPrint("Firestore Error (not Gemini-related): $e"); // Optional, for context
      throw Exception("Failed to save chat history: $e");
    }
  }

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