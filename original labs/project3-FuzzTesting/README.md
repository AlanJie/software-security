# Project 3: White Box and Black Box Fuzz Testing

这是 UMD Software Security 课程的官方 Project 3 材料。核心目标是对比两类自动化漏洞发现方法:

- Radamsa:黑盒 mutation fuzzing,只靠已有样本生成变异输入,观察程序是否崩溃。
- KLEE:白盒 symbolic execution,把输入建模成符号变量,系统探索路径并求解触发 bug 的输入。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `projects.zip` | 官方源码包,包含 `projects/3` 和复用的 `projects/1` 文件 |
| `quiz.md` | 课程 quiz 题库,包含答案和反馈,有剧透 |
| `STUDY-GUIDE.md` | 整理版学习指南 |

官方 HTML 说明页作为本地归档忽略;关键流程已整理到本 README、`STUDY-GUIDE.md` 和 `quiz.md`。

本目录保留官方压缩包,不直接展开源码。当前可运行源码已经镜像到
[../docker-p1-p3/assets/projects/3](../docker-p1-p3/assets/projects/3),并被打进 Docker / Podman 实验镜像。

## 推荐环境

官方说明假设使用 Project 1 的完整 VM,其中预装了旧版 KLEE CDE 和 Radamsa。推荐使用
[../docker-p1-p3](../docker-p1-p3) 里的轻量构建方案:

```bash
cd "../docker-p1-p3"
podman build --network host -t software-security-p1p3 .
podman run --rm -it software-security-p1p3
```

进入容器后默认目录是:

```text
/work/projects
```

Project 3 的实验文件在:

```bash
cd /work/projects/3
```

## 快速运行

先重新编译普通二进制:

```bash
build-labs
cd /work/projects/3
```

Radamsa 黑盒 fuzzing:

```bash
FUZZ_MAX=20 fuzz3.py ./wisdom-alt
FUZZ_MAX=1000 fuzz3.py ./wisdom-alt2
```

KLEE 跑 `wisdom-alt-sym.c`:

```bash
run-klee-wisdom || true
err=$(ls klee-last/*.ptr.err | tail -1)
cat "$err"
ktest-tool.cde "${err%.ptr.err}.ktest" | sed -n '1,80p'
```

KLEE 跑 `maze-sym.c`:

```bash
run-klee-maze
err=$(ls klee-last/*.assert.err | head -1)
ktest-tool.cde "${err%.assert.err}.ktest"
```

找出 maze 的全部解:

```bash
rm -rf klee-* maze-sym.bc
clang-11 -D'sleep(x)=0' -I"$KLEE_INCLUDE" \
  -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone \
  maze-sym.c -o maze-sym.bc
klee --emit-all-errors maze-sym.bc || true
ls -1 klee-last/*.assert.err
```

具体分析路径见 [STUDY-GUIDE.md](STUDY-GUIDE.md)。

## 与现有练习的关系

这个 project 适合作为模块 5 的综合练习:

- [../../labs/module5-fuzzing](../../labs/module5-fuzzing) 练的是现代 coverage-guided fuzzing / libFuzzer。
- `project3-FuzzTesting` 练的是黑盒 mutation fuzzing 和 KLEE symbolic execution。
- `wisdom-alt` 系列复用 Project 1 的漏洞程序,可以直接观察手工漏洞分析和自动化漏洞发现的差异。

建议先读 [../../notes/module5-analysis-fuzzing.md](../../notes/module5-analysis-fuzzing.md),再做本 project,最后用 `quiz.md` 核对。
