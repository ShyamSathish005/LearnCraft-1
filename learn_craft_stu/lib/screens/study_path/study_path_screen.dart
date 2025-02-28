import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';

class StudyPathScreen extends StatefulWidget {
  const StudyPathScreen({super.key});

  @override
  State<StudyPathScreen> createState() => _StudyPathScreenState();
}

class _StudyPathScreenState extends State<StudyPathScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _topicController = TextEditingController();
  List<StudyPathStep> _studyPath = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      _showLoginRequired();
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Authentication Required"),
            content: Text("Please log in to use the study path generator."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _generateStudyPath(String topic) async {
    if (topic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter a topic to generate a study path."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _studyPath.clear();
    });

    try {
      final prompt =
          "Generate a study path for learning '$topic' in a structured, step-by-step manner. Provide the path as a list of steps, where each step is a concise title (1-3 words) followed by a brief description (1-2 sentences). Format each step as 'Step X: Title - Description'. Return the list in plain text, with each step on a new line. Example: 'Step 1: Introduction - Learn the basics of the topic.'\n'Step 2: Key Concepts - Study the fundamental concepts and definitions.'";
      debugPrint("Sending prompt to Gemini: $prompt");
      String response = await _geminiService.getGeminiResponse(prompt);
      List<StudyPathStep> steps = _parseStudyPath(response);
      setState(() {
        _studyPath = steps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error generating study path: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating study path: $e")),
      );
    }
  }

  List<StudyPathStep> _parseStudyPath(String response) {
    List<StudyPathStep> steps = [];
    List<String> lines = response.split('\n');
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      RegExp regex = RegExp(r'Step \d+: (.*?)\s*-\s*(.*)');
      var match = regex.firstMatch(line);
      if (match != null && match.groupCount == 2) {
        String title = match.group(1)!.trim();
        String description = match.group(2)!.trim();
        steps.add(StudyPathStep(title: title, description: description));
      }
    }
    return steps;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Path Generator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Input field and button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: "Enter topic (e.g., Linear Regression)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[900]!),
                        ),
                        filled: true,
                        fillColor: Colors.blue[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => _generateStudyPath(_topicController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              "Generate",
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ],
              ),
            ),
            // Flowchart
            Expanded(
              child:
                  _studyPath.isEmpty
                      ? const Center(
                        child: Text(
                          "Enter a topic to generate a study path.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                      : SingleChildScrollView(
                        controller: _scrollController,
                        child: CustomPaint(
                          size: Size(
                            double.infinity,
                            _studyPath.length * 120.0 + 20,
                          ),
                          // Approximate height
                          painter: FlowchartPainter(steps: _studyPath),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(_studyPath.length, (
                                index,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildStudyPathNode(index),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyPathNode(int index) {
    final step = _studyPath[index];
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[900]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// Data model for study path steps
class StudyPathStep {
  final String title;
  final String description;

  StudyPathStep({required this.title, required this.description});
}

// Custom painter to draw arrows between flowchart nodes
class FlowchartPainter extends CustomPainter {
  final List<StudyPathStep> steps;

  FlowchartPainter({required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue[900]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final arrowPaint =
        Paint()
          ..color = Colors.blue[900]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.fill;

    // Draw arrows between nodes
    for (int i = 0; i < steps.length - 1; i++) {
      double startX = size.width / 2;
      double startY = i * 120.0 + 60; // Center of the current node (approx)
      double endX = size.width / 2;
      double endY = (i + 1) * 120.0; // Top of the next node (approx)

      // Draw the arrow line
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Draw the arrowhead
      double arrowSize = 8.0;
      Path arrowPath =
          Path()
            ..moveTo(endX, endY)
            ..lineTo(endX - arrowSize, endY - arrowSize)
            ..lineTo(endX + arrowSize, endY - arrowSize)
            ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
