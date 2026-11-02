#!/usr/bin/env bash
# complexity-audit.sh — 文本文件复杂度分级审计（只读；除自身临时目录外不写任何文件）
#
# 规则事实源：docs/complexity-budget-spec-2026-09-26.md（本仓 docs/；阈值、扫描口径、排除名单、豁免口径）
# 目的：① 新增文件硬门禁自检（默认模式只列 WARN 及以上）
#       ② 存量清单盘点（--all 连 OK 级一起列）
#       ③ 豁免登记体检（未登记的超硬限文件 = 新增负债，退出码 1）
#       ④ 目录规模与 Go 包 god-package 体检（默认只告警，--strict 计入失败）
#
# 用法：omh complexity-audit [选项] [路径...]
#       （同：libexec/omh/complexity-audit.sh；别名 omh audit-complexity）
#   --all                       列出全部被扫描文件（含 OK 级）
#   --strict                    GROWTH（已登记文件继续增长）、目录硬限、包 god-package 硬限均计入失败
#   --dir-max N                 目录「条目总数」硬限（默认 80，含 _test.go）
#   --dir-src-max N             目录「非测试文件」硬限（默认 40，不含 _test.go）
#   --pkg-decl-max N            包「导出顶层声明数」硬限（默认 120）
#   --pkg-method-max N          包「单类型方法数」硬限（默认 150）
#   --pkg-method-files-max N    包「单类型方法散布文件数」硬限（默认 15）
#   --exclude-path GLOB         追加「语料/实验产物整目录排除」路径（仓根相对或绝对；可重复）
#   --exclude-file F            指定项目级排除清单（默认自动读取 <仓根>/docs/complexity-exclude.txt 或 <仓根>/.complexityignore）
#   --no-exempt                 忽略豁免登记（全部按未登记处理，用于看存量全貌）
#   --exempt-file F             指定豁免登记文件（默认 <仓根>/docs/complexity-exemptions.txt）
#   --out F                     额外把完整 TSV 清单写入 F
#   --selftest                  跑内置自检（临时目录构造用例，验证门禁行为）
#   -h | --help                 显示本帮助
#   路径...                     扫描根或具体文件（默认＝当前 git 仓根；可给多个；显式文件同样受扩展名白名单约束）
#
# 退出码：0=通过；1=存在未登记的超硬限文件（--strict 下 GROWTH、目录硬限、god-package 硬限亦计）；2=用法错误
#
# 扫描口径（与规范一致，务必不可放宽）：
#   · 只算「手写文本」扩展名；数据语料（*.jsonl/*.parquet/*.bin/模型 blob）、图片、构建产物、
#     依赖树、锁文件、生成代码一律不入统计 —— 否则会被 GB 级数据集污染读数。
#   · 在 git 仓内用 `git ls-files --cached --others --exclude-standard` 取清单（自动尊重
#     .gitignore，且不遍历数据集），非 git 目录才退回 find（并剪掉依赖/构建目录）。
#   · 可在任意子目录调用：脚本按**调用时的 cwd** 固化入参后切到仓根执行；输出路径一律仓根相对。
#   · 目录黑名单（两侧同口径）：gen/generated/data/datasets/reports/outputs/dist/build/vendor/
#     node_modules/__snapshots__ —— 数据集与运行产物目录整目录不审计；需要时单独传具体文件路径。
#   · 语料/实验产物明示名单（可用 --exclude-path 追加，见规范 §三）：world-agent/experiments/*、
#     world-agent/references/corpus/*、product-genome/objects/*、
#     ai-content-gen/novel-gen/assets/versions/*/prompts/*
set -uo pipefail

# ---- Go 包 god-package 三指标（规范 §七）：行首正则近似统计，不含 _test.go ----
# 输入：$1=仓根；$2=目录清单文件（一行一个，仓根相对或绝对）
# 输出：TSV  decls \t methods \t method_files \t biggestType \t srcFiles \t dir
pkg_metrics() {
  python3 - "$1" "$2" <<'PYINNER'
import os, re, sys
root, listfile = sys.argv[1], sys.argv[2]
try:
    dirs = [d.strip() for d in open(listfile, encoding='utf-8', errors='replace').read().splitlines()]
except OSError:
    dirs = []
top = re.compile(r'^(type|func|var|const)\s+([A-Za-z_][A-Za-z0-9_]*)')
meth = re.compile(r'^func\s+\(\s*\w+\s+\*?([A-Za-z_][A-Za-z0-9_]*)\s*\)\s+([A-Za-z_][A-Za-z0-9_]*)')
rows = []
for d in dirs:
    if not d:
        continue
    path = d if os.path.isabs(d) else os.path.join(root, d)
    if not os.path.isdir(path):
        continue
    files = sorted(f for f in os.listdir(path) if f.endswith('.go') and not f.endswith('_test.go'))
    if not files:
        continue
    decls = 0
    methods, mfiles = {}, {}
    for f in files:
        try:
            src = open(os.path.join(path, f), encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        for line in src.splitlines():
            m = top.match(line)
            if m and m.group(2)[:1].isupper():
                decls += 1
            mm = meth.match(line)
            if mm:
                methods.setdefault(mm.group(1), set()).add(mm.group(2))
                mfiles.setdefault(mm.group(1), set()).add(f)
    big = max(methods, key=lambda k: len(methods[k])) if methods else '-'
    rows.append((decls, len(methods.get(big, ())), len(mfiles.get(big, ())), big, len(files), d))
for r in sorted(rows, key=lambda r: (-r[1], -r[0])):
    print("%d\t%d\t%d\t%s\t%d\t%s" % r)
PYINNER
}

# ---- 内置自检：构造临时用例验证门禁行为（不依赖网络、不写仓内文件）----
selftest() {
  local self="$0" t pass=0 fail=0 rc
  t=$(mktemp -d "${TMPDIR:-/tmp}/complexity-selftest.XXXXXX") || return 2
  t=$(cd "$t" && pwd -P)   # macOS $TMPDIR 是 /var → /private/var 符号链接，路径须规范化后才能与登记表比对
  gen_big() { awk -v n="$1" 'BEGIN{s="";for(i=1;i<200;i++)s=s"y";for(j=0;j<n;j++)print s}' > "$2"; }
  check() { # check <用例名> <期望 rc> <实际 rc>
    if [ "$2" = "$3" ]; then echo "  PASS  $1（rc=$3）"; pass=$((pass+1));
    else echo "  FAIL  $1（期望 rc=$2，实际 rc=$3）"; fail=$((fail+1)); fi
  }
  echo "== complexity-audit --selftest =="

  mkdir -p "$t/c1" "$t/c2" "$t/c3" "$t/c4/node_modules" "$t/c4/data" "$t/c5" "$t/c6"
  printf 'hello\n' > "$t/c1/a.md"
  gen_big 400 "$t/c2/big_new.md"            # ~80KB 未登记
  gen_big 400 "$t/c3/registered.md"
  gen_big 400 "$t/c4/node_modules/skip.md"
  gen_big 400 "$t/c4/data/skip.json"
  gen_big 400 "$t/c5/grown.md"
  printf '%s\t%s\t2026-09-26\tcode-oversize：用例\n' "$t/c3/registered.md" "$(wc -c < "$t/c3/registered.md" | tr -d ' ')" > "$t/exempt_full.tsv"
  printf '%s\t1000\t2026-09-26\tcode-oversize：用例基线偏小\n' "$t/c5/grown.md" > "$t/exempt_small.tsv"
  for i in 1 2 3; do printf 'hello\n' > "$t/c6/f$i.md"; done   # 同目录 3 个小文件，用于目录阈值用例

  bash "$self" --no-exempt "$t/c1" >/dev/null 2>&1;      check "软限内小文件" 0 $?
  bash "$self" --no-exempt "$t/c2" >/dev/null 2>&1;      check "新增超硬限未登记" 1 $?
  # 注意：pipefail 下左侧脚本 rc=1 会污染整条管道（OBS-236 同族坑），故先落文件再 grep
  bash "$self" --no-exempt "$t/c2" > "$t/c2.out" 2>/dev/null || true
  grep -c UNREGISTERED "$t/c2.out" >/dev/null; check "未登记项出现在清单" 0 $?
  bash "$self" --exempt-file "$t/exempt_full.tsv" "$t/c3" >/dev/null 2>&1; check "登记后放行" 0 $?
  bash "$self" --no-exempt "$t/c4" >/dev/null 2>&1;      check "node_modules/data 目录不入统计" 0 $?
  bash "$self" --strict --exempt-file "$t/exempt_small.tsv" "$t/c5" >/dev/null 2>&1; check "strict 下已登记文件增长报警" 1 $?
  bash "$self" --exempt-file "$t/exempt_small.tsv" "$t/c5" >/dev/null 2>&1;          check "默认模式下增长不阻塞" 0 $?
  bash "$self" --exempt-file /nonexistent/x.tsv "$t/c1" >/dev/null 2>&1;             check "登记表缺失按全未登记处理" 0 $?
  bash "$self" --no-exempt "$t/c2/big_new.md" >/dev/null 2>&1;                       check "直接传文件路径可审" 1 $?
  bash "$self" --no-exempt --dir-max 2 --dir-src-max 99 "$t/c6" >/dev/null 2>&1;             check "目录超硬限默认模式不阻塞" 0 $?
  bash "$self" --no-exempt --strict --dir-max 2 --dir-src-max 99 "$t/c6" >/dev/null 2>&1;    check "目录超硬限 strict 计分" 1 $?

  mkdir -p "$t/c7" "$t/c8/exp"
  printf 'package c7\n\ntype T struct{}\n\nfunc (t *T) A() {}\nfunc (t *T) B() {}\nfunc Exported() {}\n' > "$t/c7/a.go"
  printf 'package c7\n\nfunc (t *T) C() {}\n' > "$t/c7/b.go"
  for i in 1 2 3; do printf 'hello\n' > "$t/c8/exp/f$i.md"; done   # 语料/产物目录，用于 --exclude-path 用例

  bash "$self" --no-exempt --pkg-method-max 1 "$t/c7" >/dev/null 2>&1;         check "god-package 硬限默认不阻塞" 0 $?
  bash "$self" --no-exempt --strict --pkg-method-max 1 "$t/c7" >/dev/null 2>&1; check "god-package 硬限 strict 计分" 1 $?
  bash "$self" --no-exempt --strict --dir-max 1 --dir-src-max 99 "$t/c8" >/dev/null 2>&1; check "语料目录未排除时计分" 1 $?
  bash "$self" --no-exempt --strict --dir-max 1 --dir-src-max 99 --exclude-path "$t/c8/exp/*" "$t/c8" >/dev/null 2>&1; check "语料目录按 --exclude-path 排除后放行" 0 $?
  printf '%s/c8/exp/*\n' "$t" > "$t/ex_list.txt"
  bash "$self" --no-exempt --strict --dir-max 1 --dir-src-max 99 --exclude-file "$t/ex_list.txt" "$t/c8" >/dev/null 2>&1; check "语料目录按 --exclude-file 排除后放行" 0 $?
  bash "$self" --exclude-file >/dev/null 2>&1; check "排除清单参数缺值拒绝" 2 $?
  bash "$self" --exclude-file --all >/dev/null 2>&1; check "排除清单不吞下一个选项" 2 $?
  bash "$self" --exclude-file -h >/dev/null 2>&1; check "排除清单不吞短选项" 2 $?
  bash "$self" --exclude-path >/dev/null 2>&1; check "排除路径参数缺值拒绝" 2 $?
  bash "$self" --exclude-path --all >/dev/null 2>&1; check "排除路径不吞下一个选项" 2 $?
  bash "$self" --exclude-file "$t/not-present" "$t/c1" >/dev/null 2>&1; check "指定的排除清单不存在时拒绝" 2 $?
  bash "$self" --exclude-file "$t/c1" "$t/c1" >/dev/null 2>&1; check "指定的排除清单是目录时拒绝" 2 $?
  printf 'ignored\n' > "$t/unreadable"
  chmod 000 "$t/unreadable"
  if [ ! -r "$t/unreadable" ]; then
    bash "$self" --exclude-file "$t/unreadable" "$t/c1" >/dev/null 2>&1; check "指定的排除清单不可读时拒绝" 2 $?
  fi
  chmod 600 "$t/unreadable"

  # 路径基准用例（2026-09-28 修的同款缺陷，59c3568e）：cwd ≠ 仓根时须给出与仓根调用相同的结论。
  # 修复前 wc 按仓根相对路径读、却仍在子目录 cwd 下执行 ⇒ 一个文件都读不成却 exit 0（假通过）。
  mkdir -p "$t/c9/sub"
  if git -C "$t/c9" init -q . 2>/dev/null; then
    gen_big 400 "$t/c9/sub/big.md"
    git -C "$t/c9" add -A 2>/dev/null
    # 子 shell 会切 cwd，故必须用绝对路径调用（$0 可能是相对路径）
    self_abs="$(cd "$(dirname "$self")" && pwd)/$(basename "$self")"
    (cd "$t/c9/sub" && bash "$self_abs" --no-exempt . >/dev/null 2>&1); check "子目录 cwd 调用不静默假通过" 1 $?
    mkdir -p "$t/c9/foo" "$t/c9/bar/foo"
    gen_big 400 "$t/c9/foo/root.md"
    gen_big 400 "$t/c9/bar/foo/nested.md"
    git -C "$t/c9" add -A 2>/dev/null
    (cd "$t/c9" && bash "$self_abs" --no-exempt --all --exclude-path foo --out "$t/relative.tsv" . >/dev/null 2>&1); check "仓根相对排除不掩盖其他超限" 1 $?
    grep -q 'bar/foo/nested.md$' "$t/relative.tsv"; check "保留嵌套同名目录" 0 $?
    grep -q '^.*foo/root.md$' "$t/relative.tsv"; check "排除仓根指定目录" 1 $?
    (cd "$t/c9/sub" && bash "$self_abs" --no-exempt --all --exclude-path "$t/c9/foo" --out "$t/absolute.tsv" .. >/dev/null 2>&1); check "绝对排除保留其他超限" 1 $?
    grep -q 'bar/foo/nested.md$' "$t/absolute.tsv"; check "绝对排除保留嵌套同名目录" 0 $?
    grep -q '^.*foo/root.md$' "$t/absolute.tsv"; check "绝对路径排除仓根指定目录" 1 $?
    (cd "$t/c9" && bash "$self_abs" --no-exempt --exclude-path foo foo/root.md >/dev/null 2>&1); check "显式文件遵守排除" 0 $?
    ln -s "$t/c9" "$t/c9-link"
    (cd "$t/c9" && bash "$self_abs" --no-exempt --all --exclude-path "$t/c9-link/foo" --out "$t/symlink.tsv" . >/dev/null 2>&1); check "符号链接别名保留其他超限" 1 $?
    grep -q '^.*foo/root.md$' "$t/symlink.tsv"; check "符号链接别名排除指定目录" 1 $?
    (cd "$t/c9" && bash "$self_abs" --no-exempt --exclude-path "$t/c9/foo" "$t/c9-link/foo/root.md" >/dev/null 2>&1); check "符号链接路径下显式文件遵守排除" 0 $?
    (cd "$t/c9" && bash "$self_abs" --no-exempt --exclude-path "$t/c9-link/foo/*" foo/root.md >/dev/null 2>&1); check "通配符前符号链接前缀可排除" 0 $?
    mkdir -p "$t/c9/docs"
    printf 'foo\n' > "$t/c9/docs/complexity-exclude.txt"
    printf 'bar/foo\n' > "$t/c9/.complexityignore"
    (cd "$t/c9" && bash "$self_abs" --no-exempt --all --out "$t/auto.tsv" . >/dev/null 2>&1); check "自动排除清单仍扫描其他超限" 1 $?
    grep -q 'bar/foo/nested.md$' "$t/auto.tsv"; check "优先使用 docs 排除清单" 0 $?
    grep -q '^.*foo/root.md$' "$t/auto.tsv"; check "docs 排除清单生效" 1 $?
    (cd "$t/c9/sub" && bash "$self_abs" --no-exempt --all --exclude-file ../.complexityignore --out "$t/override.tsv" .. >/dev/null 2>&1); check "显式清单覆盖自动清单" 1 $?
    grep -q '^.*foo/root.md$' "$t/override.tsv"; check "显式清单保留未排除目录" 0 $?
    grep -q 'bar/foo/nested.md$' "$t/override.tsv"; check "调用目录相对路径的显式清单生效" 1 $?
  fi

  rm -rf "$t"
  echo "-- selftest：$pass 通过 / $fail 失败 --"
  [ "$fail" -eq 0 ] || return 1
  return 0
}

CODE_WARN_KB=24; CODE_HARD_KB=48
DOC_WARN_KB=32;  DOC_HARD_KB=64
LINE_WARN=640;   LINE_HARD=800
# 目录规模双列阈值（2026-09-26 用户裁定）：Go 强制同包同目录、_test.go 无法外迁，
# 故「条目数」与「非测试文件数」分列；软限只进关注区，硬限才在 --strict 下阻塞。
DIR_MAX=80            # 条目硬限（含 _test.go）
DIR_SRC_MAX=40        # 非测试文件硬限（不含 _test.go）
DIR_SOFT_MAX=50       # 条目软限（关注区）
DIR_SRC_SOFT=25       # 非测试文件软限（关注区）
# Go 包 god-package 三指标（2026-09-27 升级为硬门禁；阈值取在长尾起点，实测全仓仅 2 个包命中）
PKG_DECL_MAX=120          # 包导出顶层声明数硬限
PKG_METHOD_MAX=150        # 单类型方法数硬限
PKG_METHOD_FILES_MAX=15   # 单类型方法散布文件数硬限
PKG_DECL_SOFT=80          # 以下三项为关注区（只提示）
PKG_METHOD_SOFT=100
PKG_METHOD_FILES_SOFT=10
TSV_TAB=$(printf '\t')
# `usage` 打印第 2 行到 header 注释最后一行（当前是第 40 行）。改 header 时同步本常量。
USAGE_END=40
# 语料/实验产物整目录排除（明示名单，规范 §三；不做名字通配，避免误伤真代码目录）
EXCLUDE_PATHS=(
  "world-agent/experiments/*"
  "world-agent/references/corpus/*"
  "product-genome/objects/*"
  "ai-content-gen/novel-gen/assets/versions/*/prompts/*"
)

usage() { sed -n "2,${USAGE_END}p" "$0" | sed 's/^# \{0,1\}//'; }

# 路径是否命中「语料/实验产物/项目级整目录排除」名单（GLOB 按 bash case 语义匹配，可指向仓根相对或绝对路径）
is_excluded_path() {
  local p="$1" pat pat_clean candidate
  for pat in ${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}; do
    [ -n "$pat" ] || continue
    pat_clean="${pat%/}"
    case "$pat" in
      /*) case "$p" in /*) candidate="$p" ;; *) candidate="$REPO_ROOT/$p" ;; esac ;;
      *)  case "$p" in /*) continue ;; *) candidate="$p" ;; esac ;;
    esac
    case "$candidate" in
      $pat|$pat_clean/*) return 0 ;;
    esac
  done
  return 1
}

ALL=0; STRICT=0; USE_EXEMPT=1; EXEMPT_FILE=""; EXCLUDE_FILE=""; OUT=""; SELFTEST=0; DIR_MAX_SET=0
ROOTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --all)          ALL=1 ;;
    --strict)       STRICT=1 ;;
    --dir-max)      shift; DIR_MAX="${1:-80}"; DIR_MAX_SET=1 ;;
    --dir-src-max)  shift; DIR_SRC_MAX="${1:-40}" ;;
    --pkg-decl-max)         shift; PKG_DECL_MAX="${1:-120}" ;;
    --pkg-method-max)       shift; PKG_METHOD_MAX="${1:-150}" ;;
    --pkg-method-files-max) shift; PKG_METHOD_FILES_MAX="${1:-15}" ;;
    --exclude-path|--exclude-file)
      opt="$1"
      if [ "$#" -lt 2 ] || [ -z "$2" ] || [[ "$2" == -* ]]; then
        echo "选项缺少参数：$opt" >&2; exit 2
      fi
      shift
      if [ "$opt" = --exclude-path ]; then EXCLUDE_PATHS+=("$1"); else EXCLUDE_FILE="$1"; fi ;;
    --no-exempt)    USE_EXEMPT=0 ;;
    --exempt-file)  shift; EXEMPT_FILE="${1:-}" ;;
    --out)          shift; OUT="${1:-}" ;;
    --selftest)     SELFTEST=1 ;;
    -h|--help)      usage; exit 0 ;;
    --*)            echo "未知选项：$1" >&2; usage >&2; exit 2 ;;
    *)              ROOTS+=("$1") ;;
  esac
  shift
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)
[ ${#ROOTS[@]} -eq 0 ] && ROOTS=("$REPO_ROOT")
[ -z "$EXEMPT_FILE" ] && EXEMPT_FILE="$REPO_ROOT/docs/complexity-exemptions.txt"
[ -z "$EXCLUDE_FILE" ] && [ -f "$REPO_ROOT/docs/complexity-exclude.txt" ] && EXCLUDE_FILE="$REPO_ROOT/docs/complexity-exclude.txt"
[ -z "$EXCLUDE_FILE" ] && [ -f "$REPO_ROOT/.complexityignore" ] && EXCLUDE_FILE="$REPO_ROOT/.complexityignore"
if [ -n "$EXCLUDE_FILE" ] && { [ ! -f "$EXCLUDE_FILE" ] || [ ! -r "$EXCLUDE_FILE" ]; }; then
  echo "排除清单不存在、不是普通文件或不可读：$EXCLUDE_FILE" >&2; exit 2
fi

if [ "$SELFTEST" -eq 1 ]; then selftest; exit $?; fi

# 路径基准归一（2026-09-28 修）：下游一律用**仓根相对**路径，故先把入参按调用时的 cwd 固化，再切仓根执行；
# 否则从子目录调用时 wc 打不开这些相对路径，错误被吞掉 ⇒ 静默「扫描 0 个文件」并 exit 0（假通过）。
to_abs() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$(pwd)" "$1" ;; esac; }
for i in "${!ROOTS[@]}"; do
  r="${ROOTS[$i]}"
  [ -d "$r" ] || [ -f "$r" ] || { echo "扫描根不存在：$r" >&2; exit 2; }
  if [ -d "$r" ]; then ROOTS[$i]="$(cd "$r" && pwd -P)"; else ROOTS[$i]="$(to_abs "$r")"; fi
done
[ -n "$OUT" ] && OUT="$(to_abs "$OUT")"
EXEMPT_FILE="$(to_abs "$EXEMPT_FILE")"
[ -n "$EXCLUDE_FILE" ] && EXCLUDE_FILE="$(to_abs "$EXCLUDE_FILE")"
cd -- "$REPO_ROOT" || { echo "无法进入仓根：$REPO_ROOT" >&2; exit 2; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/complexity-audit.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT

EXCLUDE_DESC=""
if [ -n "$EXCLUDE_FILE" ] && [ -f "$EXCLUDE_FILE" ]; then
  ex_cnt=0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    EXCLUDE_PATHS+=("$line")
    ex_cnt=$((ex_cnt + 1))
  done < "$EXCLUDE_FILE" || { echo "无法读取排除清单：$EXCLUDE_FILE" >&2; exit 2; }
  EXCLUDE_DESC="${EXCLUDE_FILE}（生效 $ex_cnt 条）"
fi

# 绝对模式先将不含通配符且已存在的目录前缀解析为物理路径；通配符及后缀保持不变。
# 例如 macOS /var 与 /private/var 或显式符号链接指向同一目录时，匹配扫描结果的路径。
for i in "${!EXCLUDE_PATHS[@]}"; do
  pat="${EXCLUDE_PATHS[$i]}"
  case "$pat" in /*) ;; *) continue ;; esac
  prefix="${pat%%[\*\?\[]*}"
  prefix="${prefix%/}"
  [ -n "$prefix" ] || prefix=/
  while [ ! -d "$prefix" ] && [ "$prefix" != / ]; do prefix="${prefix%/*}"; [ -n "$prefix" ] || prefix=/; done
  physical=$(cd "$prefix" && pwd -P) || continue
  if [ "$prefix" = / ]; then EXCLUDE_PATHS[$i]="$physical${pat#/}";
  else EXCLUDE_PATHS[$i]="$physical${pat#"$prefix"}"; fi
done

if [ "$USE_EXEMPT" -eq 1 ] && [ -f "$EXEMPT_FILE" ]; then
  grep -v -e '^#' -e '^[[:space:]]*$' "$EXEMPT_FILE" > "$tmp/exempt.tsv" || : > "$tmp/exempt.tsv"
  REG_DESC="${EXEMPT_FILE}（生效 $(wc -l < "$tmp/exempt.tsv" | tr -d ' ') 条）"
else
  : > "$tmp/exempt.tsv"
  REG_DESC="无（按『全部未登记』处理$([ "$USE_EXEMPT" -eq 0 ] && echo "，--no-exempt")）"
fi

: > "$tmp/files0"
: > "$tmp/cand0"
SRC_DESC=""
for r in "${ROOTS[@]}"; do
  if [ -f "$r" ]; then
    abs_f="$(cd "$(dirname "$r")" && pwd -P)/$(basename "$r")"
    case "$abs_f" in
      "$REPO_ROOT"/*) rel_f="${abs_f#"$REPO_ROOT"/}" ;;
      *)              rel_f="$abs_f" ;;
    esac
    SRC_DESC="$SRC_DESC $abs_f[file]"
    is_excluded_path "$rel_f" || printf '%s\0' "$rel_f" >> "$tmp/cand0"
    continue
  fi
  abs_r=$(cd "$r" && pwd -P)
  top=$(git -C "$abs_r" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$top" ]; then
    if [ "$abs_r" = "$top" ]; then
      git -C "$top" ls-files -z --cached --others --exclude-standard >> "$tmp/files0" 2>/dev/null || true
    else
      git -C "$top" ls-files -z --cached --others --exclude-standard -- "$abs_r" \
        | while IFS= read -r -d '' rel; do printf '%s\0' "$top/$rel"; done >> "$tmp/files0" 2>/dev/null || true
    fi
    SRC_DESC="$SRC_DESC $abs_r[git]"
  else
    find "$abs_r" -type d \( \
          -name .git -o -name node_modules -o -name .venv -o -name venv -o -name dist \
       -o -name build -o -name target -o -name vendor -o -name __pycache__ -o -name .next \
       -o -name .cache -o -name Pods -o -name DerivedData -o -name site-packages \
       -o -name .terraform -o -name .cargo -o -name .dart_tool \) -prune -o -type f -print0 \
      >> "$tmp/files0" 2>/dev/null || true
    SRC_DESC="$SRC_DESC $abs_r[find]"
  fi
done

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT"/}"
  is_excluded_path "$rel" && continue
  case "${rel##*/}" in
    *.md|*.markdown|*.txt|*.rst|*.adoc|*.go|*.py|*.pyi|*.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs \
    |*.swift|*.sh|*.bash|*.zsh|*.rb|*.rs|*.java|*.kt|*.kts|*.c|*.h|*.cc|*.cpp|*.hpp|*.m|*.mm \
    |*.sql|*.lua|*.php|*.cs|*.dart|*.vue|*.svelte|*.scala|*.ex|*.exs|*.html|*.css|*.scss \
    |*.toml|*.yaml|*.yml|*.json|*.ini|*.cfg|*.conf|*.tf|*.tfvars|*.plist|*.proto|*.graphql) \
      printf '%s\0' "$rel" >> "$tmp/cand0" ;;
  esac
done < "$tmp/files0"

: > "$tmp/wc.tsv"
if [ -s "$tmp/cand0" ]; then
  xargs -0 wc -c -l < "$tmp/cand0" 2>"$tmp/wc.err" > "$tmp/wc.tsv" || true
  # 防「静默 0 文件」假通过（2026-09-28 修）：候选非空却一个都没读成＝路径基准错。判据只认
  # 「成功读到数＝0」——xargs 退出码会被断链软链误伤，wc.tsv 非空也不可靠（全失败仍写 `0 0 total`）。
  opened=$(awk '/[[:space:]]total$/{next} NF{print}' "$tmp/wc.tsv" | wc -l | tr -d ' ')
  if [ "$opened" -eq 0 ]; then
    echo "❌ 内部错误：候选 $(tr -cd '\0' < "$tmp/cand0" | wc -c | tr -d ' ') 个文件、wc 一个都没读成（路径基准错？）——拒绝按『通过』返回。" >&2
    head -n 1 "$tmp/wc.err" >&2
    exit 2
  fi
fi

awk -v reg="$tmp/exempt.tsv" -v cwk="$CODE_WARN_KB" -v chk="$CODE_HARD_KB" \
    -v dwk="$DOC_WARN_KB" -v dhk="$DOC_HARD_KB" -v lw="$LINE_WARN" -v lh="$LINE_HARD" '
  BEGIN {
    OFS = "\t"
    while ((getline line < reg) > 0) {
      if (line ~ /^#/ || line ~ /^[[:space:]]*$/) continue
      n = split(line, a, "\t")
      if (n < 2 || a[1] == "") continue
      reg_bytes[a[1]] = (a[2] == "" ? "-" : a[2])
      reg_note[a[1]]  = (n >= 4 ? a[4] : "")
    }
    close(reg)
  }
  {
    s = $0
    sub(/^[[:space:]]+/, "", s)
    sub(/^[0-9]+[[:space:]]+/, "", s)
    sub(/^[0-9]+[[:space:]]+/, "", s)
    path = s
    if (path == "" || path == "total") next
    if (NF < 3) next
    lines = $1 + 0; bytes = $2 + 0
    low = tolower(path)
    if (low ~ /(^|\/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum|cargo\.lock|poetry\.lock|composer\.lock)$/) next
    if (low ~ /\.lock$/ || low ~ /\.min\.(js|css)$/ || low ~ /_pb2\.py$/ || low ~ /\.pb\.go$/) next
    if (low ~ /zz_generated/ || low ~ /_generated\./ || low ~ /\.gen\./) next
    if (low ~ /(^|\/)(gen|generated|data|datasets|reports|outputs|dist|build|vendor|node_modules|__snapshots__)\//) next
    if (low ~ /(^|\/)worker-configuration\.d\.ts$/) next
    ext = ""
    if (match(low, /\.[^.\/]+$/)) ext = substr(low, RSTART + 1)
    if (ext ~ /^(md|markdown|txt|rst|adoc)$/) { kind = "doc"; warn = dwk * 1024; hard = dhk * 1024 }
    else if (ext ~ /^(go|py|pyi|ts|tsx|js|jsx|mjs|cjs|swift|sh|bash|zsh|rb|rs|java|kt|kts|c|h|cc|cpp|hpp|m|mm|sql|lua|php|cs|dart|vue|svelte|scala|ex|exs|html|css|scss|toml|yaml|yml|json|ini|cfg|conf|tf|tfvars|plist|proto|graphql)$/) {
      kind = "code"; warn = cwk * 1024; hard = chk * 1024
    }
    else next
    lvl = "OK"; anno = ""
    if (lines > lw || bytes > warn) lvl = "WARN"
    if (lines > lh || bytes > hard) {
      lvl = "HARD"
      if (path in reg_bytes) {
        lvl = "EXEMPT"
        anno = "已登记(基线 " sprintf("%.1f", reg_bytes[path] / 1024) "KB)"
        if (reg_bytes[path] != "-" && bytes > reg_bytes[path] + 0 && reg_note[path] !~ /append-only|active-spec|evidence/) {
          lvl = "GROWTH"
          anno = "增长 +" sprintf("%.1f", (bytes - reg_bytes[path]) / 1024) "KB(基线 " sprintf("%.1f", reg_bytes[path] / 1024) "KB)"
        }
      } else {
        lvl = "UNREGISTERED"
        anno = "超硬限且未登记"
      }
    } else if (lvl == "WARN" && (path in reg_bytes)) {
      anno = "已登记(已回到软限内)"
    }
    print lvl, kind, lines, bytes, anno, path
  }
' "$tmp/wc.tsv" > "$tmp/leveled.tsv"

if [ -n "$OUT" ]; then cp "$tmp/leveled.tsv" "$OUT"; fi

show=$tmp/leveled.tsv
if [ "$ALL" -ne 1 ]; then
  awk -F'\t' '$1 != "OK"' "$tmp/leveled.tsv" > "$tmp/show.tsv"
  show=$tmp/show.tsv
fi

echo "== 复杂度审计（阈值：代码 软 ${CODE_WARN_KB}KB/硬 ${CODE_HARD_KB}KB · 文档 软 ${DOC_WARN_KB}KB/硬 ${DOC_HARD_KB}KB · 行数 软 ${LINE_WARN}/硬 ${LINE_HARD}）=="
echo "扫描根（$([ "$ALL" -eq 1 ] && echo "全量" || echo "只列超软限")）：$SRC_DESC"
echo "豁免登记：$REG_DESC"
[ -n "$EXCLUDE_DESC" ] && echo "项目排除：$EXCLUDE_DESC"
echo

awk -F'\t' '{
    line = sprintf("%-12s %-4s %6d 行 %9.1fKB  %s", $1, $2, $3, $4 / 1024, $6)
    if ($5 != "") line = line "   [" $5 "]"
    print $4 "\t" line
  }' "$show" | sort -t"$TSV_TAB" -k1,1nr | cut -f2- 

echo
awk -F'\t' '
  { n++; tot += $4; cnt[$1]++ }
  END {
    printf "扫描 %d 个手写文本文件 / %.1fMB；分级：", n, tot / 1048576
    split("HARD UNREGISTERED GROWTH EXEMPT WARN OK", ord, " ")
    for (i = 1; i <= 6; i++) printf "%s=%d%s", ord[i], cnt[ord[i]] + 0, (i < 6 ? " " : "\n")
  }
' "$tmp/leveled.tsv"
if [ "$ALL" -ne 1 ]; then
  echo "（上表只列超软限项；加 --all 看全量清单）"
fi

dir_stats=$(awk -F'\t' -v hm="$DIR_MAX" -v hsm="$DIR_SRC_MAX" -v sm="$DIR_SOFT_MAX" -v ssm="$DIR_SRC_SOFT" '
  { f = $6; p = f
    if (p ~ /\//) sub(/\/[^\/]*$/, "", p); else p = "."
    tot[p]++
    if (f !~ /_test\.go$/) src[p]++ }
  END { for (d in tot) { t = tot[d] + 0; s = src[d] + 0
          if (t > hm || s > hsm)      printf "HARD\t%d\t%d\t%s\n", t, s, d
          else if (t >= sm || s >= ssm) printf "SOFT\t%d\t%d\t%s\n", t, s, d } }
' "$tmp/leveled.tsv" | sort -t"$TSV_TAB" -k1,1 -k2,2nr -k3,3nr)
dir_hard=$(printf '%s\n' "$dir_stats" | awk -F'\t' '$1 == "HARD"')
dir_soft=$(printf '%s\n' "$dir_stats" | awk -F'\t' '$1 == "SOFT"')
dir_hard_n=$(printf '%s\n' "$dir_hard" | grep -c . || true)
dir_soft_n=$(printf '%s\n' "$dir_soft" | grep -c . || true)
echo
if [ "$dir_hard_n" -gt 0 ]; then
  echo "== 目录超限（硬限：条目 > $DIR_MAX 或 非测试文件 > ${DIR_SRC_MAX}；Go 包边界＝目录，拆包改导出面须独立立项）=="
  printf '%s\n' "$dir_hard" | awk -F'\t' '{ printf "  条目 %5d  非测试 %5d  %s\n", $2, $3, $4 }'
fi
if [ "$dir_soft_n" -gt 0 ]; then
  echo "== 目录关注区（软限：条目 ≥ $DIR_SOFT_MAX 或 非测试文件 ≥ ${DIR_SRC_SOFT}；只提示不失败）=="
  printf '%s\n' "$dir_soft" | awk -F'\t' '{ printf "  条目 %5d  非测试 %5d  %s\n", $2, $3, $4 }'
fi
if [ "$dir_hard_n" -eq 0 ] && [ "$dir_soft_n" -eq 0 ]; then
  echo "== 目录规模 ==  无超软限（条目 ≥ $DIR_SOFT_MAX / 非测试 ≥ ${DIR_SRC_SOFT}）的目录"
else
  echo "目录超硬限 $dir_hard_n 个（默认只告警；--strict 计入失败）；关注区 $dir_soft_n 个；上限用 --dir-max N / --dir-src-max N 调整"
fi

godirs="$tmp/godirs"
awk -F'\t' '$2 == "code" { p = $6; if (p ~ /\//) sub(/\/[^\/]*$/, "", p); else p = "."; print p }' \
  "$tmp/leveled.tsv" | sort -u > "$godirs"
if command -v python3 >/dev/null 2>&1; then
  pkg_stats=$(pkg_metrics "$REPO_ROOT" "$godirs" | awk -F'\t' \
    -v dm="$PKG_DECL_MAX" -v mm="$PKG_METHOD_MAX" -v fm="$PKG_METHOD_FILES_MAX" \
    -v ds="$PKG_DECL_SOFT" -v ms="$PKG_METHOD_SOFT" -v fs="$PKG_METHOD_FILES_SOFT" '
    { d = $1 + 0; m = $2 + 0; f = $3 + 0
      if (d > dm || m > mm || f > fm)         printf "HARD\t%d\t%d\t%d\t%s\t%d\t%s\n", d, m, f, $4, $5, $6
      else if (d >= ds || m >= ms || f >= fs) printf "SOFT\t%d\t%d\t%d\t%s\t%d\t%s\n", d, m, f, $4, $5, $6 }')
  pkg_hard=$(printf '%s\n' "$pkg_stats" | awk -F'\t' '$1 == "HARD"')
  pkg_soft=$(printf '%s\n' "$pkg_stats" | awk -F'\t' '$1 == "SOFT"')
  pkg_hard_n=$(printf '%s\n' "$pkg_hard" | grep -c . || true)
  pkg_soft_n=$(printf '%s\n' "$pkg_soft" | grep -c . || true)
  echo
  if [ "$pkg_hard_n" -gt 0 ]; then
    echo "== Go 包 god-package 超硬限（导出声明 > $PKG_DECL_MAX 或 单类型方法 > $PKG_METHOD_MAX 或 方法散布文件 > ${PKG_METHOD_FILES_MAX}）=="
    printf '%s\n' "$pkg_hard" | awk -F'\t' '{ printf "  导出 %4d  单类型方法 %4d（%s）  散布文件 %3d  源码 %3d  %s\n", $2, $3, $5, $4, $6, $7 }'
  fi
  if [ "$pkg_soft_n" -gt 0 ]; then
    echo "== Go 包关注区（导出声明 ≥ $PKG_DECL_SOFT 或 单类型方法 ≥ $PKG_METHOD_SOFT 或 方法散布文件 ≥ ${PKG_METHOD_FILES_SOFT}；只提示）=="
    printf '%s\n' "$pkg_soft" | awk -F'\t' '{ printf "  导出 %4d  单类型方法 %4d（%s）  散布文件 %3d  源码 %3d  %s\n", $2, $3, $5, $4, $6, $7 }'
  fi
  if [ "$pkg_hard_n" -eq 0 ] && [ "$pkg_soft_n" -eq 0 ]; then
    echo "== Go 包规模 ==  无超软限包（导出声明 ≥ $PKG_DECL_SOFT / 单类型方法 ≥ $PKG_METHOD_SOFT / 方法散布文件 ≥ ${PKG_METHOD_FILES_SOFT}）"
  else
    echo "包超硬限 $pkg_hard_n 个（默认只告警；--strict 计入失败）；关注区 $pkg_soft_n 个；上限用 --pkg-decl-max N / --pkg-method-max N / --pkg-method-files-max N 调整"
  fi
else
  pkg_hard_n=0
  echo "（跳过 Go 包 god-package 体检：未找到 python3）"
fi

unreg=$(awk -F'\t' '$1 == "UNREGISTERED"' "$tmp/leveled.tsv" | wc -l | tr -d ' ')
grow=$(awk -F'\t' '$1 == "GROWTH"' "$tmp/leveled.tsv" | wc -l | tr -d ' ')
if [ "$unreg" -gt 0 ]; then
  echo
  echo "❌ 有 $unreg 个文件超硬限且未登记 —— 按规范不得合入；要么拆分/压缩，要么在豁免登记里补登理由。"
  exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$grow" -gt 0 ]; then
  echo
  echo "⚠️  --strict：有 $grow 个已登记文件比基线继续增长（豁免不等于允许继续堆砌）。"
  exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$dir_hard_n" -gt 0 ]; then
  echo
  echo "⚠️  --strict：有 $dir_hard_n 个目录超过硬限（条目 > $DIR_MAX 或 非测试文件 > ${DIR_SRC_MAX}）。"
  exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$pkg_hard_n" -gt 0 ]; then
  echo
  echo "⚠️  --strict：有 $pkg_hard_n 个 Go 包 god-package 指标超过硬限。"
  exit 1
fi
exit 0
