---
title: Linux--单双引号之分
date: 2018-06-06 16:17:30
tags:
  - linux
---

# 插曲
今天下午同事突然抛出一个问题，shell 中我想 `grep` 这么一段话:

```shell
scenarioFieldConfig's _id
```
有哪几种方式可以实现呢?
<!-- more -->
因为包含了 `'`，用 `""` 包起来是最简单容易的一种方式，比如:

```shell
✗ echo "scenarioFieldConfig's _id"
```
同事继续提问到，如果我不想用 `""` 来解决问题，我就是想用 `'` 怎么办呢？
> 这也简单，\ 转义一下就好了哇

```shell
✗ echo 'scenarioFieldConfig\'s _id'
quote>
```
诶诶，怎么不对?? 额嗯……，应该是这样才对:

```shell
✗ echo scenarioFieldConfig\'s _id
scenarioFieldConfig's _id
```
成功了。

如果语句更加复杂呢? 输出 `scenarioFieldConfig's _id's $1` 如上方法似乎就走不通了，问题先放在这里。

另一个种条件下，我不想使用 `""`，因为可能输入复杂的内容导致变量被扩展或替换，比如:

```shell
✗ echo "scenarioFieldConfig's _id $PATH"
scenarioFieldConfig's _id /usr/local/opt/openssl/bin:/Users/jiangwei/.nvm/versions/node/v8.11.1/bin:/Users/jiangwei/.yarn/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin:/usr/local/git/bin:/usr/local/opt/fzf/bin
```
环境变量就被引用进去了，这并不是我们期望的

# 学习过程
> PS: 虽然是工作时间，但是遇到的问题也是开发过程中遇到的，所以，我们并没有划水哟

## 我们为什么要用引号

在 `shell` 中，我们要输出一条字符串，我们通常是这么做的:

```shell
➜  ~ echo hello world
hello world
```

但是如果我们想要输出 `$hello world`，结果却不尽人意

```shell
➜  ~ echo $hello world
world
```
是的这里很好理解，`$hello` 被替换成了变量输出，值为 `Null`。
或是

```shell
➜  ~ hello=Hello && echo $hello World
Hello World
```
能够直接为变量 `$hello` 赋值。

> 同样，在同一个环境使用 `echo "$hello World"` 将是同样的输出。

不使用引号，以及使用双引号的方式我们都尝试过了，那么单引号呢，是的告诉你将会成功

```shell
➜  ~ echo '$hello world'
$hello world
```

所以，这时候我们知道我们的重点是啥了: 引号的作用或是单、双引号之分

## 引号的含义

> 引号通常用于创建 `字面量`，即原封不动的字面意义。

### 执行命令或脚本前，我们得了解 shell 是如何执行的

1. 在真正执行之前，shell会查找其中的变量、通配符以及其它代词，如果有的话，会将它们进行替代。(和我们编译过程中词法\语法分析类似)。
2. 将替换过后的结果返回。

### 创建字面量最简单的方法就是用单引号将字符串进行包围
> 单引号之间的字符、空格都会被当做单独的参数执行，当我们想使用字面量的时候，优先考虑采用单引号，保证不被替换，语法上也十分整洁。 《精通 LINUX》

和我们之前的 `Demo` 类似:
```shell
➜  ~ echo '$hello world'
$hello world
```
结合之前的几个例子以及对 `字面量`、`单引号` 的解释，双引号中所有的变量都会进行
扩展、赋值。

## 回到我们的问题

我们要输出 `scenarioFieldConfig's _id`, 当字符串中同样包含单引号的时候，我们使用单引号包裹的话:

```shell
➜  ~ echo 'scenarioFieldConfig's _id'
quote>
```
词法分析的时候只会解析到前半部分 `'scenarioFieldConfig'`, `s _id'` 则会解析为不同的语句，如何证明呢，如果我们的输入是这样的:

```shell
➜  ~ echo 'scenarioFieldConfig's '_id'
scenarioFieldConfigs _id
```
输出成功，原文的 `'` 则被疏略了。

**这个时候我们应当知道，在复杂符号的语句或者是单引号中包含单引号或者 `\` 的时候，我们需要将所有的单引号 `'` 替换为 `'\'` 来保证内容不被替换**

```shell
➜  ~ echo 'scenarioFieldConfig'\''s _id'\''s $1'
scenarioFieldConfig's _id's $1
```
