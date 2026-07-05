# 模块5 挑战B:用 fuzzing 自动找崩溃

`vuln.c` 里有一个 libFuzzer 入口 `LLVMFuzzerTestOneInput(Data, Size)`,
内部藏着一条会崩溃的路径。这一关**不用你手算输入**——让 fuzzer 自己撞出来。

## 构建与运行

```bash
# 用 clang 的 libFuzzer + AddressSanitizer 编译
clang -g -fsanitize=fuzzer,address vuln.c -o vuln

# 直接运行即开始 fuzz(覆盖引导,自动变异);限时 20 秒,崩溃样本写到 findings/
mkdir -p findings
./vuln -max_total_time=20 -artifact_prefix=findings/ findings/
```

## 目标

- 让 fuzzer 触发崩溃(你会看到 `AddressSanitizer: ... overflow`),并在 `findings/` 下得到一个 `crash-*` 文件。
- 复现:`./vuln findings/crash-*`。
- 看懂崩溃:用 `od -An -tx1z findings/crash-*` 看崩溃输入,解释**为什么**会崩。

## 想一想

- 覆盖引导 fuzzing 为什么比"纯随机砸"高效?(提示:插桩 + 覆盖反馈 + 语料演化)
- 代码里那个 `memcmp(Data,"FUZZ",4)` 像一道"门"。fuzzer 怎么这么快就猜中 `FUZZ` 这 4 个字节的?
  (提示:libFuzzer 会拦截 `memcmp`/比较指令,把"差多少"作为反馈)
- 进了门之后,什么样的 `Size` 会让 `memcpy` 出事?
- 如果没有 **AddressSanitizer**,这个越界可能"静默"不崩——sanitizer 起了什么作用?

参考分析与修复在 `.solution/`;另附"换用 AFL 怎么做"。
