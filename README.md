# Kaori iOS

**[English](#english)** | **[中文](#中文)**

<details open>
<summary><h2>English</h2></summary>

SwiftUI iOS client for [Kaori](https://github.com/dehuacheng/kaori) — a personal AI-powered life management app.

### Features

- **Dashboard** — Daily calorie/macro progress, recent meals and workouts
- **Meal tracking** — Log meals via photo or text, view AI-generated nutrition analysis
- **Weight tracking** — Log weight, view trends with interactive charts
- **Workout tracking** — Structured gym logging with exercises, sets, reps, weights
- **Workout timer** — Rest/work interval timer with Dynamic Island and Live Activity support
- **Apple Health** — Sync weight and workouts with HealthKit
- **LLM backend picker** — Choose between Claude CLI, Anthropic API, or Codex CLI

### Requirements

- iOS 17.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A running [Kaori backend](https://github.com/dehuacheng/kaori) accessible over the network

### Setup

```bash
git clone https://github.com/dehuacheng/kaori-ios.git
cd kaori-ios
xcodegen generate
open KaoriApp.xcodeproj
```

1. In Xcode, go to **Signing & Capabilities** and sign with your Apple ID
2. Connect your iPhone via USB, select it as the build destination
3. Press **Cmd+R** to build and run
4. In the app's **Settings**, enter your backend server URL and auth token

### Architecture

Pure thin client — no local database. All data lives on the Kaori Python backend and is accessed via JSON API.

- `Config/` — Server URL + bearer token (stored in UserDefaults)
- `Network/` — APIClient with URLSession
- `Models/` — Codable structs matching backend responses
- `Stores/` — `@Observable` state managers
- `Views/` — SwiftUI views organized by feature

### Free Provisioning

No paid Apple Developer Account required. The certificate expires every 7 days — re-sign by running from Xcode. App data persists across re-signings.

### Backend

The Python backend is at [kaori](https://github.com/dehuacheng/kaori).

### Roadmap

- **Personal Document Vault** — Upload and retrieve personal documents (passport, IDs, etc.) with password/Face ID protection. Design in progress: considering both a full LLM assistant mode for rich querying and a static presentation mode for maximum security. May offer both and let users choose based on their LLM setup and risk tolerance.
- **Medical Record Keeper** — Store exam results, lab work, and health records. Acts as your AI-powered PCP, nutritionist, and personal trainer — all in one place.
- **Feed-Based UI Revamp** — A unified "news feed" timeline for all daily entries: meals, weight, workouts, and eventually diary entries. The "add item" flow will feel like posting to the feed. Introducing **Scenes** (e.g., gym workout, deep focus study) — curated toolkits tailored to specific activities.
- **Personal AI Assistant (Long-Term Vision)** — The ultimate goal: a personal AI assistant (Kaori by default — pick your own name) that provides comprehensive care across all aspects of your life. Core design principle: **your data stays in your hands**. Self-host or choose a trusted LLM provider. Everything else in the app is completely free and open-source — fork it and vibe-code it to make it yours.

</details>

<details>
<summary><h2>中文</h2></summary>

[Kaori](https://github.com/dehuacheng/kaori) 的 SwiftUI iOS 客户端 — 个人 AI 驱动的生活管理应用。

### 功能

- **仪表盘** — 每日卡路里/宏量素进度，最近的饮食和健身记录
- **饮食记录** — 通过照片或文字记录饮食，查看 AI 生成的营养分析
- **体重追踪** — 记录体重，交互式图表查看趋势
- **健身记录** — 结构化健身日志，包含运动项目、组数、次数、重量
- **健身计时器** — 休息/训练间歇计时器，支持灵动岛和实时活动
- **Apple Health** — 同步体重和健身数据到 HealthKit
- **LLM 后端选择** — 可选 Claude CLI、Anthropic API 或 Codex CLI

### 环境要求

- iOS 17.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- 网络可访问的 [Kaori 后端](https://github.com/dehuacheng/kaori) 服务

### 安装

```bash
git clone https://github.com/dehuacheng/kaori-ios.git
cd kaori-ios
xcodegen generate
open KaoriApp.xcodeproj
```

1. 在 Xcode 中进入 **Signing & Capabilities**，使用你的 Apple ID 签名
2. 通过 USB 连接 iPhone，选择为构建目标
3. 按 **Cmd+R** 编译运行
4. 在应用 **设置** 中输入后端服务器地址和认证 token

### 架构

纯薄客户端 — 无本地数据库。所有数据存储在 Kaori Python 后端，通过 JSON API 访问。

- `Config/` — 服务器地址 + Bearer token（存储在 UserDefaults）
- `Network/` — 基于 URLSession 的 APIClient
- `Models/` — 与后端 JSON 响应对应的 Codable 结构体
- `Stores/` — `@Observable` 状态管理器
- `Views/` — 按功能模块组织的 SwiftUI 视图

### 免费签名

无需付费 Apple 开发者账号。证书每 7 天过期 — 在 Xcode 中重新运行即可续签。应用数据在续签后保留。

### 后端

Python 后端在 [kaori](https://github.com/dehuacheng/kaori)。

### 未来规划

- **个人文档保险库** — 上传和检索个人文档（护照、身份证等），通过密码/Face ID 保护。设计仍在进行中：考虑提供完整的 LLM 助手模式（功能更丰富）和静态展示模式（安全性最高），可能两者都提供，让用户根据自己的 LLM 配置和风险偏好自行选择。
- **医疗记录管理** — 存储体检报告、化验结果等健康档案。充当你的 AI 全科医生、营养师和私人教练 — 一站式服务。
- **信息流式 UI 重构** — 统一的"信息流"时间线，整合所有每日记录：饮食、体重、健身，未来还会加入日记。"添加记录"的交互将类似于在信息流中发帖。引入**场景**概念（如健身训练、深度专注学习等），为不同活动提供定制化的小工具集。
- **个人 AI 助手（终极愿景）** — 最终目标：一个个人 AI 助手（默认叫 Kaori，你也可以自定义名字），全方位照顾你生活的各个方面。核心设计原则：**数据掌握在自己手中**。你需要自行部署或选择信任的 LLM 服务商。应用的其他部分完全免费开源 — 随意 fork，用 AI 编程定制成你自己的版本。

</details>

## License

[MIT](LICENSE)
