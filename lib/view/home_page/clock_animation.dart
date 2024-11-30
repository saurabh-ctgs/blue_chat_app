import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/discover_controller.dart';

class RotatingConicalShape extends StatefulWidget  {
  const RotatingConicalShape({super.key});

  @override
  _RotatingConicalShapeState createState() => _RotatingConicalShapeState();
}

class _RotatingConicalShapeState extends State<RotatingConicalShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Offset> _generateRandomPositions(int count, {required double radius}) {
    final random = Random();
    return List.generate(count, (_) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius;
      return Offset(
        distance * cos(angle),
        distance * sin(angle),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Get DiscoverModelView instance
    DiscoverModelView discoverMV = Get.find<DiscoverModelView>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating cone
            CustomPaint(
              size: Size(size.width, size.width),
              painter: ConicalShapePainter(_controller),
            ),
            // Reactive device display
            Obx(() {
              // Generate random positions
              final randomPositions = _generateRandomPositions(
                discoverMV.scannedDevices.length,
                radius: 150,
              );

              // Display devices
              return Stack(
                alignment: Alignment.center,
                children: discoverMV.scannedDevices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final device = entry.value;
                  final position = randomPositions[index];

                  return Positioned(
                    left: (size.width / 2) + position.dx - 20,
                    top: (size.height / 2) + position.dy - 20,
                    child: GestureDetector(
                      onTap: (){
                        discoverMV.handleDeviceTap(device);
                      },
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.devices, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            device.name!=null ? device.name! : "Unknown",
                      
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}





class ConicalShapePainter extends CustomPainter {
  final Animation<double> animation;

  ConicalShapePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final Paint baseCirclePaint = Paint()
      // ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final Paint circleFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint circleBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint conePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.blue, Colors.transparent],
        stops: [0.0, 0.8],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final angle = animation.value * 2 * pi;
    final Path path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      )
      ..lineTo(
        center.dx + radius * cos(angle + pi / 6),
        center.dy + radius * sin(angle + pi / 6),
      )
      ..close();

    canvas.drawCircle(center, radius, baseCirclePaint);
    canvas.drawPath(path, conePaint);
    canvas.drawCircle(center, 8, circleFillPaint);
    canvas.drawCircle(center, 8, circleBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

