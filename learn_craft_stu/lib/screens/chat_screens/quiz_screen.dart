import 'package:flutter/material.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});


  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final List<Color> _initialButtonColors = [
    Colors.lightBlue[200]!, // Button 1
    Colors.purple[200]!,    // Button 2
    Colors.yellow[200]!,    // Button 3
    Colors.lightBlue[200]!, // Button 4
    Colors.purple[200]!,    // Button 5
    Colors.pink[200]!,      // Button 6 (coral-like)
  ];

  List<Color> _buttonColors = []; // Dynamic color list for changes
  List<Offset> _buttonPositions = []; // Track positions for dragging
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;


  void initState() {
    super.initState();
    _buttonColors = List.from(_initialButtonColors);
    _buttonPositions = List.generate(_initialButtonColors.length, (index) {
      return Offset(
        (index % 2) * 150 + 50, // Initial X position (staggered for visibility)
        (index ~/ 2) * 100 + 100, // Initial Y position (stack vertically)
      );
    });
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


  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onDragUpdate(int index, Offset newPosition) {
    setState(() {
      // Clamp x and y coordinates individually
      double newDx = newPosition.dx.clamp(0, MediaQuery.of(context).size.width - 80);
      double newDy = newPosition.dy.clamp(0, MediaQuery.of(context).size.height - 40);
      _buttonPositions[index] = Offset(newDx, newDy);
      _checkForCombination(index);
    });
  }

  void _checkForCombination(int index) {
    Offset currentPosition = _buttonPositions[index];
    Color newColor = _buttonColors[index];
    List<int> overlappingIndices = [];

    for (int i = 0; i < _buttonPositions.length; i++) {
      if (i != index && _isOverlapping(currentPosition, _buttonPositions[i])) {
        overlappingIndices.add(i);
      }
    }

    if (overlappingIndices.isNotEmpty) {
      // Combine colors of all overlapping buttons
      int totalRed = newColor.red;
      int totalGreen = newColor.green;
      int totalBlue = newColor.blue;
      int count = 1; // Include the current button

      for (int i in overlappingIndices) {
        Color otherColor = _buttonColors[i];
        totalRed += otherColor.red;
        totalGreen += otherColor.green;
        totalBlue += otherColor.blue;
        count++;
      }

      // Average the colors
      int r = totalRed ~/ count;
      int g = totalGreen ~/ count;
      int b = totalBlue ~/ count;
      newColor = Color.fromRGBO(r, g, b, 1.0);

      _triggerTransformAnimation(index, overlappingIndices, newColor);
    }
  }

  void _triggerTransformAnimation(int index1, List<int> indices, Color newColor) {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    _pulseController.reset();
    _pulseController.forward();
    _glowController.reset();
    _glowController.forward();

    setState(() {
      // Calculate the average position of all involved buttons
      double totalX = _buttonPositions[index1].dx;
      double totalY = _buttonPositions[index1].dy;
      int count = 1;

      for (int i in indices) {
        totalX += _buttonPositions[i].dx;
        totalY += _buttonPositions[i].dy;
        count++;
      }

      // Clamp x and y coordinates individually
      double newDx = (totalX / count).clamp(0, MediaQuery.of(context).size.width - 80);
      double newDy = (totalY / count).clamp(0, MediaQuery.of(context).size.height - 40);
      Offset newPosition = Offset(newDx, newDy);

      // Remove old buttons and create a new single button
      List<int> buttonsToRemove = [index1, ...indices];
      buttonsToRemove.sort((a, b) => b.compareTo(a)); // Sort in descending order for safe removal

      for (int i in buttonsToRemove) {
        _buttonColors.removeAt(i);
        _buttonPositions.removeAt(i);
      }

      // Add the new transformed button
      _buttonColors.add(newColor);
      _buttonPositions.add(newPosition);
    });
  }

  bool _isOverlapping(Offset pos1, Offset pos2) {
    const double buttonSize = 80; // Width and height of buttons
    const double overlapThreshold = 20; // Allow slight overlap for combination
    return (pos1.dx - pos2.dx).abs() < buttonSize - overlapThreshold &&
        (pos1.dy - pos2.dy).abs() < buttonSize - overlapThreshold;
  }

  // Infinite scrolling background with random colors
  Widget _buildInfiniteScrollBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 5000), // Slow scroll effect
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[100]!,
            Colors.purple[100]!,
            Colors.yellow[100]!,
            Colors.pink[100]!,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _InfiniteScrollPainter(),
        child: Container(),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Infinite scrolling background
          _buildInfiniteScrollBackground(),
          // Draggable buttons
          ...List.generate(_buttonColors.length, (index) {
            return Positioned(
              left: _buttonPositions[index].dx,
              top: _buttonPositions[index].dy,
              child: _buildDraggableButton(index),
            );
          }),
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
              ..rotateZ(_glowAnimation.value * 0.1), // Slight rotation for glow effect
            child: Container(
              width: 80, // Smaller size for Neal.fun-like compactness
              height: 40, // Smaller height
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(20), // Rounded corners
                border: Border.all(
                  color: Colors.black.withOpacity(0.2), // Thin stroke
                  width: 1, // Thin stroke width
                ),
              ),
              child: Container(), // No text, just color
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for infinite scroll effect (simulating movement)
class _InfiniteScrollPainter extends CustomPainter {
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

  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}