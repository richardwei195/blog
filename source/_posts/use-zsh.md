---
title: use zsh
date: 2018-07-01 18:09:19
tags:
  - linux
---

用了很久的 `zsh`，时刻都在感叹它的强大与便捷，很早就打算记录一篇安装和使用 `zsh` 的心路历程，工作忙一直在往后拖(借口啦~)

## zsh 是什么？

> Z Shell(Zsh) 是一种Unix shell，它可以用作为交互式的登录shell，也是一种强大的shell脚本命令解释器。Zsh可以认为是一种Bourne shell的扩展，带有数量庞大的改进，包括一些bash、ksh、tcsh的功能。

简而言之，就是 `shell` 脚本语言的一种扩展与加强。

## zsh 有哪些功能？

> [From Wiki](https://zh.wikipedia.org/wiki/Z_shell)

- 开箱即用、可编程的命令行补全功能可以帮助用户输入各种参数以及选项。
- 在用户启动的所有shell中共享命令历史。
- 通过扩展的文件通配符，可以不利用外部命令达到find命令一般展开文件名。
- 改进的变量与数组处理。
- 在缓冲区中编辑多行命令。
- 多种兼容模式，例如使用/bin/sh运行时可以伪装成Bourne shell。
- 可以定制呈现形式的提示符；包括在屏幕右端显示信息，并在键入长命令时自动隐藏。
- 可加载的模块，提供其他各种支持：完整的TCP与Unix域套接字控制，FTP客户端与扩充过的数学函数。
- 完全可定制化。

## zsh 的安装与使用

> 以下例子全部基于 centOS 7.4 实现, macOS 类似

通用 `yum` 安装:

```shell
sudo yum update && sudo yum -y install zsh
```

安装成功后，键入 `zsh --version` 查看是否安装成功，成功会有如下输出（不同的版本、平台会有不同的输出）:

```shell
zsh 5.0.2 (x86_64-redhat-linux-gnu)
```

`zsh` 安装成功之后，我们就可以将默认的 `shell` 切换至 `zsh`，在做这个操作之前，我们可以确认一下已经安装好的 `shell` 脚本有哪些：

```shell
~ cat /etc/shells
/bin/sh
/bin/bash
/sbin/nologin
/usr/bin/sh
/usr/bin/bash
/usr/sbin/nologin
/bin/zsh

```

能够清楚的查看已经安装好的 `shell` 脚本列表，当然，验证的方法还有很多，比如直接打印 `shell` 的环境变量:

```shell
~ echo $SHELL
/bin/zsh
```

切换默认的 `shell` 至 `zsh`:

```shell
~ chsh -s $(which zsh)
Changing shell for root.
chsh: Warning: "/usr/bin/zsh" is not listed in /etc/shells.
Shell changed.
```

安装好 `zsh` 之后，他还并不像我们前面所描述的那样这么强大，我们还需要一个很酷的工具 `Oh My Zsh` 来管理和扩展我们的 `zsh`

## Oh My Zsh

[官网地址](https://ohmyz.sh/)

官网的描述: ` It comes bundled with a ton of helpful functions, helpers, plugins, themes, and a few things that make you shout...`

支持超多的扩展函数、插件以及主题等; 具体有什么用，根据我的使用习惯列出了一个清单:

**Plugins**
- git: 强大的 git 缩写命令(默认已开启)
- zsh-autosuggestions: shell 命令提示，自动补全可能的路径
- zsh-syntax-highlighting: 特殊命令高亮提示

**Themes**
- robbyrussell: 默认主题，很好看
- af-magic
- agnoster: 暗系主题
- avit: 界面干净

- **alias**: 超链接别名，特有用，后文会提到如何使用

### 安装

```shell
1、
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
2、
cp ~/.zshrc ~/.zshrc.orig
3、
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
4、
chsh -s /bin/zsh
```

安装成功后，重新打开一个新的终端，如果发现界面主题已经改变，代表安装成功配置已经生效了。

**为了保证配置的有效性，我们可以输入简单的命令进行验证:**

```shell
➜  ~ la
总用量 100K
-rw-------   1 root root  852 7月   1 18:02 .bash_history
-rw-r--r--.  1 root root   18 12月 29 2013 .bash_logout
-rw-r--r--.  1 root root  176 12月 29 2013 .bash_profile
-rw-r--r--.  1 root root  176 12月 29 2013 .bashrc
drwx------   3 root root 4.0K 10月 15 2017 .cache
drwx------   3 root root 4.0K 7月   2 22:30 .config
-rw-r--r--.  1 root root  100 12月 29 2013 .cshrc
-rw-------   1 root root    0 7月   2 22:29 .node_repl_history
drwxr-xr-x  11 root root 4.0K 7月   1 18:04 .oh-my-zsh
drwxr-xr-x   2 root root 4.0K 10月 15 2017 .pip
drwxr-----   3 root root 4.0K 7月   1 18:04 .pki
-rw-r--r--   1 root root   64 10月 15 2017 .pydistutils.cfg
drwx------   2 root root 4.0K 7月   2 22:28 .ssh
-rw-r--r--.  1 root root  129 12月 29 2013 .tcshrc
-rw-------   1 root root 3.3K 7月   7 23:22 .viminfo
-rw-r--r--   1 root root  36K 7月   1 18:07 .zcompdump-iZ2zea8scx4z0lcmstkb0rZ-5.0.2
-rw-------   1 root root 2.6K 7月   9 09:18 .zsh_history
-rw-r--r--   1 root root 3.1K 7月   1 18:07 .zshrc
-rw-r--r--   1 root root    0 7月   1 18:07 .zshrc.orig
```

如果`la` 代替了命令 `ls -a`，恭喜你安装成功。

### 主题选择

关于主题的选择，默认的主题 `robbyrussell` 对我来说已经很满足了，如果对主题有更多要求和追求改变，可以从[这里选择相应主题进行切换](https://github.com/robbyrussell/oh-my-zsh/wiki/Themes)。

这里描述一下如何切换主题:

```shell
1. 打开配置文件
➜  ~ vim ~/.zshrc
2. 找到主题配置所在行`ZSH_THEME`，切换对应的主题即可
ZSH_THEME="robbyrussell"
3. :wq 保存退出，source ~/.zshrc 使配置文件生效，打开新终端
```

### 插件选择和配置

插件的配置:

```shell
1. 打开配置文件
➜  ~ vim ~/.zshrc
2. 找到插件配置所在行`plugins`
plugins=(
  git
)
3. 如果需要增加一个插件，只需要:
plugins=(
  git
  zsh-autosuggestions
)
```

#### git