# Project 1/3 Docker Environment

这个目录把 UMD Project 1 和 Project 3 做成 Docker / Podman 实验环境。当前版本不再保存 OVA 里提取出的 891 MB KLEE CDE 目录,而是在构建时从远端拉取 KLEE、Radamsa 和 GEF。

## 结论

Project 1 和 Project 3 很适合放进 Docker:

- 它们主要依赖用户态 C 程序、Radamsa、KLEE,不需要完整桌面 VM。
- Project 2 BadStore 是网络靶场 ISO,仍然更适合 QEMU/KVM。
- Project 1 的漏洞程序仍按课程需要编译成 32 位 i386 ELF;容器本身使用官方 KLEE amd64 镜像。

已确认:

- `mooc-vm3.ova` 内含 `mooc-vm3-disk1.vmdk`,root 分区是 `/dev/sda1` ext3。
- 原 VM 使用的是 KLEE CDE,创建时间 `2011-05-25`,LLVM `2.7`,`llvm-gcc` `4.2.1`。
- 原 VM 的 Radamsa 是 `0.3`。
- 当前 Dockerfile 使用官方 `docker.io/klee/klee:2.3` 镜像,KLEE `2.3`,LLVM `11.0.0`。
- 当前 Dockerfile 从 Google Code Archive 下载并编译 Radamsa `0.3`,tarball SHA256 为 `17131a19fb28e5c97c28bf0b407a82744c251aa8aedfa507967a92438cd803be`。
- 当前 Dockerfile 下载 GEF `2022.01`,SHA256 为 `a6b9698cdb06eefeb0a2b6ce9d31e706e75e151b4006be8d90cdcaf7f9afa1f1`;这个版本兼容 KLEE 2.3 镜像里的 GDB 8.1.1 / Python 3.6。
- `wisdom-alt-sym.c` 可触发课程要求的 `wisdom-alt-sym.c:60` 越界错误。
- `maze-sym.c` 在现代 KLEE 下通过编译参数把 `sleep(1)` 置为 no-op,可生成 306 个测试用例。

当前验证环境已经安装并验证 Podman:

- `podman version 5.8.3`
- 镜像: `localhost/software-security-p1p3:latest`
- 镜像大小约 `5.96 GB`;这是官方 KLEE 基础镜像带来的本地镜像大小,不是需要提交到 git 的大小。
- Project 1/3 可以在容器内编译、fuzz、KLEE、GEF 调试。
- 原始 `mooc-vm3.ova` 已删除,`.extracted/` 也不再需要提交。

## 目录说明

| 文件 | 用途 |
| --- | --- |
| `assets/projects` | Project 1/3 的课程文件,从现有镜像恢复的小型构建资产 |
| `extract-from-ova.sh` | 备用取证脚本:从 `../mooc-vm3.ova` 提取 Project 1/3、KLEE CDE、Radamsa |
| `Dockerfile` | 基于官方 KLEE 镜像重新构建实验镜像 |
| `tools/fuzz3.py` | Python 3 版 fuzz runner,替代官方 Python 2 `fuzz.py` |
| `tools/build-labs` | 在容器内用默认选项重新编译 Project 1/3 |
| `tools/run-klee-wisdom` | 在容器内跑 `wisdom-alt-sym.c` |
| `tools/run-klee-maze` | 在容器内跑 `maze-sym.c` |

`.extracted/` 是旧方案的大文件目录,约 891 MB。当前远端拉取方案不需要它,也不建议提交它。

当前目录的构建上下文约百 KB 级别;本地生成的镜像和中间层不需要提交到 git。

## 1. 备用: 从 OVA 重新取证

日常构建镜像不需要执行本节。只有当你想重新核对官方 VM 内容时,才需要重新把 `mooc-vm3.ova` 放回 `original labs/` 并执行本节。

在宿主机执行:

```bash
cd "original labs/docker-p1-p3"
./extract-from-ova.sh
```

如果缺少工具:

```bash
sudo dnf install -y libguestfs-tools-c
```

Debian / Ubuntu 主机对应包名通常是 `libguestfs-tools`。

提取完成后应看到:

```text
.extracted/projects
.extracted/klee-cde-package
.extracted/radamsa-0.3
```

## 2. 重新构建镜像

当前目录可以直接从 Dockerfile 重新构建。构建时会从远端拉取:

```text
docker.io/klee/klee:2.3
https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/ouspg/radamsa-0.3.tar.gz
https://raw.githubusercontent.com/hugsy/gef/2022.01/gef.py
```

本地必须存在:

```text
assets/projects
tools/fuzz3.py / tools/run-* / tools/build-labs
```

Podman:

```bash
podman build --network host -t software-security-p1p3 .
```

这里使用 `--network host` 是为了兼容通过宿主机 `127.0.0.1:7890` 代理访问外网的 WSL/Podman 环境。普通 Podman build 网络里,容器内的 `127.0.0.1` 不是 WSL 宿主机,apt 可能失败。

如果网络直连可用,也可以关闭代理注入:

```bash
podman build --http-proxy=false -t software-security-p1p3 .
```

Docker:

```bash
docker build -t software-security-p1p3 .
```

Dockerfile 默认从 pinned GitHub URL 下载 GEF。如果想禁用 GEF:

```bash
podman build --network host --build-arg INSTALL_GEF=0 -t software-security-p1p3 .
```

## 3. 启动、进入、结束容器

当前环境使用 Podman。Podman 命令和 Docker 基本兼容,如果你用 Docker Desktop,把下面命令里的 `podman` 换成 `docker` 即可。

Podman 不需要启动 Docker daemon;这里说的“启动/结束 Docker”实际是启动/停止实验容器。

### 一次性进入容器

这种方式适合快速试命令。退出 shell 后容器会自动删除:

调试 Project 1 时需要 ptrace 权限:

```bash
podman run --rm -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  software-security-p1p3
```

退出容器:

```bash
exit
```

进入后默认目录是:

```text
/work/projects
```

### 后台启动一个可反复进入的容器

这种方式适合持续做 Project 1/3。容器名固定为 `p1p3-lab`:

```bash
podman run -d \
  --name p1p3-lab \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  software-security-p1p3 \
  tail -f /dev/null
```

进入已运行容器的命令行:

```bash
podman exec -it p1p3-lab bash
```

从容器 shell 退出但不停止容器:

```bash
exit
```

查看容器状态:

```bash
podman ps
podman ps -a
```

停止容器:

```bash
podman stop p1p3-lab
```

如果 `podman stop` 等待时间较长,可以直接强制删除:

```bash
podman rm -f p1p3-lab
```

重新启动已停止的容器:

```bash
podman start p1p3-lab
podman exec -it p1p3-lab bash
```

删除容器:

```bash
podman rm p1p3-lab
```

强制停止并删除:

```bash
podman rm -f p1p3-lab
```

### Docker 等价命令

如果你使用 Docker,命令形式相同:

```bash
docker run -d \
  --name p1p3-lab \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  software-security-p1p3 \
  tail -f /dev/null

docker exec -it p1p3-lab bash
docker stop p1p3-lab
docker start p1p3-lab
docker rm p1p3-lab
```

注意:删除容器会删除容器内部的临时改动。当前实验源码已经打进镜像;如果你想长期保存自己在容器里生成的文件,不要 `rm` 这个命名容器,或者把结果复制回宿主机。

## 4. Project 1

重新编译:

```bash
build-labs
cd /work/projects/1
file wisdom-alt-rebuilt
```

默认编译选项是:

```bash
-m32 -O0 -no-pie -fno-stack-protector -include /usr/local/include/legacy-gets.h
```

其中 `-m32` 让漏洞程序保持 32 位 i386 ABI;`-O0 -no-pie` 对齐我们前面 Project 1 的做法;`-fno-stack-protector` 避免现代编译器的栈保护提前终止实验;`legacy-gets.h` 只是补回现代 glibc 头文件里缺失的 `gets` 声明。

GEF 调试:

```bash
gdb ./wisdom-alt-rebuilt
```

镜像默认已经安装 GEF,启动 `gdb` 时会自动加载。如果镜像构建时禁用了 GEF,同一命令会退回普通 GDB。

objdump / dmesg 路线仍然可用:

```bash
objdump -d ./wisdom-alt-rebuilt | grep write_secret
dmesg | tail
```

注意:容器内读取 `dmesg` 可能被宿主机内核策略限制。如果看到 `Operation not permitted`,用 GEF/GDB 查看崩溃地址更稳。

## 5. Project 3: Radamsa

```bash
build-labs
cd /work/projects/3
fuzz3.py ./wisdom-alt
fuzz3.py ./wisdom-alt2
```

预期现象:

- `wisdom-alt` 很快崩溃,通常第一轮就能触发。
- `wisdom-alt2` 修掉了菜单越界,Radamsa 默认 1000 轮通常找不到第二个 bug。

可以调整轮数:

```bash
FUZZ_MAX=5000 fuzz3.py ./wisdom-alt2
```

## 6. Project 3: KLEE

`wisdom-alt-sym.c`:

```bash
cd /work/projects/3
run-klee-wisdom || true
err=$(ls klee-last/*.ptr.err | tail -1)
cat "$err"
ktest-tool.cde "${err%.ptr.err}.ktest" | sed -n '1,80p'
```

`maze-sym.c`:

```bash
cd /work/projects/3
run-klee-maze
err=$(ls klee-last/*.assert.err | head -1)
ktest-tool.cde "${err%.assert.err}.ktest"
```

如果要列出 maze 的全部 4 条 assert 路径,需要显式加 `--emit-all-errors`:

```bash
cd /work/projects/3
rm -rf klee-* maze-sym.bc
clang-11 -D'sleep(x)=0' -I"$KLEE_INCLUDE" \
  -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone \
  maze-sym.c -o maze-sym.bc
klee --emit-all-errors maze-sym.bc || true
ls -1 klee-last/*.assert.err
```

KLEE 的 include 路径已经设成:

```text
/home/klee/klee_src/include
```

为了兼容旧笔记,镜像里保留了 `klee.cde` 和 `ktest-tool.cde` wrapper,实际调用的是现代 KLEE 2.3 的 `klee` 和 `ktest-tool`。

## 7. 常见问题

不要给当前镜像加 `--platform linux/386`。容器镜像本身是 amd64;Project 1/3 的漏洞二进制通过 `-m32` 编译成 32 位。

如果 Docker/Podman 提示无法运行 32 位程序,确认宿主机支持 i386 用户态。当前 Fedora WSL + Podman 验证环境可用。

如果 GDB/GEF 无法 attach 或调试异常,确认 `podman run` / `docker run` 带了:

```bash
--cap-add=SYS_PTRACE --security-opt seccomp=unconfined
```

如果 `dmesg` 在容器内不可读,这是宿主机内核限制,不是实验程序本身的问题。Project 1 的地址确认优先用 GEF/GDB 和 `objdump`。

如果想精确复刻 2011 KLEE CDE,需要回到 OVA 或旧 `.extracted/klee-cde-package` 方案。当前默认方案使用官方 KLEE 2.3 Docker 镜像,不是旧 CDE 包。

## 8. 已验证结果

容器内已验证:

- `klee --version` 和 `klee.cde --version` 输出 KLEE 2.3 / LLVM 11.0.0。
- `radamsa -V` 输出 Radamsa 0.3。
- `build-labs` 可编译 Project 1/3,生成 32 位 `EXEC` 非 PIE 二进制。
- `fuzz3.py ./wisdom-alt` 在短轮次内触发 crash。
- `fuzz3.py ./wisdom-alt2` 在短轮次内未触发 crash。
- `run-klee-wisdom` 检测到 `wisdom-alt-sym.c:60` 的 out-of-bound pointer。
- `run-klee-maze` 正常结束,默认找到 1 条 assert 路径;加 `--emit-all-errors` 后找到 4 条 assert 路径。
- `gdb ./wisdom-alt-rebuilt` 会加载 GEF,断点能命中 `main`。
