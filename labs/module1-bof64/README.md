# 模块1 进阶 B:64 位 ret2win

和 `module1-bof` 同一个漏洞、同一个目标(跳到 `win()` 打印 FLAG),
这次用 **64 位** 编译。重点是体会 64 位与 32 位的差异。

## 构建

```bash
gcc -g -O0 -fno-stack-protector -no-pie vuln.c -o vuln
# 注意:不加 -m32,即 64 位
```

## 目标

```bash
python3 你的exploit.py | ./vuln      # 打印出 FLAG 即成功
```

## 你已经会的

- gef `pattern create` / `pattern offset` 测偏移
- `nm` / `objdump` 找 `win` 地址,小端写入

## 64 位有什么不一样(自己动手前先想想)

- 地址多长?返回地址该写几个字节、用什么打包?(`struct` 的格式符变了)
- 偏移会和 32 位一样吗?重新测一遍。
- **栈对齐**:64 位 ABI 要求 `call` 指令执行时 `rsp` 16 字节对齐。
  某些 libc 函数(尤其 `system`,也可能是 `printf`/`puts`)内部用 SSE 的 `movaps`,
  对齐不对会**崩在 libc 内部**(报错地址在 libc 里,不在你的程序)。
  如果遇到:想想怎么让进入目标函数时栈多/少偏 8 字节。(提示:一个"什么都不做"的指令)
