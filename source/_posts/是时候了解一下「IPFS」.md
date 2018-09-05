---
title: 是时候了解一下「IPFS」
date: 2018-05-30 11:12:51
cover: https://static.oschina.net/uploads/img/201702/15131818_XMsT.png
author: 
  nick: Richardwei
  link: https://github.com/richardwei195
tags:
  - Web
  - Http
  - IPFS
  - Tech
---

# 背景

IPFS (**InterPlanetary File System**) 中文名是 「星际文件系统」，由 Juan Benet 在2014年5月份发起，Protocol Labs 实验室维护和发展。

> **IPFS本质上是一种内容可寻址、版本化、点对点超媒体的分布式存储、传输协议，目标是补充甚至取代过去20年里使用的超文本媒体传输协议（HTTP），希望构建更快、更安全、更自由的互联网时代。**


<!-- more -->

# 既然目标是为了替代 HTTP，解释一下现有 HTTP 协议所存在的一些"缺点":

>  我们不能说这些问题就是http协议的缺点，更应该理解为不足或者相比之下的劣势点 

1. 传统的中心化架构依赖单个服务器、有限的集群以及 Internet 主干网
2. 容易遭受 DDOS 攻击(亦或是自然灾害、战争导致的)，出现单点故障
3. 比较浪费带宽
4. 中心化相比之下的低效率
5. 不可追述文件的修改历史



# IPFS 的几个特点？

1. **内容可寻址**:  通过文件内容生成唯一的哈希标识，一定程度上节约了空间开销的成本

   > 内容寻址会通过唯一的标识去访问，并且提前检验这个标识是否已经被存储过。如果被存储过，直接从其它节点读取它，不需要重复存储，一定意义上节约了空间。HTTP 协议的寻址则是只关心 IP 下的某个主机中的某个目录，并不关心文件是否相同。

2. **文件切片**

   > 放到 IPFS 节点中的文件，会根据其内容生成出唯一的加密哈希值，我们不需要关心文件的存储路径或者名字，可以将一个大文件进行切片存储，使用的时候并行下载多个切片文件(并行速度大于串行速度)，最后本地拼装成一个完整的文件进行使用，比如我们想看一部电影。

3. **去中心化，区块链技术，分布式网络结构**

   > 区块链的本质是分布式账本，本身的瓶颈之一就是账本的存储能力，目前大部分公链的最大问题是没法存储大量的超媒体数据在自己的链上

   ![51t621zg47045r97!1200](51t621zg47045r97!1200.jpeg)

4. **哈希加密存储，安全保证**

   > 基于SFS（自认证系统）命名体系

5. **CDN加速**

6. **版本化：可追溯文件修改历史，类似于git**

 

 

# 无法预测 IPFS 的未来? 至少先玩一玩

> 官方教程: https://ipfs.io/docs/getting-started/

1. 环境配置:

- 系统: mac OS 10.13.4
- IPFS版本:  v0.4.15 for OS X 64bit
- 终端: iTerm2
- Shell: zsh

2. [下载地址](https://dist.ipfs.io/#go-ipfs)，针对不同平台下载对应版本，省略下载及安装步骤

3. 解压下载好的压缩文件

   ```shell
   tar -zxvf go-ipfs_v0.4.15_darwin-amd64.tar.gz
   ```

解压后的文件有:

```shell
➜  go-ipfs ls
LICENSE    README.md  build-log  install.sh ipfs
```

解压后的文件已经默认为我们生成了一个安装脚本，充满好奇心，我们 `cat` 查看一下:

```shell
#!/bin/sh
#
# Installation script for ipfs. It tries to move $bin in one of the
# directories stored in $binpaths.

INSTALL_DIR=$(dirname $0)

bin="$INSTALL_DIR/ipfs"
binpaths="/usr/local/bin /usr/bin"

# This variable contains a nonzero length string in case the script fails
# because of missing write permissions.
is_write_perm_missing=""

for binpath in $binpaths; do
  if mv "$bin" "$binpath/$bin" 2> /dev/null; then
    echo "Moved $bin to $binpath"
    exit 0
  else
    if [ -d "$binpath" -a ! -w "$binpath" ]; then
      is_write_perm_missing=1
    fi
  fi
done

echo "We cannot install $bin in one of the directories $binpaths"

if [ -n "$is_write_perm_missing" ]; then
  echo "It seems that we do not have the necessary write permissions."
  echo "Perhaps try running this script as a privileged user:"
  echo
  echo "    sudo $0"
  echo
fi

exit 1
```



文件头的注释解释得很清晰了: 

> Installation script for ipfs. It tries to move $bin in one of the directories stored in $binpaths.
>
> bin="$INSTALL_DIR/ipfs" 
>
> binpaths="/usr/local/bin /usr/bin"

将当前目录下的 `ipfs` 可执行文件移动至 `/usr/local/bin` 文件夹中，其实翻译过来也就是:

`mv ipfs /usr/local/bin/ipfs`

结束之后，执行以下 `ipfs -h` 查看是否安装成功，顺利的话，应该是如下内容:

```shell
USAGE
  ipfs - Global p2p merkle-dag filesystem.

  ipfs [--config=<config> | -c] [--debug=<debug> | -D] [--help=<help>] [-h=<h>] [--local=<local> | -L] [--api=<api>] <command> ...

SUBCOMMANDS
  BASIC COMMANDS
    init          Initialize ipfs local configuration
    add <path>    Add a file to IPFS
    cat <ref>     Show IPFS object data
    get <ref>     Download IPFS objects
    ls <ref>      List links from an object
    refs <ref>    List hashes of links from an object

  DATA STRUCTURE COMMANDS
    block         Interact with raw blocks in the datastore
    object        Interact with raw dag nodes
    files         Interact with objects as if they were a unix filesystem
    dag           Interact with IPLD documents (experimental)

  ADVANCED COMMANDS
    daemon        Start a long-running daemon process
    mount         Mount an IPFS read-only mountpoint
    resolve       Resolve any type of name
    name          Publish and resolve IPNS names
    key           Create and list IPNS name keypairs
    dns           Resolve DNS links
    pin           Pin objects to local storage
    repo          Manipulate the IPFS repository
    stats         Various operational stats
    p2p           Libp2p stream mounting
    filestore     Manage the filestore (experimental)

  NETWORK COMMANDS
    id            Show info about IPFS peers
    bootstrap     Add or remove bootstrap peers
    swarm         Manage connections to the p2p network
    dht           Query the DHT for values or peers
    ping          Measure the latency of a connection
    diag          Print diagnostics

  TOOL COMMANDS
    config        Manage configuration
    version       Show ipfs version information
    update        Download and apply go-ipfs updates
    commands      List all available commands

  Use 'ipfs <command> --help' to learn more about each command.

  ipfs uses a repository in the local file system. By default, the repo is
  located at ~/.ipfs. To change the repo location, set the $IPFS_PATH
  environment variable:

    export IPFS_PATH=/path/to/ipfsrepo

  EXIT STATUS

  The CLI will exit with one of the following values:

  0     Successful execution.
  1     Failed executions.
```



4. 初始化本地节点

安装完毕后，我们需要在本地建立一个 `IPFS` 节点以提供访问

```shell
> go-ipfs ipfs init
initializing IPFS node at /Users/jiangwei/.ipfs
generating 2048-bit RSA keypair...done
peer identity: QmPTSkPhYHqfimiDDU3X4GYmUHYW4pzUKBd1ufo6eivste
to get started, enter:

	ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
```

执行该条命令之后, `cli` 已经在我们用户组下创建了 `~/.ipfs` 文件夹以供存放相关数据(包括节点数据)

`cd ~/.ipfs` 进去看一下：

```bash
➜  .ipfs ls
blocks         datastore      keystore
config         datastore_spec version
```

`blocks、datastore、datastore_spec` 显然就是存放节点数据的地方，暂时不深入探究和查看。

我们可以在 `config` 文件里查看 `IPFS` 的相关配置:

```shell
{
    "Identity": 自认证数据
    "Datastore"：数据仓库，默认存放 10GB数据
    "Addresses"
    "Routing"
    "Gateway"
    "API"： ...地址、网关及API等配置
    ...省略
}
```



执行 `ipfs init` 后告诉我们的命令: 

```shell
➜  .ipfs ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
Hello and Welcome to IPFS!

██╗██████╗ ███████╗███████╗
██║██╔══██╗██╔════╝██╔════╝
██║██████╔╝█████╗  ███████╗
██║██╔═══╝ ██╔══╝  ╚════██║
██║██║     ██║     ███████║
╚═╝╚═╝     ╚═╝     ╚══════╝

If you're seeing this, you have successfully installed
IPFS and are now interfacing with the ipfs merkledag!

 -------------------------------------------------------
| Warning:                                              |
|   This is alpha software. Use at your own discretion! |
|   Much is missing or lacking polish. There are bugs.  |
|   Not yet secure. Read the security notes for more.   |
 -------------------------------------------------------

Check out some of the other files in this directory:

  ./about
  ./help
  ./quick-start     <-- usage examples
  ./readme          <-- this file
  ./security-notes
```

没错，到这里我们已经成功安装完毕 `IPFS` 可以愉快的折腾了。



5. 入网上线

启动后台程序:

```shell
➜  .ipfs ipfs daemon
Initializing daemon...
Swarm listening on /ip4/127.0.0.1/tcp/4001
Swarm listening on /ip4/127.94.0.1/tcp/4001
Swarm listening on /ip4/192.168.0.116/tcp/4001
Swarm listening on /ip6/::1/tcp/4001
Swarm listening on /ip6/fdbe:9257:c1d1:9ff4:b155:28b:c98d:e31f/tcp/4001
Swarm listening on /p2p-circuit/ipfs/QmPTSkPhYHqfimiDDU3X4GYmUHYW4pzUKBd1ufo6eivste
Swarm announcing /ip4/127.0.0.1/tcp/4001
Swarm announcing /ip4/127.94.0.1/tcp/4001
Swarm announcing /ip4/192.168.0.116/tcp/4001
Swarm announcing /ip6/::1/tcp/4001
Swarm announcing /ip6/fdbe:9257:c1d1:9ff4:b155:28b:c98d:e31f/tcp/4001
API server listening on /ip4/127.0.0.1/tcp/5001
Gateway (readonly) server listening on /ip4/127.0.0.1/tcp/8080
Daemon is ready
```



如何验证或者访问呢，打开浏览器输入 `http://localhost:5001/webui`，成功访问并查看UI界面

![WX20180530-095025@2x](WX20180530-095025@2x.png)

是的没错，我们已经在地球上一座名叫上海的城市建立了我们自己的IPFS节点(: 果然是星际文件系统~)

6. 上传文件至节点并查看

我们仅尝试通过UI界面上传文件(吐槽一下UI界面还是有很多BUG)，我们可以通过`ipfs add` 命令将文件添加至本地节点

>  小本子记一下: **如果没有启动后台程序，通过 ipfs add 添加后的文件，仅仅是存储在本地节点并未同步至IPFS网络，血泪的教训-。-，同步至ipfs.io节点，我们需要开启后台程序: ipfs daemon**



点击 Files > Upload > you file 上传至本地节点，成功后右键查看并复制生成的唯一 `hash`

![WX20180530-100202@2x](WX20180530-100202@2x.png)



浏览器中打开输入`http://localhost:8080/ipfs/Qmay5SpLXHq8Up4VkHwu3D4pEkcyFkXsPAebrrSaAmVo84`可以成功的查看我们上传好的文件(Demo是图片，能够直接预览)

查看 `ipfs.io ` 节点是否同步成功:

http://ipfs.io/ipfs/Qmay5SpLXHq8Up4VkHwu3D4pEkcyFkXsPAebrrSaAmVo84 顺利的话我们能查看到如下预览图:

![宣传图-项目统计 copy](宣传图-项目统计 copy.png)



可不可以自豪的说: 只要世界还存在一个 `IPFS` 节点，我们此时此刻上传的文件就不会消失呢？

# 留下的思考

- ipfs 有什么缺点？
- ipfs 和bittorrent有什么区别？
- 现有哪些商业系统能否改成ipfs系统？

# 写在最后

我认为看到这你已经对 `IPFS` 产生的背景和技术有了基础的认识，说不定和我一样还玩儿了一把，你有怎样的感受呢?  

我们无法预测 `IPFS` 最终会发展得如何，是否能够像它的愿景一样最终替换掉 `http` 协议，尚需时间证明，但是 `去中心化` 、`分布式网络结构` 等概念及对应的有效应用场景都值得我们去学习和了解。

像官方的第一篇博客说的那样:

**Don’t miss any InterPlanetary updates!**

![earthrise](earthrise.png)