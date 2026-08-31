# 项目：AI 工作副驾驶（Android MVP）

## 这是什么
Android 应用（Flutter）。台湾的销售 / 业务主管 / 中小企业老板在拜访或会议结束后录音，
手机端**离线**转写为台湾正体中文，LLM 生成"分得清事实和推断"的结构化记录，
并把记录附着在客户 / 人 / 项目实体上，下次回访前主动提醒。

目标用户每天的动作：录音 → 看结构化卡片 → 逐条确认 → 下次见同一个客户前被提醒。

## 不可违反的产品原则
1. AI 每条输出必须标注 `type: FACT | OPINION | INFERENCE | SUGGESTION`。
2. FACT / OPINION / INFERENCE 必须带 `evidence`（转写段落 id + 时间戳 + 原话）。
   没有 evidence 的 FACT 在客户端直接丢弃，不展示。
3. 信息不足时输出 `confidence: UNCERTAIN` 并填 `missing_info`，不猜。
4. 不做"他在糊弄 / 说谎"之类对人的判断；只陈述说法之间的差异并附原话。
5. 用户对话内容不得发送到中国大陆托管的模型服务。
6. 原始音频默认不上传；只有转写文本发往 LLM 代理。

## 架构
- **本地优先**：录音、转写、浏览、记忆全部离线可用；只有 LLM 分析走网络。
- 数据全部存手机 SQLite（drift）；**不做账号，不做云同步**。
- 后端仅为无状态 LLM 代理：`POST /analyze`、`POST /verify`；不存用户内容；按设备令牌限额。
- 分层：`features/`(UI) → `domain/usecases` → `data/repositories` → `core/(platform|network|storage)`
- 平台通道（Kotlin）：`RecordingService`（前台服务、每 30 秒分片落盘）、`AsrBridge`（sherpa-onnx）、`NotificationBridge`。

## 目录结构
```
lib/
├── app/            入口、路由、主题、DI
├── core/
│   ├── platform/   录音、ASR、通知的平台通道封装
│   ├── network/    dio client、LLM 代理调用、离线队列、重试
│   ├── storage/    drift 数据库、文件管理、模型文件管理
│   └── utils/      opencc、时间、日志
├── domain/
│   ├── entities/   Recording、Transcript、Claim、Entity、MemoryItem
│   ├── repositories/
│   └── usecases/   RecordAudio、TranscribeLocally、AnalyzeTranscript、
│                   AttachToEntity、ConfirmClaims、BuildReminder、RecallForEntity
├── data/
│   ├── local/
│   ├── remote/
│   └── repositories_impl/
├── features/
│   ├── record/     录音页
│   ├── transcript/ 转写查看、片段回放
│   ├── analysis/   结构化卡片、四类标签、证据回溯、确认流
│   ├── entities/   客户/人/项目、时间线
│   ├── reminders/
│   └── settings/
└── shared/
android/app/src/main/kotlin/.../
├── RecordingService.kt
├── AsrBridge.kt
└── NotificationBridge.kt
```

## 技术选型（不要改，除非我明确说改）
- Flutter（稳定版）+ Riverpod + drift + go_router + dio
- ASR：sherpa-onnx（官方 Flutter 插件）+ SenseVoice-small int8；silero-vad 切段；OpenCC `s2twp` 转繁
- ASR 模型文件首次启动下载（带进度、断点续传、校验），**不打进 APK**
- 音频：16 kHz 单声道，本地 Opus/AAC，默认 7 天后自动删除
- 所有异步任务（转写、分析）走本地持久化队列，可离线排队，联网后自动执行
- 后端：Python FastAPI

## 环境（9 月内不升级任何一项）
- Flutter 3.47.2 (stable)，`/home/roo/Development/Server/flutter`；不在 PATH，命令前需 `export PATH=/home/roo/Development/Server/flutter/bin:$PATH`
- Dart 3.13.2
- JDK 17.0.20-tem（sdkman），已用 `flutter config --jdk-dir` 指定
- Android SDK 36，NDK 27.1，CMake 3.22.1
- 包名：Dart package `aivoice`；namespace = applicationId = `app.aivoice.mobile`
- minSdk 24 / targetSdk 36 / compileSdk 36
- 不执行 `flutter upgrade`、不切 channel、不改 Gradle / AGP / NDK 版本
- 构建失败先贴完整报错，由我决定是否动版本

## 数据契约（App 与后端共用一份 JSON Schema，改动必须同时改两边）
```
Claim {
  id, recording_id,
  type: FACT|OPINION|INFERENCE|SUGGESTION,
  category: SUMMARY|TODO|DECISION|RISK,
  text,
  evidence: [{segment_id, start_ms, end_ms, quote}],   # FACT/OPINION/INFERENCE 必填
  reasoning: string|null,                              # INFERENCE/SUGGESTION 必填
  confidence: HIGH|MEDIUM|LOW|UNCERTAIN,
  missing_info: [string],                              # UNCERTAIN 时必填
  owner, due_date,                                     # TODO 用
  entity_ids: [],
  user_action: CONFIRMED|EDITED|REJECTED|PENDING,
  created_at, source                                   # 例 "asr:sensevoice-small@int8 + llm:<model>@<prompt_version>"
}
Transcript { recording_id, segments: [{id, start_ms, end_ms, text, confidence}] }
Entity     { id, type: CUSTOMER|PERSON|PROJECT, name, aliases: [] }
MemoryItem { id, entity_id, kind: COMMITMENT|PREFERENCE|CONSTRAINT|OPEN_ISSUE|DECISION|RELATION,
             text, claim_id, observed_at, status: ACTIVE|RESOLVED|SUPERSEDED, superseded_by }
```

## LLM 流水线
1. Analyzer：输入 Transcript + 该实体最近 N 条 MemoryItem → 输出 Claim[]（严格 JSON）。
2. Verifier：同一模型、不同提示词，逐条检查 evidence 是否真的支持该 claim；
   不通过的降级为 UNCERTAIN 或删除。
3. 客户端结构校验：无 evidence 的 FACT 丢弃。
提示词文件放 `backend/prompts/`，带版本号；Claim.source 记录用了哪个版本。

## 本月明确不做
账号、云同步、iOS、实时字幕、会议机器人、CRM、团队功能、多 Agent、多模型路由、
说话人分离（可选项）、点击术语解释（可选项）。
新想法写进 `NOT_NOW.md`，不在当前任务里实现。

## 工作方式
- 每次任务先列出要改的文件和步骤，等我确认再动手。
- 一次只做 `PLAN.md` 里的一项；做完运行 `flutter analyze` 和 `flutter build apk --debug`，贴出结果。
- 遇到 Gradle / NDK / ABI 报错，先贴完整报错和你的一句话判断，再改；不要连续试错超过 3 次。
- 不要为了通过构建或测试而删除、绕过产品原则相关的校验逻辑。
- 不要引入未列在技术选型里的第三方库；需要的话先问。
- 语言：UI 文案和注释用台湾正体中文；代码标识符、commit message 用英文。
- 每完成一项就 commit，message 格式：`feat(scope): ...` / `fix(scope): ...`。

## 当前进度
（每次任务结束后更新这一段：已完成哪几项、下一项是什么、已知问题）
- 已完成 9/1：工程初始化、Git、`flutter analyze` 无错、`flutter build apk --debug` 产出 APK。
- 下一项：9/2 录音（Kotlin 前台服务、30 秒分片、Opus/AAC、波形与计时）。
- 已知问题：
  - `sqlite3_flutter_libs` 0.6.0+eol 已是空包（sqlite3 3.x 改用 hooks 编译），直接依赖可删，暂留。
  - 构建时 Gradle 自动装了 NDK r28c 与 SDK Platform 35（未经确认）；实际参与编译的仍是 27.1。
  - `flutter doctor` 报 Android license status unknown，不影响构建。
