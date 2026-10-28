import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'liquid_glass_runtime.dart';

/// Shares a scene texture between glass surfaces, including on Skia / Web.
/// Put [LiquidGlassBackdrop] around the body, never around the glass itself.
class LiquidGlassBackdropScope extends StatefulWidget {
  const LiquidGlassBackdropScope({super.key, required this.child});

  final Widget child;

  static LiquidGlassScene? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SceneScope>()?.scene;

  @override
  State<LiquidGlassBackdropScope> createState() => _BackdropScopeState();
}

class _BackdropScopeState extends State<LiquidGlassBackdropScope> {
  final scene = LiquidGlassScene();

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SceneScope(scene: scene, child: widget.child);
}

class _SceneScope extends InheritedWidget {
  const _SceneScope({required this.scene, required super.child});
  final LiquidGlassScene scene;

  @override
  bool updateShouldNotify(_SceneScope oldWidget) => scene != oldWidget.scene;
}

/// One snapshot per scene repaint, not one screenshot per lens / animation tick.
/// A moving lens only changes sampling coordinates in the retained GPU texture.
class LiquidGlassScene extends ChangeNotifier {
  static const blurSigma = 2.0;
  _SceneBoundary? _boundary;
  ui.Image? _image;
  ui.Image? _sharpImage;
  bool _scheduled = false;
  bool _capturing = false;
  bool _buildingImage = false;
  bool _dirty = false;
  bool _disposed = false;

  void _scenePainted(_SceneBoundary boundary) {
    if (_buildingImage || _disposed) return;
    _boundary = boundary;
    _dirty = true;
    _schedule();
  }

  void _schedule() {
    if (_disposed || _scheduled || _capturing) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    _scheduled = false;
    final boundary = _boundary;
    if (_disposed || !_dirty || boundary == null || !boundary.attached) return;
    if (boundary.debugNeedsPaint || boundary.size.isEmpty) return;
    _dirty = false;
    _capturing = true;
    try {
      // Cap memory on desktop; logical coordinates remain independent of DPR.
      final ratio = math.min(boundary.pixelRatio, 2.0);
      _buildingImage = true;
      final pendingImage = boundary.toImage(pixelRatio: ratio);
      _buildingImage = false;
      final raw = await pendingImage;
      // Blur the source once before refraction. Sparse shader blur taps produce
      // repeated letter contours on detailed pages, unlike a real Gaussian blur.
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(
        raw,
        Offset.zero,
        ui.Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: blurSigma * ratio,
            sigmaY: blurSigma * ratio,
            tileMode: TileMode.clamp,
          ),
      );
      final picture = recorder.endRecording();
      late final ui.Image image;
      try {
        image = await picture.toImage(raw.width, raw.height);
      } catch (_) {
        raw.dispose();
        rethrow;
      } finally {
        picture.dispose();
      }
      if (_disposed || boundary != _boundary || !boundary.attached) {
        image.dispose();
        raw.dispose();
        return;
      }
      final previous = _image;
      final previousSharp = _sharpImage;
      _image = image;
      _sharpImage = raw;
      notifyListeners();
      previous?.dispose();
      previousSharp?.dispose();
    } catch (error) {
      debugPrint('[LiquidGlass] scene capture failed: $error');
    } finally {
      _buildingImage = false;
      _capturing = false;
      if (_dirty && !_disposed) {
        _schedule();
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _image?.dispose();
    _sharpImage?.dispose();
    _image = null;
    super.dispose();
  }
}

class LiquidGlassBackdrop extends SingleChildRenderObjectWidget {
  const LiquidGlassBackdrop({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _SceneBoundary(
    LiquidGlassBackdropScope.maybeOf(context)!,
    MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRepaintBoundary renderObject,
  ) {
    (renderObject as _SceneBoundary)
      ..scene = LiquidGlassBackdropScope.maybeOf(context)!
      ..pixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..markNeedsPaint();
  }
}

class _SceneBoundary extends RenderRepaintBoundary {
  _SceneBoundary(this.scene, this.pixelRatio);
  LiquidGlassScene scene;
  double pixelRatio;

  @override
  OffsetLayer updateCompositedLayer({
    required covariant OffsetLayer? oldLayer,
  }) => oldLayer ?? _SceneLayer(() => scene._scenePainted(this));

  @override
  void detach() {
    if (scene._boundary == this) scene._boundary = null;
    super.detach();
  }
}

/// addToScene is skipped for retained content, but runs when any descendant
/// layer changes, including scrolling inside a nested repaint boundary.
class _SceneLayer extends OffsetLayer {
  _SceneLayer(this.onChanged);
  final VoidCallback onChanged;

  @override
  void addToScene(ui.SceneBuilder builder) {
    super.addToScene(builder);
    onChanged();
  }
}

Future<ui.FragmentProgram>? _sceneProgram;

/// Samples only the scene behind the navigation; labels stay in the foreground.
class LiquidGlassSceneSurface extends StatefulWidget {
  const LiquidGlassSceneSurface({
    super.key,
    required this.scene,
    required this.refraction,
    required this.depth,
    required this.chromatic,
    required this.blur,
    required this.fallback,
    this.dockRect,
    this.dockTint = Colors.transparent,
    this.dockRefraction = 24,
    this.dockDepth = 18,
    this.specular = 1,
  });

  final LiquidGlassScene scene;
  final double refraction;
  final double depth;
  final double chromatic;
  final double blur;
  final Widget fallback;
  final Rect? dockRect;
  final Color dockTint;
  final double dockRefraction, dockDepth;
  final double specular;

  @override
  State<LiquidGlassSceneSurface> createState() => _SceneSurfaceState();
}

class _SceneSurfaceState extends State<LiquidGlassSceneSurface> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await (_sceneProgram ??= ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass_scene.frag',
      ));
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (error) {
      updateLiquidGlassRuntimeStatus(
        tier: LiquidGlassTier.c,
        shaderSupported: false,
        detail: 'Scene shader unavailable: $error',
      );
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return widget.fallback;
    return _SceneSurface(
      scene: widget.scene,
      shader: shader,
      refraction: widget.refraction,
      depth: widget.depth,
      chromatic: widget.chromatic,
      blur: widget.blur,
      dockRect: widget.dockRect,
      dockTint: widget.dockTint,
      dockRefraction: widget.dockRefraction,
      dockDepth: widget.dockDepth,
      specular: widget.specular,
      child: widget.fallback,
    );
  }
}

class _SceneSurface extends SingleChildRenderObjectWidget {
  const _SceneSurface({
    required this.scene,
    required this.shader,
    required this.refraction,
    required this.depth,
    required this.chromatic,
    required this.blur,
    required this.dockRect,
    required this.dockTint,
    required this.dockRefraction,
    required this.dockDepth,
    required this.specular,
    required super.child,
  });
  final LiquidGlassScene scene;
  final ui.FragmentShader shader;
  final double refraction, depth, chromatic, blur;
  final Rect? dockRect;
  final Color dockTint;
  final double dockRefraction, dockDepth;
  final double specular;

  @override
  RenderObject createRenderObject(BuildContext context) => _SceneSurfaceRender(
    scene,
    shader,
    refraction,
    depth,
    chromatic,
    blur,
    dockRect,
    dockTint,
    dockRefraction,
    dockDepth,
    specular,
  );

  @override
  void updateRenderObject(BuildContext context, _SceneSurfaceRender object) {
    object.update(
      scene,
      shader,
      refraction,
      depth,
      chromatic,
      blur,
      dockRect,
      dockTint,
      dockRefraction,
      dockDepth,
      specular,
    );
  }
}

class _SceneSurfaceRender extends RenderProxyBox {
  _SceneSurfaceRender(
    this.scene,
    this.shader,
    this.refraction,
    this.edgeDepth,
    this.chromatic,
    this.blur,
    this.dockRect,
    this.dockTint,
    this.dockRefraction,
    this.dockDepth,
    this.specular,
  );
  LiquidGlassScene scene;
  ui.FragmentShader shader;
  double refraction, edgeDepth, chromatic, blur;
  Rect? dockRect;
  Color dockTint;
  double dockRefraction, dockDepth;
  double specular;
  bool _reported = false;

  void update(
    LiquidGlassScene value,
    ui.FragmentShader program,
    double amount,
    double height,
    double dispersion,
    double softness,
    Rect? dockBounds,
    Color tint,
    double baseRefraction,
    double baseDepth,
    double reflection,
  ) {
    if (value != scene) {
      if (attached) scene.removeListener(markNeedsPaint);
      scene = value;
      if (attached) scene.addListener(markNeedsPaint);
    }
    shader = program;
    refraction = amount;
    edgeDepth = height;
    chromatic = dispersion;
    blur = softness;
    dockRect = dockBounds;
    dockTint = tint;
    dockRefraction = baseRefraction;
    dockDepth = baseDepth;
    specular = reflection;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    scene.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    scene.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final image = scene._image;
    final sharpImage = scene._sharpImage;
    final source = scene._boundary;
    if (image == null ||
        sharpImage == null ||
        source == null ||
        !source.attached ||
        size.isEmpty) {
      super.paint(context, offset);
      return;
    }
    // Transform to source coordinates at paint time: correct while dragging,
    // scrolling, resizing, and under an ancestor's scale / translation.
    Offset point(Offset p) => source.globalToLocal(localToGlobal(p));
    final origin = point(Offset.zero);
    final axisX = point(const Offset(1, 0)) - origin;
    final axisY = point(const Offset(0, 1)) - origin;
    final values = <double>[
      size.width,
      size.height,
      source.size.width,
      source.size.height,
      origin.dx,
      origin.dy,
      axisX.dx,
      axisX.dy,
      axisY.dx,
      axisY.dy,
      refraction,
      edgeDepth,
      chromatic,
      math.max(0, blur - LiquidGlassScene.blurSigma),
      dockRect?.left ?? 0,
      dockRect?.top ?? 0,
      dockRect?.width ?? 0,
      dockRect?.height ?? 0,
      dockTint.r,
      dockTint.g,
      dockTint.b,
      dockTint.a,
      dockRect == null ? 0 : 1,
      specular,
      dockRefraction,
      dockDepth,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    shader.setImageSampler(0, sharpImage);
    shader.setImageSampler(1, image);
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(math.min(size.width, size.height) / 2),
      ),
      Paint()..shader = shader,
    );
    canvas.restore();
    if (!_reported) {
      _reported = true;
      updateLiquidGlassRuntimeStatus(
        tier: LiquidGlassTier.b,
        shaderSupported: true,
        detail: 'Scene texture + FragmentShader (Skia / Impeller)',
      );
    }
  }
}
