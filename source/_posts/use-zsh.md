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

> 以下例子全部基于 centOS 7.4 实现

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

## 安装 Oh My Zsh