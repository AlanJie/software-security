# 分级提示(从弱到强,按需逐条看)

> 假设按 README 用 `-m32` 编的 32 位程序。尽量只看到能让你动起来的那一条就停。

## H1 — 方向

程序把输入读进一个**固定大小的栈缓冲区**,但读取的字节数远多于缓冲区容量。
想想:多出来的字节覆盖了栈上的什么?函数返回时会发生什么?

## H2 — 找到关键偏移

你需要知道:从输入第 0 字节,到"函数返回时会跳去的那个地址(`$eip`)"之间隔了多少字节。
别数源码——用工具测。gef 的 `pattern create` + 崩溃后 `pattern offset $eip`:
喂入模式让它崩,`$eip` 会被模式里的某 4 字节覆盖,gef 反查出偏移。

## H3 — 跳到哪里

有个函数打印 FLAG 但从不被调用。拿它的地址:`nm vuln | grep win` 或 `objdump -d vuln`。
因为 `-no-pie`,这个地址**每次运行固定**,直接写进 payload(32 位是**小端 4 字节**)。

## H4 — 拼 payload

```python
payload = b"A"*OFFSET + p32(win)        # 32 位用 4 字节地址(struct '<I')
```

喂进去:`python3 exploit.py | ./vuln`。

## H5 — 看不到 FLAG?

管道下 stdout 是全缓冲——本题 win() 里调了 `exit()` 会 flush,正常能看到。
若你换成 64 位(不加 `-m32`)还崩在 libc 内部,那是**栈对齐**坑,见 WALKTHROUGH「64 位差异」。

具体数值见 `exploit.py`,完整推导见 `WALKTHROUGH.md`。
