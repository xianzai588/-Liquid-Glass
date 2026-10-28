import 'package:flutter/material.dart';

import 'widgets/bottom_nav.dart';
import 'widgets/liquid_glass/liquid_glass_backdrop.dart';

/// Reproducible optical fixture; enabled only with --dart-define=GLASS_COMPARE=true.
/// Shares the unmodified reference demo's image, screen, and dock placement.
class GlassComparisonDemo extends StatefulWidget {
  const GlassComparisonDemo({super.key});

  @override
  State<GlassComparisonDemo> createState() => _GlassComparisonDemoState();
}

class _GlassComparisonDemoState extends State<GlassComparisonDemo> {
  int index = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'NotoSansCJKsc'),
    home: LiquidGlassBackdropScope(
      child: Scaffold(
        extendBody: true,
        body: LiquidGlassBackdrop(
          child: SizedBox.expand(
            child: Image.asset(
              'assets/reference/system_home_screen_light.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
        bottomNavigationBar: BottomNav(
          style: BottomNavStyle.liquidGlass,
          currentIndex: index,
          onTap: (value) => setState(() => index = value),
        ),
      ),
    ),
  );
}
