# 模块5:程序分析与安全测试

怎么**自动**发现前面那些漏洞?这一模块连接程序分析、fuzzing 和漏洞发现实践。
三大类方法:静态分析、动态分析 / fuzzing、符号执行。

---

## 1. 静态分析(Static Analysis)

**不运行程序**,直接分析源码 / 中间表示(IR),靠数据流、控制流、模式匹配找可疑点。

- 优点:覆盖所有代码路径(包括很少执行的)、上线前就能跑、快。
- 缺点:受不可判定性限制,必然在**漏报(false negative)**与**误报(false positive)**间权衡——结论要人工复核。
- 工具:`cppcheck`(轻量、模式)、`clang scan-build`(符号执行/数据流,更深)、Coverity、CodeQL。
- 动手:`labs/module5-static`(用两个工具找越界/泄露/UAF/空指针,体会互补与误报)。

## 2. 动态分析与 Fuzzing(★ 重点)

**真正运行程序**,喂大量输入观察是否崩溃/异常。Fuzzing = 自动生成海量输入去"砸"程序。

### 三种生成方式

| 方式 | 思路 | 适合 |
|---|---|---|
| 黑盒/纯随机 | 乱造输入 | 简单,但很难过"校验门" |
| 变异式 mutation | 在已有样本上随机改 | 通用,AFL 默认 |
| 生成式 generation | 按格式/语法造结构化输入 | 复杂格式(协议、编译器) |

### 覆盖引导(coverage-guided)——现代 fuzzing 的核心
给程序**插桩**记录每次执行覆盖了哪些分支;**保留**触达新覆盖的输入进语料池,再对它变异。
于是 fuzzer 像"爬山"一样逐步钻进深层代码,而不是原地乱撞。代表:**AFL/AFL++**、**libFuzzer**。

- **AFL / AFL++**:独立进程 + 编译期插桩(`afl-cc`),喂文件/ stdin;经典、社区大,适合深入 coverage-guided fuzzing。
- **libFuzzer**:进程内,和程序一起用 `clang -fsanitize=fuzzer` 编译,写一个 `LLVMFuzzerTestOneInput` 入口即可;快、适合库函数。
- **Sanitizer(ASan/UBSan)**:把"静默的内存/未定义错误"变成"立即崩溃 + 精确报告",
  是 fuzzing 的"眼睛"——没有它,很多越界不崩、fuzzer 看不见。
- 动手:`labs/module5-fuzzing`(libFuzzer 几秒内自动撞出栈溢出;附 AFL 等价做法)。

## 3. 符号执行(Symbolic Execution)

把输入当作**符号变量**,沿程序路径收集约束(path constraints),用约束求解器(SMT)解出
"能走到某条路径 / 触发某 bug"的具体输入。

- 优点:能"定向"到达深层、稀有路径(fuzzing 靠运气的地方它靠求解)。
- 缺点:**路径爆炸**(分支随路径指数增长)、对复杂库/系统调用建模难。
- 工具:**angr**(Python,可按需安装)、KLEE。
- 常与 fuzzing 结合(concolic / 混合执行):fuzzing 跑得快,符号执行帮它过"难的门"。

---

## 速查

| 方法 | 跑程序吗 | 强项 | 弱点 | 工具 |
|---|---|---|---|---|
| 静态分析 | 否 | 覆盖全、早 | 误报/漏报 | cppcheck, scan-build, CodeQL |
| Fuzzing | 是 | 真崩溃、可扩展 | 难过校验门、看运气 | AFL/AFL++, libFuzzer |
| 符号执行 | 符号地 | 定向到稀有路径 | 路径爆炸 | angr, KLEE |

> **进阶路线**:fuzzing 是自动发现漏洞的主力,适合作为深入 AFL/AFL++ 和真实漏洞挖掘的起点。
> 路线建议:先用 libFuzzer 建立直觉(`labs/module5-fuzzing`)→ 再跑 AFL/AFL++ 并阅读核心源码
> → 读 fuzzingbook.org 理解覆盖引导/变异/语法 fuzzing 的原理。
