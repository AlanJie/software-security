# Software Security Roadmap

本路线覆盖 software security 的核心主题:低层内存漏洞、防御机制、Web 安全、安全设计、程序分析、fuzzing 和真实漏洞案例。模块顺序参考 UMD / Coursera Software Security 课程,并扩展了可复现实验。

> 背景:原 Coursera 课程已下架,可参考 Hicks 教授公开页面(https://mhicks.me/courses/software-security/)、讲义/PPT、录播和本仓库整理的 archived labs。

## 主题清单

### 模块 1 · 低层攻击:内存漏洞 ⬜

- [ ] 软件安全总览、威胁模型基本概念
- [ ] 进程内存布局:栈 / 堆 / 代码段 / 数据段
- [ ] 缓冲区溢出(栈溢出):返回地址覆盖原理
- [ ] 代码注入(shellcode)
- [ ] 其他内存漏洞:格式化字符串、整数溢出、堆溢出
- [ ] return-to-libc、ROP(返回导向编程)
- [ ] **缓冲区溢出 project(推荐)**:[original labs/project1-BOF](original%20labs/project1-BOF)

### 模块 2 · 低层攻击的防御 ⬜

- [ ] 内存安全(memory safety)与类型安全(type safety)
- [ ] 栈金丝雀(stack canaries)、DEP/NX、ASLR
- [ ] 控制流完整性 CFI
- [ ] 安全编码:处理不可信输入、防御性编程

### 模块 3 · Web 安全 ⬜

- [ ] Web/HTTP/浏览器安全模型
- [ ] SQL 注入、XSS、CSRF
- [ ] 会话劫持及防御

### 模块 4 · 安全软件设计与开发 ⬜

- [ ] 威胁建模、攻击面分析
- [ ] 安全需求、滥用用例(abuse cases)
- [ ] 设计原则(Saltzer & Schroeder:最小权限、失败安全默认、完全仲裁等)
- [ ] 常见设计缺陷

### 模块 5 · 程序分析与安全测试 ⬜

- [ ] 静态分析(static analysis)
- [ ] Fuzzing:黑盒 / 变异式 / 生成式 / 白盒覆盖引导(AFL 类)
- [ ] 符号执行(symbolic execution)
- [ ] 渗透测试、代码审计

### 模块 6 · 实践与案例 ⬜

- [ ] 真实案例剖析(Heartbleed 等)
- [ ] 案例复盘
- [ ] 进阶:AFL / AFL++ / fuzzingbook 实操

## 实验材料速查

每个模块配一份知识笔记(`notes/`)和可运行挑战(`labs/`)。部分实验目录包含 `.solution/` 作为参考解法与修复说明;个人临时答案使用 `answer.md`,默认不纳入 Git。

| 模块 | 知识笔记 | 动手挑战 |
| --- | --- | --- |
| 1 | [notes/x86-32-vs-64.md](notes/x86-32-vs-64.md) | [module1-bof](labs/module1-bof)(32位 ret2win)、[module1-bof64](labs/module1-bof64)(64位)、[module1-shell](labs/module1-shell)(ret2shell) |
| 2 | [notes/module2-defenses.md](notes/module2-defenses.md) | [module2-canary](labs/module2-canary)(格式化串泄露 canary → 绕过) |
| 3 | [notes/module3-web.md](notes/module3-web.md) | [module3-sqli](labs/module3-sqli)(SQL 注入登录绕过)、[project2-BadStore](original%20labs/project2-BadStore)(官方 Web 综合靶场) |
| 4 | [notes/module4-secure-design.md](notes/module4-secure-design.md) | [module4-threat-model](labs/module4-threat-model)(威胁建模纸面练习) |
| 5 | [notes/module5-analysis-fuzzing.md](notes/module5-analysis-fuzzing.md) | [module5-static](labs/module5-static)(cppcheck/scan-build)、[module5-fuzzing](labs/module5-fuzzing)(libFuzzer) |
| 6 | [notes/module6-cases.md](notes/module6-cases.md) | [module6-heartbleed](labs/module6-heartbleed)(缓冲区过读泄露) |

UMD / Coursera archived labs 见 [original labs/](original%20labs/)。目前已整理:

| 参考 project | 对应模块 | 建议定位 |
| --- | --- | --- |
| [project1-BOF](original%20labs/project1-BOF) | 模块 1 | 完成 `module1-bof` / `module1-bof64` 后的综合练习 |
| [project2-BadStore](original%20labs/project2-BadStore) | 模块 3 | 完成 `module3-sqli` 后的综合 Web 安全练习 |
| [project3-FuzzTesting](original%20labs/project3-FuzzTesting) | 模块 5 | 完成 `module5-static` / `module5-fuzzing` 后的 Radamsa + KLEE 综合练习 |

## Milestones

- **Milestone 1**:模块 1 + 缓冲区溢出 project
- **Milestone 2**:模块 2 + 模块 3
- **Milestone 3**:模块 4 + 模块 5(分析 / fuzzing)
- **Milestone 4**:模块 6 案例 + AFL / AFL++ / fuzzingbook 实操
