import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';

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
  final GeminiService _geminiService = GeminiService();
  final List<Map<String, String>> _messages = [];
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _username;

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      _showLoginRequired();
      return;
    }
    _loadUserDetails();
    _loadChatHistory();
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Authentication Required"),
        content: Text("Please log in to use the chat."),
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

  void _loadUserDetails() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error loading user details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading user details: $e")),
      );
    }
  }

  void _loadChatHistory() async {
    if (_user == null) return;
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
      debugPrint("Error loading chat history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading chat history: $e")),
      );
    }
  }

  void sendMessage() async {
    if (_user == null) {
      _showLoginRequired();
      return;
    }

    if (textController.text.isEmpty) return;

    setState(() {
      isExpanded = false;
      isTyping = true;
      _messages.add({'userMessage': textController.text, 'botResponse': ''});
    });

    try {
      debugPrint("Sending prompt to Gemini: ${textController.text}");
      String response = await _geminiService.getGeminiResponse(textController.text);
      debugPrint("Gemini response received: $response");
      setState(() {
        isTyping = false;
        _messages[_messages.length - 1]['botResponse'] = response;
      });
    } catch (e) {
      debugPrint("Error getting Gemini response: $e");
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
      appBar: AppBar(
        title: Text("LearnCraft Chat", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blue[900],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.person, color: Colors.white), // Profile icon as sidebar toggle
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _username ?? 'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                'View Profile',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/profile'); // Navigate to ProfileScreen
              },
            ),
            ListTile(
              title: Text(
                'Debug Menu',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/debug'); // Navigate to DebugMenu
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._messages.map((message) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _TypingIndicator(),
                      ],
                    ),
                  ),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({super.key});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
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
      mainAxisSize: MainAxisSize.min,
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