# 参考解法说明 — canary 泄露 + 绕过

## 核心思想
栈金丝雀(canary)是放在"局部变量"和"saved ebp / 返回地址"之间的一个随机值。
函数返回前会检查它有没有被改动:溢出覆盖返回地址时,必然先覆盖掉 canary,
校验失败 → `__stack_chk_fail` → `*** stack smashing detected ***` 中止。

**绕过前提:你得知道 canary 的当前值**,把它**原样填回**,校验就以为没被动过。
本关用第 1 步的格式化字符串漏洞把 canary 泄露出来。

## 实测数据(本二进制)
反汇编 `vulnerable()`:
```
mov eax, gs:0x14 ; mov [ebp-0xc], eax   → canary 在 ebp-0xc
lea eax, [ebp-0x70]                      → buf 在 ebp-0x70
```
- buf → canary = 0x70-0xc = **100** 字节
- buf → 返回地址([ebp+4]) = 0x70+4 = **116** 字节
- `win` = `0x080483a6`(`nm vuln | grep ' T win'`)

## 第 1 步:定位泄露索引
发 `ABCD%1$p.%2$p...` 找到打印出 `0x44434241`("ABCD")的是 **%6$p** → 指向 buf 开头。
canary 在 buf+100 字节 = +25 个 dword → 索引 = 6+25 = **%31$p**。
gdb 核对:`%31$p` 的值 == `[ebp-0xc]` 处 canary,且每次运行随机、末字节为 `0x00`
(32 位 canary 的低字节固定是 `\x00`,用来吞掉字符串读取意外越界)。

## 第 2 步:溢出布局
```
[ 100 × 'A' ][ canary(4) ][ 12 × 'B' ][ win(4) ]
  填到canary    原样填回      填到ret      改写返回地址
```
返回地址在偏移 116;canary 与 ret 之间还隔 12 字节(ebp-8、ebp-4、saved ebp)。
**必须用 `read()`**(不是 fgets):canary 含 `\x00`,fgets 遇 `\0`/换行会截断。

## 完整流程
见 `exploit.py`:`subprocess` 交互——先收 `leak>`、发 `%31$p`、解析 canary,
再收 `overflow>`、发上面布局的 payload。验证输出:`done` + `FLAG{canary_bypassed}`。

## 防御角度(本模块重点)
- canary 能挡"覆盖返回地址",但**挡不住信息泄露 + 精确改写**。纵深防御才靠谱。
- 真正的根因是**格式化字符串漏洞**与**无边界写**:`printf("%s", buf)`(而非 `printf(buf)`)
  + 用带长度的安全读取,可直接消除本关的两个洞。
