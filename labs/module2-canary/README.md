# 模块2 挑战:绕过栈金丝雀(canary)

这次程序**开启了栈金丝雀(stack canary)**——上一关那种直接覆盖返回地址的做法
会被检测、触发 `*** stack smashing detected ***` 而中止。你的任务是想办法**绕过**它,
仍然跳到 `win()`(打印 FLAG)。

## 构建

```bash
gcc -m32 -g -O0 -fstack-protector-all -no-pie vuln.c -o vuln
gdb -q ./vuln -ex checksec -ex quit   # 确认 Canary ✓
```

## 目标

```bash
./your_exploit.py        # 让程序打印出 FLAG{...}
```

## 程序行为

读两次输入:
1. `leak>`:把你的输入直接 `printf(输入)` 后回显;
2. `overflow>`:把你的输入读进一个栈缓冲区。

## 想一想

- 金丝雀是怎么工作的?它在栈上的什么位置、函数返回前如何被检查?
  为什么单纯覆盖返回地址会被发现?
- 第 1 步那个 `printf(输入)` 有什么问题?(关键词:格式化字符串)
  能不能用它**读出**栈上的某个值?金丝雀也在栈上……
- 如果你知道了金丝雀的当前值,第 2 步的溢出该怎么排布,才能让校验"看起来没被改动"?
- 金丝雀每次运行都变吗?所以"泄露"和"利用"必须在**同一次运行**里完成——
  你的 exploit 脚本需要先收泄露、再发 payload(想想 `subprocess` 交互)。

提示与参考解法在 `.solution/`(自己先试,卡住再看)。
