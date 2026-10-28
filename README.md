# 液态玻璃底部导航演示

Flutter 底部导航演示，提供液态玻璃、悬浮和普通三种样式。液态样式参考 [AndroidLiquidGlass](https://github.com/Kyant0/AndroidLiquidGlass) 和 [LocationSpoofer](https://github.com/TaoCultivator/LocationSpoofer)，实现独立底座折射、双层背景透镜、七段色散、按压膨胀和阻尼回弹。支持深浅色、减少动态效果和徽标。

`lib/widgets/bottom_nav.dart` 为接入入口，传入 `currentIndex`、`onTap`、`style` 和 `badges`；液态实现位于 `lib/widgets/liquid_bottom_nav.dart`。五个页面是占位演示，未接入业务或后端。

```sh
flutter pub get
flutter run -d chrome
flutter test
```

接入时用 `LiquidGlassBackdropScope` 包住 Scaffold，再用 `LiquidGlassBackdrop` 包住背景内容（不要包住导航本身）：

```dart
LiquidGlassBackdropScope(
  child: Scaffold(
    extendBody: true,
    body: LiquidGlassBackdrop(child: pageContent),
    bottomNavigationBar: BottomNav(
      currentIndex: index,
      onTap: onTabChanged,
      style: BottomNavStyle.liquidGlass,
    ),
  ),
)
```

场景重绘后缓存清晰纹理和高斯模糊纹理，透镜组合采样底座内外两层，导航移动时只改变采样坐标。默认使用 2px 轻模糊、16% 底座覆盖和常驻选中态折射，保留可辨认的背景纹理；按压、点击和拖动连续增强曲面效果。底座光学独立于选中透镜的高光强度，触点高光沿边缘移动。捕获分辨率上限为 2 倍逻辑像素，异步纹理更新可能比滚动内容晚一帧；尚未做真机性能基准。该路径使用普通 FragmentShader，兼容 Skia / Impeller；shader 加载失败时回退毛玻璃。没有场景 scope 的旧接入方式保留原有滤镜路径。

点击任意 Tab 会带着膨胀和过冲移动到目标；可从任意 Tab 按下并横向拖动，松手吸附并回弹。减少动态效果时关闭移动形变，保留折射材质。

## 编译原版与 ADB 对照

已在同一台 Android 17 / API 37 模拟器（1080×2400、420 dpi）编译安装 AndroidLiquidGlass 的 Android 分支，并以相同背景、底栏位置和 ADB 手势比较静止、按压、拖动、松手状态。两个组件保留各自的前景图标与文字；本项目的前景内容仍以 Flutter widget 放大，未完整复制原版前景层折射。LocationSpoofer 拉取了液态组件源码作对照，未编译其整个应用。

- AndroidLiquidGlass：`896a94a3ade1cc1a940b92365f942a34971fecda`（android 分支）
- LocationSpoofer：`44e1ce221e47499b973fb1a1400fe8e45c9403a8`
- 原版对照页：[tool/reference/ComparisonContent.kt](tool/reference/ComparisonContent.kt)
- 手势和截图脚本：[tool/compare_glass_adb.py](tool/compare_glass_adb.py)

原版复现步骤：clone AndroidLiquidGlass 的 android 分支并切到上述提交，将对照页复制到 `catalog/src/main/java/com/kyant/backdrop/catalog/`；MainActivity 的 `setContent` 中使用 `if (intent.getBooleanExtra("compare", false)) ComparisonContent() else MainContent()`。本机以 JDK 21、Gradle 9.1.0、Android SDK 36 编译 `:catalog:assembleDebug`；将 catalog/backdrop 的 buildToolsVersion 从 36.1.0 调整为已安装的 36.0.0，移开 daemon JVM 自动下载配置，光学与动画源码未改动。

```sh
# 先安装原版 catalog-debug.apk，再录制原版
python tool/compare_glass_adb.py reference
# 本项目同背景对照包
flutter build apk --debug --dart-define=GLASS_COMPARE=true
adb install -r build/app/outputs/flutter-apk/app-debug.apk
python tool/compare_glass_adb.py flutter
# 恢复正常演示包
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

截图和录屏输出到 `build/visual-checks/`。脚本当前针对 Windows 默认 SDK 路径及 `emulator-5554`，启动后等待页面就绪再发送手势。测试覆盖核心区域不放大、边缘向内折射、清晰/模糊两层采样，以及按压膨胀和释放过冲回弹。

## 来源与许可

- 导航组件、shader、主题文件和字体来自 SYLUlive 项目，其中代码遵循 [SYLUlive MIT 许可](licenses/SYLUlive-MIT.txt)。
- Noto Sans CJK SC 字体遵循 [SIL Open Font License 1.1](licenses/NotoSansCJK-OFL.txt)。
- LocationSpoofer 作为设计和交互参考，未直接复制其代码。
- 圆弧折射函数和七段色散权重移植自 AndroidLiquidGlass，已改写为 Flutter 双纹理 shader。对照背景取自其 catalog 示例；详见 [NOTICE](licenses/NOTICE.txt) 和 [Apache-2.0 许可](licenses/AndroidLiquidGlass-Apache-2.0.txt)。
