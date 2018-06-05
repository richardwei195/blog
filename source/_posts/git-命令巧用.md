---
title: git 命令巧用
date: 2018-06-04 17:34:27
tags:
  - git
---

## 重置(reset)某次提交改动的文件

```shell
git checkout commitId -- file1 file2 file3
```

## 一条命令将改动的文件加入工作区并提交 commit

```shell
git commit -m '' -a
```

## 更加直观的log记录

```shell
git log --oneline --decorate
```

## 修改上一个 commit

```shell
git commit --amend
```

## 修改某一个 commit 后的记录，可以通过 rebase 对应的 commitId 进行命令操作

```shell
git rebase -i commitId

demo:
git rebase -i c2006a2
```
Demo:

进入编辑面板, 将 `c2006a2` 后的所有提交记录列举出来, 并进行修改操作

键入: `git rebase -i c2006a2`

```
  pick 0892376 fix date
  pick 6957357 fix
  pick 66f9048 fix
  pick 898d986 debug
  pick 082f724 debug
  pick 9b557fb debug
  
  # Rebase c2006a2..9b557fb onto c2006a2 (6 commands)
  #
  # Commands:
  # p, pick = use commit
  # r, reword = use commit, but edit the commit message
  # e, edit = use commit, but stop for amending
  # s, squash = use commit, but meld into previous commit
  # f, fixup = like "squash", but discard this commit's log message
  # x, exec = run command (the rest of the line) using shell
  # d, drop = remove commit
  #
  # These lines can be re-ordered; they are executed from top to bottom.
  #
  # If you remove a line here THAT COMMIT WILL BE LOST.
  #
  # However, if you remove everything, the rebase will be aborted.
  #
  # Note that empty commits are commented out
```

如果我们想要编辑 commitId `898d986`, 并合并 `9b557fb`, 如下修改:

```shell
  pick 0892376 fix date
  pick 6957357 fix
  pick 66f9048 fix
  e 898d986 debug
  pick 082f724 debug
  f 9b557fb debug
```

`wq` 保存退出, 能够看见:

```shell
Stopped at 898d986... debug
You can amend the commit now, with

	git commit --amend

Once you are satisfied with your changes, run

	git rebase --continue
```

是的，现在我们可以修改(amend) commit 了，键入 `git commit --amend`, 将会进入编辑 commitId 为 `898d986` 的编辑界面，可以修改提交信息并保存退出，完毕之后键入 `git rebase --continue` 将自动合并 commit `9b557fb`，修改结束。

## 修改了 `.gitignore` 如何生效

```shell
git rm -r --cached .  // 移除当前工作空间的文件版本
git add .
git commit -m ".gitignore is now working"
```