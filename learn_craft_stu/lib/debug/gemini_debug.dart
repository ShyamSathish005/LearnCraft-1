/*
import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> listAvailableModels() async {
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro', // Use a known model or leave blank for default
      apiKey: '',
    );
    final models = await model.listModels();
    debugPrint("Available models: $models");
  } catch (e) {
    debugPrint("Error listing models: $e");
  }
}

 */