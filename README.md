# Software Security Labs

一个面向 software security 基础训练的通用仓库,包含核心知识笔记、可复现实验、漏洞复现代码和参考课程材料。部分路线与实验参考 Michael Hicks / UMD / Coursera 的 Software Security 课程。

## 路线图

仓库按主题模块组织,从内存漏洞到防御、Web 安全、程序分析和真实案例:

1. 低层漏洞:缓冲区/栈溢出、代码注入、格式化字符串(含缓冲区溢出 project)
2. 防御技术:内存/类型安全、栈金丝雀、ASLR、DEP、不可信输入处理
3. 安全开发与分析:威胁建模、静态分析、符号执行、**fuzzing**
4. Web 安全:SQLi、XSS、会话劫持
5. 进阶 fuzzing:AFL/AFL++ + fuzzingbook

详细路线见 [PLAN.md](PLAN.md)。

## 仓库结构

| 内容 | 位置 |
|---|---|
| 实验记录 / 复盘 | [reports/](reports/) |
| 动手实验 / 漏洞复现代码 | [labs/](labs/) |
| UMD / Coursera 参考实验材料 | [original labs/](original%20labs/) |
| 知识笔记 | [notes/](notes/) |
| 推荐路线图 | [PLAN.md](PLAN.md) |

## 版本控制约定

- `labs/**/.solution/` 会纳入 Git,作为公开参考解法与修复说明。
- `labs/**/answer.md` 仍作为个人临时答案忽略。
- 普通本地数据库文件默认忽略;`labs/module3-sqli/users.db` 是 SQL 注入实验的种子数据库,会纳入 Git。


## 参考

- UMD / Coursera Software Security: https://www.coursera.org/learn/software-security
- Michael Hicks course materials: https://mhicks.me/courses/software-security/
- fuzzingbook:https://www.fuzzingbook.org
- Awesome Fuzzing:https://github.com/cpuu/awesome-fuzzing
