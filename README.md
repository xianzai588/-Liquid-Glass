# 液态玻璃底部导航演示

Flutter 底部导航演示，提供液态玻璃、悬浮和普通三种样式。液态样式参考 [LocationSpoofer](https://github.com/TaoCultivator/LocationSpoofer) 的半透明底座、可拖拽透镜与阻尼回弹交互，使用 SYLUlive 的 Flutter 实现与 shader。设备不支持 shader 滤镜时退回毛玻璃渲染。支持深浅色、减少动态效果和徽标。

`lib/widgets/bottom_nav.dart` 为接入入口，传入 `currentIndex`、`onTap`、`style` 和 `badges`；液态实现位于 `lib/widgets/liquid_bottom_nav.dart`。五个页面是占位演示，未接入业务或后端。

```sh
flutter pub get
flutter run -d chrome
flutter test
```

折射效果需要支持 Flutter shader 滤镜的渲染器；拖拽手感和折射请在目标设备上验证。

## 来源与许可

- 导航组件、shader、主题文件和字体来自 SYLUlive 项目，其中代码遵循 [SYLUlive MIT 许可](licenses/SYLUlive-MIT.txt)。
- Noto Sans CJK SC 字体遵循 [SIL Open Font License 1.1](licenses/NotoSansCJK-OFL.txt)。
- LocationSpoofer 作为设计和交互参考，未直接复制其代码。
