import 'package:flutter/material.dart';
import '../services/gemini_service.dart'; // Import GeminiService for chat functionality
import 'package:firebase_auth/firebase_auth.dart'; // Add FirebaseAuth for authentication check

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  bool isTyping = false;
  final TextEditingController textController = TextEditingController();
  final GeminiService _geminiService = GeminiService(); // Initialize GeminiService
  final List<Map<String, String>> _messages = []; // Store chat messages locally
  final User? _user = FirebaseAuth.instance.currentUser; // Get current user

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      // Handle unauthenticated user (redirect to login or show error)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in to use the chat.")),
      );
      return;
    }
    _loadChatHistory(); // Load existing chat history from Firestore
  }

  void _loadChatHistory() async {
    if (_user == null) return; // Ensure user is authenticated
    try {
      _geminiService.getChatHistory().listen((snapshot) {
        setState(() {
          _messages.clear();
          _messages.addAll(snapshot.docs.map((doc) => {
            'userMessage': doc['userMessage'] as String? ?? '',
            'botResponse': doc['botResponse'] as String? ?? '',
          }).toList());
        });
      });
    } catch (e) {
      debugPrint("Error loading chat history: $e"); // Use debugPrint for better logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading chat history: $e")),
      );
    }
  }

  void sendMessage() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in to send messages.")),
      );
      return;
    }

    if (textController.text.isEmpty) return;

    setState(() {
      isExpanded = false;
      isTyping = true;
      _messages.add({'userMessage': textController.text, 'botResponse': ''});
    });

    try {
      debugPrint("Sending prompt to Gemini: ${textController.text}"); // Debug log
      String response = await _geminiService.getGeminiResponse(textController.text);
      debugPrint("Gemini response received: $response"); // Debug log
      setState(() {
        isTyping = false;
        _messages[_messages.length - 1]['botResponse'] = response;
      });
    } catch (e) {
      debugPrint("Error getting Gemini response: $e"); // Debug log
      setState(() {
        isTyping = false;
        _messages[_messages.length - 1]['botResponse'] = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting Gemini response: $e")),
      );
    } finally {
      textController.clear();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("LearnCraft Chat", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blue[900],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // Scroll to bottom for new messages
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prevent overflow in Column
              children: [
                // Display chat messages
                ..._messages.map((message) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Prevent overflow in Row
                      mainAxisAlignment: message['userMessage']!.isNotEmpty
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (message['userMessage']!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['userMessage']!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (message['botResponse']!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['botResponse']!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                if (isTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Prevent overflow
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TypingIndicator(),
                      ],
                    ),
                  ),
                SizedBox(height: 80), // Space for the text field
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max, // Ensure Row fits within screen width
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                onTap: () {
                  setState(() {
                    isExpanded = true;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Ask Learn Craft...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue[900]!),
                  ),
                  filled: true,
                  fillColor: Colors.blue[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (value) => sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue[900]),
              onPressed: sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// Typing indicator animation (updated to fix Tween assertion)
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ScaleTransition(
            scale: _animation,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}