# 三平台导出

项目固定使用 Godot 4.6.3，导出预设保存在 `godot-game/crow-feather/export_presets.cfg`。

| 平台 | 架构 | 输出 |
| --- | --- | --- |
| Android | ARM64 | `dist/android/CrowFeather.apk` |
| Windows | x86_64 | `dist/windows/CrowFeather.exe` |
| Linux | x86_64 | `dist/linux/CrowFeather.x86_64` |

在 Godot 4.6.3 中安装相同版本的 Export Templates，先创建输出目录，再从 `godot-game/crow-feather` 运行：

```sh
mkdir -p ../../dist/windows ../../dist/linux ../../dist/android
godot --headless --export-release "Windows Desktop"
godot --headless --export-release "Linux/X11"
godot --headless --export-debug Android
```

Android 需要 JDK 17 和 Android SDK。Godot 的 Android 导出设置中填写 Java SDK 与 Android SDK 路径，并安装 Android Platform 35、Build Tools 35.0.1 与 Platform Tools。当前 Android 预设使用 debug 导出签名，可直接安装测试；正式发布前需改用自己的发布签名密钥。Android 屏幕控制采用左侧虚拟摇杆与右侧拾取、背包按钮。

输出目录已由仓库根目录 `.gitignore` 排除，构建产物不会混入源码提交。
