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
  String? _username;
  final GeminiService _geminiService = GeminiService();
  List<Color> _buttonColors = [];
  List<Offset> _buttonPositions = [];
  List<String> _buttonLabels = [];
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final TextEditingController _newElementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      _showLoginRequired();
      return;
    }
    _loadUserDetails();
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

  void _showLoginRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Authentication Required"),
        content: Text("Please log in to use the teach screen."),
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
            (index) => Offset((index % 3) * 70 + 20, (index ~/ 3) * 40 + 20),
      );
      _buttonLabels = List.from(initialLabels);
    });
  }

  void _onDragUpdate(int index, Offset newPosition) {
    setState(() {
      double newDx = newPosition.dx.clamp(
        0,
        MediaQuery.of(context).size.width - 60, // Match card width
      );
      double newDy = newPosition.dy.clamp(
        0,
        MediaQuery.of(context).size.height - 30, // Match card height
      );
      _buttonPositions[index] = Offset(newDx, newDy);
      _checkForCombination(index);
    });
  }

  void _checkForCombination(int index) {
    Offset currentPosition = _buttonPositions[index];
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
        currentLabel,
      );
    }
  }

  Future<void> _triggerMergeAnimation(
      int index1,
      int index2,
      String currentLabel,
      ) async {
    _scaleController.forward().then((_) => _scaleController.reverse());
    _pulseController.reset();
    _pulseController.forward();
    _glowController.reset();
    _glowController.forward();

    String otherLabel = _buttonLabels[index2];
    String newLabel = await _generateMeaningfulMerge(currentLabel, otherLabel);

    Color currentColor = _buttonColors[index1];
    Color otherColor = _buttonColors[index2];

    double newX = (_buttonPositions[index1].dx + _buttonPositions[index2].dx) / 2;
    double newY = (_buttonPositions[index1].dy + _buttonPositions[index2].dy) / 2;
    Offset newPosition = Offset(
      newX.clamp(0, MediaQuery.of(context).size.width - 60),
      newY.clamp(0, MediaQuery.of(context).size.height - 30),
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
        }

        _buttonColors.add(newColor);
        _buttonPositions.add(newPosition);
        _buttonLabels.add(newLabel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Merged into: $newLabel")),
        );
      });
    }
  }

  Future<String> _generateMeaningfulMerge(String label1, String label2) async {
    try {
      final prompt = "Combine '$label1' and '$label2' to create a new, meaningful element or concept in the domain of linear regression (e.g., machine learning, statistics). The result must be a single word or a concise two-word term (e.g., 'Feature Vector', 'Residual') that is a valid concept in linear regression. Do not concatenate the input labels or produce invalid terms. Respond with just the name of the new element or concept, no extra text. Examples: 'Data + Feature = Feature Vector', 'Model + Error = Residual', 'Feature + Model = Coefficient', 'Slope + Intercept = Line Equation'.";
      debugPrint("Sending prompt to Gemini: $prompt");
      String response = await _geminiService.getGeminiResponse(prompt);
      String newElementName = response.trim();

      // Validate the response: should be 1-2 words, no spaces beyond two words, and not a concatenation
      if (newElementName.isEmpty || newElementName.contains("Error") || newElementName.split(' ').length > 2 || newElementName == "$label1$label2") {
        return _generateFallbackMerge(label1, label2); // Handle invalid responses
      }
      return newElementName;
    } catch (e) {
      debugPrint("Error generating merge: $e");
      return _generateFallbackMerge(label1, label2); // Fallback to predefined merge
    }
  }

  String _generateFallbackMerge(String label1, String label2) {
    // Fallback combinations for meaningful linear regression concepts (single or double-word terms)
    if ((label1 == "Slope" && label2 == "Intercept") ||
        (label1 == "Intercept" && label2 == "Slope")) {
      return "Line Equation";
    } else if ((label1 == "Error" && label2 == "Prediction") ||
        (label1 == "Prediction" && label2 == "Error")) {
      return "Residual";
    } else if ((label1 == "Data" && label2 == "Fit") ||
        (label1 == "Fit" && label2 == "Data")) {
      return "Model";
    } else if ((label1 == "Slope" && label2 == "Error") ||
        (label1 == "Error" && label2 == "Slope")) {
      return "Slope Error";
    } else if ((label1 == "Intercept" && label2 == "Error") ||
        (label1 == "Error" && label2 == "Intercept")) {
      return "Intercept Error";
    } else if ((label1 == "Data" && label2 == "Feature") ||
        (label1 == "Feature" && label2 == "Data")) {
      return "Feature Vector";
    } else if ((label1 == "Model" && label2 == "Fit") ||
        (label1 == "Fit" && label2 == "Model")) {
      return "Goodness Fit";
    } else if ((label1 == "Prediction" && label2 == "Fit") ||
        (label1 == "Fit" && label2 == "Prediction")) {
      return "Accuracy";
    } else if ((label1 == "Data" && label2 == "Error") ||
        (label1 == "Error" && label2 == "Data")) {
      return "Noise";
    } else if ((label1 == "Slope" && label2 == "Prediction") ||
        (label1 == "Prediction" && label2 == "Slope")) {
      return "Trend";
    } else if ((label1 == "Intercept" && label2 == "Prediction") ||
        (label1 == "Prediction" && label2 == "Intercept")) {
      return "Baseline";
    } else {
      return "Regression Term"; // Generic fallback
    }
  }

  Future<void> _explainButton(int index) async {
    String label = _buttonLabels[index];
    try {
      final prompt = "Explain '$label' briefly as an element or concept in the context of linear regression. Provide a concise, meaningful explanation (1-2 sentences) that is accurate and relevant to linear regression.";
      debugPrint("Sending explanation prompt to Gemini: $prompt");
      String explanation = await _geminiService.getGeminiResponse(prompt);
      if (explanation.isEmpty || explanation.contains("Error")) {
        explanation = _generateFallbackExplanation(label); // Handle Gemini errors
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(explanation),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("Error explaining button: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error explaining '$label': $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _generateFallbackExplanation(String label) {
    // Fallback explanations for meaningful linear regression concepts
    switch (label) {
      case "Slope":
        return "Slope represents the rate of change in the dependent variable for each unit change in the independent variable in linear regression.";
      case "Intercept":
        return "Intercept is the value of the dependent variable when the independent variable is zero, defining the starting point of the regression line.";
      case "Error":
        return "Error measures the difference between the actual and predicted values in linear regression, indicating prediction inaccuracies.";
      case "Prediction":
        return "Prediction is the value estimated by the linear regression model for a given set of inputs.";
      case "Data":
        return "Data refers to the set of observations used to train and evaluate a linear regression model.";
      case "Fit":
        return "Fit indicates how well the regression line approximates the actual data points.";
      case "Line Equation":
        return "Line Equation (y = mx + b) defines the linear relationship between variables using slope and intercept.";
      case "Residual":
        return "Residual is the difference between the observed value and the value predicted by the regression model.";
      case "Model":
        return "Model is the mathematical representation of the relationship between variables in linear regression.";
      case "Slope Error":
        return "Slope Error quantifies the uncertainty or variability in the estimated slope of the regression line.";
      case "Intercept Error":
        return "Intercept Error quantifies the uncertainty or variability in the estimated intercept of the regression line.";
      case "Feature Vector":
        return "Feature Vector is a set of features extracted from the data, used as input for the linear regression model.";
      case "Goodness Fit":
        return "Goodness Fit measures how well the regression model explains the variability of the data, often using metrics like R-squared.";
      case "Accuracy":
        return "Accuracy in linear regression refers to how closely the predicted values match the actual values.";
      case "Noise":
        return "Noise represents random variations or errors in the data that cannot be explained by the regression model.";
      case "Trend":
        return "Trend describes the general direction of the relationship between variables, influenced by the slope in linear regression.";
      case "Baseline":
        return "Baseline is the predicted value when the independent variable is zero, determined by the intercept.";
      case "Regression Term":
        return "Regression Term is a general concept derived from combining elements in linear regression.";
      default:
        return "$label is a concept derived from combining terms in linear regression.";
    }
  }

  bool _isOverlapping(Offset pos1, Offset pos2) {
    const double buttonSize = 60; // Match card width
    const double overlapThreshold = 15;
    return (pos1.dx - pos2.dx).abs() < buttonSize - overlapThreshold &&
        (pos1.dy - pos2.dy).abs() < buttonSize - overlapThreshold;
  }

  void _addElement(String label) {
    setState(() {
      _buttonColors.add(Colors.primaries[_buttonColors.length % Colors.primaries.length][200]!);
      _buttonPositions.add(Offset(20, 20)); // Start at top-left, draggable
      _buttonLabels.add(label);
    });
  }

  Future<void> _addNewElement() async {
    try {
      final prompt = "Suggest a new, meaningful element or concept in the domain of linear regression (e.g., machine learning, statistics). The element must be a single word or a concise two-word term (e.g., 'Gradient', 'R-Squared') that is a valid concept in linear regression. Respond with just the name of the new element or concept, no extra text. Examples: 'Gradient', 'R-Squared', 'Outlier', 'Variance', 'Bias'.";
      debugPrint("Sending prompt to Gemini for new element: $prompt");
      String response = await _geminiService.getGeminiResponse(prompt);
      String newElementName = response.trim();
      if (newElementName.isEmpty || newElementName.contains("Error") || newElementName.split(' ').length > 2) {
        newElementName = _generateFallbackNewElement(); // Handle Gemini errors
      }
      _addElement(newElementName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added new element: $newElementName")),
      );
    } catch (e) {
      debugPrint("Error adding new element: $e");
      String newElementName = _generateFallbackNewElement();
      _addElement(newElementName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added fallback element: $newElementName")),
      );
    }
  }

  String _generateFallbackNewElement() {
    // Fallback new elements for linear regression
    List<String> fallbackElements = [
      "Gradient",
      "R-Squared",
      "Outlier",
      "Variance",
      "Bias",
      "P-Value",
      "T-Statistic",
      "F-Statistic",
      "Overfitting",
      "Underfitting",
    ];
    return fallbackElements[Random().nextInt(fallbackElements.length)];
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _newElementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linear Regression Teach'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.blue[900]),
            onPressed: () {
              if (_user != null) {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 20, color: Colors.blue[900]),
            onPressed: _addNewElement,
            tooltip: 'Add New Element',
          ),
        ],
      ),
      drawer: _user != null
          ? Drawer(
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
                    'Linear Regression Elements',
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
                'Add Slope',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Slope");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Add Intercept',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Intercept");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Add Error',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Error");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Add Prediction',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Prediction");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Add Data',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Data");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Add Fit',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () {
                _addElement("Fit");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Clear All Elements',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.red[900]),
              ),
              onTap: () {
                setState(() {
                  _buttonColors.clear();
                  _buttonPositions.clear();
                  _buttonLabels.clear();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      )
          : null,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Infinite scrolling background with constraints to prevent overflow
            SizedBox.expand(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 5000), // Slow scroll effect
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[100]!,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Draggable buttons with overflow prevention and grid-like layout
            ...List.generate(_buttonColors.length, (index) {
              if (index >= _buttonPositions.length || index >= _buttonLabels.length) {
                debugPrint("Index out of bounds in List.generate: $index");
                return SizedBox.shrink(); // Prevent crashes due to mismatched lengths
              }
              return Positioned(
                left: _buttonPositions[index].dx,
                top: _buttonPositions[index].dy,
                child: _buildDraggableButton(index),
              );
            }),
            if (_buttonLabels.isEmpty)
              const Center(child: Text("No elements available")),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableButton(int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Ensure the entire area is interactive
      onTap: () => _explainButton(index),
      onPanUpdate: (details) {
        Offset newPosition = _buttonPositions[index] + details.delta;
        _onDragUpdate(index, newPosition);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleController,
          _pulseController,
          _glowController,
        ]),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..scale(_scaleAnimation.value * _pulseAnimation.value)
              ..rotateZ(_glowAnimation.value * 0.1),
            child: Container(
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _buttonLabels[index],
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}