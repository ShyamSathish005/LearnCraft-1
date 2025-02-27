import 'dart:math';
import 'package:flutter/material.dart';

class TeachScreen extends StatefulWidget {
  const TeachScreen({super.key});

  @override
  State<TeachScreen> createState() => _TeachScreenState();
}

class _TeachScreenState extends State<TeachScreen>
    with TickerProviderStateMixin {
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
    _initializeButtons();

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
        (index) => Colors.primaries[index % Colors.primaries.length][200]!,
      );
      _buttonPositions = List.generate(
        initialLabels.length,
        (index) => Offset((index % 3) * 100 + 40, (index ~/ 3) * 60 + 80),
      );
      _buttonLabels = List.from(initialLabels);
    });
  }

  void _onDragUpdate(int index, Offset newPosition) {
    setState(() {
      double newDx = newPosition.dx.clamp(
        0,
        MediaQuery.of(context).size.width - 80,
      );
      double newDy = newPosition.dy.clamp(
        0,
        MediaQuery.of(context).size.height - 80,
      );
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
      _triggerMergeAnimation(
        index,
        overlappingIndex,
        currentColor,
        currentLabel,
      );
    }
  }

  void _triggerMergeAnimation(
    int index1,
    int index2,
    Color currentColor,
    String currentLabel,
  ) {
    _scaleController.forward().then((_) => _scaleController.reverse());
    _pulseController.reset();
    _pulseController.forward();
    _glowController.reset();
    _glowController.forward();

    setState(() {
      Color otherColor = _buttonColors[index2];
      String otherLabel = _buttonLabels[index2];
      double newX =
          (_buttonPositions[index1].dx + _buttonPositions[index2].dx) / 2;
      double newY =
          (_buttonPositions[index1].dy + _buttonPositions[index2].dy) / 2;
      Offset newPosition = Offset(
        newX.clamp(0, MediaQuery.of(context).size.width - 80),
        newY.clamp(0, MediaQuery.of(context).size.height - 80),
      );

      int r = (currentColor.red + otherColor.red) ~/ 2;
      int g = (currentColor.green + otherColor.green) ~/ 2;
      int b = (currentColor.blue + otherColor.blue) ~/ 2;
      Color newColor = Color.fromRGBO(r, g, b, 1.0);

      String newLabel = _generateMeaningfulMerge(currentLabel, otherLabel);

      List<int> buttonsToRemove = [index1, index2]
        ..sort((a, b) => b.compareTo(a));
      for (int i in buttonsToRemove) {
        _buttonColors.removeAt(i);
        _buttonPositions.removeAt(i);
        _buttonLabels.removeAt(i);
      }

      _buttonColors.add(newColor);
      _buttonPositions.add(newPosition);
      _buttonLabels.add(newLabel);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Merged into: $newLabel")));
    });
  }

  String _generateMeaningfulMerge(String label1, String label2) {
    if ((label1 == "Slope" && label2 == "Intercept") ||
        (label1 == "Intercept" && label2 == "Slope")) {
      return "LineEquation";
    } else if ((label1 == "Error" && label2 == "Prediction") ||
        (label1 == "Prediction" && label2 == "Error")) {
      return "Residual";
    } else if ((label1 == "Data" && label2 == "Fit") ||
        (label1 == "Fit" && label2 == "Data")) {
      return "Model";
    } else if ((label1 == "Slope" && label2 == "Error") ||
        (label1 == "Error" && label2 == "Slope")) {
      return "SlopeError";
    } else if ((label1 == "Intercept" && label2 == "Error") ||
        (label1 == "Error" && label2 == "Intercept")) {
      return "Error of Intercept";
    } else {
      return "$label1$label2";
    }
  }

  bool _isOverlapping(Offset pos1, Offset pos2) {
    const double buttonSize = 80;
    const double overlapThreshold = 20;
    return (pos1.dx - pos2.dx).abs() < buttonSize - overlapThreshold &&
        (pos1.dy - pos2.dy).abs() < buttonSize - overlapThreshold;
  }

  void _explainButton(int index) {
    String label = _buttonLabels[index];
    String explanation;
    switch (label) {
      case "Slope":
        explanation =
            "Slope is the steepness or rate of change of the line in linear regression.";
        break;
      case "Intercept":
        explanation =
            "Intercept is the point where the regression line crosses the y-axis.";
        break;
      case "Error":
        explanation =
            "Error is the difference between the actual data points and the predicted values.";
        break;
      case "Prediction":
        explanation =
            "Prediction is the value estimated by the linear regression model for a given input.";
        break;
      case "Data":
        explanation =
            "Data is the collection of observations used to create the regression model.";
        break;
      case "Fit":
        explanation =
            "Fit describes how well the regression line matches the data points.";
        break;
      case "LineEquation":
        explanation =
            "LineEquation is the formula y = mx + b, combining slope and intercept.";
        break;
      case "Residual":
        explanation =
            "Residual is the error between a predicted value and the actual value.";
        break;
      case "Model":
        explanation =
            "Model is the mathematical representation of the data using a regression line.";
        break;
      case "SlopeError":
        explanation =
            "SlopeError is the uncertainty or variability in the slope estimate.";
        break;
      case "InterceptError":
        explanation =
            "InterceptError is the uncertainty or variability in the intercept estimate.";
        break;
      default:
        explanation =
            "$label is a concept derived from combining terms in linear regression.";
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(explanation),
        duration: const Duration(seconds: 3),
      ),
    );
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
        title: const Text('Linear Regression Teach'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
      ),
      body: Stack(
        children: [
          ...List.generate(_buttonColors.length, (index) {
            return Positioned(
              left: _buttonPositions[index].dx,
              top: _buttonPositions[index].dy,
              child: _buildDraggableButton(index),
            );
          }),
          if (_buttonLabels.isEmpty)
            const Center(child: Text("No buttons available")),
        ],
      ),
    );
  }

  Widget _buildDraggableButton(int index) {
    return GestureDetector(
      onTap: () => _explainButton(index),
      onPanUpdate: (details) {
        _onDragUpdate(index, _buttonPositions[index] + details.delta);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleController,
          _pulseController,
          _glowController,
        ]),
        builder: (context, child) {
          return Transform(
            transform:
                Matrix4.identity()
                  ..scale(_scaleAnimation.value * _pulseAnimation.value)
                  ..rotateZ(_glowAnimation.value * 0.1),
            child: Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 1,
                ),
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
