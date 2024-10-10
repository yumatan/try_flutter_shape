import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polygon Widget Example'),
        ),
        body: const PolygonWidgetDemo(),
      ),
    );
  }
}

// Polygon data for testing.
// You can add polygon vertices.
List<Offset> vertices = _normalizePoints([
  const Offset(100, 100),
  const Offset(200, 100),
  const Offset(250, 200),
  const Offset(150, 300),
  const Offset(50, 200),
]);

int selectedVertex = 0;

Offset canvasCenterOffset = const Offset(100, 100);

// Normalize the points to make sure the topmost and leftmost points are at (0, 0)
List<Offset> _normalizePoints(List<Offset> points) {
  final double minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
  final double minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);

  // Update additionalOffset based on the most negative values
  canvasCenterOffset -= Offset(minX < 0 ? -minX : 0, minY < 0 ? -minY : 0);
  // Update additionalOffset based on the smallest positive values
  canvasCenterOffset += Offset(minX > 0 ? minX : 0, minY > 0 ? minY : 0);

  // Return the normalized points without any negative values
  return points.map((p) => Offset(p.dx - minX, p.dy - minY)).toList();
}

class PolygonWidgetDemo extends StatefulWidget {
  const PolygonWidgetDemo({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PolygonWidgetDemoState createState() => _PolygonWidgetDemoState();
}

class _PolygonWidgetDemoState extends State<PolygonWidgetDemo> {
  double borderWidth = 5.0;
  double scaleX = 1.0;
  double scaleY = 1.0;

  @override
  Widget build(BuildContext context) {
    // Normalize the vertices to make sure the most top and left vertices are at (0, 0)
    vertices = _normalizePoints(vertices);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          canvasCenterOffset += details.delta;
        });
      },
      child: Stack(
        children: [
          Positioned(
            left: canvasCenterOffset.dx,
            top: canvasCenterOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  canvasCenterOffset += details.delta;
                });
              },
              // Default Canvas is a rectangle (Size).
              // By using ClipPath, we can make the displayed canvas widget size with same size of polygon.
              // This will make sure that GestureDetector will not work outside the polygon.
              // Also, to make sure that ClipPath is done properly, we are calculating the Canvas size dynamically.
              // 通常の Canvas は四角形(Size)だが、ClipPath を利用することで、
              // 表示している多角形(Polygon)を同じ大きさにすることができる
              // これにより、多角形の外側ではGestureDetectorが反応しないようになる
              // また、ClipPath を確実に行うため、Canvas サイズは動的計算をしている
              child: ClipPath(
                clipper: PolygonClipper(),
                child: CustomPaint(
                  size: _calculateCanvasSize(vertices),
                  painter: PolygonPainter(vertices, borderWidth),
                ),
              ),
            ),
          ),
          ...vertices.asMap().entries.map((entry) {
            final int idx = entry.key;
            final bool selected = idx == selectedVertex;
            final Offset point = canvasCenterOffset + vertices[idx];
            return Positioned(
              left: point.dx - 10,
              top: point.dy - 10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    vertices[idx] = Offset(
                      vertices[idx].dx + details.delta.dx / scaleX,
                      vertices[idx].dy + details.delta.dy / scaleY,
                    );
                    vertices = _normalizePoints(vertices);
                  });
                },
                onTap: () {
                  setState(() {
                    selectedVertex = idx;
                  });
                },
                child: _buildVertexWidget(selected: selected),
              ),
            );
          }),
          // Scale handles
          buildScaleHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, -90.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();

                scaleY += details.delta.dy * -0.01;
                if (scaleY < 0.5) scaleY = 0.5;
                vertices = vertices
                    .map(
                      (p) => Offset(p.dx, p.dy * scaleY),
                    )
                    .toList();
                // get New Center
                final newCenter = getCenter();
                vertices = vertices
                    .map(
                      (p) => Offset(p.dx, p.dy - (newCenter.dy - oldCenter.dy)),
                    )
                    .toList();
                scaleY = 1.0;
                vertices = _normalizePoints(vertices);
              });
            },
            child: _buildScaleHandleWidget(Icons.swap_vert),
          ),
          buildScaleHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, -60.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();

                scaleX += details.delta.dx * 0.01;
                if (scaleX < 0.5) scaleX = 0.5;
                vertices =
                    vertices.map((p) => Offset(p.dx * scaleX, p.dy)).toList();
                // get New Center
                final newCenter = getCenter();
                vertices = vertices
                    .map(
                      (p) => Offset(p.dx - (newCenter.dx - oldCenter.dx), p.dy),
                    )
                    .toList();
                scaleX = 1.0;
                vertices = _normalizePoints(vertices);
              });
            },
            child: _buildScaleHandleWidget(Icons.swap_horiz),
          ),
          buildScaleHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, -30.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();
                final double delta = details.delta.dy * -0.01;
                scaleX += delta;
                scaleY += delta;
                if (scaleX < 0.5) scaleX = 0.5;
                if (scaleY < 0.5) scaleY = 0.5;
                vertices = vertices
                    .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
                    .toList();
                // get New Center
                final newCenter = getCenter();
                vertices = vertices
                    .map(
                      (p) => Offset(
                        p.dx - (newCenter.dx - oldCenter.dx),
                        p.dy - (newCenter.dy - oldCenter.dy),
                      ),
                    )
                    .toList();
                scaleX = 1.0;
                scaleY = 1.0;
                vertices = _normalizePoints(vertices);
              });
            },
            child: _buildScaleHandleWidget(Icons.aspect_ratio),
          ),
          buildScaleHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, 0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();
                scaleX += details.delta.dx * 0.01;
                scaleY += details.delta.dy * -0.01;
                if (scaleX < 0.5) scaleX = 0.5;
                if (scaleY < 0.5) scaleY = 0.5;
                vertices = vertices
                    .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
                    .toList();
                // get New Center
                final newCenter = getCenter();
                vertices = vertices
                    .map(
                      (p) => Offset(
                        p.dx - (newCenter.dx - oldCenter.dx),
                        p.dy - (newCenter.dy - oldCenter.dy),
                      ),
                    )
                    .toList();
                scaleX = 1.0;
                scaleY = 1.0;
                vertices = _normalizePoints(vertices);
              });
            },
            child: _buildScaleHandleWidget(Icons.zoom_out_map),
          ),
          // Rotation handle
          // 回転ハンドル
          buildScaleHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, 50.0),
            onPanUpdate: (details) {
              setState(() {
                final double rotationDelta = details.delta.dx * 0.01;
                final double cosTheta = cos(rotationDelta);
                final double sinTheta = sin(rotationDelta);
                final Offset center = getCenter();

                final List<Offset> rotatePoints = vertices.map((p) {
                  final double dx = p.dx - center.dx;
                  final double dy = p.dy - center.dy;
                  final double newX = dx * cosTheta - dy * sinTheta + center.dx;
                  final double newY = dx * sinTheta + dy * cosTheta + center.dy;
                  return Offset(newX, newY);
                }).toList();

                vertices = _normalizePoints(rotatePoints);
              });
            },
            child: _buildScaleHandleWidget(Icons.rotate_right),
          ),
          // Polygon vertex addition button (reusing ScaleHandler)
          // 多角形の頂点追加ボタン（ScaleHandlerの再利用）
          buildTapHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, 100.0),
            onTap: () {
              setState(() {
                // Add a new point after the selected point
                // 選択中の頂点の次に新しい頂点を追加する
                vertices.insert(
                  selectedVertex + 1,
                  vertices[selectedVertex] + const Offset(10, 10),
                );
              });
            },
            child: _buildScaleHandleWidget(Icons.add_circle),
          ),
          // Polygon vertex addition button (reusing ScaleHandler)
          // 多角形の頂点追加ボタン（ScaleHandlerの再利用）
          buildTapHandle(
            position: canvasCenterOffset + getCenter() + const Offset(150.0, 130.0),
            onTap: () {
              setState(() {
                if (vertices.length > 3) {
                  // Remove the selected point
                  // 選択中の頂点を削除する
                  vertices.removeAt(selectedVertex);
                }
              });
            },
            child: _buildScaleHandleWidget(Icons.do_not_disturb_on),
          ),
        ],
      ),
    );
  }

  // Calculate the size of the canvas based on the vertices
  Size _calculateCanvasSize(List<Offset> vertices) {
    final double maxX = vertices.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double maxY = vertices.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
    return Size(maxX, maxY);
  }

  // Get the center of the polygon
  // 多角形の中心座標を取得する
  Offset getCenter() {
    double dx = 0;
    double dy = 0;
    for (final Offset point in vertices) {
      dx += point.dx;
      dy += point.dy;
    }
    return Offset(dx / vertices.length, dy / vertices.length);
  }

  // Widget builders for the polygon vertices and position handles
  // 多角形の頂点に配置する、多角形操作用のWidgetビルダー
  Widget _buildVertexWidget({bool selected = false}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected
            ? Colors.purpleAccent.withOpacity(0.5)
            : Colors.red.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  // Widget builders for the polygon scale handles
  // 多角形の拡大縮小操作用のWidgetビルダー
  Widget _buildScaleHandleWidget(IconData iconData) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(iconData, color: Colors.white, size: 16),
      ),
    );
  }

  Widget buildScaleHandle({
    required Offset position,
    required void Function(DragUpdateDetails) onPanUpdate,
    required Widget child,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: child,
      ),
    );
  }

  Widget buildTapHandle({
    required Offset position,
    required void Function() onTap,
    required Widget child,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final double borderWidth;

  PolygonPainter(this.points, this.borderWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()..addPolygon(points, true);
    final Paint paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    paint
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// CustomClipper to clip the Canvas to the polygon
// Canvas を多角形に切り取るためのCustomClipper
class PolygonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // 形状を指定するpathを返す
    final path = Path();
    path.addPolygon(vertices, true);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    // clipperが変わらない場合はfalse、変わる場合はtrue
    return true;
  }
}
