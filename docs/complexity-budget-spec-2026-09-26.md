# 文本文件复杂度预算规范（行数 + 字节双维度 · 2026-09-26）

> **状态**：`ACTIVE`（2026-09-26 **用户裁定默认生效**）：阈值＝全局 `~/.codex/AGENTS.md`「文本体量门禁」默认值（**2026-09-28 起数值定义点上移，本文不复写数字**）；已接入 `labs/AGENTS.md`「单文件复杂度与行数上限」与 `world-agent/webtouch/AGENTS.md` §75（两处只留阈值与门禁口径，正文以本文为唯一事实源）。
> **配套**：审计工具 [`../libexec/omh/complexity-audit.sh`](../libexec/omh/complexity-audit.sh)（只读；入口 `omh complexity-audit`，别名 `omh audit-complexity`）。存量豁免登记不随本仓分发，运行时从**目标仓** `docs/complexity-exemptions.txt` 读取。
> **关系**：本文是 2026-09-25「≤800 行硬上限」（`labs/AGENTS.md` §82 / `webtouch/AGENTS.md` §75）的**补充维度**，不替代、不放宽行数门禁。

---

## 一、 为什么只卡行数不够（2026-09-26 实测）

| 文件 | 行数 | 字节 | 说明 |
| :--- | ---: | ---: | :--- |
| `world-agent/webtouch/Tasks.md` | **578** 行（远在 800 行线内） | **217.0KB** | 平均 ~384 B/行；11 个 >2KB 的巨型行占约 15% 字节 |
| `world-agent/webtouch/handoff.md` | **151** 行（超自身 ≤150 行纪律） | **70.1KB** | 8 个 >2KB 的巨型行占约 44% 字节 |
| `world-agent/webtouch/pkg/browser/cdp_session.go` | 4430 行 | 176.0KB | 行数维度能拦，但字节维度早该报警 |

**结论**：行数是「结构」指标，字节是「体量」指标。长文本行、宽表格、内联大段原文会让文档在**行数达标**的同时体量失控——两者必须同时卡。

---

## 二、 双维度阈值（默认值 · **数值不在本文定义**）

**数值的唯一定义点＝全局 `~/.codex/AGENTS.md`「文本体量门禁」**（代码/文档的字节软硬限、行数软硬限、目录规模与非测试/条目双列口径）。本文只保留本仓的口径与取值依据，**不复写数字**。

- **取严口径**：字节或行数**任一**超限即按超限处理。
- **判据来源（2026-09-26 首轮全仓扫描口径）**：3795 个手写文本文件 / 30.2MB；分位数 p50 4.6KB、p75 8.4KB、p90 17.1KB、p95 25.9KB、p99 57.8KB。命中数：>32KB 126 个、>48KB 的代码 23 个、>64KB 的文档 23 个、>100KB 16 个。
- **阈值取在长尾起点**：代码硬限取在代码 p99 量级、文档硬限取在文档 p98 量级，既能拦住新增巨石，又不把正常文件卷入告警。
- 1KB = 1024 字节。

---

## 三、 扫描口径（谁被统计）

- **白名单（手写文本才入统计）**：`.md .markdown .txt .rst .adoc` ＋ 代码 `.go .py .pyi .ts .tsx .js .jsx .mjs .cjs .swift .sh .bash .zsh .rb .rs .java .kt .kts .c .h .cc .cpp .hpp .m .mm .sql .lua .php .cs .dart .vue .svelte .scala .ex .exs .html .css .scss .toml .yaml .yml .json .ini .cfg .conf .tf .tfvars .plist .proto .graphql`。
- **整目录排除**：`gen/` `generated/` `data/` `datasets/` `reports/` `outputs/` `dist/` `build/` `vendor/` `node_modules/` `__snapshots__/`（数据集与运行产物目录）。非 git 目录另剪依赖/构建目录。
- **语料/实验产物整目录排除（明示名单；2026-09-27 追加）**：机器产出的语料快照与实验产物目录整目录不审计 —— `world-agent/experiments/*`、`world-agent/references/corpus/*`、`product-genome/objects/*`、`ai-content-gen/novel-gen/assets/versions/*/prompts/*`。判定口径：目录内容为**数据/语料/评测产物**（json/txt/md 数据片，无手写代码与活文档）；名单**显式登记、不做名字通配**（`corpus`/`objects`/`legacy` 这类名字不单独通配，避免把真代码目录按名误伤）。跨项目默认名单应同步本条与脚本；项目专属名单按下一条维护。效果：纳入统计的基数 3795 文件 / 30.2MB → **2967 文件 / 26.7MB**，目录超硬限 16 → **6** 个。
- **项目排除清单**：适用同一数据/语料/评测产物判定，不排除手写代码或活文档；每行一个仓根相对或绝对的 Bash `case` glob，去除行首尾空白，空行及以 `#` 开头的行为注释。目录路径也匹配其后代。`--exclude-path GLOB` 可重复追加；`--exclude-file F` 指定一份清单并覆盖自动选择（路径相对调用时目录）；以 `-` 开头的参数须加 `./` 前缀。未显式指定时依次选仓根 `docs/complexity-exclude.txt`、`.complexityignore` 中第一份存在的普通文件；两者均不存在时不附加清单。显式指定的清单不存在、非普通文件或不可读，以及排除选项缺值，均以退出码 2 拒绝；选中的自动清单不可读也拒绝。相对 glob 以仓根为基准，不按任意层级同名目录匹配。
- **文件级排除（生成物/锁文件）**：`*.lock`、`package-lock.json`、`yarn.lock`、`pnpm-lock.yaml`、`go.sum`、`Cargo.lock`、`poetry.lock`、`*.min.js`、`*.min.css`、`*_pb2.py`、`*.pb.go`、`zz_generated*`、`*_generated.*`、`*.gen.*`、`worker-configuration.d.ts`。
- **完全不入统计**：图片/音视频/二进制/模型 blob/数据语料（如 `*.jsonl`）。
- **实现要点**：审计脚本在 git 仓内用 `git ls-files --cached --others --exclude-standard` 取清单（自动尊重 `.gitignore`，且**不遍历** GB 级数据目录）；非 git 目录才退回 `find`。清单口径下路径一律以**仓根相对路径**为键。
- **口径差异声明**：2026-09-26 首次人工量化用的是文件系统遍历（5477 文件 / 49.4MB，含被 ignore 的工作产物）；本规范**以 git 清单口径为准**（3795 文件 / 30.2MB），两个数字不可混用。

---

## 四、 豁免登记（Grandfather Clause）

- **登记文件**：`docs/complexity-exemptions.txt`，TSV 四列——`路径 <TAB> 登记字节数 <TAB> 登记日期 <TAB> 备注`；`#` 开头为注释。
- **只有「超硬限」文件进登记**；软限内的文件**不登记**（登记会让门禁对该文件失效，必须保留灵敏度）。
- **未登记的超硬限文件 = 新增负债**：审计退出码 1，**不得合入**；要么拆分/压缩，要么补登并写清理由。
- **备注词表**（决定「继续增长」是否报警）：

  | 备注关键词 | 含义 | 增长是否报警 |
  | :--- | :--- | :--- |
  | `append-only` | 追加型日志/归档/历史案卷（`操作记录.md`/`指令日志.md`/`*-归档.md`） | 否（靠轮转与下沉治理） |
  | `active-spec` | 活规范/状态文档（`handoff.md`/契约/设计文档） | 否（但每次改动须评估拆分） |
  | `evidence` | 单次取证产物（QA/案卷证据） | 否 |
  | `frozen-snapshot` | 历史版本/原型快照，基本冻结 | **是**（增长说明被改动，需复核） |
  | `pending-split` | 已定拆分方案、未拆完 | **是** |
  | `code-oversize` | 代码巨石，拆分须独立立项 | **是** |

- **豁免 != 允许继续堆砌**：在豁免文件里修 bug / 补特例时严禁追加流水；新增能力必须抽到独立子模块、helper 或新文档。
- **首轮基线（2026-09-26）**：登记 85 条（超硬限）；另有 110 个文件落在软限与硬限之间（`WARN`，不登记、持续观察）。

---

## 五、 分解纪律（超限了怎么办）

- **拆分独立立项**，不得夹带在业务修复批次里（沿用 2026-09-25 定案）。
- **文档三落点**（先例：`world-agent/webtouch/archive/algorithm-kernel.md`）：
  1. **append-only 执行流水** → `docs/archive/execution-log-YYYY-MM.md`；本体只留**最近一条 + 指针**；
  2. **决策与订正** → `docs/decisions/dec-YYYY-MM-DD-<slug>.md`，**一条一文件** ＋ `docs/decisions/README.md` 索引；
  3. **已结项历史** → 项目 `archive/`（沿用既有先例，不新建体系）。
- **本体必须保留**（否则「唯一事实源」失守）：目标 / 判据 / 活跃 todo / gate / 授权 / 停止线 / 验证方法 ＋ **一张索引表**（指向已下沉内容）。
- **搬运零裁剪**：用 `git mv` 或内容零裁剪搬运；每步一个可独立回退的提交。
- **拆分顺序建议**：先流水、再决策、最后本体；每一步单独提交、单独验证。

---

## 六、 审计与门禁用法

```bash
omh complexity-audit                    # 默认：只列超软限项（日常/提交前）
omh complexity-audit --all             # 全量清单（存量盘点、季度复核）
omh complexity-audit --strict          # 已登记文件继续增长也计入失败（全面体检）
omh complexity-audit --no-exempt       # 忽略登记，看存量全貌
omh complexity-audit --out inv.tsv     # 额外落完整 TSV 清单
omh complexity-audit --pkg-method-max N # 调包「单类型方法数」硬限（默认 150；另有 --pkg-decl-max 120 / --pkg-method-files-max 15）
omh complexity-audit --exclude-path 'dir/*'  # 追加语料/产物整目录排除（默认名单见 §三）
omh complexity-audit --exclude-file path  # 指定项目排除清单（格式和优先级见 §三）
omh complexity-audit --selftest        # 内置用例自检
omh complexity-audit <改动路径...>      # 只审本次改动面（秒级）
```

- **退出码**：`0`＝通过；`1`＝存在未登记的超硬限文件（`--strict` 下 `GROWTH`、§七 目录超限与 §7.1 包 god-package 超限亦计）；`2`＝用法错误。
- **建议节奏**：提交前跑默认模式；每季度跑 `--all --strict` 复核存量与增长。
- **自检**：运行 `omh complexity-audit --selftest`（或 `bash libexec/omh/complexity-audit.sh --selftest`），检查全部用例通过（包含新增未登记、登记后放行、排除清单和路径边界、增长报警等）。本仓用例入口：`bash tests/complexity-audit-selftest.sh`。
- **性能**：全仓默认约 30–60 秒（沙箱下逐文件 stat 较慢）；指定路径时秒级。

---

## 七、 目录规模上限（2026-09-26 用户裁定 · 同日按实测复核改为双列口径）

- **阈值（双列）**——Go 强制「包内所有文件同目录」，`_test.go` 无法外迁，故条目与非测试分列：
  - **非测试文件数**（不含 `_test.go`）：软限 **25** / 硬限 **40**；
  - **目录条目总数**（含 `_test.go`）：软限 **50** / 硬限 **80**。
  - 可用 `omh complexity-audit --dir-max N`（条目硬限）与 `--dir-src-max N`（非测试硬限）调整。
- **为什么分两列**：Go 的包边界＝目录，测试与源码必须同目录，故「条目数 ≈ 源码数 × 2」是常态；只卡条目会把「仅 10 个源码文件」的包判成超限（旧的单一 20 即如此）。实测依据与全仓对照表见附录 A.1。
- **两档处置**：**超软限**（条目 ≥50 或 非测试 ≥25）＝**关注区**，只提示、不影响退出码；**超硬限**（条目 >80 或 非测试 >40）＝**必须处置**，`--strict` 下计入失败退出码。
- **超限处置**：**建子目录分层**，把同类文件下沉到子目录 —— 单文件合格不等于目录合格；一个目录塞进几十上百个文件，同样是不可维护的复杂度。
- **Go 包边界＝目录**：跨目录搬运文件会改变包归属（同包内 `unexported` 标识符不可跨目录访问），因此 Go 目录超限＝**拆子包并调整导出面**，属高风险重构，**必须独立立项**，与「同包内按声明边界拆文件」分开对待（后者可机器证明零语义改动，前者不能）。
- **扫描口径**：与 §三 完全一致（同一批被统计文件，按父目录聚合）；`gen/data/dist/vendor/node_modules` 等整目录排除项照旧。
- **门禁口径**：默认模式**只告警**（不影响退出码，分别给出「目录超限（硬）」与「目录关注区（软）」两段清单）；`--strict` 下**仅硬限超限**计入失败，软限仍只提示。存量目录债务在收敛前不阻塞业务改动，但**新增目录不得越线**。

### 7.1 Go 包 god-package 三指标（2026-09-27 由诊断项升为硬门禁）
- **三指标**（均为**包级**、只统计非 `_test.go` 源码）：① 包**导出顶层声明数**（`type/func/var/const` 且名首大写，不含方法）；② 单类型**方法数**（导出＋未导出，取包内最大者）；③ 单类型**方法散布文件数**（该类型的方法分布在几个源码文件里）。
- **阈值**：① 软 **80** / 硬 **120**；② 软 **100** / 硬 **150**；③ 软 **10** / 硬 **15**。超软限＝关注区（只提示），超硬限＝必须处置、`--strict` 计入失败。数值取在长尾起点 —— 口径内全仓 **99** 个 Go 包仅 **1 个**命中硬限、3 个进关注区。
- **实测（2026-09-27）**：硬限命中 `world-agent/webtouch/pkg/browser`（导出 **87** / `cdpSession` 方法 **174** / 散布 **23** 个文件）；关注区＝`world-agent/agent-hub/internal/until`（45/72/10）、`webtouch/pkg/engine`（41/69/12）、`world-agent/agent-hub/cmd/ahub`（3/68/13）。`world-agent/cc-connect/**` 是**嵌套 git 仓且被 .gitignore**，不在本仓扫描口径内（其 `core.Engine` 394 个方法不计入）。
- **统计口径**：行首正则近似统计（单行接收者写法；多行接收者极罕见），实现＝审计脚本内 `pkg_metrics()`。与 §一 的文件维度互补：文件合格、目录合格，仍可能是一个 god-package。
- **处置**：与前段一致 —— 建子包分层、改导出面者须独立立项；`pkg/browser` 的收敛计划见附录 A。

---

## 八、 生效状态与裁定（2026-09-26）

- **用户裁定：本规范按默认阈值生效，审计入口照加。** ① 阈值＝**全局默认**（`~/.codex/AGENTS.md`「文本体量门禁」；2026-09-28 起定义点上移，本仓不复写数字）；② 已接入 `labs/AGENTS.md`「单文件复杂度与行数上限」与 `world-agent/webtouch/AGENTS.md` §75（两处不复制正文，只留阈值 + 门禁 + 指针）；③ `omh complexity-audit`（`libexec/omh/complexity-audit.sh`）为日常审计入口，首轮 **85 条存量登记**为基线。 ④ **目录阈值（§七）同日改为双列口径**（非测试 ≤25 软/40 硬 · 条目 ≤50 软/80 硬；`--strict` 只对硬限失败），按附录 A 计划收敛 `pkg/browser`。
- **仍待办（不阻塞生效）**：① 语料快照落点是否再上对象存储/异地；② `webtouch/Tasks.md` 实际拆分——**依赖归属解决**（该文件工作树存在并行会话未提交改动），顺序＝流水 → 决策 → 本体；③ **阶段 1 残余与阶段 2 立项**：`profile_dir.go` 已于 2026-09-27 出包（单元 4，见 §九），阶段 1 **已全部完成**（`profile_dir` 单元 4、`screencast` 单元 5，均见 §九）；`probe.go` 经实测判定**不搬**、`doc.go` 是包文档**不搬**；「按子系统成簇下沉」（transport/probe/modelbridge/window/input 六簇）已获用户口头 GO（2026-09-27），但阶段 2 簇（modelbridge/window/input）与阶段 3 的立项登记**曾须等 `Tasks.md` 并行会话落定**（见 ②）——**2026-09-29 已解决**：`T-28` 登记在案，且已加 scope 变更把阶段 3 由非目标转开工；不涉立项的规范内记录可先做。

- **同日追加两项裁定（2026-09-27）**：⑤ 语料/实验产物目录按 §三 明示名单**整类排除**（目录超硬限 16 → 6，`pkg/browser` 成为口径内唯一「代码目录超硬限」）；⑥ god-package 三指标按 §7.1 **升为硬门禁**（口径内仅 `pkg/browser` 命中，正是待收敛目标）。
- **`--strict` 实测（2026-09-27）**：`exit=1`，首因是 **GROWTH=3**（`webtouch/Tasks.md`、`agent-hub/cmd/ahub/serve_discussions.go`、`world-dash/hosts/web/src/discussion/DiscussionWorkspace.tsx`，均为跨会话在制品），目录/包硬限的失败分支因此到不了。故 `--strict` 现状是**全面体检**用，不作日常/提交前门禁。

## 九、 变更记录

- **2026-09-30 阶段 3 · 单元 3（`events` 簇）判定不搬 ＋ 清包内最后 WARN**：`cdp_session_events.go`（276 行/8.55KB，4 方法 ＋ 2 自由函数）形态判定＝**不搬**（设计＝`world-agent/webtouch/docs/evidence/complexity-stage3-unit3-events-design-2026-09-30.md`）。锁语义补测结清：8 字段在 23 处读写**全部**在 `s.mu` 内、无裸访问，`chat` 走自带 `mu`（无嵌套）⇒ V-A 技术前提成立，但被三条实测否决——① §A.3 分层句「字段定义仍留 `cdp_session_core.go`」与状态迁移冲突；② 按该口径直译需宿主补 ≈9 项状态门面 ⇒ `cdpSession` 方法净 **+5**（读数倒退）；③ 23 处改写主落点 `cdp_session_eval.go`（634 行/23.7KB）与 `cdp_session_action.go`（574 行/23.6KB）已在代码软限 96% ⇒ 有新增 WARN 风险；另本簇实为「导航 ＋ 页面/挑战 ＋ 聊天捕获」三簇交集（`challenge` 与搭档 `challengeSignal`/`detector` 属输入/挑战域，拆开需新增回调接缝）。改走规范允许的替代路径（拆测试文件，纯搬移、断言零改动）：`shared_window_test.go` 666 行/24.1KB → 588 行/21.2KB ＋ 新 `shared_window_pure_test.go` 85 行/3.5KB ⇒ **`pkg/browser` 包内 WARN 1 → 0**（120 OK，代码侧全库唯一 WARN 消除；审计 `docs` 域下本文自身的 53.1KB 文档软限 WARN 为存量口径、仍 <64KB 硬限）、条目 66 → **67**（拆分＝目录多一个 `.go`）、非测试 24／源码 23／导出 68／单类型方法 121／散布 12 **不变**；`gofmt -l` 空、`go vet ./pkg/browser/...` ＋ 三包测试（`browser`/`engine`/`viewerhub`）全绿。

- **2026-09-30 阶段 3 · 单元 2（身份/设备指标域出包，第二刀）**：`cdp_session_fingerprint.go`（326 行/14.66KB，**未触软限**）按 §A.3 分层口径只下沉**域能力/原语 5 项**到新子包 **`pkg/browser/identity`**（`identity.go` 133 行/6.8KB ＋ `viewport.go` 58 行/1.9KB；窄接口 `Session` **4 项**＝`Call`/`CallSession`/`On`/`EvalValue`，**＝实测出边、无发明项**）：`InstallWorkerHooks`（Worker auto-attach 订阅）、`ApplyScreenMetrics`（档案屏幕指标）、`LogApplied`（生效日志）、`SetDeviceMetrics`（设备指标原语，合并 `applyViewportMetrics`/`SetViewport` 两处重复字面量）、`AdoptWindowViewport`（窗口视口读取）。**编排层留宿主**（`enableTargetDomains`、`applyTargetIdentity`——身份解析优先级与按序应用）＋ **门面导出面留宿主**（`SetViewport` 仍实现 `ViewportSetter`）；状态归属＝`workerHookCancel`（域函数返回句柄、宿主落账，close 路径 `cdp_session_control.go` 依赖）与 `cfg.Viewport` 写回留宿主（同单元 1 `lastHit` 先例）。子包名取 `identity` 以避免与模型包 `uws/pkg/fingerprint` 重名。宿主文件 → **240 行/11.0KB**，6 个**包级**薄包装折叠进原文件（不新开转发文件 ⇒ 条目读数不变）。**读数（`complexity-audit pkg/browser`）**：`cdpSession` 单类型方法 **126 → 121**；条目 66／非测试 24／源码 23／导出 68／散布文件 12／WARN 1（`shared_window_test.go`）**与设计 §5 预估逐项零偏差**；`pkg/browser/identity` 2 文件、WARN 0。**等价性（§A.5 跨包口径）**：搬移体逐行 diff 仅三类标注改动（签名/接收者；`s.client.X`→`s.X`、`s.evalValue`→`s.EvalValue`、事件入参 `ev cdpEvent`/`ev.Params`→`params json.RawMessage`；订阅句柄与 `cfg.Viewport` 写入上移宿主）＋ `SetDeviceMetrics` 合并原两处重复字面量；`gofmt -l` 为空 ＋ `go build ./...` ＋ `go vet ./...` ＋ `go test -count=1 ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿（含真机段）＋ `go list -deps ./pkg/browser/identity` ＝ 标准库 ＋ `uws/pkg/fingerprint`（无环）＋ 消费方（`engine`/`viewerhub`/`qa`/`provider`）零改动 ＋ 8 方法同包测试引用 **0 处**（未改测试）。**遗留**：设计块沉归档暂缓——归档已 31.2KB（软限 32KB），待分卷评估后与单元 1 一并回填；单元 3（`events`）／单元 4（`core`）未开工。

- **2026-09-30 阶段 3 · 单元 1（`find` 域出包，阶段 3 第一刀）**：`cdp_session_find.go`（585 行/29.2KB，WARN 首位）按 §A.3 分层口径下沉新子包 **`pkg/browser/find`**——`scan.go`（`Scan` ＋ 扫描脚本**后半段** ＋ 窄接口 `Evaluator` **1 项**（`EvalRaw`）＋ `quoteJS`，17.6KB）、`scan_predicates.go`（扫描脚本**前半段**：归一化/可见性与可编辑谓词/打分函数/几何工具，7.9KB）、`node.go`（`NodeByID` ＋ `resolveNodeByIdExpr`，2.5KB）。**页内脚本拆两文件同 3a 判据**：单文件实测 24.1KB 会**新增**代码软限 WARN ⇒ 按「谓词工具 / 候选池＋择优」拆，**两段拼接后与原 340 行单段模板逐字节等值**（`diff` 为空，等价性因此仍可机器判）。宿主 `cdp_session_find.go` **585 行/29.2KB → 140 行/5.9KB**：只留 `findBridge`（宿主求值面）＋ 3 个**包级**薄适配（`findElementOpt`/`findElementMode`/`resolveNodeById`，注入 `*cdpSession`）＋ `recordHit`（**`lastHit` 落账归宿主**：find 写入、action 侧 `enrichHitSelector` 补全、`pkg/engine` 经 `LastHitElement()` 读取）＋ `LastHitElement`/`enrichHitSelector`/`checkOcclusion`；`clickAt`/`clickPoint` 属输入域，折进 `cdp_session_input.go`（18.5 → 19.4KB；**不落** 23.6KB 的 `cdp_session_action.go`、**不落** 已 597 行的 `cdp_session_control.go`）。**读数**：WARN **2 → 1**（余 `shared_window_test.go` 666 行/24.1KB，属阶段 2 单元 3）、`cdpSession` 单类型方法 **129 → 126**、散布文件 12（不变）、条目 66 / 非测试 24 / 源码 23（**不变**）、包导出 68（不变）；`pkg/browser/find` 3 文件、WARN 0、无目录/包关注区。**与预估的偏差（如实登记）**：① 预估「条目 66→65、源码 23→22」**未达成**——宿主保留 `cdp_session_find.go` 作适配文件（既不为转发新开文件、也不删既有文件），故目录读数不变，真实收益＝WARN −1 ＋ `cdpSession` 方法 −3 ＋ 上帝文件 29.2KB→5.9KB；② find 包 3 文件而非设计的 2 文件（JS 拆两文件，见上）；③ `quoteJS` 不引 `modelbridge`（本包 3 行同实现，维持「只向下依赖 `input`/`semantics`」）。**等价性（§A.5 跨包口径）**：两段 JS 逐字节 diff 为空；Go 改动仅三类且均标注（接收者 `s.evalRaw` → `ev.EvalRaw`、`elementTarget{}` → `input.ElementTarget{}`、`lastHit` 写入上移宿主 `recordHit`，仍只在 `Found` 时写）；`gofmt -l` 为空 ＋ `go build ./...` ＋ `go vet ./...` ＋ `go test -count=1 ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿（含真机段）；`go list -deps ./pkg/browser/find` ＝ 标准库 ＋ `input` ＋ `semantics`（无环）；消费方（`pkg/engine`/`pkg/viewerhub`/`webcontrol`/`qa`/`cmd/*`）零改动、`LastHitElement` 导出面原样；同包测试 14 处调用点只注入会话实参。**遗留**：`shared_window_test.go`（唯一剩余 WARN）属阶段 2 单元 3；`cdp_session_input.go` 19.4KB（软限余量 4.6KB）；`3b`（`window.go` 策略/几何下沉）仍未开工。

- **2026-09-29 阶段 2 · 单元 3c（真窗口/观看壳域出包）**：`viewer_window.go`（317 行/13.8KB）流程下沉 `window/viewer.go`（319 行/14.4KB：`Bounds`/`Size`/`DefaultMargin` ＋ `ViewerSession` 窄接口 **8 项 ≤ 实测 8 项** ＋ `Controller`/`Geometry` ＋ `Prepare`/`Raise`/`Activate`/`Restore`/`RealBounds`/`VisibleEnough` ＋ `ReadBounds`/`SetBounds`/`SetState` 命令面）；`viewer_bridge.go`（246 行/8.0KB）**逐行搬运** `window/bridge.go`（248 行/8.2KB；`ScreencastFrame`/`Metadata` 改引 `screencast` 子包，无环）。宿主 `cdp_session_control.go`（429 → **597 行/21.2KB**，仍在软限内）折叠：`bridgeViewerSession` 适配器（`RememberWindow`/`TakeSavedWindow` **保留「首次救援优先 ＋ 取走清零」的锁语义原样**）＋ 4 类型别名 ＋ `ErrNoViewerWindow` ＋ `BrowserProcessInfo`（留宿主）＋ 观看壳 9 类型/3 常量/`NewViewerBridge` 同名面 ＋ **7 个一行门面方法** ＋ 3 个 `*cdpClient` 窗口命令别名（命令形状只在子包定义一处）；`defaultWindowMargin` 移入子包（`window.DefaultMargin`，宿主 3 文件 9 处改带包名）；`BrowserPID`/`ViewerAlive` 无流程、留宿主原样（做成门面只会白加两次方法计数）。**「纯搬移」证据**：旧文件 41 条字符串字面量在新面 100% 命中、零丢失。**验收**：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿；`go list -deps ./pkg/browser/window` ＝ 标准库 ＋ `input` ＋ `screencast`；消费方（`pkg/viewerhub`/`pkg/engine`/`cmd/uws-viewer-demo`）**零改动**。**读数与预估零偏差**：条目 68 → **66**、非测试 26 → **24**、单类型方法 131 → **129**、散布文件 13 → **12**、WARN 2 → **2**。附带读数：包导出声明 81 → **68** —— **别名声明未被该口径计入**，此项不可当收益看（宿主 API 面并未缩小）。**遗留（另案，不在本单元顺手做）**：① `clampCoord` 与 `ViewerWindowSize` 均 0 引用，作为死代码原样搬运待清理；② `cdp.go` 的 `moveWindow` 仍自写一份 `Browser.setWindowBounds` 命令形状，可与 `window.SetBounds` 合并（与 3b 同批较自然——`cdp.go` 本就在 3b 的改动面内）；③ 宿主 `cdp_session_control.go` 已 597 行/21.2KB，**后续单元别再往这个文件堆**（改选 `cdp_session_input.go` 或在评估条目收益后新开文件）。

- **2026-09-29 阶段 2 · 单元 3a（共享窗口簇出包，单笔净减最大）**：`pkg/browser/shared_window.go`（559 行/23.2KB，**15 个 `cdpSession` 方法且全私有**）整体拆入新子包 `pkg/browser/window`（`shared.go` 314 行/13.0KB ＋ `anchor.go` 345 行/14.0KB；**拆两文件是硬约束**——首版单文件实测 644 行/26.5KB 会**新增**代码软限 WARN，违反本单元判据）。**接口面**＝`Session` 窄接口 **11 项**（7 项 CDP 通道 `Call`/`CallSession`/`Send`/`OffSession`/`AttachTarget`/`CreateTarget`/`WindowIDForTarget` ＋ 4 项会话事实 `Key`/`Headless`/`MarkShared`/`SharedWindowID`），**＝实测出边、未发明新能力**（11 ≤ 11）；形态＝`Registry` 类型 ＋ 导出入口 `(*Registry).OpenTab(ctx, s, width, height)`/`(*Registry).Release(s)` ＋ 导出纯函数 `Key`/`NewPageTargets`/`BlankURL`/`Handle`/`TargetSpec`；宿主适配器 `bridgeWindowSession` ＋ 薄包装 `sharedWindowKey(cfg Config)` ＋ 注册表入口 `windowRegistry()`（三者折叠进 `cdp_session_control.go`，429 行/13.9KB），**不给 `cdpSession` 加访问器**，故 146−15＝**131**。**注册表改为可注入是本单元的关键改进**：原包级 `sharedWindowMu`＋`sharedWindows` 随流程下沉为 `Registry`（`NewRegistry`/`DefaultRegistry`/`Seed`/`Entry`，持锁语义原样＝「查不到就建」整段串行），生产走 `DefaultRegistry()`，测试各自 `NewRegistry()` ⇒ **消除 `resetSharedWindows` 对包级 map 的全局复位**。类型面：子包自带最小同形解码 `TargetInfo`（只解 `targetId`/`type`/`url`）与 `point`（宿主 `pt` 字段未导出、不出包），`errEvalEmpty` 在子包重申同文案；宿主 `pageTarget`/`pt` 属会话域、多处引用，**不搬**。**测试**：`shared_window_test.go` **留宿主**（`fakeSharedBrowser` 的 ws 级假 CDP 服务端是这套时序的证据载体，不降级为 Go 级 fake），只改调用面——10 处 `resetSharedWindows` → `newSharedRegistry(t)`，9 处 `s.openTabInSharedWindow(ctx, windowPolicy{...})` → `reg.OpenTab(ctx, bridgeWindowSession{s}, 1440, 900)`，`s.releaseSharedWindow()` → `reg.Release(...)`，`seedSharedWindow`/`sharedRegistryEntry` → `reg.Seed`/`reg.Entry`（`window.Handle`），`TestCreateSharedAnchorWindowClosesAnchorWhenWindowUnknown` 更名 `TestOpenTabInSharedWindowClosesAnchorWhenWindowUnknown`（改由 `reg.OpenTab` 走同一条「锚页归属读不到 ⇒ 关掉自建锚页并报错」路径断言）。验收：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿；`go list -deps ./pkg/browser/window`＝**标准库 ＋ `uws/pkg/browser/input`**（无环）；消费方（`pkg/engine`/`pkg/viewerhub`/`cmd`）**零改动**。读数：目录条目 69 → **68**、非测试 27 → **26**；god-package 导出声明 81（不变）、单类型方法 146 → **131**、散布文件 14 → **13**、软限 WARN 2 → 2（均既有：`cdp_session_find.go` 585 行/29.2KB、`shared_window_test.go` **666 行/24.1KB**——迁移后较迁移前 685 行/24.6KB 略降，未新增）。**与事前估计的偏差**：方法 131、散布 13、条目 68、非测试 26 **四项与 §A.3 预估完全吻合，零偏差**。

- **2026-09-29 阶段 2 · 单元 2c（穿透寻底 + 点击/输入自愈出包）**：`pkg/browser/{pierce_hit,click_recovery}.go`（567 ＋ 380 行，含 **17 个 `cdpSession` 方法**）拆入既有子包 `pkg/browser/input`，**单笔同时退出 god-package 两条硬限**。**接口面**＝新增 `Session` **13 项**（内嵌 2a `Eval` ＋ `Call` ＋ `InsertText` ＋ `EvalBool`/`FindElementMode`/`CheckOcclusion`/`ClickAt`/`InputAt`/`NotifyPreDispatchReceptor`/`CloseGeminiMenu`/`GeminiInputEmpty`/`TargetDestroyed`/`RecordHit`），**＝实测出边、未发明新能力**（13 ≤ 16；`findElementOpt` 由子包按 `FindElementMode(...,false,false)` 现取不占接口）；形态＝**自由函数**（`StemAt`/`PierceViaAX`/`PierceViaNodeForLocation`/`PierceHitAt`/`CallOnPierced`/`PiercedValue`/`InputAtPierced`/`ClickWithRecovery`/`InputWithRecovery`/`InputLanded`/`IsGeminiClick`）＋ 宿主适配器 `bridgeInputSession`（折叠进 `cdp_session_input.go`，与 `bridgeCaller`/`bridgeEval` 并列）——**不给 `cdpSession` 加访问器或薄包装**，故 163−17＝**146**。类型面：`piercedHit`→`input.PiercedHit`（字段全导出 ⇒ 零别名）、`piercedStem`→`input.PierceStem`，`boxQuad`/`axCandidate`/`strayUIState` 留包内私有；`dispatchTracker` 整体迁为 `input.DispatchTracker`（宿主留 `type dispatchTracker = input.DispatchTracker` 别名，8 处调用点改 `Mark()`/`Dispatched()`）；4 个 `Fault*` 常量入子包、`interfaces.go` 别名块续登记（`pkg/engine` 零改动）。**两处与事前设计的偏差（均已定案）**：① **`pierce_hit.go` 未原样整体搬**——21.7KB 原文件加迁移注记与本包 AX 解码会**触发新的代码软限 WARN**（违反本单元「WARN 不新增」判据），故一拆为三：`input/pierce.go` 447 行/16.2KB（受体画像与穿透主流程）＋ `input/pierce_probe.go` 201 行/8.4KB（两个页内 JS 常量 ＋ `PierceStem`/`StemAt` ＋ 本包 AX 最小解码）＋ `input/recovery.go` 381 行/16.7KB（自愈闭环），`input/session.go` 53 行（接口＋标记面）。② **AX 取值解码的宿主落点经只读实测修正**：`axNodeRaw`/`axStr`/`axProp` 定义在宿主 `axsnapshot.go`（非事前以为的 `probe.go`），属 AX 快照域且被宿主 3 个文件引用 ⇒ **不搬**，子包自带**最小同形解码**（只取 `ignored`/`backendDOMNodeId`/`role`/`name`/`editable`，取值语义与 `axStr` 一致），避免「把 AX 原语塞进 input 域」与「为搬运给宿主加方法（撑大接口面）」两条歧路。**测试**：`pierce_hit_test.go` 整体入 `input/pierce_test.go`（207 行；源码扫描改读 `pierce.go`、`input.X` 去前缀、`TestboxQuad…` 更名 `TestBoxQuadContainsAndArea`）；`click_recovery_test.go` 拆两半——两条纯判定入 `input/recovery_test.go`（29 行），真机 `TestCDPSessionTargetDestroyed` 留宿主（40 行，改用 `bridgeInputSession{sess}.TargetDestroyed()`）；`pierce_e2e_capability_test.go` 4 处调用改 `input.X(ctx, bridgeInputSession{s}, …)`，`pierce_e2e*.go` 仍留宿主（会话级集成）。验收：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿；`go list -deps ./pkg/browser/input`＝**仅标准库**；消费方（`pkg/engine`/`pkg/viewerhub`/`pkg/qa`/`cmd`）**零改动**。读数：目录条目 72 → **69**、非测试 29 → **27**；god-package 导出声明 81（不变）、单类型方法 163 → **146**（**退出 ≤150 硬限**）、散布文件 16 → **14**（**退出 ≤15 硬限**）、软限 WARN 2 → 2（均既有：`cdp_session_find.go` 585 行/29.2KB、`shared_window_test.go` 685 行/24.6KB）。**与事前估计的偏差**：条目估计「72 → 70」而实测 **69**——目录关注区只统计本级目录条目，`pierce_hit_test.go` 外迁进子包后本级少 1 条（非测试口径同理 −2，与估计一致）；方法/散布两项与估计**完全吻合**。

- **2026-09-29 阶段 2 · 单元 2b（输入必达护栏 + 指针拟人化出包）**：`pkg/browser/{input_reliability,pointer_humanize}.go`（2 文件 365 行）拆入子包 `pkg/browser/input`（`RetryGuard` ＋ 窄接口 `Caller`、导出原语 `FocusEmulationEnabled`/`AttemptsFromEnv`/`BackoffFor`/`IsTimeoutLike`/`AttemptTimeout`/`ReadinessTimeout`，`Pointer` 组件 ＋ `ClickLandingPoint`/`IdleDriftPath`/`PointerDriftEnabled`/`DriftTuning`/`Point`，`ElementTarget`）。**接口面实测**：只需 1 项下发能力（`Call`）＋「会话是否已附着」（`Ready`）；但**出边比事前估计宽**——`shared_window.go` 的锚页中键重试直接复用 4 项原语（`AttemptTimeout`/`ReadinessTimeout`/`BackoffFor`/`IsTimeoutLike`）＋`FocusEmulationEnabled` ⇒ 这些必须**导出**而非留宿主；`cdp_session_eval.go`/`pierce_hit.go` 另有 2 处 `callInputWithRetry` 调用点（原估 1 处）；`pointer_humanize` 的轨迹数学（`overshootPath`/`pointerStepDelay` ＋ 4 常量）因宿主 `clickPoint`/`dragAt` 在 `[]pt` 上循环而**留宿主**（折进 `cdp_js_helpers.go`，避免 `[]pt↔[]Point` 双向转换），落点采样与漂移状态机入子包；`elementTarget` 移入 `input.ElementTarget`，宿主以 `type elementTarget = input.ElementTarget` 别名引用（字段全导出、无方法 ⇒ **调用点零改动**）；`pt` 维持宿主类型（字段小写，别名会逼改多处调用点）。宿主接线＝`inputGuard()`/`pointerHumanizer()` 两个访问器 ＋ `bridgeCaller` 适配器，折叠进 `cdp_session_input.go`（不新开转发文件）；漂移节奏宿主 var 经 `DriftTuning` 在**建会话时**注入组件 ⇒ 真机 e2e「建会话前调参」写法不变。测试：重试语义 4 例入子包（fake `Caller`，另补「未附着不重放就绪」「`AttemptsFromEnv` 取值」两例）；落点/漂移纯函数与组件闸门入子包，宿主保留轨迹数学、`ClickTarget` 与漂移集成；`inputFakeCDP`/`newInputTestSession` 留宿主（`viewer_window_test.go` 复用）。验收：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿；`go list -deps ./pkg/browser/input`＝**仅标准库**；消费方（`pkg/engine`/`pkg/viewerhub`/webcontrol/qa/cmd）**零改动**。读数：条目 74 → **72**、非测试 31 → **29**；god-package 导出声明 81（不变）、单类型方法 170 → **163**、散布文件 18 → **16**；软限 WARN 2 → 2（均既有：`cdp_session_find.go` 585 行、`shared_window_test.go` 685 行，后者与本次改动无关）。

- **2026-09-29 阶段 2 · 单元 2a（输入域低耦合组出包）**：`pkg/browser/{reanchor,input_gate,input_receptor_guard,drag}.go`（4 文件 528 行）搬入子包 `pkg/browser/input`（`StructuralIdentity`/`Lease`/`StructuralIdentity.Fingerprint`/`Lease.Valid`/`RoleCongruent`/`ReanchorVerdict`/`CaptureLease`/`Reanchor`、`InputValueLanded`/`NormalizeText`、`ReceptorProfile` 及其 `ProfileText`/`Describe`/`IsSensitiveReceptor`/`IsSearchReceptor`、`CredentialIntent`/`GuardReceptorProfile`/`GuardInputReceptor`、`ParseDragCoords`；页内探针 JS 同包 `IsEditableFnJS`/`InputTargetEditableJS`/`InputTargetSnapshotJS`/`SelectInputContentJS`/`StructuralIdentityFnJS`/`IdentityProbeJS`/`ReanchorCandidateJS`）。**接口面实测**：本组只用宿主能力 1 项 —— `Eval`（`EvalValue`），两个会话态函数 `CaptureLease`/`Reanchor` 改为收 `Eval` 的自由函数，`GuardInputReceptor` 同。宿主 `*cdpSession` 经 `bridgeEval` 适配器注入，薄包装（`captureTargetLease`/`reanchorTarget`/`guardInputReceptor`/`ParseDragCoords`）**折叠进既有文件 `cdp_session_input.go`**（该文件＝输入域宿主侧，378 行／16K，余量足；先落 `cdp_session_action.go` 时触发代码体积软限 WARN 24.1KB ⇒ 改落点消除）；三个结构化代号在 `interfaces.go` 加常量别名（**`pkg/engine` 零改动**）。测试范式：`reanchor_test`/`input_gate_test`/`drag_test` 整体随包搬（各补 1 例子包纯判定测试）；`input_receptor_guard_test` **拆两半**——纯判定表随包入 `input/receptor_guard_test.go`，真机 `httptest` 段留宿主。验收：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿；`go list -deps ./pkg/browser/input`＝**仅标准库**（无环）。目录读数：`pkg/browser` 条目 81 → **74**、非测试 35 → **31**（**退出目录硬限，转为软限关注区**）；god-package 导出声明 83 → **81**、单类型方法 170（不变）、散布文件 20 → **18**；软限 WARN 2 → 2（均既有，未新增）。

- **2026-09-29 阶段 2 · 单元 1（站点 LLM 模型桥出包）**：`pkg/browser/{sse,gemini_ndjson,deepseek_sse,gemini_model,deepseek_mode}.go`（5 文件 1385 行）搬入子包 `pkg/browser/modelbridge`（流状态机 `Stream`/`Sink`/`NewStream`/`NewSink`/`Chunk`/`Snapshot`、URL 判据 `IsChatCompletionURL`/`IsGeminiStreamURL`、`QuoteJS`、模型菜单 `OpenGeminiPicker`/`WaitGeminiMenu`/`SwitchGeminiModel`/`SwitchGeminiThinking`/`ReadThinkingState`/`CloseGeminiMenu`/`GeminiInputEmpty`、模式 `SwitchDeepSeekMode`/`ReadDeepSeekModes`/`ToggleDeepSeekSwitch` 与纯匹配器 `PickGeminiOption`/`FindThinkingOption`/`PickDeepSeekMode`/`ModeNameEqual`）。**接口面实测**：只有菜单/模式切换需要宿主能力，收窄为 6 项（`EvalValue`/`EvalBool`/`EvalResult`/`ClickAt`/`FindElementOpt`/`Call`）＋ 标记面 `Dispatch`（`Mark`）；流解析/状态机**零宿主依赖**（`go list -deps` 仅标准库）。宿主 `cdpSession` 经 `bridgeSession`/`bridgeDispatch` 适配器注入，六个薄包装折叠进 `cdp_session_action.go`；`fetchChatBody` 因需 CDP 留在宿主 `cdp_session_events.go`；`ChatStreamChunk`/`ChatStreamSnapshot` 在 `interfaces.go` 改为子包类型别名（**engine 零改动**）；`quoteJS` 改为委托。验收：`gofmt` 干净、`go build ./...`、`go vet ./...`、`go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿。目录读数：`pkg/browser` 条目 86 → **81**、非测试 40 → **35**；god-package 导出声明 83、单类型方法 174 → **170**、散布文件 23 → **20**。

- **2026-09-29 §九 历史下沉归档（随 3a 一并）**：3a 条目写入后正文达 **62.9KB**（逼近文档硬限 64KB，仅剩 ~1KB），按根 `AGENTS.md`「历史不占加载上下文」把 2026-09-26 ~ 2026-09-28 的 **13 条**变更下沉 `complexity-budget-spec-2026-09-26-变更记录归档.md`（8.0KB）——正文回到 **56.0KB**、余量 ~8KB（足够容纳 3b/3c 条目）；§九 只留阶段 2（2026-09-29）条目 ＋ 归档指针。

- **正文预算提示（2026-09-29，硬约束）**：**同日已执行压行**——阶段 1 已实施手法（单元 3/4/5）与阶段 2 已实施单元（2a/2b/2c/3a）的「落地设计/实测」块已下沉 `complexity-budget-spec-2026-09-26-变更记录归档.md`，正文 60.4KB → **46.1KB**（KB 按 `complexity-audit` 口径；硬限 64KB，余量 ~18KB）。**纪律照旧**：此后每实施完一个单元，先把该单元的「落地设计/实测」块沉入归档、再追加 §九 读数条目（单条 2~4KB，累积会顶穿硬限、把 `--strict` 判红）。

- **更早变更（2026-09-26 ~ 2026-09-28，13 条）已归档** → [`complexity-budget-spec-2026-09-26-变更记录归档.md`](complexity-budget-spec-2026-09-26-变更记录归档.md)（历史只管可追溯、不占加载上下文；检索关键词：阶段 1 单元 1~5、tier2、语料排除、god-package 硬门禁、目录阈值裁定、拆分批次、首版）。


---

## 附录 A、 目录规模阈值复核与 `pkg/browser` 拆分计划（2026-09-26 复核 · 阈值与阶段 1 已裁定）

> 背景：用户问「20 个文件的限制是不是太严？多少合理？browser 98 个是否不合理？先给拆的计划」。
> 本节是**测算与提案**，不改 §七 现行阈值；阈值调整需用户一句话裁定。

### A.1 复核结论：20 作为「目录条目总数」偏严，应分列源码/测试

- **Go 强制同包同目录**：包内所有文件（含 `_test.go`）必须在同一目录，测试无法搬走。故「目录条目数 ≈ 源码文件数 × 2」是常态，20 个条目 = 只允许 10 个源码文件的包，对成熟领域包过严。
- **实测（webtouch 全部 16 个包）**：多数包 **2–9** 个 `.go`；次大为 `pkg/engine` 54；`pkg/browser` 98 是**明显离群点**。

| 目录 | 条目 | 源码 | 测试 | 源码行 | 导出顶层声明 |
|---|---|---|---|---|---|
| `pkg/browser` | 98 | 46 | 52 | 13655 | 317 |
| `pkg/engine` | 54 | 25 | 29 | 12893 | 189 |
| `apps/gateway` | 37 | 20 | 17 | 8877 | 182 |
| `pkg/matcher` | 17 | 9 | 8 | 3291 | 96 |
| `pkg/fingerprint` | 13 | 7 | 6 | 3487 | 87 |
| `pkg/viewerhub` | 9 | — | — | 2598 | 57 |

- **建议新口径（双列，替代单一 20）**：**源码文件数**（不含 `_test.go`）软限 **25** / 硬限 **40**；**目录条目总数**（含测试）软限 **50** / 硬限 **80**。按此：`apps/gateway` 20/37 **合格**（与用户直觉一致）、`pkg/engine` 25/54 **触软限**、`pkg/browser` 46/98 **超硬限**。
- **新增诊断项（只报告、不设门禁）**：包导出顶层声明数、单类型方法数、单类型方法**散布文件数**。这三项才是 god-package 的真实症状。

### A.2 `pkg/browser` 98 个为什么确实不合理

不是文件数本身，而是**一个包塞了 6 类职责**：CDP 会话核心 / 输入可靠性 / 窗口与视图 / 模型桥 / 基准 runner / 探针。同一包内：**145 个顶层类型、458 个自由函数、317 个导出声明**；单类型 `cdpSession` **199 个方法**、其方法声明散布在 **25 个源码文件**、被 56 个文件引用。这个规模已无法靠「看一眼目录」建立心智模型。

**口径修正（2026-09-27）**：上段「145 个顶层类型 / 458 个自由函数 / 317 个导出声明 / `cdpSession` 199 个方法 / 散布 25 个文件」是人工粗算（含 `_test.go`、含未导出、按声明块内每个名字计）。脚本口径（非测试源码、行首正则、导出＝名首大写、方法不计入导出声明）实测为：全部顶层声明 **293**、导出顶层声明 **87**、`cdpSession` 方法 **174**（其中导出 50）、散布 **23** 个源码文件。**结论不变**（`pkg/browser` 仍是口径内唯一 god-package），但此后**引用数字以脚本口径为准**（§7.1）。

### A.3 三阶段拆分方案（按「风险最低 → 收益最大」排序）

**阶段 1：可直接搬（零接口改造；风险 低）**
- 候选原为：`tier2*.go`(3，已被 `cmd/tier2` 独立消费)、`probe.go`、`wsconn.go`、`profile_dir.go`、`semantic_aliases.go`、`action_budget.go`、`doc.go`。
- **实测修正（2026-09-26，单元 1/2 执行中）：`grep -c cdpSession`＝0 只是必要不充分条件，另有两道筛子**
  ① **共享测试夹具归属**：夹具被多文件复用时随文件搬走会连带改测试（`wsconn.go` 的 `startWSTestServer` 被 6 个 browser 测试复用 → 收益 −2 条目、成本翻倍，暂缓）；
  ② **包内调用点/常量面**：被核心会话文件直接引用即需导出 + 改调用点（`probe.go` 的表达式构造被 `cdp_session_find/action/input.go` 引用、`actionBudget` 常量被 5 处引用）。
  ⇒ 实际按「**消费面 × 夹具归属 × 调用点数**」逐单元实测筛选，不再照抄清单；`doc.go`（包文档）不搬。
  
- **阶段 1 已实施手法（单元 3/4/5）与阶段 2 已实施单元（2a/2b/2c）的落地设计、实测细节 → 已下沉归档**（2026-09-29 压行；检索关键词：单元 4/5 手法、夹具归属、2a、2b、2c）→ [`complexity-budget-spec-2026-09-26-变更记录归档.md`](complexity-budget-spec-2026-09-26-变更记录归档.md)

- **落点纪律（2b/2c/3a 沿用，2026-09-29 复核行数）**：适配器/薄包装**不得**落 `cdp_session_eval.go`（632 行）与 `cdp_session_action.go`（578 行——先落此处把该文件推到 24.1KB 触发**新的**代码软限 WARN）；优选 `cdp_session_control.go`（429 行/13.9KB，已有窗口/画面桥接面）、`cdp_session_input.go`（522 行/18.5KB）。

- **阶段 2 已实施结论（一行版；读数见 §九）**：单元 1 `modelbridge` ✅、单元 2 `input` 簇（2a/2b/2c ✅；入边仅 9 符号/11 处，三步独立提交）、单元 3a `shared_window` ✅（15 个全私有 `cdpSession` 方法整体出包，单笔净减最大）。

**单元 3（窗口簇）2026-09-29 只读实测**（`shared_window`/`viewer_window`/`window`/`viewer_bridge`，实测 **4 文件 1375 行**；A.3 旧记「6 文件 1899 行」为 2026-09-26 粗读数，以实测为准）：

- **3a 逐文件内容/入边/出边/落地设计与验收 → 已下沉归档**（关键词 3a）：结论＝15 个全私有方法进 `window`（`shared.go`＋`anchor.go`）、接口面 11 项＝实测出边、宿主桥接面折叠进 `cdp_session_control.go`、消费方零改动（commit `98804146`）；四项读数与预估零偏差。

- **3b 只读实测（2026-09-29，未动代码；`window.go` 253 行/10.8KB）**：
  - **声明面**：8 个函数（`resolveWindowPolicy`/`parseSize`/`parsePos`/`fitRightTopInWorkArea`/`needForegroundActivation`/`parkedOutsideWorkArea`/`visibleInWorkArea` ＋ `(screenWorkArea).intersects`）＋ 2 类型（`windowPolicy` 8 私有字段、`screenWorkArea`）＋ 常量四组（`windowMode*`/`activate*`/`defaultWindow*`/`parkWide*`）；**0 个 `cdpSession` 方法** ⇒ 收益只有条目 −1／非测试 −1，**方法数 131 不变**。
  - **入边实测**：`windowPolicy` 类型引用 **20 处 / 7 文件**（`cdp_session_core.go` 4、`cdp_session_factory.go` 3、`cdp.go` 1（注释）、`window.go` 4、测试 3 文件 8）；**自由函数的生产入边只 4 处**（`core`：`fitRightTopInWorkArea`/`parkedOutsideWorkArea`/`screenWorkArea`×3＋`resolveWindowPolicy`；`factory`：`resolveWindowPolicy`），其余 32 处集中在 `window_test.go`；**消费方（`pkg/engine`/`viewerhub`/`cmd`）零入边**。
  - **真实成本＝字段与常量改名**（跨包后必须带包名/导出名）：字段直接访问 `p.mode/.width/.height/.left/.top/.autoPosition/.park/.inputActivate` **约 28 处**（`window_test.go` 11、`cdp_session_core.go` 6）；常量引用 **约 49 处**（`windowMode*` 22 ＝ core 11／`window_test` 5／`shared_window_test` 6、`defaultWindow*` 14 ＝ `window_test` 11／`viewer_window` 2／`core` 1、`activate*` 9（`window_test`）、`parkWide*` 4 ＝ `core` 2／`viewer_window` 2）。**关键约束**：按 §九 2026-09-28「同一数值只允许定义一处」的用户裁定，宿主**不得**留 `const X = window.X` 复制件 ⇒ 这 ≈49 处常量引用必须改为 `window.X`（这是本单元最大的一笔机械面，远超 3a 的生产入边 5 处）。
  - **出边实测**：仅标准库（`os`/`strconv`/`strings`）＋ 宿主门面类型 `ViewerWindowBounds`（`viewer_window.go` 定义、`pkg/viewerhub`/`cmd` 消费）⇒ 下沉**须先定 bounds 归属**：子包自带 `window.Bounds`，宿主 `interfaces.go` 留 `type ViewerWindowBounds = window.Bounds`（消费方零改动，3c 沿用）。
  - **落地口径建议（据此执行，可不再补测）**：子包 `window/policy.go` 导出 `Policy`（字段导出）／`WorkArea`／`Bounds` ＋ 常量 `ModeShared|Window|Tab`、`ActivateAuto|Always|Never`、`DefaultWindowWidth|Height|Margin`、`ParkWideLeft|Top` ＋ 上述 8 函数；宿主 `interfaces.go` 落 `type windowPolicy = window.Policy`、`type screenWorkArea = window.WorkArea` 别名（类型名零改动，字段/常量按上表改）。判据同 3a：`gofmt`／`go build ./...`／`go vet ./...`／三包测试全绿、`go list -deps ./pkg/browser/window` 仍为标准库＋`input`、消费方零改动、读数 条目 68 → **67**、非测试 26 → **25**、方法 **131 不变**、WARN 不新增。
  - **与 3c 的顺序/合并（供决策）**：`viewer_window.go`（3c）同时引用 `windowPolicy`/`screenWorkArea`/`defaultWindow*`/`parkWide*`，故 3b 是 3c 的自然前置；**也可把 3b＋3c 合并为一次提交**（避免 `viewer_window.go` 先改一遍 `window.X` 再整体搬家），代价是单笔改动面更大、回滚颗粒度更粗。**收益/成本比**：3b 面最宽（≈90 引用点）而收益最小（仅 −1/−1）——若窗口有限，建议把 **3c（2 文件、含 3 个 `cdpClient` 方法）** 与**阶段 3 第一刀（`cdp_session_find.go`，585 行/29.2KB 在软限 WARN）** 排在 3b 之前；此排序属规划建议，实施前无须再测。

- **3b（同单元剩余一笔；实测已毕，落地前无须再补测）**：`window.go` 纯策略/几何下沉（`windowPolicy`→`window.Policy` **须导出字段**，全包 33 处测试 ＋ `core`/`factory`/`cdp.go` 约 8 处构造点随之改；零方法收益，收益是 **−1 条目/−1 非测试**）。**3c 落地后 `defaultWindowMargin` 已入子包**（`window.DefaultMargin`），3b 只剩 `windowMode*`/`defaultWindow*`/`parkWide*`/`activate*` 四组常量与 `windowPolicy`/`screenWorkArea`/`fitRightTopInWorkArea` 类型与函数面。

- **3c（真窗口/观看壳域）已实施验收（2026-09-29，commit `5dad8710`）**：设计/实测细节 → 已下沉归档（关键词 3c）；读数与预估**零偏差**（条目 68 → 66、非测试 26 → 24、单类型方法 131 → 129、散布文件 13 → 12、WARN 2 → 2 不新增），消费方零改动；遗留（死代码 / `moveWindow` 去重 / 该文件行数余量）见 §九。

**阶段 2：接口下沉后搬（−19 个源码文件；风险 中）**
- 搬出：input 域(8 文件 1836 行：`pierce_hit`/`click_recovery`/`reanchor`/`pointer_humanize`/`input_gate`/`input_reliability`/`input_receptor_guard`/`drag`)、viewer·window 域(6 文件 1899 行)、llm 模型桥(5 文件 1385 行)。
- 手法：在子包定义**窄接口**（与本仓既有 `ActionSession`/`ProbeStatsSource`/`WindowEvents` 同风格），由会话实现体注入；实测 input 簇只用 `evalValue`/`clickAt`/`callOnPierced`/`detectStrayUI`/`recoverStrayUI` 等十余个能力，接口面可控。
- 判据：接口方法数 ≤ 该簇实测用到的能力数；不得出现「为了搬运而发明大接口」。

**阶段 3：拆 `cdpSession` 本体（2026-09-29 用户现场指令：改为开工）**
- **口径变更**：本段原写「不建议开工（高风险、收益最小）」系**规划侧自拟建议、非用户裁定**；2026-09-29 用户现场指令明确「核心模块必须继续改，核心模块不改则拆叶子没有意义」⇒ 原建议作废，阶段 3 转为开工项（登记＝`webtouch/Tasks.md` `T-28` scope 变更）。原理由「无法机器证明等价」不成立：等价性由**机器判据**兜底（见下），不靠人肉信心。
- **分层目标（先定依赖方向，再动第一刀）**：`门面`（`*cdpSession` 导出方法面，冻结不变、消费方零改动）→ `编排层`（流程/时序组合：action 与 eval 序列、重试与兜底）→ `域能力层`（按域收拢：find / fingerprint / events / snapshot / window）→ `原语层`（CDP 通道、窗口、时钟、输入设备等最小能力）。**依赖只允许上层指向下层**；`cdpSession` 结构体字段定义仍留 `cdp_session_core.go`，出包单元经窄接口取用。
- **机器等价判据（每单元）**：① `go build ./...` ＋ `go vet ./...`；② `go test ./pkg/browser/... ./pkg/engine/... ./pkg/viewerhub/...` 全绿（含真机段）；③ 消费方零改动 ＋ 门面导出面原样保留；④ 纯搬移的方法体逐行 diff 为空，行为差异只允许出现在**显式标注的适配层**。
- **第一刀候选（2026-09-29 实测：私有方法多、入边窄）**：① `cdp_session_find.go` 8 方法 / 7 私有 / 597 行（且已在软限 WARN，优先）；② `cdp_session_fingerprint.go` 8/7/325 行；③ `cdp_session_events.go` 4/4；④ `cdp_session_core.go` 14/11（持字段定义、churn 最大，最后动）。窗口簇 `shared_window.go` 15 方法全私有（净减约 13，单笔最大）归**阶段 2 单元 3**，不占阶段 3 预算。

- **候选状态（2026-09-30 更新；逐单元实测筛选、不照抄清单）**：① `find` ✅ 实施完成（§九 单元 1）；② `fingerprint` ✅ 实施完成（§九 单元 2）；③ `events` ✅ **实测判定不搬**（状态绑定簇：规范口径下算术为负 ＋ 宿主落点贴软限；设计＝`world-agent/webtouch/docs/evidence/complexity-stage3-unit3-events-design-2026-09-30.md`，§九 单元 3）；④ `core.go` **实测判定不搬（2026-09-30 Agent 自决）**：14 方法/11 私有且持 `cdpSession` 字段定义 ⇒ 单类型方法 121 → 107（搬走 14 方法为收益上限）仍高于软限 100，且形态须先改本节「字段定义留 `cdp_session_core.go`」口径，而单元 3 已证窄接口直译让宿主补状态门面、读数倒退。**重新评估条件**＝与「状态绑定簇」合并立项（届时同步改口径）。另：`shared_window_test.go`（阶段 2 单元 3 遗留 WARN）已拆分子文件清零（§九 单元 3 条目）。

**阶段 1+2 完成后预估**：`pkg/browser` 源码 46 → **~18**，目录条目 98 → **~45**（回到建议软限内）；本仓当前唯一超硬限目录消失。

### A.4 拆完算不算「变好」——可测判据（before/after 同口径复测）

- **结构**：目录条目数 · 源码文件数 · 最大单文件行数（现 632）· 包导出声明数（现 317）· 单类型方法数（现 199）
- **构建**：`go build ./pkg/browser`、`go build ./pkg/engine` 耗时；`pkg/engine` 的依赖包数（现 `pkg/browser` 被 34 个文件 import）
- **红线（不达标即判「白拆」）**：阶段 1 必须做到**消费方（engine/viewerhub/webcontrol/qa/cmd/*）零改动**；全量 `go build ./...` + `pkg/browser`/`pkg/engine` 测试保持绿

### A.5 验证口径：跨包搬运**不能**沿用「逐声明 sha256 等价」

同包内搬运可机器证明零语义改动（§五）；**跨目录＝改包归属＝导出面变更**，证明力下降。改用组合证据：① 原包保留 `type X = sub.X` 别名 / 薄包装函数，旧符号继续可用；② `go build ./...` + 全量测试绿；③ `go list -deps` 无环；④ 消费方零改动即通过（阶段 1）；⑤ tier2/probe 有独立 cmd/测试入口可冒烟。

### A.6 裁定结果（原「待用户裁定」三条 · 2026-09-26 用户批复）

1. §七 阈值 **已按建议改为双列口径**（非测试 ≤25 软/40 硬 · 条目 ≤50 软/80 硬），旧口径「20」作废；已同步 `bin/complexity-audit.sh`（默认值、`--dir-src-max`、硬/软两段输出、`--strict` 只算硬限）与三处规范指针。
2. **阶段 1 已批准开工**：按 A.3 清单从 `pkg/browser/tier2*` 起逐单元搬迁，每单元以「消费方零改动 + 全量 build/vet/test 绿 + `go list -deps` 无环」为验收，逐单元独立提交。
3. 阶段 2/3 **立项仍待登记**：登记须写入 webtouch `Tasks.md`，该文件当前有并行会话在编辑，须等其改动落定后再写（本规范内不抢先登记）。

---
