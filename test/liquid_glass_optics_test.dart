import 'dart:ui' as ui;

import 'package:bottom_nav_demo/widgets/liquid_glass/bottom_nav_controller.dart';
import 'package:bottom_nav_demo/widgets/liquid_glass/liquid_glass_motion.dart';
import 'package:bottom_nav_demo/widgets/liquid_glass/liquid_glass_tuning.dart';
import 'package:bottom_nav_demo/widgets/liquid_glass/liquid_glass_visual_inertia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('one large pointer move cannot strand the lens between tabs', () {
    final surface = liquidGlassSurfacePositionFor(
      logicalPosition: 3,
      previousPosition: 0,
      velocityPixelsPerSecond: 2000,
      itemWidth: 80,
      dragging: true,
      reduceMotion: false,
    );
    expect((surface - 3).abs() * 80, lessThanOrEqualTo(6.001));
  });

  test('idle and reduced motion retain both lens and dock optics', () {
    for (final reduceMotion in [false, true]) {
      final motion = liquidGlassMotionFor(
        phase: LiquidNavPhase.idle,
        activation: 0,
        velocityPixelsPerSecond: 0,
        visualPosition: 0,
        currentIndex: 0,
        edgeCompression: 0,
        reduceMotion: reduceMotion,
        tuning: const LiquidGlassTuning(),
      );
      expect(motion.opticalActivation, greaterThan(.5));
      expect(motion.refraction, greaterThan(15));
      expect(motion.dockRefraction, greaterThan(0));
      expect(motion.dockRecoilX, 0);
    }
  });

  testWidgets('scene shader preserves the core and bends only the bevel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_scene.frag',
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      // Encode scene x in red and y in green to expose wrong origins / UVs.
      for (var y = 0; y < 200; y++) {
        for (var x = 0; x < 200; x++) {
          canvas.drawRect(
            ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
            ui.Paint()..color = ui.Color.fromARGB(255, x, y, 80),
          );
        }
      }
      final picture = recorder.endRecording();
      final scene = await picture.toImage(200, 200);
      picture.dispose();
      final shader = program.fragmentShader()
        ..setImageSampler(0, scene)
        ..setImageSampler(1, scene);
      final values = <double>[
        120,
        60,
        200,
        200,
        30,
        80,
        1,
        0,
        0,
        1,
        16,
        12,
        0,
        0,
      ];
      for (var i = 0; i < values.length; i++) {
        shader.setFloat(i, values[i]);
      }
      Future<ui.Image> render(double refraction) async {
        shader.setFloat(10, refraction);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 120, 60),
          ui.Paint()..shader = shader,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(120, 60);
        picture.dispose();
        return image;
      }

      final flat = await render(0);
      final glass = await render(16);
      final a = (await flat.toByteData())!;
      final b = (await glass.toByteData())!;
      int channel(int x, int y, int c) => (y * 120 + x) * 4 + c;
      // Core maps to scene (90,110), with no magnification or displacement.
      expect(b.getUint8(channel(60, 30, 0)), closeTo(90, 2));
      expect(b.getUint8(channel(60, 30, 1)), closeTo(110, 2));
      expect(b.getUint8(channel(60, 30, 0)), a.getUint8(channel(60, 30, 0)));
      // Inward bending on the right bevel samples a smaller scene x.
      expect(
        b.getUint8(channel(116, 30, 0)),
        lessThan(a.getUint8(channel(116, 30, 0)) - 3),
      );
      expect(b.getUint8(channel(60, 30, 3)), 255);

      // A lens crossing the dock must sample the sharp exterior and the soft
      // interior separately; blurring both destroys the folded edge.
      final softRecorder = ui.PictureRecorder();
      ui.Canvas(
        softRecorder,
      ).drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      final softPicture = softRecorder.endRecording();
      final soft = await softPicture.toImage(200, 200);
      softPicture.dispose();
      shader
        ..setImageSampler(1, soft)
        ..setFloat(14, 30)
        ..setFloat(15, 10)
        ..setFloat(16, 60)
        ..setFloat(17, 40)
        ..setFloat(22, 1);
      final combined = await render(0);
      final pixels = (await combined.toByteData())!;
      // Dock interior keeps a clear image with a small soft contribution.
      expect(pixels.getUint8(channel(60, 30, 0)), closeTo(126, 3));
      expect(pixels.getUint8(channel(10, 30, 0)), closeTo(40, 2));

      // Changing the lens reflection must never switch off the underlying
      // dock's refraction (including when the lens is resting).
      shader
        ..setFloat(24, 24)
        ..setFloat(25, 18);
      final curvedDock = await render(0);
      final curvedPixels = (await curvedDock.toByteData())!;
      expect(
        curvedPixels.getUint8(channel(34, 30, 0)),
        greaterThan(pixels.getUint8(channel(34, 30, 0)) + 5),
      );
      shader.setFloat(23, 1);
      final litDock = await render(0);
      final litPixels = (await litDock.toByteData())!;
      expect(
        litPixels.getUint8(channel(34, 30, 0)),
        closeTo(curvedPixels.getUint8(channel(34, 30, 0)), 1),
      );
      curvedDock.dispose();
      litDock.dispose();
      combined.dispose();
      soft.dispose();
      flat.dispose();
      glass.dispose();
      shader.dispose();
      scene.dispose();
    });
  });
}
