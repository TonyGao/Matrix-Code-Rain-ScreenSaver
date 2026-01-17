# Matrix Code Rain Screensaver for macOS

![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue?style=flat-square)
![macOS: 11.0+](https://img.shields.io/badge/macOS-11.0+-brightgreen?style=flat-square)

> **🚀 这是一个 Vibe Coding 项目 | This is a Vibe Coding project**
>
> 本项目纯粹由灵感驱动，追求极致的视觉氛围。欢迎大家 Fork 本仓库，加入你自己的创意，继续进行 Vibe 改造！
>
> [English Documentation](./README.md)

---

## 🎬 效果演示

GitHub 的 README 不支持内嵌视频预览，演示视频请前往：

- YouTube：（待补充）
- B 站：（待补充）

一款为 macOS 设计的高级黑客帝国代码雨屏幕保护程序。它不仅还原了经典的绿色数字雨效果，还融入了中文古诗词、随机警语、多层景深以及炫酷的红色“故障”流。

---

## 💻 系统要求

- **操作系统**: macOS 11.0 (Big Sur) 或更高版本
- **架构**: 支持 Intel 和 Apple Silicon (M1/M2/M3)

---

## ✨ 主要功能

- **📺 多层景深**: 5层不同缩放和速度的代码流，营造出真实的空间感。
- **📜 古诗词融入**: 代码雨中随机出现《道德经》、《论语》、唐诗宋词等名句，且阅读顺序由上至下，具有连贯性。
- **🔴 故障流效果**: 5% 的概率出现红色的“故障”代码流，下落速度更快，增加视觉冲击力。
- **🧩 周期性警语**: 每隔 15-30 秒，代码雨会汇聚成一句极具科幻感的中文警语（如“勺子不存在”、“系统即将崩溃”）。
- **🔠 中英混合**: 完美融合了 ASCII 字符与常用汉字。
- **⚡️ 高性能渲染**: 采用原生 Objective-C 与 Cocoa 框架开发，60 FPS 流畅运行，低 CPU 占用。
- **📏 智能适配**: 自动适配不同屏幕分辨率，支持文字自动换行与缩放。

---

## 🚀 快速安装

### 方法一：从 Release 下载（推荐）

1. 前往 [Releases](https://github.com/TonyGao/Matrix-Code-Rain-ScreenSaver/releases) 页面。
2. 下载最新的 `Matrix Code Rain.saver.zip` 文件。
3. 解压后双击 `Matrix Code Rain.saver`，系统会提示是否安装。
4. 在“系统设置” -> “屏幕保护程序”中选择 “Matrix Code Rain”。

> **注意**：如果 Release 页面暂无文件，请使用**方法二**通过源码编译安装。

### 方法二：一键脚本安装（源码编译）

如果你已安装 Xcode，可以使用提供的脚本一键编译并安装：

```bash
git clone https://github.com/TonyGao/Matrix-Code-Rain-ScreenSaver.git
cd Matrix-Code-Rain-ScreenSaver
chmod +x install_and_refresh.sh
./install_and_refresh.sh
```

---

## 🛠 开发与编译

### 运行环境

- macOS 11.0 或更高版本
- Xcode 12.0 或更高版本

### 编译步骤

1. 克隆仓库：

   ```bash
   git clone https://github.com/TonyGao/Matrix-Code-Rain-ScreenSaver.git
   cd Matrix-Code-Rain-ScreenSaver
   ```

2. 使用 Xcode 打开 `Matrix Code Rain/Matrix Code Rain.xcodeproj`。
3. 选择 `Matrix Code Rain` Scheme，目标选择 `My Mac`。
4. 按下 `Cmd + B` 进行编译。
5. 编译产物将自动同步到项目根目录下的 `bin` 文件夹中。

---

## 📝 配置文件与自定义

你可以在 `Matrix_Code_RainView.m` 中轻松修改以下内容：

- **古诗词列表**: 修改 `randomPoem` 函数中的 `poems` 数组。
- **警语列表**: 修改 `initializeMatrix` 函数中的 `aiQuotes` 数组。
- **流速与密度**: 调整 `MatrixStream` 类中的速度计算逻辑。

---

## 📄 开源协议

本项目基于 [MIT License](LICENSE) 协议开源。

---

## 🤝 贡献

欢迎提交 Issue 或 Pull Request 来改进这个项目！

---

## ❤️ 感谢

- 灵感来自电影《黑客帝国》(The Matrix)。
- 感谢所有为中文开源社区做出贡献的开发者。

---

*Made with ❤️ by [Tony Gao](https://github.com/TonyGao)*
