# 参考解法说明 — ret2shell

## 与上一关的唯一技术差异
目标地址从 `win`(打印 flag + exit)换成 `shell`(`system("/bin/sh")`)。
偏移、字节序、payload 结构完全一样。`nm vuln | grep ' T shell'` 取地址。

## 真正的新知识:保住 shell(stdin EOF 问题)
`python3 exploit.py | ./vuln` 时,vuln 的 stdin 是管道。payload 一写完,
管道关闭 → `/bin/sh` 读到 EOF → 立即退出,你来不及交互。

**解法:用 `cat` 续接 stdin**

```bash
(python3 exploit.py; cat) | ./vuln
```

子shell 先把 payload 喂进去,接着 `cat` 把**你键盘的输入**继续转发给 vuln 的
stdin → 转交给 `/bin/sh`。于是 shell 保持等待,你敲 `id`/`ls` 有回显。

### 为什么不是 `&& cat`
- `prog && cat`:是"prog 成功才运行 cat",且加在 `./vuln` 之后是接到**终端**,
  根本没接到 vuln 的 stdin。
- 关键是 `cat` 必须在管道的**喂入端**(`(...; cat) | ./vuln`),而不是消费端。

### 非交互验证(脚本里自测用)
```bash
(python3 exploit.py; echo "id; echo PWNED_OK; exit") | ./vuln
# 看到 uid=... 和 PWNED_OK 即成功;结尾进程崩(139)是 shell 退出后才发生,无害
```

## 32 位的便利
32 位调用约定参数走栈、无 `movaps` 对齐要求,所以直接 ret 进 `shell` 即可,
不像 64 位 ret2libc 还要处理对齐和寄存器传参。

## 再进阶(可选)
本关的 `shell()` 是程序自带的"后门函数"。真实场景没有这种函数时,要做 **ret2libc**:
自己从 libc 里找 `system` 和 `"/bin/sh"` 字符串地址拼起来(需关 ASLR 或先泄露 libc 基址)。
那是模块5/后续 pwn 的内容。
