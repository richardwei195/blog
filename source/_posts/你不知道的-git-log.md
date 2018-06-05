---
title: 你不知道的 git log
date: 2018-04-12 17:11:48
tags: git
---

> [原文链接](https://zwischenzugs.com/2018/03/26/git-log-the-good-parts/?utm_source=wanqu.co&utm_campaign=Wanqu+Daily&utm_medium=website)

假设您正在与多个开发者共同维护管理复杂的 git 代码库，那您可能会使用`GitHub` 或 `BitBucket` 等工具有深入研究提交历史，并且希望从中找出分支以及合并 `issue`  的相关问题。



图形化界面为用户提供了非常友好的接口来管理 PR 以及查看一些简单的历史记录，但是当工作流程 SHTF (译者注: 这里我理解为是混乱、糟糕的意思) 已经不能用 git log 来替代或者一些相关的标记来挖掘出实际的情况时，你应该和我一起来通过命令行去学习还有掌握它(git log) 。



# 一个关于Git Repository 的例子

为了配合这个例子，我特地准备了一个 git 仓库，可以克隆下来并且运行它: 

```bash
$ git clone https://github.com/ianmiell/cookbook-openshift3-frozen
$ cd cookbook-openshift3-frozen
```



**git log**

git log 是应该是你最熟悉的 vanlilla log 命令: 

```bash
$ git log

commit f40f8813d7fb1ab9f47aa19a27099c9e1836ed4f 
Author: Ian Miell <ian.miell@gmail.com>
Date: Sat Mar 24 12:00:23 2018 +0000

pip

commit 14df2f39d40c43f9b9915226bc8455c8b27e841b
Author: Ian Miell <ian.miell@gmail.com>
Date: Sat Mar 24 11:55:18 2018 +0000

ignore

commit 5d42c78c30e9caff953b42362de29748c1a2a350
Author: Ian Miell <ian.miell@gmail.com>
Date: Sat Mar 24 09:43:45 2018 +0000

latest
```

输出显示每一个提交的占用5+行, 包含了日期、作者的提交信息以及id。提交信息按照时间进行倒序排列，因为我们通常只对最近的几次提交感兴趣啊。

> NOTE:  值得一提的是，我们可以控制输出到控制台的信息是否包含版本、别名等等



**--oneline**

其实在大部分时间我都不会关心作者或者提交日期, 因此如果想要在一块屏幕里看见更多的信息，我们可以使用 `--oneline`  命令来仅显示提交的 `id` 信息以及每一个提交的评论信息

```shell
$ git log --oneline
ecab26a JENKINSFILE: Upgrade from 1.3 only
886111a JENKINSFILE: default is master if not a multi-branch Jenkins build
9816651 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
bf36cf5 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
```



**--decorate**

查看  `git log` 信息，有时候我们会想知道每一个提交更多的信息，比如这次提交是来自哪一个分支呢？标签有吗，如果有是多少？

此时 `--decorate` 命令就为我们提供了以上信息:

```bash
$ git log --oneline --decorate
ecab26a (HEAD -> master, origin/master, origin/HEAD) JENKINSFILE: Upgrade from 1.3 only
886111a JENKINSFILE: default is master if not a multi-branch Jenkins build
9816651 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
```

其实版本的更新记录 `git` 已经设为了默认功能，所以我们不需要敲打额外的命令来获取相关信息，这很棒。



**--all**

```shell
$ git log --oneline --decorate --all
ecab26a (HEAD -> master, origin/master, origin/HEAD) JENKINSFILE: Upgrade from 1.3 only
886111a JENKINSFILE: default is master if not a multi-branch Jenkins build
9816651 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
[...]
a1eceaf DOCS: Known issue added to upgrade docs
774a816 (origin/first_etcd, first_etcd) first_etcd
7bbe328 first_etcd check
654f8e1 (origin/iptables_fix, iptables_fix) retry added to iptables to prevent race conditions with iptables updates
e1ee997 Merge branch 'development'
```

你能看清楚上面的信息多了什么吗？咱们可以对比一下之前的  `--oneline` 命令来理解，是的，所有的分支都被展示出来了...



**--graph**

`--graph` 命令除了能够提供以上信息之外，还能让我们能够在命令行中看见类似 `git GUI` 的输出，让我们随时随地能够更轻松的理解和掌握我们所需的信息。

```shell
$ git log --oneline --decorate --all --graph
* ecab26a (HEAD -> master, origin/master, origin/HEAD) JENKINSFILE: Upgrade from 1.3 only
* 886111a JENKINSFILE: default is master if not a multi-branch Jenkins build
* 9816651 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
|\ 
| * bf36cf5 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
| |\ 
| | * 313c03a JENKINSFILE: quick mode is INFO level only
| | * 340a8f2 JENKINSFILES: divided up into separate jobs
| | * 79e82bc JENKINSFILE: upgrades-specific Jenkinsfile added
| * | dce4c71 Add logic for additional FW for master (When not a node)
* | | d21351c Update utils/atomic
|/ / 
* | 3bd51ba Fix issue with ETCD
* | b87091a Add missing FW for HTTPD
|/ 
* a29df49 Missing (s)
* 51dff3a Fix rubocop
```



# 不要惊慌！

以上介绍的问题可能对新手来说比较难以理解和接受，也没有什么好的教程能够指引。但是我会提供一些小技巧来帮助新手更容易的阅读和理解 `git log`

`*` 符号表示对应的某次提交，并且记录了提交的详细信息(这里只列出了提交id以及第一行评论信息)

我们可以通过下面这个例子帮助我们看清楚每条分支内容上的改动在分支线上的呈现效果:

```shell
| * bf36cf5 Merge branch 'master' of github.com:IshentRas/cookbook-openshift3
| |\ 
| | * 313c03a JENKINSFILE: quick mode is INFO level only
```

左边的一条线我们可以看做是稳定的分支，右边两条线表示对应的改动，以及彼此之间提交的改动(9816651 and d21351c)。

蓝线会将您带到bf36cf5合并的一个父代（蓝色父代的提交标识是什么？），粉红色代码则转到另一个父代提交（313c03a）。

左起第二条线会显示 `bf36cf5`的一次合并, 第三条则显示了另一个合并提交`313c03a`

> 花点时间弄清楚这些基本信息是值得的，它将帮助我们更容易的理解后面的相关内容**



 **--simplify-by-decoration**

如果你正在寻找项目的整个历史并且只想知道关键的变化信息，这个命令可能对你有很大的帮助，如果要结合 `--decorate` 命令使用的话，需要跟随在这个命令之后。

它将移除掉提交里所有我们没有标记的信息，当然，最新的一次提交是永远存在的:

```shell
$ git log --oneline --decorate --all --graph --simplify-by-decoration
* ecab26a (HEAD -> master, origin/master, origin/HEAD) JENKINSFILE: Upgrade from 1.3 only
| * 774a816 (origin/first_etcd) first_etcd
|/ 
| * 654f8e1 (origin/iptables_fix) retry added to iptables to prevent race conditions with iptables updates
|/ 
* 652b1ff (origin/new-logic-upgrade) Fix issue iwith kitchen and remove sensitive output
* ed226f7 First commit
```



# 文件信息

使用 `--oneline` 命令展示出来的信息是有点稀少的，所以通常 `--stat` 能够提供给你更多关于每次变动的信息。

数字表示更改的行数，用一个 `+` 符号表示插入，然后 `-` 符号表示删除。这里是没有更改概念的，假如一行只有一个单次被修改了，也是新增的意思。

```shell
$ git log --oneline --decorate --all --graph --stat
* ecab26a (HEAD -> master, origin/master, origin/HEAD) JENKINSFILE: Upgrade from 1.3 only
| Jenkinsfile.upgrades | 2 +-
| 1 file changed, 1 insertion(+), 1 deletion(-)
* 886111a JENKINSFILE: default is master if not a multi-branch Jenkins build
| Jenkinsfile.full | 2 +-
| Jenkinsfile.upgrades | 2 +-
| 2 files changed, 2 insertions(+), 2 deletions(-)
```

如果你发现 `--stat`  很难记住，你可以选择 `--name-only`， 但是这会丢失行数变动的相关信息。



# 正则在提交中的运用

这个命令使用起来也是很方便的。`-G` 命令能够允许您搜索所有提交，并且通过正则表达式只返回提交和它们的文件。

下面这个例子j就展示了通过正则表达式搜索文本为 `chef-client`  的相关变动:

```shell
$ git log -G 'chef-client' --graph --oneline --stat
...
* 22c2b1b Fix script for deploying origin
| scripts/origin_deploy.sh | 65 ++++++++++++-----------------------------------------------------
| 1 file changed, 12 insertions(+), 53 deletions(-)
... 
| * | 1a112bf - Move origin_deploy.sh in scripts folder - Enable HTTPD at startup
| | | origin_deploy.sh | 148 ----------------------------------------------------------------------------------------------------------------------------------------------------
| | | scripts/origin_deploy.sh | 148 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
| | | 2 files changed, 148 insertions(+), 148 deletions(-)
... 
| * | 9bb795d - Add MIT LICENCE model - Add script to auto deploy origin instance
|/ / 
| | origin_deploy.sh | 93 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
| | 1 file changed, 93 insertions(+)
```

如果你过去花了很多时间使用 `git log --patch` 来搜索相关改动的输出，结合这个命令，就更加完美啦。

有一个奇怪的命令叫做 `--pickaxe-all`，能够告诉你每次提交里所有文件的变动，不仅仅是通过正则表达式所匹配出来的内容: `$ git log -G 'chef-client' --graph --oneline --stat --pickaxe-all`



说了这么多，赶紧去尝试一下吧~