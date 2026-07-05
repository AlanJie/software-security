# 模块6 挑战:mini-Heartbleed(缓冲区过读)

复刻 Heartbleed(CVE-2014-0160)的核心 bug:一个"心跳"服务**回显你请求的长度**,
却不检查这个长度是否超过它实际拥有的数据。内存里 `payload` 缓冲区紧邻一段 `secret`。
你的任务:**让服务把相邻的 secret 泄露出来。**

## 构建

```bash
gcc -g -O0 vuln.c -o vuln
```

## 协议(从 stdin 读)

```
[1 字节 type][2 字节 length,大端][payload 字节...]
```
服务会回显 `length` 字节的 payload。

## 目标

构造一个请求,让回显内容里出现 `FLAG{...}`(它本不属于你的 payload)。

```bash
printf '<你的请求字节>' | ./vuln | od -An -c
```

## 想一想

- 服务到底信任了谁给的 `length`?它检查过这个 `length` 和你**真实发送的 payload 长度**的关系吗?
- 如果你只发很短的 payload,却把 `length` 填得很大,服务会从哪里"多读"出字节来?
- `payload` 和 `secret` 在内存里相邻意味着什么?
- 这正是真实 Heartbleed 的逻辑:攻击者声称"我的心跳数据有 64KB",服务就回 64KB——
  把进程内存(含私钥、会话)一起带出来。

参考解法、与真实漏洞的对应、以及修复在 `.solution/`。
