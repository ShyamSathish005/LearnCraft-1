import 'dart:async';

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
  StreamSubscription<QuerySnapshot>? _chatHistorySubscription; // Store the subscription
  bool _isSelecting = false; // Track selection mode
  Set<int> _selectedMessages = {}; // Track selected message indices

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
        if (mounted) {
          setState(() {
            _username = doc.data()?['username'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Error loading user details: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading user details: $e")),
        );
      }
    }
  }

  void _loadChatHistory() async {
    if (_user == null) return;
    try {
      debugPrint("Loading chat history for userId: ${_user!.uid}");
      _chatHistorySubscription?.cancel(); // Cancel any existing subscription
      _chatHistorySubscription = _geminiService.getChatHistory().listen((snapshot) {
        if (!mounted) return; // Check if the widget is still mounted
        debugPrint("Chat history snapshot received with ${snapshot.docs.length} documents");
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(snapshot.docs.reversed.map((doc) { // Reversed for oldest at top, newest at bottom
              final data = doc.data() as Map<String, dynamic>;
              debugPrint("Processing Firestore document: userMessage=${data['userMessage']}, botResponse=${data['botResponse']}");
              return {
                'userMessage': data['userMessage'] as String? ?? '',
                'botResponse': data['botResponse'] as String? ?? '',
              };
            }).toList());
            debugPrint("Updated _messages list with ${_messages.length} messages: ${_messages.map((m) => 'userMessage=${m['userMessage']}, botResponse=${m['botResponse']}').join(', ')}");
          });
        }
      }, onError: (e) {
        if (!mounted) return;
        debugPrint("Error in chat history stream: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading chat history: $e")),
        );
      });
    } catch (e) {
      if (!mounted) return;
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

    if (mounted) {
      setState(() {
        isExpanded = false;
        isTyping = true;
        _messages.insert(0, {'userMessage': textController.text, 'botResponse': ''}); // Add new messages at the top (bottom in UI due to reverse)
      });
    }

    try {
      debugPrint("Sending prompt to Gemini: ${textController.text}");
      String response = await _geminiService.getGeminiResponse(textController.text);
      debugPrint("Gemini response received: $response");
      if (mounted) {
        setState(() {
          isTyping = false;
          _messages[0]['botResponse'] = response; // Update the newest message with the bot response
          debugPrint("Updated last message: userMessage=${_messages[0]['userMessage']}, botResponse=${_messages[0]['botResponse']}");
        });
      }
    } catch (e) {
      debugPrint("Error getting Gemini response: $e");
      if (mounted) {
        setState(() {
          isTyping = false;
          _messages[0]['botResponse'] = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting Gemini response: $e")),
        );
      }
    } finally {
      textController.clear();
    }
  }

  Future<void> clearChatHistory() async {
    if (_user == null) return;
    try {
      if (mounted) {
        setState(() {
          _messages.clear(); // Clear local messages
          _selectedMessages.clear(); // Clear selected messages
          _isSelecting = false; // Exit selection mode
        });
      }
      // Clear Firestore messages for the current user
      final collection = FirebaseFirestore.instance
          .collection('chats')
          .doc(_user!.uid)
          .collection('messages');
      final querySnapshot = await collection.get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint("Chat history cleared for userId: ${_user!.uid}");
    } catch (e) {
      if (mounted) {
        debugPrint("Error clearing chat history: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error clearing chat history: $e")),
        );
      }
    }
  }

  Future<void> deleteSelectedMessages() async {
    if (_user == null) return;
    try {
      if (mounted) {
        setState(() async {
          // Sort selected indices in descending order to avoid index shifting during deletion
          final selectedIndices = _selectedMessages.toList()..sort((a, b) => b.compareTo(a));
          for (var index in selectedIndices) {
            if (index >= 0 && index < _messages.length) {
              final message = _messages[index];
              // Delete from Firestore if the message exists
              final querySnapshot = await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_user!.uid)
                  .collection('messages')
                  .where('userMessage', isEqualTo: message['userMessage'])
                  .where('botResponse', isEqualTo: message['botResponse'])
                  .get();
              for (var doc in querySnapshot.docs) {
                await doc.reference.delete();
              }
              _messages.removeAt(index);
            }
          }
          _selectedMessages.clear(); // Clear selection after deletion
          _isSelecting = false; // Exit selection mode
        });
      }
      debugPrint("Selected messages deleted for userId: ${_user!.uid}");
    } catch (e) {
      if (mounted) {
        debugPrint("Error deleting selected messages: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting selected messages: $e")),
        );
      }
    }
  }

  void _showDeleteOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Messages'),
        content: Text('Would you like to delete selected messages or clear all?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteSelectedMessages();
            },
            child: Text('Delete Selected'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              clearChatHistory();
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectMode() {
    if (mounted) {
      setState(() {
        _isSelecting = !_isSelecting;
        if (!_isSelecting) {
          _selectedMessages.clear(); // Clear selection when exiting select mode
        }
      });
    }
  }

  @override
  void dispose() {
    _chatHistorySubscription?.cancel(); // Cancel the Firestore stream subscription
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.person, color: Colors.blue[900]), // Profile icon as sidebar toggle
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (!_isSelecting)
            IconButton(
              icon: Icon(Icons.select_all, size: 20, color: Colors.blue[900]), // Select button
              onPressed: _toggleSelectMode, // Toggle selection mode
              tooltip: 'Select Messages', // Tooltip for accessibility
            ),
          if (_isSelecting)
            IconButton(
              icon: Icon(Icons.cancel, size: 20, color: Colors.blue[900]), // Cancel selection mode
              onPressed: _toggleSelectMode, // Exit selection mode
              tooltip: 'Cancel Selection', // Tooltip for accessibility
            ),
          IconButton(
            icon: Icon(Icons.delete, size: 20, color: Colors.blue[900]), // Delete button for options
            onPressed: _isSelecting ? _showDeleteOptions : null, // Show delete options only in select mode
            tooltip: 'Delete Messages', // Tooltip for accessibility
          ),
          IconButton(
            icon: Icon(Icons.clear, size: 20, color: Colors.blue[900]), // Small clear button
            onPressed: clearChatHistory, // Clear chat history
            tooltip: 'Clear Chat', // Tooltip for accessibility
          ),
        ],
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
                'Quiz',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/quiz'); // Navigate to DebugMenu
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
          reverse: true, // Keep reverse scrolling to start at the bottom
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Start messages from the top
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._messages.reversed.map((message) { // Reverse the order of messages in the UI (oldest at top, newest at bottom)
                  debugPrint("Rendering message: userMessage=${message['userMessage']}, botResponse=${message['botResponse']}");
                  final index = _messages.indexOf(message);
                  return GestureDetector(
                    onTap: _isSelecting
                        ? () {
                      if (mounted) {
                        setState(() {
                          if (_selectedMessages.contains(index)) {
                            _selectedMessages.remove(index);
                          } else {
                            _selectedMessages.add(index);
                          }
                        });
                      }
                    }
                        : null, // Disable tap when not in select mode
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: message['userMessage']!.isNotEmpty && message['botResponse']!.isEmpty
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSelecting && _selectedMessages.contains(index)
                                    ? Colors.orange.withOpacity(0.3) // Highlight selected messages
                                    : (message['userMessage']!.isNotEmpty && message['botResponse']!.isEmpty
                                    ? Colors.blue
                                    : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message['userMessage']!.isNotEmpty && message['botResponse']!.isEmpty
                                    ? message['userMessage']!
                                    : (message['botResponse']!.isNotEmpty
                                    ? message['botResponse']!
                                    : ''),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: message['userMessage']!.isNotEmpty && message['botResponse']!.isEmpty
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                softWrap: true, // Allow text to wrap
                                maxLines: null, // Allow unlimited lines
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  if (mounted) {
                    setState(() {
                      isExpanded = true;
                    });
                  }
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