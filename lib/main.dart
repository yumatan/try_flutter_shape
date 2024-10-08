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
// You can add polygon vertices to add Offset to the points.
// 表示テスト用のポリゴン
// オフセットを追加することで、多角形の変更が可能
// ARVI Lamp で実装する場合は、この値を provider に保持させ、
// 編集モード時に利用する
List<Offset> points = _normalizePoints([
  const Offset(100, 100),
  const Offset(200, 100),
  const Offset(250, 200),
  const Offset(150, 300),
  const Offset(50, 200),
]);

// 選択中のPointsの番号（デフォルトは始点）
// タップすることで番号を変更する。（＋、－ボタンを推すことで、頂点の増減を行う）
// ARVI Lamp で実装する場合は、この値を provider に保持させる
int selectedPoint = 0;

// Offset of canvas on screen to write polygon.
// 画面上のキャンバス(ポリゴン描画用の)のオフセット
// サンプルは初期値を(100,100)に設定しているが、
// ARVI Lamp の場合、編集地点の中心座標を設定すると良いと思われる
Offset canvasOffset = const Offset(100, 100);

// Normalize the points to make sure the topmost and leftmost points are at (0, 0)
// ノーマライズ処理。多角形の左端を(0,y)に、上端を(x,0)に移動する
List<Offset> _normalizePoints(List<Offset> points) {
  final double minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
  final double minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);

  // Update additionalOffset based on the most negative values
  // ノーマライズに伴うオフセットの更新（最小値が負の場合）
  canvasOffset -= Offset(minX < 0 ? -minX : 0, minY < 0 ? -minY : 0);
  // Update additionalOffset based on the smallest positive values
  // ノーマライズに伴うオフセットの更新（最小値が正の場合）
  canvasOffset += Offset(minX > 0 ? minX : 0, minY > 0 ? minY : 0);

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
    // Normalize the points to make sure the topmost and leftmost points are at (0, 0)
    // pointsの初期値がノーマライズされていない場合の対処
    points = _normalizePoints(points);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          canvasOffset += details.delta;
        });
      },
      child: Stack(
        children: [
          Positioned(
            left: canvasOffset.dx,
            top: canvasOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  canvasOffset += details.delta;
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
                  size: _calculateCanvasSize(points),
                  painter: PolygonPainter(points, borderWidth),
                ),
              ),
            ),
          ),
          ...points.asMap().entries.map((entry) {
            final int idx = entry.key;
            final bool selected = idx == selectedPoint;
            final Offset point = canvasOffset + points[idx];
            return Positioned(
              left: point.dx - 10,
              top: point.dy - 10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    points[idx] = Offset(
                      points[idx].dx + details.delta.dx / scaleX,
                      points[idx].dy + details.delta.dy / scaleY,
                    );
                    points = _normalizePoints(points);
                  });
                },
                onTap: () {
                  setState(() {
                    selectedPoint = idx;
                  });
                },
                child: _buildVertexWidget(selected: selected),
              ),
            );
          }),
          // Scale handles
          buildScaleHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, -90.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();

                scaleY += details.delta.dy * -0.01;
                if (scaleY < 0.5) scaleY = 0.5;
                points = points
                    .map(
                      (p) => Offset(p.dx, p.dy * scaleY),
                    )
                    .toList();
                // get New Center
                final newCenter = getCenter();
                points = points
                    .map(
                      (p) => Offset(p.dx, p.dy - (newCenter.dy - oldCenter.dy)),
                    )
                    .toList();
                scaleY = 1.0;
                points = _normalizePoints(points);
              });
            },
            child: _buildScaleHandleWidget(Icons.swap_vert),
          ),
          buildScaleHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, -60.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();

                scaleX += details.delta.dx * 0.01;
                if (scaleX < 0.5) scaleX = 0.5;
                points =
                    points.map((p) => Offset(p.dx * scaleX, p.dy)).toList();
                // get New Center
                final newCenter = getCenter();
                points = points
                    .map(
                      (p) => Offset(p.dx - (newCenter.dx - oldCenter.dx), p.dy),
                    )
                    .toList();
                scaleX = 1.0;
                points = _normalizePoints(points);
              });
            },
            child: _buildScaleHandleWidget(Icons.swap_horiz),
          ),
          buildScaleHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, -30.0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();
                final double delta = details.delta.dy * -0.01;
                scaleX += delta;
                scaleY += delta;
                if (scaleX < 0.5) scaleX = 0.5;
                if (scaleY < 0.5) scaleY = 0.5;
                points = points
                    .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
                    .toList();
                // get New Center
                final newCenter = getCenter();
                points = points
                    .map(
                      (p) => Offset(
                        p.dx - (newCenter.dx - oldCenter.dx),
                        p.dy - (newCenter.dy - oldCenter.dy),
                      ),
                    )
                    .toList();
                scaleX = 1.0;
                scaleY = 1.0;
                points = _normalizePoints(points);
              });
            },
            child: _buildScaleHandleWidget(Icons.aspect_ratio),
          ),
          buildScaleHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, 0),
            onPanUpdate: (details) {
              setState(() {
                // get old center
                final oldCenter = getCenter();
                scaleX += details.delta.dx * 0.01;
                scaleY += details.delta.dy * -0.01;
                if (scaleX < 0.5) scaleX = 0.5;
                if (scaleY < 0.5) scaleY = 0.5;
                points = points
                    .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
                    .toList();
                // get New Center
                final newCenter = getCenter();
                points = points
                    .map(
                      (p) => Offset(
                        p.dx - (newCenter.dx - oldCenter.dx),
                        p.dy - (newCenter.dy - oldCenter.dy),
                      ),
                    )
                    .toList();
                scaleX = 1.0;
                scaleY = 1.0;
                points = _normalizePoints(points);
              });
            },
            child: _buildScaleHandleWidget(Icons.zoom_out_map),
          ),
          // Rotation handle
          // 回転ハンドル
          buildScaleHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, 50.0),
            onPanUpdate: (details) {
              setState(() {
                final double rotationDelta = details.delta.dx * 0.01;
                final double cosTheta = cos(rotationDelta);
                final double sinTheta = sin(rotationDelta);
                final Offset center = getCenter();

                final List<Offset> rotatePoints = points.map((p) {
                  final double dx = p.dx - center.dx;
                  final double dy = p.dy - center.dy;
                  final double newX = dx * cosTheta - dy * sinTheta + center.dx;
                  final double newY = dx * sinTheta + dy * cosTheta + center.dy;
                  return Offset(newX, newY);
                }).toList();

                points = _normalizePoints(rotatePoints);
              });
            },
            child: _buildScaleHandleWidget(Icons.rotate_right),
          ),
          // Polygon vertex addition button (reusing ScaleHandler)
          // 多角形の頂点追加ボタン（ScaleHandlerの再利用）
          buildTapHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, 100.0),
            onTap: () {
              setState(() {
                // Add a new point after the selected point
                // 選択中の頂点の次に新しい頂点を追加する
                points.insert(
                  selectedPoint + 1,
                  points[selectedPoint] + const Offset(10, 10),
                );
              });
            },
            child: _buildScaleHandleWidget(Icons.add_circle),
          ),
          // Polygon vertex addition button (reusing ScaleHandler)
          // 多角形の頂点追加ボタン（ScaleHandlerの再利用）
          buildTapHandle(
            position: canvasOffset + getCenter() + const Offset(150.0, 130.0),
            onTap: () {
              setState(() {
                if (points.length > 3) {
                  // Remove the selected point
                  // 選択中の頂点を削除する
                  points.removeAt(selectedPoint);
                }
              });
            },
            child: _buildScaleHandleWidget(Icons.do_not_disturb_on),
          ),
        ],
      ),
    );
  }

  // Calculate the size of the canvas based on the points
  // ポリゴンの頂点からキャンバスのサイズを計算する
  Size _calculateCanvasSize(List<Offset> points) {
    final double maxX = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double maxY = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
    return Size(maxX, maxY);
  }

  // Get the center of the polygon
  // 多角形の中心座標を取得する
  Offset getCenter() {
    double dx = 0;
    double dy = 0;
    for (final Offset point in points) {
      dx += point.dx;
      dy += point.dy;
    }
    return Offset(dx / points.length, dy / points.length);
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
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    // clipperが変わらない場合はfalse、変わる場合はtrue
    return true;
  }
}
