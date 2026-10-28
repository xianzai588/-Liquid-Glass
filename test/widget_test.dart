import 'package:bottom_nav_demo/main.dart';
import 'package:bottom_nav_demo/widgets/bottom_nav.dart';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'press lifts the lens and release springs back through its rest size',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const NavigationDemo());
      final lens = find.byKey(const ValueKey('bottom-nav-selection'));
      final dock = tester.getRect(
        find.byKey(const ValueKey('bottom-nav-floating-dock')),
      );
      final resting = tester.getRect(lens);
      final gesture = await tester.startGesture(resting.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final pressed = tester.getRect(lens);
      expect(pressed.height, greaterThan(resting.height * 1.35));
      expect(pressed.top, lessThan(dock.top));
      await gesture.up();
      var smallest = pressed.height;
      for (var frame = 0; frame < 45; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final height = tester.getRect(lens).height;
        if (height < smallest) smallest = height;
      }
      expect(smallest, lessThan(resting.height));
      await tester.pumpAndSettle();
      expect(tester.getRect(lens).height, closeTo(resting.height, .1));
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('tap travels through the dock with visible lift', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const NavigationDemo());
    final lens = find.byKey(const ValueKey('bottom-nav-selection'));
    final resting = tester.getRect(lens);
    final dock = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-floating-dock')),
    );
    final target = Offset(dock.left + dock.width * .7, dock.center.dy);
    await tester.tapAt(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final moving = tester.getRect(lens);
    expect(moving.center.dx, greaterThan(resting.center.dx + 20));
    expect(moving.center.dx, lessThan(target.dx - 10));
    expect(moving.height, greaterThan(resting.height * 1.1));
    await tester.pumpAndSettle();
    expect(tester.getRect(lens).center.dx, closeTo(target.dx, 1));
    expect(tester.getRect(lens).height, closeTo(resting.height, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag can start on an unselected tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const NavigationDemo());
    final dock = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-floating-dock')),
    );
    Offset tab(int index) =>
        Offset(dock.left + dock.width * (index + .5) / 5, dock.center.dy);
    final gesture = await tester.startGesture(tab(2));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.moveTo(tab(3), timeStamp: const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 80));
    final lens = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-selection')),
    );
    expect(lens.center.dx, closeTo(tab(3).dx, 8));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('current-page-title')))
          .data,
      '校园',
    );
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
