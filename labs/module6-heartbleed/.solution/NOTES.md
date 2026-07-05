# 参考解法说明 — mini-Heartbleed

## 漏洞
```c
unsigned int length = (hdr[1] << 8) | hdr[2];   // 长度完全由请求方决定
read(0, hb.payload, sizeof(hb.payload));         // 真实只读进 ≤32 字节
write(1, hb.payload, length);                    // 却回显 length 字节 → 过读
```
`payload[32]` 与 `secret[48]` 在同一结构体里相邻(secret 在偏移 32)。
只要 `length > 32`,`write` 就会把 payload 之后相邻的 secret 一起读出。

## 利用
请求 = `type=1` + `length=80`(大端 `00 50`)+ 1 字节 payload。
80 > 32+25,足以覆盖 payload(32)+ `FLAG{heartbleed_overread}`(25)。
回显里前 32 字节是 payload(我们的 'A' + 清零),其后即 secret。

```bash
python3 exploit.py 2>&1 >/dev/null
# [+] leaked secret: FLAG{heartbleed_overread}
```

## 与真实 Heartbleed(CVE-2014-0160)的对应
| 本挑战 | 真实 Heartbleed |
|---|---|
| 请求里的 `length` | 心跳请求里声明的 payload 长度 |
| 不校验 length ≤ 真实长度 | OpenSSL 用 `n2s` 取 length 后直接 `memcpy`,未对照实际记录长度 |
| 回显相邻 secret | 回包带出进程内存:私钥、会话 cookie、明文…… |
| 一次最多 ~80 字节 | 一次最多 ~64KB,可反复抓取 |

根因都属于:**信任了攻击者提供的长度 + 越界读(out-of-bounds read)**。

## 修复
拷贝/回显前,用**真实数据长度**夹取:
```c
ssize_t got = read(0, hb.payload, sizeof(hb.payload));   // 真实读到的字节数
if (got < 0) got = 0;
unsigned int n = length < (unsigned)got ? length : (unsigned)got;  // 不超过真实长度
write(1, hb.payload, n);
```
真实 Heartbleed 的官方修复也是同一思路:**校验声明长度不超过收到的记录长度**,否则丢弃。
教训贯穿全课:**永远不要用外部提供的长度去决定读写量**(同模块5 fuzzing 挑战的 `memcpy`)。
