import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:material_ui/material_ui.dart';

class InterfaceGlobe extends StatelessWidget {
  const InterfaceGlobe({super.key, this.size = 29});
  final double size;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.brightnessOf(context) == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF6CA5E3), Color(0xFF2E5189)]
                : const [Color(0xFF88D6F6), Color(0xFF2B6FC7)],
          ),
          shape: AppShape.full.copyWith(
            side: BorderSide(
              color: dark ? const Color(0xFF597DAE) : const Color(0xFF87C3EF),
              width: 0.6,
            ),
          ),
        ),
        child: const CustomPaint(painter: _GlobeLines()),
      ),
    );
  }
}

class _GlobeLines extends CustomPainter {
  const _GlobeLines();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6F5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.08,
        size.width * 0.36,
        size.height * 0.84,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.5),
      Offset(size.width * 0.88, size.height * 0.5),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.29,
        size.width * 0.76,
        size.height * 0.41,
      ),
      paint..color = const Color(0xFFADD6F3),
    );
  }

  @override
  bool shouldRepaint(_GlobeLines oldDelegate) => false;
}

class InterfaceOverviewGlyph extends StatelessWidget {
  const InterfaceOverviewGlyph({
    super.key,
    this.size = 22,
    this.selected = true,
  });
  final bool selected;
  final double size;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.brightnessOf(context) == Brightness.dark;
    Widget tile() => Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: !selected
                  ? [
                      context.colorScheme.onSurfaceVariant,
                      context.colorScheme.onSurfaceVariant,
                    ]
                  : dark
                  ? const [Color(0xFFBBD1FF), Color(0xFF7CA4F3)]
                  : const [Color(0xFF719AF1), Color(0xFF3265CD)],
            ),
            shape: AppShape.all(3).copyWith(
              side: BorderSide(
                color: !selected
                    ? context.colorScheme.onSurfaceVariant
                    : dark
                    ? const Color(0xFFA6C3F8)
                    : const Color(0xFF5782DB),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Column(
        children: [
          Row(children: [tile(), const SizedBox(width: 3), tile()]),
          const SizedBox(height: 3),
          Row(children: [tile(), const SizedBox(width: 3), tile()]),
        ],
      ),
    );
  }
}

class InterfaceBrandGlyph extends StatelessWidget {
  const InterfaceBrandGlyph({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 28,
    height: 31,
    child: CustomPaint(painter: _BrandPainter()),
  );
}

class _BrandPainter extends CustomPainter {
  const _BrandPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 27 * 0.24
      ..strokeCap = StrokeCap.round;
    Offset at(double x, double y) => Offset(1 + x * 27, y * 27);
    canvas.drawLine(
      at(0.13, 0.42),
      at(0.82, 0.04),
      paint..color = const Color(0xFF6964F3),
    );
    canvas.drawLine(
      at(0.28, 0.7),
      at(0.64, 0.5),
      paint..color = const Color(0xFF376EBB),
    );
    canvas.drawCircle(
      at(0.43, 0.94),
      27 * 0.12,
      paint..color = const Color(0xFF62A7DE),
    );
  }

  @override
  bool shouldRepaint(_BrandPainter oldDelegate) => false;
}

abstract final class InterfaceGlyphs {
  static const profiles = Glyph([
    GlyphBox(5, 2, 19, 22, 3),
    GlyphPolyline([
      GlyphVertex(8, 8),
      GlyphVertex(16, 8),
    ], role: GlyphRole.detail),
    GlyphPolyline([
      GlyphVertex(8, 12),
      GlyphVertex(16, 12),
    ], role: GlyphRole.detail),
    GlyphPolyline([
      GlyphVertex(8, 16),
      GlyphVertex(16, 16),
    ], role: GlyphRole.detail),
  ]);
  static const settings = Glyph([
    GlyphCircle(12, 12, 6.3, role: GlyphRole.line),
    GlyphCircle(12, 12, 2.9, role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(12, 0.6),
      GlyphVertex(12, 4),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(12, 20),
      GlyphVertex(12, 23.4),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(0.6, 12),
      GlyphVertex(4, 12),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(20, 12),
      GlyphVertex(23.4, 12),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(3.9, 3.9),
      GlyphVertex(6.3, 6.3),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(17.7, 17.7),
      GlyphVertex(20.1, 20.1),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(3.9, 20.1),
      GlyphVertex(6.3, 17.7),
    ], role: GlyphRole.line),
    GlyphPolyline([
      GlyphVertex(17.7, 6.3),
      GlyphVertex(20.1, 3.9),
    ], role: GlyphRole.line),
  ]);
}
