# UMD 官方实验材料

这里放 UMD / Coursera Software Security 的 archived lab materials。原则是:

- **原始材料不改动**:保留官方源码、脚本、quiz,方便和课程说明逐字对照。
- **整理文档另写**:新增 README / STUDY-GUIDE 只做导航、解释和运行建议。
- **先做自建 labs,再做官方 project**:自建 labs 更小、更线性;官方 project 更接近综合场景。

## 版本控制约定

- 官方 `quiz.md`、`quiz-zh.md`、源码、脚本、Project 2 的 `BadStore_212.iso`、Project 3 的 `projects.zip` 会纳入 Git。
- 官方 HTML 说明页(`*.htm` / `*.html`)作为本地归档忽略;对应内容已整理到各 project 的 README、STUDY-GUIDE 和 quiz 文件。
- Project 1/3 的容器构建文件保存在 [docker-p1-p3](docker-p1-p3);本地生成的镜像、临时展开目录和运行目录不纳入 Git。

## 当前材料

| 目录 | 对应主题 | 用途 |
| --- | --- | --- |
| [project1-BOF](project1-BOF) | Buffer overflow / control-flow hijacking | UMD 官方 Project 1,适合作为模块 1 的综合练习 |
| [project2-BadStore](project2-BadStore) | Web security / BadStore | UMD 官方 Project 2,适合作为模块 3 的综合 Web 安全练习 |
| [project3-FuzzTesting](project3-FuzzTesting) | Fuzzing / symbolic execution | UMD 官方 Project 3,适合作为模块 5 的 Radamsa + KLEE 练习 |
| [docker-p1-p3](docker-p1-p3) | Docker environment | Project 1/3 的 Podman/Docker 环境,构建时远端拉取 KLEE、Radamsa、GEF |

## 推荐顺序

1. 先完成 [labs/module1-bof](../labs/module1-bof):最小 32 位 ret2win。
2. 再完成 [labs/module1-bof64](../labs/module1-bof64):理解 64 位偏移和栈对齐。
3. 然后做 [project1-BOF](project1-BOF):官方综合题,包含栈溢出和函数指针数组越界。
4. Web 安全模块可做 [project2-BadStore](project2-BadStore):SQL injection、XSS、cookie 与权限控制。
5. 分析与 fuzzing 模块可做 [project3-FuzzTesting](project3-FuzzTesting):Radamsa 黑盒 fuzzing 和 KLEE 白盒符号执行。
6. 如果不想长期使用完整课程 VM,用 [docker-p1-p3](docker-p1-p3) 构建 Project 1/3 的可复现实验环境。

各 project 的 `quiz.md` 是带答案和反馈的题库,建议最后核对时再看。
