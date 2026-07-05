# Project 2: BadStore

这是 UMD Software Security 课程的官方 Project 2 材料。BadStore 是一个故意脆弱的
Web 商店靶场,官方说明使用 VirtualBox 启动 `BadStore_212.iso`;本仓库提供 QEMU/KVM
运行方式。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `BadStore_212.iso` | 官方 bootable ISO |
| `a4b414f6-9ee3-49a3-b503-cdf0e8ad1177.htm` | 官方 project 说明页 |
| `quiz.md` | 整理后的课程 quiz,包含答案和反馈,有剧透 |
| `QEMU-SETUP.md` | QEMU/KVM 安装、启动、验证与排错记录 |
| `STUDY-GUIDE.md` | 学习路线与注意事项 |
| `start-qemu.sh` | 启动 BadStore VM |
| `stop-qemu.sh` | 停止 BadStore VM |

## 官方说明要点

用 BeautifulSoup 读取官方 HTML 后,核心流程是:

1. 创建一台 Linux 32-bit VM。
2. 把 `BadStore_212.iso` 挂到 CD-ROM。
3. 使用 Host-Only 网络,让 host 浏览器能访问 guest。
4. 在 host 的 hosts 文件中把 `www.badstore.net` 指向 BadStore VM。
5. 用 Firefox Developer Tools 查看页面源码、表单、cookies 和网络请求。
6. 完成 SQL injection、隐藏表单字段、权限提升、XSS、cookie 解码/篡改等题目。

当前 QEMU 方案不使用 Host-Only 网段,而是把 guest 的 80/443 转发到
`127.0.0.1:80/443`,再把 `www.badstore.net` 映射到 `127.0.0.1`。这样更适合 WSL,
也不会把脆弱靶场暴露到局域网。

## 快速使用

```bash
cd "original labs/project2-BadStore"
./start-qemu.sh
curl --noproxy '*' http://www.badstore.net/
```

浏览器打开:

```text
http://www.badstore.net/
```

停止:

```bash
./stop-qemu.sh
```

如果浏览器开了代理,需要把 `www.badstore.net` 加到直连/绕过代理列表。
