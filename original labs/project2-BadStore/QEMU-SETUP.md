# BadStore QEMU/KVM Setup

目标:不用 VirtualBox,在 Fedora WSL / Linux 环境中用 QEMU/KVM 运行官方
`BadStore_212.iso`,并让浏览器按课程要求访问 `www.badstore.net`。

## 环境确认

验证环境:

```text
Fedora Linux 44 (WSL)
QEMU emulator version 10.2.2
BeautifulSoup 4.15.0
```

已安装包:

```bash
sudo dnf install -y \
  python3-beautifulsoup4 \
  qemu-system-x86-core \
  qemu-img \
  qemu-ui-curses
```

确认 KVM:

```bash
ls -l /dev/kvm
```

如果 `/dev/kvm` 不存在,脚本会去掉 `-enable-kvm`,使用 QEMU 软件模拟。能跑,只是更慢。

## 为什么选 QEMU/KVM

官方说明使用 VirtualBox,但这个 project 的核心资产是一个 bootable ISO。QEMU/KVM
可以直接启动 ISO,保留原来的系统、Apache/CGI/MySQL 行为,比 Docker 更接近课程环境。

Docker 不适合作为第一选择,因为它不能直接运行 ISO。要用 Docker 就得把 ISO 里的服务
拆出来重建镜像,这会变成迁移工程,并可能改变老版本 Web 栈、TLS、路径和漏洞行为。

## 网络设计

官方 VirtualBox 流程是 Host-Only 网络:

```text
host browser -> host-only IP -> BadStore guest
```

当前 QEMU 流程是 user-mode forwarding:

```text
host browser -> 127.0.0.1:80/443 -> QEMU slirp -> BadStore guest:80/443
```

同时在 `/etc/hosts` 加:

```text
127.0.0.1 www.badstore.net
```

这样浏览器可以访问:

```text
http://www.badstore.net/
```

端口只绑定在 `127.0.0.1`,不会暴露到局域网。

## 启动

推荐用脚本:

```bash
cd "original labs/project2-BadStore"
./start-qemu.sh
```

脚本做的事:

- 如果 `/etc/hosts` 没有 `www.badstore.net`,追加 `127.0.0.1 www.badstore.net`;
- 使用 `qemu-system-i386` 启动 `BadStore_212.iso`;
- 使用 `rtl8139` 网卡模型。该模型能让 BadStore 的老 Linux 正常加载网卡;
- 转发 guest `80 -> 127.0.0.1:80`,guest `443 -> 127.0.0.1:443`;
- 写入 pidfile: `/tmp/badstore-qemu.pid`;
- 写入串口日志: `/tmp/badstore-qemu.serial.log`;
- 创建 monitor socket: `/tmp/badstore-qemu.monitor`。

核心 QEMU 命令等价于:

```bash
sudo qemu-system-i386 \
  -name badstore-project2 \
  -m 512 \
  -enable-kvm \
  -cdrom BadStore_212.iso \
  -boot d \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:80-:80,hostfwd=tcp:127.0.0.1:443-:443 \
  -device rtl8139,netdev=net0 \
  -display none \
  -serial file:/tmp/badstore-qemu.serial.log \
  -monitor unix:/tmp/badstore-qemu.monitor,server,nowait \
  -pidfile /tmp/badstore-qemu.pid \
  -daemonize
```

## 验证

BadStore 启动需要一点时间。原文提到 DHCP 可能卡两三分钟;当前验证环境通常几十秒内可用。

用 curl 验证时要绕过本地代理:

```bash
curl --noproxy '*' http://www.badstore.net/
```

成功时会看到:

```html
<TITLE>BadStore.net - Redirect to Home Page</TITLE>
```

也可以直接打开:

```text
http://www.badstore.net/cgi-bin/badstore.cgi
```

## 停止

```bash
./stop-qemu.sh
```

或手动:

```bash
sudo kill "$(sudo cat /tmp/badstore-qemu.pid)"
```

## 现代环境注意

- 浏览器或 shell 如果配置了 HTTP proxy,要把 `www.badstore.net` 加到 no-proxy/直连列表。
  如果浏览器访问时看到 `502 Bad Gateway`,优先检查这一项。当前验证环境中:

  ```bash
  curl http://www.badstore.net/
  ```

  会走 `http_proxy=http://127.0.0.1:7890` 并返回 502;而下面这样绕过代理后正常:

  ```bash
  curl --noproxy '*' http://www.badstore.net/cgi-bin/badstore.cgi
  ```

  浏览器里对应的修复是把 `www.badstore.net` 加到代理软件的 DIRECT/绕过规则。如果浏览器
  在 Windows 侧运行,还需要在 Windows 的 hosts 文件中加入
  `127.0.0.1 www.badstore.net`;WSL 里的 `/etc/hosts` 只影响 WSL 内进程。
  如果设置 no-proxy 后从 502 变成 timeout,通常就是 Windows hosts 还没生效:

  ```powershell
  Resolve-DnsName www.badstore.net
  ```

  如果结果不是 `127.0.0.1`,用管理员权限打开 PowerShell 后执行:

  ```powershell
  Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "`n127.0.0.1 www.badstore.net"
  ipconfig /flushdns
  ```

  临时绕过域名也可以访问:

  ```text
  http://127.0.0.1/cgi-bin/badstore.cgi
  ```

  但课程里的绝对链接和 cookie 练习更适合用 `www.badstore.net` 域名。
- BadStore 的 HTTPS 很老,Apache 是 `1.3.28`,OpenSSL 是 `0.9.7c`。现代 curl/浏览器
  可能拒绝旧 TLS/legacy renegotiation。课程提示里也说某些流程切到 HTTPS 后,
  可以手动把 URL 改回 HTTP。
- 如果端口 80/443 被占用,先停掉占用服务,或者临时改脚本里的 `BADSTORE_HTTP_PORT`
  和 `BADSTORE_HTTPS_PORT`,例如:

  ```bash
  BADSTORE_HTTP_PORT=8080 BADSTORE_HTTPS_PORT=8443 ./start-qemu.sh
  ```

  这种情况下访问 `http://www.badstore.net:8080/`,但部分绝对链接可能仍指向默认 80。
- 如果 `curl` 连接超时,先等一分钟;仍不行再查看 QEMU 是否在跑:

  ```bash
  sudo cat /tmp/badstore-qemu.pid
  ps -ef | grep qemu-system-i386
  ss -ltnp '( sport = :80 or sport = :443 )'
  ```

## 官方文章内容摘要

官方 HTML 主要讲:

- BadStore 是 Linux-based server application,以 bootable ISO 分发;
- VirtualBox 设置选择 Linux / 32-bit Ubuntu,512 MB RAM 即可;
- CD-ROM 挂载 `BadStore_212.iso`,并删除空的 CD/DVD 项;
- Host-Only DHCP 常见地址是 `192.168.56.110`;
- host 的 hosts 文件要把 `www.badstore.net` 指向 guest IP;
- 推荐 Firefox Developer Tools,重点用 View Source、Page Inspector、Network 和 cookie 工具;
- exploit 任务覆盖隐藏权限字段、SQL injection、supplier 权限、previous orders、admin、
  XSS cookie 读取、session/cart cookie 结构和购物车金额篡改。
