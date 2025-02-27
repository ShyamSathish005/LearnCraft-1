import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeminiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    // Replace with your actual Google Generative AI API key
    apiKey: 'AIzaSyCDGana6U0f7kre53WTFFYxayPlYAcVAJA', // Replace with your actual key
  );

  Future<String> getGeminiResponse(String prompt) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      debugPrint("Sending prompt to Gemini: $prompt"); // Debug log
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String generatedText = response.text!;
        debugPrint("Gemini response received: $generatedText"); // Debug log
        await saveChatHistory(prompt, generatedText, user.uid);
        return generatedText;
      } else {
        throw Exception("No response received from Gemini");
      }
    } catch (e) {
      debugPrint("Gemini Service Error: $e"); // Debug log
      return "Error: $e";
    }
  }

  Future<void> saveChatHistory(String userMessage, String botResponse, String userId) async {
    try {
      debugPrint("Saving to Firestore for user: $userId"); // Debug log
      await _firestore.collection('chats').doc(userId).collection('messages').add({
        'userMessage': userMessage,
        'botResponse': botResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      debugPrint("Firestore Error: $e"); // Debug log
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