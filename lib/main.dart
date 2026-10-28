import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/liquid_glass/liquid_glass_backdrop.dart';
import 'reference_compare.dart';

void main() => runApp(
  const bool.fromEnvironment('GLASS_COMPARE')
      ? const GlassComparisonDemo()
      : const NavigationDemo(),
);

class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});
  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  int index = 0;
  BottomNavStyle style = BottomNavStyle.liquidGlass;
  bool dark = false;
  bool grid = false;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '液态玻璃 · 光学实验室',
      theme: ThemeData(
        fontFamily: 'NotoSansCJKsc',
        colorScheme: scheme,
        useMaterial3: true,
      ),
      home: LiquidGlassBackdropScope(
        child: Scaffold(
          extendBody: true,
          body: LiquidGlassBackdrop(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _GlassBackdropPainter(dark: dark, grid: grid),
                ),
                SafeArea(
                  bottom: false,
                  child: ListView(
                    key: const ValueKey('glass-demo-scroll'),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '材质实验室 / 01',
                              style: TextStyle(fontSize: 13, letterSpacing: 2),
                            ),
                          ),
                          IconButton(
                            tooltip: grid ? '切换彩色背景' : '切换网格背景',
                            onPressed: () => setState(() => grid = !grid),
                            icon: Icon(
                              grid ? Icons.palette_outlined : Icons.grid_4x4,
                            ),
                          ),
                          IconButton(
                            tooltip: dark ? '切换浅色模式' : '切换深色模式',
                            onPressed: () => setState(() => dark = !dark),
                            icon: Icon(
                              dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Liquid\nGlass.',
                        style: TextStyle(
                          fontSize: 58,
                          height: 1.02,
                          letterSpacing: -3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '光穿过界面。',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '拖动底部透镜，观察背景在弧面边缘的弯折。\n滚动页面，玻璃里的内容也会随之变化。',
                        style: TextStyle(fontSize: 13, height: 1.8),
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<BottomNavStyle>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: BottomNavStyle.liquidGlass,
                            label: Text('液态玻璃'),
                          ),
                          ButtonSegment(
                            value: BottomNavStyle.floating,
                            label: Text('悬浮底栏'),
                          ),
                          ButtonSegment(
                            value: BottomNavStyle.normal,
                            label: Text('普通底栏'),
                          ),
                        ],
                        selected: {style},
                        onSelectionChanged: (selection) =>
                            setState(() => style = selection.first),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(
                            alpha: dark ? .65 : .76,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: scheme.onSurface.withValues(alpha: .08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              BottomNav.icons[index],
                              color: scheme.primary,
                              size: 34,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    BottomNav.labels[index],
                                    key: const ValueKey('current-page-title'),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '点击切换 · 长按滑动',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '0${index + 1}',
                              style: TextStyle(
                                fontSize: 32,
                                color: scheme.onSurface.withValues(alpha: .25),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      for (final item in const [
                        ('01', '通透', '保留背景纹理，让玻璃里的世界清晰可见。', Color(0xFF70CFC6)),
                        ('02', '折射', '曲面边缘压缩与偏移光线，呈现透镜厚度。', Color(0xFF7CA6E9)),
                        ('03', '流动', '按压膨胀、拖动拉伸、松手回弹。', Color(0xFFE8B87D)),
                      ])
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(22),
                          constraints: const BoxConstraints(minHeight: 150),
                          decoration: BoxDecoration(
                            color: item.$4.withValues(alpha: dark ? .22 : .70),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.$1} / ${item.$2}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item.$3,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNav(
            currentIndex: index,
            style: style,
            onTap: (value) => setState(() => index = value),
          ),
        ),
      ),
    );
  }
}

/// Actual scene detail behind the dock makes refraction observable at rest.
class _GlassBackdropPainter extends CustomPainter {
  const _GlassBackdropPainter({required this.dark, required this.grid});
  final bool dark, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF142B32), Color(0xFF17202E), Color(0xFF29334A)]
              : const [Color(0xFFF2F6EE), Color(0xFFE0F2EF), Color(0xFFD4E2F2)],
        ).createShader(rect),
    );
    final colors = dark
        ? const [Color(0xFF237F81), Color(0xFF466AB0), Color(0xFFB78659)]
        : const [Color(0xFF78CCC5), Color(0xFF8CAEE6), Color(0xFFEFC391)];
    for (var i = 0; i < colors.length; i++) {
      final path = Path()
        ..moveTo(size.width * (-.45 + i * .52), size.height * .48)
        ..cubicTo(
          size.width * (1.1 + i * .2),
          size.height * .66,
          size.width * (-.6 + i * .5),
          size.height * .88,
          size.width * (.3 + i * .5),
          size.height * 1.15,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[i].withValues(alpha: grid ? .25 : .68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .17,
      );
    }
    final line = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF285466)).withValues(
        alpha: grid ? .30 : .10,
      )
      ..strokeWidth = grid ? 1.2 : .8;
    final spacing = grid ? 22.0 : 44.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_GlassBackdropPainter oldDelegate) =>
      dark != oldDelegate.dark || grid != oldDelegate.grid;
}
