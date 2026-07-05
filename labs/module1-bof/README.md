# 模块1 挑战:让程序吐出 FLAG

`vuln.c` 是一个会读取你输入的小程序。代码里有一个会打印 `FLAG{...}` 的函数,
但**正常执行流永远不会调用它**。你的任务:只通过**标准输入**,让程序打印出 FLAG。

## 构建

```bash
gcc -m32 -g -O0 -fno-stack-protector -no-pie vuln.c -o vuln
```

(编译选项已替你定好——这关不考"绕过缓解措施",专注于利用本身。
用 32 位(`-m32`)起步:返回地址布局更直观,也没有 64 位的栈对齐坑。)

## 你的产出

在本目录写 `exploit.py`,生成 payload 喂给程序:

```bash
python3 exploit.py | ./vuln
# 目标输出:FLAG{control_flow_hijacked}
```

## 规则

- 不要修改 `vuln.c`。
- 允许用 `gdb`(已装 gef)、`objdump`、`nm`、`readelf` 等工具分析二进制。
- 目标是自己想清楚"为什么"。

## 卡住了?

本目录下有个 **`.solution/`** 文件夹(本地存在,未纳入 git),里面有**分级提示**
(`HINTS.md`)和完整解法(`exploit.py` + `WALKTHROUGH.md`)。先看提示,再看答案。
