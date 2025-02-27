import 'package:flutter/material.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final List<Color> _initialButtonColors = [
    Colors.lightBlue[200]!,
    Colors.purple[200]!,
    Colors.yellow[200]!,
  ];

  List<Color> _buttonColors = [];
  List<Offset> _buttonPositions = [];
  List<String> _buttonLabels = [];
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _buttonColors = List.from(_initialButtonColors);
    _buttonPositions = List.generate(_initialButtonColors.length, (index) {
      return Offset(
        (index % 2) * 150 + 50,
        (index ~/ 2) * 100 + 100,
      );
    });
    _buttonLabels = ["Chat", "Talk", "Speak"];

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeIn),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.reverse();
      }
    });
    _pulseController.forward();
    _glowController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _addNewButton(String label) {
    setState(() {
      _buttonColors.add(Colors.primaries[Random().nextInt(Colors.primaries.length)][200]!);
      _buttonPositions.add(Offset(
        Random().nextDouble() * (MediaQuery.of(context).size.width - 80),
        Random().nextDouble() * (MediaQuery.of(context).size.height - 40),
      ));
      _buttonLabels.add(label);
    });
  }

  void _onDragUpdate(int index, Offset newPosition) {
    setState(() {
      double newDx = newPosition.dx.clamp(0, MediaQuery.of(context).size.width - 80);
      double newDy = newPosition.dy.clamp(0, MediaQuery.of(context).size.height - 40);
      _buttonPositions[index] = Offset(newDx, newDy);
      _checkForCombination(index);
    });
  }

  void _checkForCombination(int index) {
    Offset currentPosition = _buttonPositions[index];
    Color currentColor = _buttonColors[index];
    String currentLabel = _buttonLabels[index];
    int? overlappingIndex;

    for (int i = 0; i < _buttonPositions.length; i++) {
      if (i != index && _isOverlapping(currentPosition, _buttonPositions[i])) {
        overlappingIndex = i;
        break;
      }
    }

    if (overlappingIndex != null) {
      _triggerMergeAnimation(index, overlappingIndex, currentColor, currentLabel);
    }
  }

  void _triggerMergeAnimation(int index1, int index2, Color currentColor, String currentLabel) {
    _scaleController.forward().then((_) => _scaleController.reverse());
    _pulseController.reset();
    _pulseController.forward();
    _glowController.reset(); // Fixed the typo here
    _glowController.forward();

    setState(() {
      Color otherColor = _buttonColors[index2];
      String otherLabel = _buttonLabels[index2];
      double newX = (_buttonPositions[index1].dx + _buttonPositions[index2].dx) / 2;
      double newY = (_buttonPositions[index1].dy + _buttonPositions[index2].dy) / 2;
      Offset newPosition = Offset(
        newX.clamp(0, MediaQuery.of(context).size.width - 80),
        newY.clamp(0, MediaQuery.of(context).size.height - 40),
      );

      // Merge colors
      int r = (currentColor.red + otherColor.red) ~/ 2;
      int g = (currentColor.green + otherColor.green) ~/ 2;
      int b = (currentColor.blue + otherColor.blue) ~/ 2;
      Color newColor = Color.fromRGBO(r, g, b, 1.0);

      // Merge labels into a single word
      String newLabel = currentLabel + otherLabel;

      // Remove old buttons (in descending order to avoid index issues)
      List<int> buttonsToRemove = [index1, index2]..sort((a, b) => b.compareTo(a));
      for (int i in buttonsToRemove) {
        _buttonColors.removeAt(i);
        _buttonPositions.removeAt(i);
        _buttonLabels.removeAt(i);
      }

      // Add merged button
      _buttonColors.add(newColor);
      _buttonPositions.add(newPosition);
      _buttonLabels.add(newLabel);

      // Notify user of the merge
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Merged into: $newLabel")),
      );

      // Add a new button to continue the chat
      _addNewButton("Next${_buttonLabels.length + 1}");
    });
  }

  bool _isOverlapping(Offset pos1, Offset pos2) {
    const double buttonSize = 80;
    const double overlapThreshold = 20;
    return (pos1.dx - pos2.dx).abs() < buttonSize - overlapThreshold &&
        (pos1.dy - pos2.dy).abs() < buttonSize - overlapThreshold;
  }

  Widget _buildInfiniteScrollBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 5000),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[100]!, Colors.purple[100]!],
        ),
      ),
      child: CustomPaint(
        painter: _InfiniteScrollPainter(),
        child: Container(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildInfiniteScrollBackground(),
          ...List.generate(_buttonColors.length, (index) {
            return Positioned(
              left: _buttonPositions[index].dx,
              top: _buttonPositions[index].dy,
              child: _buildDraggableButton(index),
            );
          }),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _addNewButton("Chat${_buttonLabels.length + 1}"),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableButton(int index) {
    return GestureDetector(
      onPanUpdate: (details) {
        _onDragUpdate(index, _buttonPositions[index] + details.delta);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _pulseController, _glowController]),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..scale(_scaleAnimation.value * _pulseAnimation.value)
              ..rotateZ(_glowAnimation.value * 0.1),
            child: Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  _buttonLabels[index],
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfiniteScrollPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 2;
    double offsetY = DateTime.now().millisecondsSinceEpoch % size.height;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(0, offsetY + i * size.height),
        Offset(size.width, offsetY + i * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() {
  runApp(const MaterialApp(home: QuizScreen()));
}