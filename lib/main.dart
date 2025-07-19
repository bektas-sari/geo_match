import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const PuzzleGameApp());
}

class PuzzleGameApp extends StatelessWidget {
  const PuzzleGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Puzzle Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Comic Sans MS',
      ),
      home: const PuzzleGameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({Key? key}) : super(key: key);

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin {
  // Game state variables
  List<GameShape> shapes = [];
  bool gameCompleted = false;
  late DateTime gameStartTime;
  Duration gameDuration = Duration.zero;
  Timer? gameTimer;
  Timer? speedIncreaseTimer;
  double currentSpeed = 1.0;

  // Animation controller for floating movement
  late AnimationController _animationController;

  // Screen dimensions
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    gameTimer?.cancel();
    speedIncreaseTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    gameStartTime = DateTime.now();
    gameCompleted = false;
    currentSpeed = 1.0;

    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height - 100; // Account for app bar and padding

    // Create shape pairs
    _createShapes();

    // Start game timer
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gameCompleted) {
        setState(() {
          gameDuration = DateTime.now().difference(gameStartTime);
        });
      }
    });

    // Increase speed every 30 seconds
    speedIncreaseTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!gameCompleted) {
        setState(() {
          currentSpeed += 0.3;
        });
      }
    });
  }

  void _createShapes() {
    shapes.clear();
    final random = Random();
    final shapeTypes = [
      ShapeType.square,
      ShapeType.rectangle,
      ShapeType.circle,
      ShapeType.triangle,
      ShapeType.trapezoid,
      ShapeType.pentagon,
      ShapeType.hexagon,
    ];

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];

    // Create pairs of each shape
    for (int i = 0; i < shapeTypes.length; i++) {
      final shapeType = shapeTypes[i];
      final color = colors[i];

      // Create first shape of the pair
      shapes.add(GameShape(
        id: '${shapeType.name}_1',
        type: shapeType,
        color: color,
        position: Offset(
          random.nextDouble() * (screenWidth - 80),
          random.nextDouble() * (screenHeight - 80),
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 2,
          (random.nextDouble() - 0.5) * 2,
        ),
      ));

      // Create second shape of the pair
      shapes.add(GameShape(
        id: '${shapeType.name}_2',
        type: shapeType,
        color: color,
        position: Offset(
          random.nextDouble() * (screenWidth - 80),
          random.nextDouble() * (screenHeight - 80),
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 2,
          (random.nextDouble() - 0.5) * 2,
        ),
      ));
    }

    setState(() {});
  }

  void _updateShapePositions() {
    for (var shape in shapes) {
      // Update position based on velocity and current speed
      shape.position = Offset(
        shape.position.dx + shape.velocity.dx * currentSpeed,
        shape.position.dy + shape.velocity.dy * currentSpeed,
      );

      // Bounce off walls
      if (shape.position.dx <= 0 || shape.position.dx >= screenWidth - 80) {
        shape.velocity = Offset(-shape.velocity.dx, shape.velocity.dy);
      }
      if (shape.position.dy <= 0 || shape.position.dy >= screenHeight - 80) {
        shape.velocity = Offset(shape.velocity.dx, -shape.velocity.dy);
      }

      // Keep shapes within bounds
      shape.position = Offset(
        shape.position.dx.clamp(0, screenWidth - 80),
        shape.position.dy.clamp(0, screenHeight - 80),
      );
    }
  }

  void _onShapeDragUpdate(GameShape shape, DragUpdateDetails details) {
    setState(() {
      shape.position = Offset(
        (shape.position.dx + details.delta.dx).clamp(0, screenWidth - 80),
        (shape.position.dy + details.delta.dy).clamp(0, screenHeight - 80),
      );
    });

    // Check for collisions with other shapes
    _checkCollisions(shape);
  }

  void _checkCollisions(GameShape draggedShape) {
    for (var otherShape in shapes) {
      if (otherShape.id != draggedShape.id &&
          otherShape.type == draggedShape.type &&
          !otherShape.isMatched &&
          !draggedShape.isMatched) {

        // Calculate distance between shapes
        final distance = (draggedShape.position - otherShape.position).distance;

        // If shapes are close enough (collision detected)
        if (distance < 60) {
          setState(() {
            draggedShape.isMatched = true;
            otherShape.isMatched = true;
          });

          // Remove matched shapes after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              shapes.removeWhere((shape) =>
              shape.id == draggedShape.id || shape.id == otherShape.id);
            });

            // Check if game is completed
            if (shapes.isEmpty) {
              _completeGame();
            }
          });
          break;
        }
      }
    }
  }

  void _completeGame() {
    gameCompleted = true;
    gameTimer?.cancel();
    speedIncreaseTimer?.cancel();
    gameDuration = DateTime.now().difference(gameStartTime);

    // Show completion dialog
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '🎉 Congratulations! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You completed the puzzle!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                'Time: ${_formatDuration(gameDuration)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // In a real app, you might navigate back or close the app
                    // For now, we'll just restart the game
                    _restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    gameTimer?.cancel();
    speedIncreaseTimer?.cancel();
    _initializeGame();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Kids Puzzle Game',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                _formatDuration(gameDuration),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          if (!gameCompleted) {
            _updateShapePositions();
          }

          return Stack(
            children: shapes.map((shape) {
              return Positioned(
                left: shape.position.dx,
                top: shape.position.dy,
                child: GestureDetector(
                  onPanUpdate: (details) => _onShapeDragUpdate(shape, details),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: shape.isMatched ? 300 : 0),
                    transform: Matrix4.identity()
                      ..scale(shape.isMatched ? 0.0 : 1.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: ShapePainter(
                          shapeType: shape.type,
                          color: shape.color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// Enum for different shape types
enum ShapeType {
  square,
  rectangle,
  circle,
  triangle,
  trapezoid,
  pentagon,
  hexagon,
}

// Game shape class to hold shape data
class GameShape {
  final String id;
  final ShapeType type;
  final Color color;
  Offset position;
  Offset velocity;
  bool isMatched;

  GameShape({
    required this.id,
    required this.type,
    required this.color,
    required this.position,
    required this.velocity,
    this.isMatched = false,
  });
}

// Custom painter to draw different geometric shapes
class ShapePainter extends CustomPainter {
  final ShapeType shapeType;
  final Color color;

  ShapePainter({
    required this.shapeType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 5;

    switch (shapeType) {
      case ShapeType.square:
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.4,
          height: radius * 1.4,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case ShapeType.rectangle:
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.8,
          height: radius * 1.2,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case ShapeType.circle:
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, strokePaint);
        break;

      case ShapeType.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - radius);
        path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
        path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.trapezoid:
        final path = Path();
        path.moveTo(center.dx - radius * 0.5, center.dy - radius);
        path.lineTo(center.dx + radius * 0.5, center.dy - radius);
        path.lineTo(center.dx + radius, center.dy + radius);
        path.lineTo(center.dx - radius, center.dy + radius);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.pentagon:
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * pi / 5) - pi / 2;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * pi / 3;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}