# Project 3 学习指南

目标:理解黑盒 fuzzing 和白盒 symbolic execution 在同一组 C 程序上的差异,并能解释为什么 KLEE 能找到 Radamsa 默认配置较难触发的路径。

## 进入容器

本 project 使用 [../docker-p1-p3](../docker-p1-p3) 里的 `software-security-p1p3` 镜像。先在宿主机确认镜像已构建:

```bash
cd "../docker-p1-p3"
podman build --network host -t software-security-p1p3 .
```

一次性进入容器:

```bash
podman run --rm -it software-security-p1p3
```

进入后切到 Project 3 目录并重新编译普通二进制:

```bash
cd /work/projects/3
build-labs
```

如果想保留一个可反复进入的容器:

```bash
podman run -d --name p1p3-lab software-security-p1p3 tail -f /dev/null
podman exec -it p1p3-lab bash
```

退出容器 shell 用 `exit`;停止并删除后台容器用 `podman rm -f p1p3-lab`。如果使用 Docker,把命令里的 `podman` 换成 `docker`。

## 先读代码

当前可运行源码在容器内 `/work/projects/3`,宿主机镜像副本在
[../docker-p1-p3/assets/projects/3](../docker-p1-p3/assets/projects/3)。

| 文件 | 代码点 | 关注问题 |
| --- | --- | --- |
| `wisdom-alt.c` | `ptrs[s]` 没有边界检查 | 非 `1` / `2` 的菜单输入会让程序把越界内存当函数指针调用 |
| `wisdom-alt.c` | `gets(wis)` | 仍然存在栈缓冲区溢出 |
| `wisdom-alt2.c` | `if(s == 1 || s == 2)` | 修复 Project 1 里函数指针数组越界的问题 |
| `wisdom-alt-sym.c` | `klee_make_symbolic(buf, ...)` | 把菜单输入变成符号变量 |
| `wisdom-alt-sym.c` | `sym_gets()` + `klee_range()` | 用符号字节模拟 `gets()` 输入 |
| `maze-sym.c` | `klee_make_symbolic(program, ...)` | 把整段移动序列变成符号输入 |
| `maze-sym.c` | `klee_assert(0)` | 用 assertion failure 标记找到终点的路径 |
| `maze-sym.c` | `if (maze[y][x] != ' ' && ...)` | 额外条件允许穿墙,这是 maze bug |

## 方法 A:Radamsa 黑盒 fuzzing

Radamsa 不理解程序结构,只会基于 `fuzzinput` 变异输入。官方脚本是 Python 2 风格的 `fuzz.py`;当前容器提供 Python 3 版 `fuzz3.py`,逻辑等价,并支持用环境变量调整轮数和 seed。

在容器内运行:

```bash
build-labs
cd /work/projects/3
FUZZ_MAX=20 fuzz3.py ./wisdom-alt
FUZZ_MAX=1000 fuzz3.py ./wisdom-alt2
```

预期现象:

- `wisdom-alt` 很快崩溃。官方 quiz 记录为 1 轮;当前 Python 3 helper 受进程轮询时机影响,日志可能显示在第 1 或第 2 次输入后发现 crash。
- `wisdom-alt2` 默认 1000 轮通常不崩溃,因为菜单下标已经限制为 `1` 或 `2`。
- `wisdom-alt2` 仍然有 `gets(wis)` 的栈溢出,但随机变异输入必须先稳定进入 `put_wisdom()` 再构造足够长的 payload,黑盒 mutation fuzzing 默认配置不容易做到。

可以固定或调整 Radamsa seed:

```bash
FUZZ_SEED=12458341 FUZZ_MAX=50 fuzz3.py ./wisdom-alt
FUZZ_SEED=12458342 FUZZ_MAX=5000 fuzz3.py ./wisdom-alt2
```

要能解释的问题:

1. 为什么 `wisdom-alt` 中任意非 `1` / `2` 输入都可能很快触发问题?
2. 为什么给 `ptrs[s]` 加边界检查后,Radamsa 变得不容易发现剩下的 `gets()` bug?
3. 黑盒 fuzzer 看到的信号是什么?它知道源码里的 `gets()` 吗?

## 方法 B:KLEE 跑 `wisdom-alt-sym.c`

KLEE 把输入变成符号变量,沿着分支收集路径约束。`wisdom-alt-sym.c` 对原程序做了几处适配:

- 引入 `<klee/klee.h>`。
- 用 `klee_make_symbolic(buf, sizeof(buf), "buf")` 代替 `read()`。
- 用 `klee_range(-1, sizeof(buf), "r")` 建模读取长度。
- 用 `klee_range(0, 255, "v")` 建模菜单选择。
- 用 `sym_gets()` 和多次名为 `input` 的符号值模拟 `gets()`。
- 去掉无限循环,让 KLEE 只探索一次菜单输入。

当前 Docker 环境的快捷命令:

```bash
cd /work/projects/3
run-klee-wisdom || true
```

预期会看到:

```text
KLEE: ERROR: wisdom-alt-sym.c:60: memory error: out of bound pointer
```

定位错误路径和符号对象:

```bash
err=$(ls klee-last/*.ptr.err | tail -1)
cat "$err"
ktest-tool.cde "${err%.ptr.err}.ktest" | sed -n '1,80p'
```

当前验证环境中错误路径文件通常是 `test000132.ptr.err`,但编号不应硬编码。`ktest-tool` 输出里能看到 `buf`、`r`、`v` 和多个 `input` 对象。课程 quiz 的官方答案重点接受 `buf` 和 `r`,因为它问的是 path condition 中的符号变量。

官方 VM 的旧命令大致是:

```bash
export PATH=$HOME/klee-cde-package/bin/:$PATH
llvm-gcc.cde -I../../klee-cde-package/cde-root/home/pgbovine/klee/include \
  --emit-llvm -c -g wisdom-alt-sym.c
klee.cde -exit-on-error wisdom-alt-sym.o
```

当前 Dockerfile 使用官方 `klee/klee:2.3` 镜像,所以 helper 实际执行的是现代命令:

```bash
clang-11 -I"$KLEE_INCLUDE" -emit-llvm -c -g -O0 \
  -Xclang -disable-O0-optnone \
  wisdom-alt-sym.c -o wisdom-alt-sym.bc
klee -exit-on-error wisdom-alt-sym.bc
```

## 方法 C:KLEE 跑 `maze-sym.c`

`maze.c` 是一个用 `w` / `a` / `s` / `d` 控制移动的迷宫程序。`maze-sym.c` 把整个移动序列 `program` 变成符号变量,当到达 `#` 时调用 `klee_assert(0)`,让成功路径以 `.assert.err` 的形式出现在 `klee-last` 中。

先跑默认 helper:

```bash
cd /work/projects/3
run-klee-maze
err=$(ls klee-last/*.assert.err | head -1)
ktest-tool.cde "${err%.assert.err}.ktest"
```

如果只关心全部解,用 `--emit-all-errors`:

```bash
rm -rf klee-* maze-sym.bc
clang-11 -D'sleep(x)=0' -I"$KLEE_INCLUDE" \
  -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone \
  maze-sym.c -o maze-sym.bc
klee --emit-all-errors maze-sym.bc || true
```

查看所有成功路径:

```bash
for err in klee-last/*.assert.err; do
  kt="${err%.assert.err}.ktest"
  echo "== $kt =="
  ktest-tool.cde "$kt" | grep "object 0: data"
done
```

当前验证环境能得到 4 个 assert 路径,对应的有效移动前缀包括:

```text
sddwddddsddw
ssssddddwwaawwddddsddw
sddwddddssssddwwww
ssssddddwwaawwddddssssddwwww
```

`ktest-tool` 可能在有效前缀后显示 `\xff` 或 `\x00` 填充。回答 quiz 时只取前面的 `s` / `d` / `w` / `a` 移动序列。

## Maze 穿墙 bug

关键代码在 `maze-sym.c` 的条件判断:

```c
if (maze[y][x] != ' '
    &&
    !((y == 2 && maze[y][x] == '|' && x > 0 && x < W)))
```

第一行本来表示“目标格不是空格就阻止移动”。后面额外加的条件把 `y == 2` 且目标是 `|` 的情况放行了,所以玩家可以在特定行穿过墙。

修复时把条件收回到只检查空格:

```c
if (maze[y][x] != ' ')
```

再跑 `klee --emit-all-errors maze-sym.bc`,成功路径数量应减少。课程 quiz 接受 bug 行号 `112` 或 `113`,因为错误条件跨了这两行。

## 环境注意

- 官方 `fuzz.py` 是 Python 2 写法;当前容器使用 `fuzz3.py`。
- 官方说明使用 `llvm-gcc.cde` / `klee.cde`;当前容器保留 `klee.cde` wrapper,实际调用 KLEE 2.3。
- `maze-sym.c` 原代码每一步 `sleep(1)`,在 symbolic execution 下会拖慢运行。当前 helper 编译时使用 `-D'sleep(x)=0'`。
- KLEE 可能打印 `undefined reference to function: write/strlen/strcpy` 这类 warning。只要生成目标 `.ptr.err` / `.assert.err`,本实验可继续分析。
- `quiz.md` 已经包含答案,建议完成实验后再打开核对。

## 完成标准

完成这个 project 后,你应该能用自己的话解释:

- 黑盒 mutation fuzzing 和 symbolic execution 的输入生成方式有何不同;
- 为什么 Radamsa 能快速找到 `wisdom-alt` 的函数指针越界,但默认配置难以找到 `wisdom-alt2` 的栈溢出;
- KLEE 如何通过 `klee_make_symbolic` / `klee_range` 生成可触发错误的路径;
- 如何用 `ktest-tool` 从 `.ktest` 文件中读出具体输入;
- 为什么 maze 会有 4 条“解”,以及哪段条件允许玩家穿墙。
