import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';

class TeachScreen extends StatefulWidget {
  const TeachScreen({super.key});

  @override
  State<TeachScreen> createState() => _TeachScreenState();
}

class _TeachScreenState extends State<TeachScreen> with TickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;
  final GeminiService _geminiService = GeminiService();
  List<Color> _buttonColors = [];
  List<Offset> _buttonPositions = [];
  List<String> _buttonLabels = [];
  List<Size> _buttonSizes = [];
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeButtons();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
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
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.reverse();
      }
    });
    _pulseController.forward();
    _glowController.forward();
  }

  void _initializeButtons() {
    const initialLabels = [
      "Slope",
      "Intercept",
      "Error",
      "Prediction",
      "Data",
      "Fit",
    ];
    setState(() {
      _buttonColors = List.generate(
        initialLabels.length,
            (index) => Colors.primaries[index % Colors.primaries.length][300]!,
      );
      _buttonPositions = List.generate(
        initialLabels.length,
            (index) => Offset((index % 3) * 120 + 30, (index ~/ 3) * 70 + 80),
      );
      _buttonLabels = List.from(initialLabels);
      _buttonSizes = List.generate(
        initialLabels.length,
            (index) => _calculateButtonSize(initialLabels[index]),
      );
    });
  }

  Size _calculateButtonSize(String label) {
    const double baseHeight = 50.0;
    double width = (label.length * 10.0).clamp(80.0, 160.0); // Dynamic width
    return Size(width, baseHeight);
  }

  void _onDragUpdate(int index, Offset newPosition) {
    setState(() {
      double buttonWidth = _buttonSizes[index].width;
      double buttonHeight = _buttonSizes[index].height;
      double newDx = newPosition.dx.clamp(0, MediaQuery.of(context).size.width - buttonWidth);
      double newDy = newPosition.dy.clamp(0, MediaQuery.of(context).size.height - buttonHeight - 56); // Account for AppBar
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
      if (i != index && _isOverlapping(currentPosition, _buttonPositions[i], index, i)) {
        overlappingIndex = i;
        break;
      }
    }

    if (overlappingIndex != null) {
      _triggerMergeAnimation(index, overlappingIndex, currentColor, currentLabel);
    }
  }

  Future<void> _triggerMergeAnimation(int index1, int index2, Color currentColor, String currentLabel) async {
    _scaleController.forward().then((_) => _scaleController.reverse());
    _pulseController.reset();
    _pulseController.forward();
    _glowController.reset();
    _glowController.forward();

    String otherLabel = _buttonLabels[index2];
    String newLabel = await _generateMeaningfulMerge(currentLabel, otherLabel);

    Color otherColor = _buttonColors[index2];
    double newX = (_buttonPositions[index1].dx + _buttonPositions[index2].dx) / 2;
    double newY = (_buttonPositions[index1].dy + _buttonPositions[index2].dy) / 2;
    Size newSize = _calculateButtonSize(newLabel);
    Offset newPosition = Offset(
      newX.clamp(0, MediaQuery.of(context).size.width - newSize.width),
      newY.clamp(0, MediaQuery.of(context).size.height - newSize.height - 56),
    );

    int r = (currentColor.red + otherColor.red) ~/ 2;
    int g = (currentColor.green + otherColor.green) ~/ 2;
    int b = (currentColor.blue + otherColor.blue) ~/ 2;
    Color newColor = Color.fromRGBO(r, g, b, 1.0);

    if (mounted) {
      setState(() {
        List<int> buttonsToRemove = [index1, index2]..sort((a, b) => b.compareTo(a));
        for (int i in buttonsToRemove) {
          _buttonColors.removeAt(i);
          _buttonPositions.removeAt(i);
          _buttonLabels.removeAt(i);
          _buttonSizes.removeAt(i);
        }

        _buttonColors.add(newColor);
        _buttonPositions.add(newPosition);
        _buttonLabels.add(newLabel);
        _buttonSizes.add(newSize);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Merged into: $newLabel")),
        );
      });
    }
  }

  Future<String> _generateMeaningfulMerge(String label1, String label2) async {
    try {
      final prompt =
          "Combine '$label1' and '$label2' into a meaningful concept in linear regression. Return a single word or concise two-word term (e.g., 'Line Equation', 'Residual') that is valid in this context, without concatenating the inputs directly.";
      String response = await _geminiService.getGeminiResponse(prompt);
      String newElementName = response.trim();
      if (newElementName.isEmpty || newElementName.split(' ').length > 2) {
        return _generateFallbackMerge(label1, label2);
      }
      return newElementName;
    } catch (e) {
      debugPrint("Error generating merge: $e");
      return _generateFallbackMerge(label1, label2);
    }
  }

  String _generateFallbackMerge(String label1, String label2) {
    if ((label1 == "Slope" && label2 == "Intercept") || (label1 == "Intercept" && label2 == "Slope")) {
      return "Line Equation";
    } else if ((label1 == "Error" && label2 == "Prediction") || (label1 == "Prediction" && label2 == "Error")) {
      return "Residual";
    } else if ((label1 == "Data" && label2 == "Fit") || (label1 == "Fit" && label2 == "Data")) {
      return "Model";
    } else if ((label1 == "Slope" && label2 == "Error") || (label1 == "Error" && label2 == "Slope")) {
      return "Slope Error";
    } else if ((label1 == "Intercept" && label2 == "Error") || (label1 == "Error" && label2 == "Intercept")) {
      return "Intercept Error";
    } else {
      return "Regression Term";
    }
  }

  Future<void> _explainButton(int index) async {
    String label = _buttonLabels[index];
    try {
      final prompt =
          "Provide a concise definition (1-2 sentences) of '$label' in the context of linear regression.";
      debugPrint("Sending explanation prompt to Gemini: $prompt");
      String explanation = await _geminiService.getGeminiResponse(prompt);
      if (explanation.trim().isEmpty || explanation.toLowerCase().contains("error")) {
        explanation = _generateFallbackExplanation(label);
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(explanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error fetching explanation for '$label': $e");
      if (mounted) {
        String fallbackExplanation = _generateFallbackExplanation(label);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(fallbackExplanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  String _generateFallbackExplanation(String label) {
    switch (label) {
      case "Slope":
        return "Slope is the rate of change of the dependent variable per unit change in the independent variable in linear regression.";
      case "Intercept":
        return "Intercept is the value of the dependent variable when the independent variable is zero in a linear regression model.";
      case "Error":
        return "Error is the difference between the actual observed value and the value predicted by the regression model.";
      case "Prediction":
        return "Prediction is the estimated value of the dependent variable based on the linear regression model.";
      case "Data":
        return "Data refers to the collection of observations used to train and evaluate the linear regression model.";
      case "Fit":
        return "Fit describes how well the regression line approximates the actual data points.";
      case "Line Equation":
        return "Line Equation (y = mx + b) defines the linear relationship between variables using slope and intercept.";
      case "Residual":
        return "Residual is the difference between the observed value and the predicted value in linear regression.";
      case "Model":
        return "Model is the mathematical representation of the relationship between variables in linear regression.";
      case "Slope Error":
        return "Slope Error quantifies the uncertainty or variability in the estimated slope of the regression line.";
      case "Intercept Error":
        return "Intercept Error quantifies the uncertainty or variability in the estimated intercept of the regression line.";
      default:
        return "$label is a concept related to linear regression.";
    }
  }

  bool _isOverlapping(Offset pos1, Offset pos2, int index1, int index2) {
    double buttonWidth1 = _buttonSizes[index1].width;
    double buttonHeight1 = _buttonSizes[index1].height;
    double buttonWidth2 = _buttonSizes[index2].width;
    double buttonHeight2 = _buttonSizes[index2].height;
    const double overlapThreshold = 20;
    return (pos1.dx - pos2.dx).abs() < (buttonWidth1 + buttonWidth2) / 2 - overlapThreshold &&
        (pos1.dy - pos2.dy).abs() < (buttonHeight1 + buttonHeight2) / 2 - overlapThreshold;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Linear Regression Explorer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(_buttonColors.length, (index) {
              if (index >= _buttonPositions.length ||
                  index >= _buttonLabels.length ||
                  index >= _buttonSizes.length) {
                debugPrint("Index out of bounds in List.generate: $index");
                return const SizedBox.shrink();
              }
              return Positioned(
                left: _buttonPositions[index].dx,
                top: _buttonPositions[index].dy,
                child: _buildDraggableButton(index),
              );
            }),
            if (_buttonLabels.isEmpty)
              const Center(
                child: Text(
                  "No elements available",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableButton(int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _explainButton(index),
      onPanUpdate: (details) {
        Offset newPosition = _buttonPositions[index] + details.delta;
        _onDragUpdate(index, newPosition);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _pulseController, _glowController]),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..scale(_scaleAnimation.value * _pulseAnimation.value)
              ..rotateZ(_glowAnimation.value * 0.05),
            child: Container(
              width: _buttonSizes[index].width,
              height: _buttonSizes[index].height,
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _buttonColors[index].withOpacity(0.9),
                    _buttonColors[index],
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _buttonLabels[index],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black26,
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}