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
- 音频：16 kHz 单声道，本地 Opus/AAC；**不自动删除**，只有用户主动删除才消失
- 中间产物（转写用的 `decoded.pcm`、合并档 `full.aac`）用完即删，可随时从分片重建；
  「不自动删除」只保护原始录音分片
- 音频不进任何备份：`allowBackup=false` + `dataExtractionRules` 同时排除云端备份与装置间转移
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
- 澄清：禁止的是主动修改 Flutter/Gradle/AGP/NDK 版本号来绕过构建失败；
  工具链自动拉取的附属组件不在此列。
  （例：构建时 AGP 自动装了 NDK 28.2.13676358 与 SDK Platform 35，保留；实际编译仍用 27.1）

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
- 已完成 9/1–9/4。9/2、9/3 由我真机验过；9/4 的数字是模拟器（x86_64）测的。
- 9/4 实测：10 分 01 秒音频，冷启动（行程新开、模型未载入）34 秒转完，
  热的 32 秒；切出 108 段，与测试音档重复次数完全一致；输出台湾正体。
- 转写管线：
  `chunk_*.aac` →（暂存合并）→ `AsrBridge` 解码成 16 kHz PCM →
  常驻 isolate（`AsrWorker`：OfflineRecognizer + silero-vad 只载入一次）→
  VAD 切段、逐段辨识、带 start/end 时间戳 → OpenCC s2twp → `Transcript`
  中间产物 `transcode.aac` / `transcode.pcm` 在 finally 里删掉，失败也清。
- OpenCC 是自己实作的（`lib/core/utils/opencc.dart`）：pub.dev 上 `opencc` 依赖已被
  取代的 native_assets_cli、`flutter_opencc` 停在 Dart 2，两个都不能用。
  字典用官方 OpenCC 原始 .txt 放 `assets/opencc/`（约 1.1 MB，Apache-2.0，附 LICENSE）。
  转换链照 `s2twp.json`：STPhrases 短路 STCharacters，再 TWPhrases ∪ TWVariantsPhrases ∪ TWVariants。
  有 8 条单元测试钉住行为（`test/opencc_test.dart`）。
- 模型：SenseVoice-small int8 228 MB + tokens.txt + silero_vad.onnx 643 KB，合计 229 MB。
  只抓单档，不下载官方那包 1.05 GB 的 tar.bz2。校验值是自己下载后算的 ——
  **Hugging Face 的 ETag 不是 SHA-256**（该 repo 走 Xet 储存），别再拿它当校验值。
- 隐私：`allowBackup=false` + `data_extraction_rules.xml`（cloud-backup 与 device-transfer
  都排除全部 domain）。录音不自动删除，只有用户主动删除才消失。
- 已知问题：
  - OpenCC s2twp 会把 台 转成 臺（台灣→臺灣）。这是上游 OpenCC 的行为，不是 bug，
    但台湾用户日常写「台灣」。要不要加例外是产品决定，未决。
  - 同一段音频重复 108 次，SenseVoice 会输出 開飯／派飯／菜飯／派放 等不同结果，
    这是辨识准确度问题，9/7 归类转写错误时一并记录。
  - `AsrWorker` 常驻会一直占着模型的记忆体（约 300–400 MB），低阶机在背景可能被系统回收。
    目前没有闲置释放机制。（PCM 已改成边读边喂，不再整档载入。）
  - 9/4 的效能数字来自模拟器，真机是 arm64，快慢未知。
  - `flutter doctor` 报 Android license status unknown，不影响构建，忽略。
- 依赖现状：flutter_riverpod / go_router / dio / drift / drift_flutter / sherpa_onnx
  （+ dev: drift_dev / build_runner）。drift 只写进 pubspec，未写代码、未跑 codegen。
  go_router 已列入但延后到 9/5 有第二页时才接。
- code review 修过的：worker 启动失败会永久卡死（已改成明确报错，有回归测试）、
  `dispose()` 先 kill 导致原生记忆体不释放、isolate 崩溃后 ReceivePort 泄漏、
  `_commands!` 竞态、OpenCC 字典解析阻塞主 isolate（已搬进 `Isolate.run`）、
  PCM 整档载入（已改成串流读取，20 分钟录音不再吃 115 MB）。
- 下一项：9/5 转写页（段落列表、点段落回放对应音频），顺便把转写显示从录音页搬走。
