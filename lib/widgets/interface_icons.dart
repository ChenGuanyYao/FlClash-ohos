import 'package:fl_clash/common/common.dart';
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
  const InterfaceOverviewGlyph({super.key, this.size = 22});
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
              colors: dark
                  ? const [Color(0xFFBBD1FF), Color(0xFF7CA4F3)]
                  : const [Color(0xFF719AF1), Color(0xFF3265CD)],
            ),
            shape: AppShape.all(3).copyWith(
              side: BorderSide(
                color: dark ? const Color(0xFFA6C3F8) : const Color(0xFF5782DB),
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
