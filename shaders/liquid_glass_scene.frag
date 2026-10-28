#version 460 core
#include <flutter/runtime_effect.glsl>

// Circular edge profile and spectral weights adapted from
// Kyant0/AndroidLiquidGlass, Shaders.kt (Apache-2.0; see licenses/NOTICE.txt).
// Modified for Flutter scene textures, dual-source sampling and capsule geometry.
// This path samples a retained scene texture and also runs on Skia / CanvasKit.
uniform vec2 uSize;
uniform vec2 uSceneSize;
uniform vec2 uOrigin;
uniform vec2 uAxisX;
uniform vec2 uAxisY;
uniform float uRefraction;
uniform float uDepth;
uniform float uChromatic;
uniform float uBlur;
uniform vec4 uDockRect;
uniform vec4 uDockTint;
uniform float uIsLens;
uniform float uSpecular;
uniform vec2 uDockOptics;
uniform sampler2D uScene;
uniform sampler2D uSoftScene;
out vec4 fragColor;

vec4 sampleScene(vec2 p) {
  vec2 scene = uOrigin + p.x * uAxisX + p.y * uAxisY;
  vec2 uv = clamp(scene / uSceneSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  // RepaintBoundary.toImage is an offscreen render target on GLES.
  uv.y = 1.0 - uv.y;
#endif
  vec4 sharp = texture(uScene, uv);
  vec4 soft = texture(uSoftScene, uv);
  if (uIsLens < 0.5) return mix(sharp, soft, 0.55);
  vec2 halfDock = uDockRect.zw * 0.5;
  float radius = min(halfDock.x, halfDock.y);
  vec2 q = abs(p - uDockRect.xy - halfDock) - halfDock + radius;
  float sd = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
  float inside = 1.0 - smoothstep(-0.5, 0.5, sd);
  // The reference combines the original scene with a second backdrop that
  // already has the dock's lens applied. Sampling plain blur here loses a
  // complete refraction stage and produces a flat, milky selection.
  vec2 dockNormal = sign(p - uDockRect.xy - halfDock) *
      max(q, 0.0) / max(length(max(q, 0.0)), 0.0001);
  float dockEdge = clamp(1.0 + sd / max(uDockOptics.y, 0.001), 0.0, 1.0);
  float dockProfile = 1.0 - sqrt(max(0.0, 1.0 - dockEdge * dockEdge));
  vec2 dockDelta = -dockNormal * uDockOptics.x * dockProfile;
  vec2 softUv = clamp((scene + dockDelta.x * uAxisX + dockDelta.y * uAxisY)
      / uSceneSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  softUv.y = 1.0 - softUv.y;
#endif
  // A clear curved surface retains enough detail to expose the folded image.
  // Blur and tint belong to the underlying dock, with independent optics.
  soft = mix(texture(uScene, softUv), texture(uSoftScene, softUv), 0.22);
  soft.rgb = mix(soft.rgb, uDockTint.rgb * soft.a, uDockTint.a);
  return mix(sharp, soft, inside);
}

vec4 softScene(vec2 p) {
  if (uBlur < 0.01) return sampleScene(p);
  // Additional softness beyond the cached Gaussian source.
  vec4 color = vec4(0.0);
  for (int y = -2; y <= 2; y++) {
    float wy = y == 0 ? 6.0 : ((y == -1 || y == 1) ? 4.0 : 1.0);
    for (int x = -2; x <= 2; x++) {
      float wx = x == 0 ? 6.0 : ((x == -1 || x == 1) ? 4.0 : 1.0);
      color += sampleScene(p + vec2(float(x), float(y)) * uBlur * 0.7)
          * (wx * wy / 256.0);
    }
  }
  return color;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = uSize * 0.5;
  float radius = min(halfSize.x, halfSize.y);
  vec2 centered = p - halfSize;
  vec2 q = abs(centered) - halfSize + radius;
  vec2 outside = max(q, 0.0);
  float sd = length(outside) + min(max(q.x, q.y), 0.0) - radius;
  float edge = clamp(1.0 + sd / max(uDepth, 0.001), 0.0, 1.0);
  float profile = 1.0 - sqrt(max(0.0, 1.0 - edge * edge));
  vec2 normal = sign(centered) * outside / max(length(outside), 0.0001);
  // Negative displacement bends the image inward at the bevel; no UV clamping
  // to the capsule, which would smear pixels into flat stripes at the boundary.
  vec2 displacement = -normal * uRefraction * profile;
  vec2 refracted = p + displacement;
  vec4 color = softScene(refracted);
  if (uChromatic > 0.001 && edge > 0.001) {
    // Dispersion changes sign across the four quadrants, as in the reference.
    // Seven spectral taps avoid an artificial red/blue outline around the core.
    vec2 dispersion = displacement * uChromatic *
        (centered.x * centered.y / max(halfSize.x * halfSize.y, 0.001));
    vec4 red = sampleScene(refracted + dispersion);
    vec4 orange = sampleScene(refracted + dispersion * (2.0 / 3.0));
    vec4 yellow = sampleScene(refracted + dispersion / 3.0);
    vec4 green = sampleScene(refracted);
    vec4 cyan = sampleScene(refracted - dispersion / 3.0);
    vec4 blue = sampleScene(refracted - dispersion * (2.0 / 3.0));
    vec4 purple = sampleScene(refracted - dispersion);
    color = vec4(
      (red.r + orange.r + yellow.r) / 3.5 + purple.r / 7.0,
      orange.g / 7.0 + (yellow.g + green.g + cyan.g) / 3.5,
      (cyan.b + blue.b + purple.b) / 3.0,
      (red.a + orange.a + yellow.a + green.a + cyan.a + blue.a + purple.a) / 7.0
    );
  }

  // Narrow directional reflection + inner shadow describe the curved surface.
  // No broad white overlay: the scene remains visible through the core.
  vec2 light = normalize(vec2(-0.55, -0.83));
  float facing = dot(normal, light);
  float rim = exp(-abs(sd + 0.75) * 1.7);
  float inner = exp(-abs(sd + 2.8) * 0.8);
  float reflection = rim * (0.06 + 0.24 * pow(abs(facing), 5.0)) * uSpecular;
  color.rgb *= 1.0 - inner * 0.09 * max(-facing, 0.0);
  color.rgb = mix(color.rgb, vec3(color.a), reflection);
  fragColor = color;
}
