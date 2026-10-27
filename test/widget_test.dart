import 'package:bottom_nav_demo/main.dart';
import 'package:bottom_nav_demo/widgets/bottom_nav.dart';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('liquid tabs respond to tap, drag, and rapid retargeting', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const NavigationDemo());
    final dock = find.byKey(const ValueKey('bottom-nav-floating-dock'));
    final rect = tester.getRect(dock);
    Offset tab(int index) =>
        Offset(rect.left + rect.width * (index + .5) / 5, rect.center.dy);
    String title() => tester
        .widget<Text>(find.byKey(const ValueKey('current-page-title')))
        .data!;

    await tester.tapAt(tab(3));
    await tester.pump();
    expect(title(), '校园');
    await tester.tapAt(tab(1));
    await tester.pumpAndSettle();
    expect(title(), '集市');
    final gesture = await tester.startGesture(tab(1));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(tab(4));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(title(), '我');
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal and floating tabs remain usable', (tester) async {
    await tester.pumpWidget(const NavigationDemo());
    for (final style in ['悬浮底栏', '普通底栏']) {
      await tester.tap(find.text(style));
      await tester.pumpAndSettle();
      for (var i = 0; i < BottomNav.labels.length; i++) {
        await tester.tap(find.byKey(ValueKey('bottom-nav-item-$i')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('current-page-title')))
              .data,
          BottomNav.labels[i],
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode and large text render without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const NavigationDemo());
    await tester.tap(find.byTooltip('切换深色模式'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('切换浅色模式'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('liquid navigation exposes independent accessible tab actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const NavigationDemo());
    final node = tester.getSemantics(
      find.byKey(const ValueKey('bottom-nav-semantic-2')),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('current-page-title')))
          .data,
      '课表',
    );
    handle.dispose();
  });

  testWidgets('liquid navigation follows external selection', (tester) async {
    late StateSetter change;
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            change = setState;
            return Scaffold(
              bottomNavigationBar: BottomNav(
                style: BottomNavStyle.liquidGlass,
                currentIndex: index,
                onTap: (value) => setState(() => index = value),
              ),
            );
          },
        ),
      ),
    );
    change(() => index = 4);
    await tester.pumpAndSettle();
    final node = tester.widget<Semantics>(
      find.byKey(const ValueKey('bottom-nav-semantic-4')),
    );
    expect(node.properties.selected, isTrue);
    final dock = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-floating-dock')),
    );
    final selection = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-selection')),
    );
    expect(selection.center.dx, closeTo(dock.left + dock.width * .9, 2));
  });
}
