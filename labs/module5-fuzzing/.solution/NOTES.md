# 参考分析与修复 — fuzzing

## 崩溃根因
```c
char buf[16];
if (Size >= 4 && memcmp(Data, "FUZZ", 4) == 0) {
    memcpy(buf, Data, Size);   // Size 可远大于 16 → 栈缓冲区溢出
    return buf[Size % 16];
}
```
当输入以魔数 `FUZZ` 开头、且总长 `Size > 16` 时,`memcpy` 把 `Size` 字节拷进 16 字节的栈数组 → **栈缓冲区越界写**。AddressSanitizer 在越界那一刻报 `stack-buffer-overflow`。

最小崩溃输入:`FUZZ` + 任意 ≥13 字节(总长 ≥17)。例如实测 crash 样本 17 字节,头 4 字节 `46 55 5a 5a` = `FUZZ`。

## 为什么 fuzzer 找得快
- **覆盖引导**:`-fsanitize=fuzzer` 给每个分支插桩;输入触达新分支就被保留进语料,再变异 → 逐步深入。
- **比较插桩 / memcmp 拦截**:libFuzzer 拦截 `memcmp`,把"还差几个字节匹配"当作梯度反馈,
  所以 4 字节魔数几乎瞬间被解出(否则纯随机要 2^32 次)。
- **ASan**:把"静默的内存越界"变成"立刻崩溃 + 精确报告",fuzzer 才知道"这是个 bug"。

## 修复
```c
int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    char buf[16];
    if (Size >= 4 && memcmp(Data, "FUZZ", 4) == 0) {
        size_t n = Size < sizeof(buf) ? Size : sizeof(buf);  // 夹取长度
        memcpy(buf, Data, n);
        return buf[n ? n - 1 : 0];
    }
    return 0;
}
```
根治:拷贝前**夹取/校验长度**,绝不让外部长度决定写入量(同模块6 Heartbleed 的教训)。

## 换用 AFL 怎么做(导师的 AFL 路线)
libFuzzer 是"进程内、随程序编译"的 fuzzer;AFL/AFL++ 是"独立进程 + 插桩"的 fuzzer,
也是导师让你撸的方向。等价做法:
```bash
# 把同样的逻辑包成读 stdin/文件的普通程序,然后:
afl-cc -o vuln vuln_main.c          # 或 afl-clang-fast,编译插桩
mkdir in && printf 'FUZZ' > in/seed  # 种子语料(给个魔数前缀做提示)
afl-fuzz -i in -o out -- ./vuln @@   # @@ 表示用文件喂入
```
AFL 源码在 `~/AILearning/AFL`(可 `make` 构建;老版本在 gcc16 下可能要小改)。
延伸阅读:fuzzingbook.org(覆盖引导/变异/语法 fuzzing 的原理与代码)。
