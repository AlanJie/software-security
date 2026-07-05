# 模块2:低层攻击的防御

模块1 学了怎么打(覆盖返回地址、ret2win/ret2shell)。这一模块反过来:
现代系统用哪些**缓解措施**让这些攻击变难,它们各自防什么、怎么被绕过。
核心心态:**没有任何单一措施是绝对的;它们提高成本,纵深叠加才有效。**

---

## 1. 栈金丝雀 Stack Canary

在局部变量与"saved ebp / 返回地址"之间放一个随机值(canary / cookie),
函数返回前检查它有没有被改动。溢出要覆盖返回地址,必然先踩坏 canary → 检测到 → 中止。

- 开关:`-fstack-protector` / `-fstack-protector-all`(开,默认常开);`-fno-stack-protector`(关)。
- 32 位 canary 低字节固定 `\x00`,防止字符串函数把它整体读/写出去。
- **绕过**:信息泄露拿到 canary 值后**原样填回**(见 `labs/module2-canary` 挑战);
  或不经返回地址改写(改写函数指针、覆盖局部变量等)。

## 2. NX / DEP(不可执行栈)

把栈、堆等数据区标记为**不可执行**,于是"往栈里塞 shellcode 再跳过去"失效。

- 开关:默认开;`-z execstack` 关闭(让栈可执行)。
- **绕过**:不注入代码,而是**复用已有代码**——ret2libc、**ROP**(返回导向编程):
  把多个以 `ret` 结尾的小片段(gadget)串起来完成任意逻辑。

## 3. ASLR(地址空间布局随机化)

每次运行随机化栈、堆、共享库、(PIE 时)程序自身的基址,让攻击者**猜不到地址**。

- 开关(系统级):`/proc/sys/kernel/randomize_va_space`(2 全开 / 0 关);
  单进程 `setarch -R ./prog`;gdb 默认对被调试进程关闭。
- 32 位熵低,可**爆破**;64 位熵高,通常需先**泄露**一个地址再算基址。
- 注意:**非 PIE 程序的代码段地址不随机**(模块1 的 ret2win 正因此免疫 ASLR)。

## 4. PIE(位置无关可执行)

让**程序自身**也能被 ASLR 随机化(配合 ASLR)。非 PIE 时代码地址固定、好打。

- 开关:`-pie`(开,现代默认)/ `-no-pie`(关)。
- 影响:开 PIE 后,连 `win`、gadget 的地址都要先泄露才能用。

## 5. RELRO(只读重定位)

把 GOT(全局偏移表)等重定位数据在启动后设为只读,防"改 GOT 表项劫持控制流"。

- `partial`(部分,默认)/ `full`(`-Wl,-z,relro,-z,now`,GOT 全只读)。

## 6. CFI(控制流完整性)

在**间接跳转/调用**前检查目标是否合法(在预先计算的合法目标集合里),
让 ROP/改函数指针难以跳到任意位置。代表:clang `-fsanitize=cfi`、Intel CET(影子栈)。

## 7. 安全编码 / 处理不可信输入(最根本)

上面都是"亡羊补牢";根因是**无边界写**和**误信输入**。从源头消除:

- 用带长度的接口:`fgets`/`snprintf`/`strncpy`(并自己保证 `\0` 收尾),别用 `gets`/`strcpy`/`sprintf`。
- 格式化字符串永远写 `printf("%s", s)`,**不要** `printf(s)`(否则就是模块2挑战里的洞)。
- 校验所有长度/索引/整数范围(防越界、整数溢出)。
- 最小信任:对外部输入默认不可信。

---

## 缓解措施速查

| 措施 | 防什么 | gcc 开/关 | 典型绕过 |
|---|---|---|---|
| Canary | 覆盖返回地址 | `-fstack-protector(-all)` / `-fno-stack-protector` | 泄露后填回 |
| NX/DEP | 栈上 shellcode | 默认开 / `-z execstack` | ret2libc / ROP |
| ASLR | 猜地址 | `randomize_va_space` | 泄露地址 / 32位爆破 |
| PIE | 程序自身地址固定 | `-pie` / `-no-pie` | 泄露程序基址 |
| RELRO | 改 GOT | `-z relro,now` | full 下改不动 GOT |
| CFI | 间接跳转到任意处 | `-fsanitize=cfi` / CET | 受限,较难 |

> 配套实验:`labs/module2-canary`(开启 canary,用格式化字符串泄露后绕过)。
> 想直观看到各措施状态:`gdb -q ./prog -ex checksec -ex quit`(gef 内置)。
