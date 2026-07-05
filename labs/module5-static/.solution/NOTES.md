# 参考结论与修复 — 静态分析

## vuln.c 的缺陷

| 行 | 缺陷 | 类型 | 后果 | cppcheck | scan-build |
|---|---|---|---|---|---|
| 8 | `strcpy(buf,"hello")` 写 6 字节进 `char buf[4]` | 栈缓冲区越界写 | 破坏栈、可被利用 | `bufferAccessOutOfBounds` | `stringop-overflow` |
| 6/10 | `malloc(8)` 给 `p` 但从不释放 | 内存泄露 | 长跑耗尽内存 | `memleak` | `deadcode.DeadStores` |
| 15/16 | `free(a)` 后 `return a[0]` | 释放后使用 (UAF) | 未定义行为、可被利用 | `deallocret` | `unix.Malloc: Use after free` |
| 14 | `malloc` 可能返回 NULL 未检查就 `a[0]=1` | 空指针解引用 | 崩溃 | `nullPointerOutOfMemory` | — |

## 两工具对比(体会误报/漏报)
- **cppcheck**:模式匹配为主,轻快,报全了越界/泄露/UAF/空指针,还给出 style 提示。
- **scan-build**(clang 分析器):基于路径/符号执行,报出 UAF 与 dead store,描述更贴近"哪条路径触发"。
- 两者**互补**:没有单一工具能全覆盖;静态分析受不可判定性限制,必然在**漏报**(放过真 bug)与**误报**(把好代码标红)之间权衡 → 工具结论要人工复核。

## 修复版
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void process(void) {
    char buf[8];                       /* 放得下 "hello\0" */
    snprintf(buf, sizeof(buf), "%s", "hello");   /* 带长度,不溢出 */
    printf("%s\n", buf);
    /* 不再无意义地 malloc;若确需,用完 free */
}

int compute(void) {
    int *a = malloc(sizeof(int) * 4);
    if (!a) return -1;                 /* 检查 NULL */
    a[0] = 1;
    int r = a[0];                      /* 先取值 */
    free(a);                           /* 再释放 */
    return r;                          /* 不在 free 后使用 a */
}
```

## 衔接
静态分析是"上线前"的廉价防线;它发现的越界/UAF 正是模块1/2/6 里被利用的漏洞类型。
与之互补的是**动态分析 / fuzzing**(挑战B):真正跑起来、用 sanitizer 把静默错误变崩溃。
