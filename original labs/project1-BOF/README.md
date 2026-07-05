# Project 1: Buffer Overflow

这是 UMD Software Security 课程的官方 Project 1 材料。核心程序是
`wisdom-alt.c`:一个维护 "wisdom" 链表的小程序,里面故意放了多个内存安全漏洞。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `wisdom-alt.c` | 官方实验源码,包含漏洞目标 |
| `runbin.sh` | 把转义字符串输入转换为真实字节后喂给程序 |
| `quiz.md` | 课程 quiz 题库,包含答案和反馈,有剧透 |
| `STUDY-GUIDE.md` | 整理版学习指南 |

## 构建

官方源码首行给出的构建命令是:

```bash
gcc -fno-stack-protector -ggdb -m32 wisdom-alt.c -o wisdom-alt
```

推荐使用下面这个学习命令:`-O0` 让栈帧和反汇编更直观,`-no-pie`
让函数和全局变量地址更稳定:

```bash
gcc -O0 -fno-stack-protector -ggdb -m32 -no-pie wisdom-alt.c -o wisdom-alt
```

如果使用较新的 GCC,`gets()` 的隐式声明可能会被当作编译错误。这个实验就是要研究
危险 API,可以临时加上:

```bash
gcc -O0 -fno-stack-protector -ggdb -m32 -no-pie \
  -Wno-implicit-function-declaration \
  wisdom-alt.c -o wisdom-alt
```

如果缺少 32 位编译环境,需要先安装 `gcc-multilib` / 32 位 libc 开发包。

## 运行

```bash
./wisdom-alt
```

程序菜单:

```text
1. Receive wisdom
2. Add wisdom
Selection >
```

如果要输入包含 `\xNN` 的 payload,可以使用官方脚本:

```bash
chmod +x runbin.sh
./runbin.sh < payload.txt
```

## 与现有练习的关系

这个 project 比 [../../labs/module1-bof](../../labs/module1-bof) 更综合:

- `module1-bof` 只练习最小的返回地址覆盖。
- `project1-BOF` 同时覆盖:
  - `gets(wis)` 导致的栈缓冲区溢出;
  - `ptrs[s]` 缺少边界检查导致的函数指针数组越界;
  - 通过地址计算让程序调用本不该调用的函数;
  - 小端序地址写入;
  - GDB 中观察栈变量、全局变量和函数地址。

具体做法见 [STUDY-GUIDE.md](STUDY-GUIDE.md),里面补了两条路线:

- GEF 路线:用 `checksec`、`pattern create/search`、断点和表达式计算完成分析。
- `dmesg + objdump` 路线:不用调试器,通过崩溃日志定位返回地址偏移,通过反汇编找目标函数地址。

建议把它作为模块 1 的收束 project,完成后再进入 canary / ASLR / DEP 等防御内容。
