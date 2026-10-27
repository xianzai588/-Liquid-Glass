import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav.dart';

void main() => runApp(const NavigationDemo());

class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});
  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  int index = 0;
  BottomNavStyle style = BottomNavStyle.liquidGlass;
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '底部导航演示',
      theme: ThemeData(
        fontFamily: 'NotoSansCJKsc',
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: dark
            ? AppColors.surfacePrimaryDark
            : AppColors.surfacePrimaryLight,
      ),
      home: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('底部导航演示'),
          actions: [
            IconButton(
              tooltip: dark ? '切换浅色模式' : '切换深色模式',
              onPressed: () => setState(() => dark = !dark),
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 112),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    BottomNav.icons[index],
                    color: AppColors.brandPrimary,
                    size: 42,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    BottomNav.labels[index],
                    key: const ValueKey('current-page-title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '演示页面 · 点击或拖动底部导航切换入口',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<BottomNavStyle>(
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
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: index,
          style: style,
          onTap: (value) => setState(() => index = value),
        ),
      ),
    );
  }
}
