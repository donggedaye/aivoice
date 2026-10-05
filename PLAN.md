# PLAN.md — 30 天冲刺（2026-09-01 → 09-30）

交付定义：Android 内测版。我自己每天用，另有 3–5 个台湾销售/主管**直接装 APK**，
每人由我当面陪着录一次真实对话。

规则：一次只做一项；每项有完成标准；达不到就砍后面的，不顺延。
做完一项在前面打 [x]，并更新 CLAUDE.md 的"当前进度"。

## 9/20 重排纪录

9/1–9/6 六项花了六天，9/7–9/19 停摆。剩 10 天，原本还有 24 天份的工作，砍法：

- 这个月只回答 Q1（分得清事实与推断有什么用）与 Q3（有没有人问价格）。
- **Q2（记忆／回访提醒）整段移到 10 月**。理由：记忆功能没有「分得清事实与推断的卡片」
  垫底就只是笔记本，做浅了反而问不出真东西。
- **Play 封闭测试移到 10 月**，改直接发 APK。封闭测试轨道要 Google 审核，1–7 天不等，
  9 月赌不起。
- 其余砍掉的项目与理由列在 `NOT_NOW.md` 的「10 月第一周」。

## 10/5 重排纪录

9 月冲刺 9/30 收线。9/1–9/6 与 9/21 完成；9/22–9/30 没做；9/23 的 schema 那半做完了，
提示词那半没写。10 月把顺序翻过来：**App 侧先做，后端最后做**。

- 唯一卡住的是后端：模型服务与部署主机都还没定，受产品原则 5 限制（不能是中国大陆托管）。
  其余项目都不卡。
- 契约已经冻在 `schema/claim.json`，所以 App 侧不必等后端：拿
  `schema/examples/analyze_response.json` 当本地固件，照它写落库、校验与 UI。
  等模型服务定了，剩下的就只有后端一项。
- 9/22–9/30 没打勾的项目全部并进下面的 10/A–10/D，不再按原日期执行。

## 已完成（9/1–9/6）

- [x] 9/1 Flutter 工程初始化（按 CLAUDE.md 目录结构）、Git、`flutter build apk --debug` 本地跑通
      完成标准：干净构建出 APK，能装到真机
- [x] 9/2 录音：Kotlin 前台服务、锁屏不断、每 30 秒分片落盘、Opus/AAC、录音页波形与计时
      完成标准：锁屏录 20 分钟不丢，分片可拼接
- [x] 9/3 sherpa-onnx 接入、SenseVoice-small int8、首次启动模型下载（进度、断点续传、校验）
      完成标准：真机转写 1 分钟音频，输出文字
- [x] 9/4 silero-vad 切段 + 逐段转写 + 段落时间戳；OpenCC s2twp
      完成标准：10 分钟音频 60 秒内转完，输出台湾正体
- [x] 9/5 转写页：段落列表、点段落回放对应音频
      完成标准：点任一段放出该段音频，定位误差在一帧（64 ms）内
- [x] 9/6 录音列表、单笔删除、设置页（清空全部数据）；音频不自动清理
      完成标准：删除要二次确认，录音进行中挡下删除，语音模型不受影响

## 剩下 10 天（9/21–9/30）

- [x] 9/21 drift 上线：transcripts / transcript_segments 两张表 + codegen
      完成标准：转写结果落库，从列表点开旧录音不再重新转写
      改动：不建 `recordings` 表（列表走档案系统已够快），`claims` 表移到 9/23
      跟 `schema/claim.json` 一起定，免得建完就要迁移
- [ ] 9/22 后端 FastAPI：单一 `/analyze`（内部跑 analyzer + verifier 两次调用）、
      设备令牌、每设备每日用量上限、部署
      完成标准：从手机打得到，超过上限会被挡
      **卡关点：模型服务与主机要先定案，不能是中国大陆托管**
- [ ] 9/23 Claim JSON Schema（`schema/claim.json`，App 与后端共用）+ Analyzer 提示词 v1
      （`backend/prompts/analyzer_v1.md`）
      完成标准：回传合法 JSON，每条带 type；FACT/OPINION/INFERENCE 必带 evidence，SUGGESTION 不必
      进度：**Schema 与正反例 9/20 已完成**（`schema/check.py` 跑过，0 失败）；
      提示词还没写，等模型定案
- [ ] 9/24 Verifier 提示词 v1 + 客户端结构校验：无 evidence 的 FACT 丢弃
      完成标准：手工构造一条无依据的 FACT，能被拦下
- [ ] 9/25 分析卡片 UI：摘要/待办/决策/风险四区；四类标签四色；
      INFERENCE 默认折叠并显示依据
- [ ] 9/26 证据回溯：点任一条跳到转写段落并回放（复用 9/5 的回放）；
      UNCERTAIN 条目显示 missing_info
- [ ] 9/27 逐条 确认 / 拒绝；分析失败留在本地，可手动重试
      （逐条「修改」与 `claim_edits` 表移到 10 月）
- [ ] 9/28 3–5 个真实用户直接装 APK，每人陪 15 分钟录一次真实对话；
      同时补完原 9/7 的转写错误分类，填进 `docs/asr-errors.md`
- [ ] 9/29 只修他们遇到的问题，不加功能
- [ ] 9/30 复盘写入 `docs/retro-sep.md`：谁回来了、INFERENCE 被拒率、转写错误率、10 月做什么

以上 9/22–9/30 没打勾的项目不再按原日期执行，已并进下面的 10 月。

## 10 月（按 A→B→C→D 顺序做，不排日期）

- [x] 10/A claims 落库 + 客户端结构校验（9/21 延后的 `claims` 表 + 原 9/24 后半）
      完成标准：无 evidence 的 FACT 会被丢弃（要有测试证明）、drift 迁移能跑在既有资料库上、
      正例能在资料库里来回一趟不失真，`flutter analyze`、`flutter test`、
      `flutter build apk --debug` 三个都绿
      决定：按「重新转写」时连同该笔录音的 claims 一起删。段落 id 是照 VAD 的序号生成的
      （`lib/data/repositories_impl/transcription_repository_impl.dart:71`），`save` 又是先删再插，
      重转之后存着的 `segment_id` 可能无声无息地指到另一段话。依据没了，结论就不留。
      改动：建了 `analyses` / `claims` / `claim_evidence` 三张表，schemaVersion 1→2，
      本专案第一支 `MigrationStrategy`。`analyses` 表头的理由与 `transcripts` 一样 ——
      分不出「分析过但 0 条」与「还没分析过」就会每次点开都重送网路请求。
      结果：`flutter analyze` 0 问题、`flutter test` 51 条全过（原 30 条 + 新增 21 条）、
      `flutter build apk --debug` 成功。迁移在真的 v1 档案上跑过（`claim_migration_test`）。
      未验：模拟器与真机都还没跑过，这一项没有 UI，没东西可看。
- [ ] 10/B 分析卡片 UI + 证据回溯 + 逐条确认 / 拒绝（原 9/25、9/26、9/27）
      摘要/待办/决策/风险四区；四类标签四色；INFERENCE 默认折叠并显示依据；
      点任一条跳到转写段落并回放（复用 9/5 的回放）；UNCERTAIN 条目显示 missing_info；
      分析失败留在本地，可手动重试
      完成标准：全程用 `schema/examples/analyze_response.json` 当本地固件驱动，不连后端
      范围：照 `NOT_NOW.md`，逐条「修改」与 `claim_edits` 表不做，只做确认 / 拒绝
- [ ] 10/C 后端 FastAPI + Analyzer / Verifier 提示词（原 9/22、9/23 后半、9/24 前半）
      单一 `/analyze`（内部跑 analyzer + verifier 两次调用）、设备令牌、
      每设备每日用量上限、部署；提示词放 `backend/prompts/`，带版本号，写进 `Claim.source`
      完成标准：从手机打得到，超过上限会被挡；后端直接拿 `schema/claim.json` 验模型输出，
      不另外写一份
      决定：设备令牌就存 App files 目录下的一个纯文字档，不加第三方套件
      （`allowBackup=false` 已经把整个 files domain 排除在备份与装置间转移之外）
      **卡关：模型服务选哪家、部署到哪，两件都要你先定。限制是产品原则 5，
      不能是中国大陆托管。API key 与主机没定之前这一项动不了。**
- [ ] 10/D 接上网络、真机验证、3–5 人试用、复盘（原 9/28、9/29、9/30）
      把 10/B 的本地固件换成真的 `/analyze`；3–5 个真实用户直接装 APK，
      每人陪 15 分钟录一次真实对话；只修他们遇到的问题，不加功能；
      补完原 9/7 的转写错误分类填进 `docs/asr-errors.md`（要真机、真人讲话，
      模拟器麦克风只录得到静音）；复盘写入 `docs/retro-oct.md`

## 两个必须回答的问题（9/30）

1. 用户能否说出 FACT 和 INFERENCE 的区别对他有什么用？
2. 有没有人主动问价格？

第三个问题「用户是否因为『上次的事被记起来了』而再次打开？」移到 10 月，
这个月没有记忆功能，问不了。
