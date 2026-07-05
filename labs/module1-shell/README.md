# 模块1 进阶 A:ret2shell(拿真实交互 shell)

承接 `module1-bof`。这次目标不是打印 FLAG,而是劫持控制流去执行一个能
**spawn `/bin/sh`** 的函数,并真正拿到一个可交互的 shell。

## 文件

- `vuln.c` — 同样的栈溢出,但程序里多了一个 spawn shell 的函数(从不被正常调用)
- 参考解法见本地 `.solution/`(不纳入 git)

## 构建

```bash
gcc -m32 -g -O0 -fno-stack-protector -no-pie vuln.c -o vuln
```

## 目标

```bash
# 让下面这条跑出一个能输入命令的 shell:
./your_exploit_here
# 验证:在 shell 里执行 id / ls 有回显
```

## 你已经掌握的(来自上一关)

- 用 gef `pattern offset` 测返回地址偏移
- 用 `nm` / `objdump` 找目标函数地址,小端写入

## 这一关新增的难点

- 找到并跳到那个 spawn shell 的函数(而不是 win/flag)
- **shell 一闪而过怎么办?** 想想:`payload | ./vuln` 时,shell 的 stdin 是什么?
  写完 payload 管道就 EOF 了,shell 会立刻退出。怎么让它保持等待你的输入?
