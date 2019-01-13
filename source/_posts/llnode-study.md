---
title: 使用llnode追溯OOM源头
date: 2019-01-13 15:41:10
tags:
  - Node.Js
  - Javascript
---

![](skill.jpg)

## 背景

> 公司部分后端的 Node.Js 服务在2018年年初接入了SOA基础平台(服务拆分、下沉)，由于对接得非常匆忙，因此在上游服务这边的代码大部分仅仅考虑了如何接入封装好的 SDK，并未及时考虑在具体场景下接入是否会存在较明显的风险甚至影响服务的稳定。

在对接底层服务的时候，一个非常重要的目的是将不同的业务线所使用的同一个模型的「写」操作权限收拢至一个独立的服务提供相关的功能，目的是为了对同一个模「型\数据表」进行不同应用的写入、更新权限分应用验证，以及敏感数据、字段的 **脱敏**。

在实际的业务场景中，`Teambition` 有一个常用的功能就是「批量归档任务」，随着使用 Teambition 的任务功能时间越来越长，一个列表下的任务可能有成千上万条，这时候我们可以将这些已经过去很久的任务归档掉。

## 插曲

需要注意的一个点是，在归档的过程中，不仅仅是对 `DB` 的 `CRUD` 操作，伴随更新的过程中我们可能需要针对每一条数据(任务)触发一系列行为，这些行为可能有:

- 发送 websocket
- 为其他几张表写入相关业务数据
- 发送 webhook
- 发送通知、推送
- 进入数据分析系统
  ...

这个过程中每一个任务的处理都有各自独立的特点: 需要考虑不同的键值、不同的业务逻辑处理等等，简而言之就是对待不同的任务得把它取出来做不同的业务处理操作。

在归档这个场景，我们之前是采用「游标」的方式来对某一集合的数据进行更新及连带更新，Teambition 的任务数据模型是一个树状结构，抽象出来就是一颗树，在业务上有个基本逻辑是: **当父节点被删除（归档），子孙节点也需要被删除**，因此在具体的业务场景中，我们可能在处理一颗树的根节点的时候，需要把它的子孙节点一并处理掉，当然，这里也有一个需要特别解释的点，如果我们对一个树的遍历是递归遍历的话，那么我们只需要把根节点处理掉就好了，子孙节点其实也是跟着父节点(根节点)的行为属性保持一致的，根\父节点不满足筛选条件即跳出递归。 

如果仅仅考虑这个场景的话，已经满足了我们普通的业务处理，在处理一个任务(节点)的时候，节点本身做了标记，那么下次查询的时候忽略有相关标记的节点即可。但是在真实的业务场景中，我们需要考虑的不仅仅是如何实现它，也需要保证通过每一种模型实现背后的代价，性能、通用性拓展性、耦合度等等；我们对任务的应用场景是「读多写少」，那么如果我们在**数据库**中查询任务，还需要采用递归的方式来查询那么毫无疑问效率是非常低的，因此在设计此类数据模型的时候，针对这类的业务场景，我们参考的是 MongoDB 推荐的数据结构 -- [Model Tree Structures with an Array of Ancestors](https://docs.mongodb.com/manual/tutorial/model-tree-structures-with-ancestors-array/)

![](tree.svg)

```shell
db.categories.insert( { _id: "MongoDB", ancestors: [ "Books", "Programming", "Databases" ] } )
db.categories.insert( { _id: "dbm", ancestors: [ "Books", "Programming", "Databases" ] } )
db.categories.insert( { _id: "Databases", ancestors: [ "Books", "Programming" ] } )
db.categories.insert( { _id: "Languages", ancestors: [ "Books", "Programming" ] } )
db.categories.insert( { _id: "Programming", ancestors: [ "Books" ] } )
db.categories.insert( { _id: "Books", ancestors: [ ]} )
```

对于每一个节点，我们都用额外的空间记录了他的祖先节点，因此当我们需要查询某一条任务的时候，只需要将它本身及 **ancestors** 中包含它的数据找出来即可，极大程度上满足了我们对「读」这一场景的性能要求。

回到我们本身遇到的问题中来，在上游应用能够独立操作数据库的时候，我们只需要按照一定的方式处理一批数据，在一定的程度上保证效率以及内存的稳定。关键问题出现在文首我提到的，在对接底层服务的过程中，由于不能自由的操作数据库，因此前段时间我们遭遇了 `OOM` 黑洞: 生产环境 `k8s` 集群里的某个或者某几个实例(pod)会因为触发类似的操作行为导致 `OOM` 被`kill` 掉。

原因是因为在相关同事对接的过程中，将获取到的所有的数据一并放到内存中进行计算，计算的过程中由于方法的不当还需要申请大量的内存来进行 `tmp` 的存储，在数据量很大的情况下，处于新生代的变量频繁被使用，老生代由于一直被引用无法被及时`GC`，处理的数据量过多导致 `CPU ` 较忙，`GC` 也执行较慢，最终导致应用 `OOM`，如图:

![](oom.png)

## 目的

一旦应用被中途杀死势必会将整个 `API` 请求的链路打断，出现了脏数据并且影响了不同的业务场景，令人遗憾的是，在 `OOM` 的过程前后，我们只能靠监控系统及时发现应用 `Crash`，再根据相关的时间日志去推测导致 `OOM` 的原因，我们并被有把应用被”杀死“之前的案发现场给 `dump` 下来，因此，摆在面前的解决思路只有两条:

1. 从代码的角度来讲，改变处理策略
- 数据分批处理，减少内存的使用，优化算法；
- 将相关的行为放入消息队列，由多个应用从消息队列中获取并处理相关行为，减轻单个实例的负载；

2. 维护的角度来看
- 服务出现此类异常一定要能够寻找案发源头；
- 找到源头并快速进行分析，查明原因，尽力保证避免类似的错误再次发生；

代码的处理上，在进行一定的优化之后已经避免了在这里我只简单的讲一下第二点我的实践思路，并未应用到生产环境中去。

## 方案

`Node.Js` 官方有一个启动命令叫做 `--abort-on-uncaught-exception`, 用来解决应用异常崩溃或者终止的时候会生成用于调试的 `core.pid` 文件，我们可以理解为应用异常退出前的快照。

这是最关键的一个环节，有了这个文件之后，我们只需要对这个文件进行分析就好，只要案卷在手，找到分析方式只是时间问题（目前我们遇到的问题就是连案卷也没有）

如何将对应的方案落实到实际中去，结合工程项目我完整的梳理一遍，希望能够帮助读者理解。


#### 1. 注入能够导致「爆栈」的代码
在实际的工程项目中，我为某个 `API` 注入了如下代码:

```js
  function func () {
    let arr = []
    for (let i = 0; i < 9999999999; i++) {
      arr.push(i)
    }
  }
  func()
```
如果我们在浏览器或者 Node 环境中执行以上代码，通常会导致「爆栈」，也就是堆内存溢出(JavaScript heap out of memory)

#### 2. 启动我们的实例，访问 API

毫无疑问，应用 `Crash` 并抛出如下错误:

```
<--- Last few GCs --->

[36270:0x102802400]    14867 ms: Mark-sweep 696.0 (746.8) -> 692.9 (746.2) MB, 132.5 / 0.0 ms  allocation failure GC in old space requested
[36270:0x102802400]    15010 ms: Mark-sweep 692.9 (746.2) -> 692.5 (706.2) MB, 142.3 / 0.0 ms  last resort GC in old space requested
[36270:0x102802400]    15172 ms: Mark-sweep 692.5 (706.2) -> 692.5 (706.2) MB, 162.1 / 0.0 ms  last resort GC in old space requested


<--- JS stacktrace --->

==== JS stack trace =========================================

Security context: 0x27be5dd25879 <JSObject>
    1: func [/Users/jiangwei/Desktop/Teambition/Code/core/lib/*****.js:~29] [pc=0xffc20deeda](this=0x27be5ed04f01 <JSGlobal Object>)
    2: getTasksByTQL [/Users/jiangwei/Desktop/Teambition/Code/core/lib/*****.js:35] [bytecode=0x27be9a61ba51 offset=369](this=0x27be5ed04f01 <JSGlobal Object>,req=0x27beb7082311 <the_hole>)
    3: /* anonymous */(th...

FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory
 1: node::Abort() [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 2: node::FatalException(v8::Isolate*, v8::Local<v8::Value>, v8::Local<v8::Message>) [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 3: v8::internal::V8::FatalProcessOutOfMemory(char const*, bool) [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 4: v8::internal::Factory::NewUninitializedFixedArray(int) [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 5: v8::internal::(anonymous namespace)::ElementsAccessorBase<v8::internal::(anonymous namespace)::FastPackedSmiElementsAccessor, v8::internal::(anonymous namespace)::ElementsKindTraits<(v8::internal::ElementsKind)0> >::GrowCapacity(v8::internal::Handle<v8::internal::JSObject>, unsigned int) [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 6: v8::internal::Runtime_GrowArrayElements(int, v8::internal::Object**, v8::internal::Isolate*) [/Users/jiangwei/.nvm/versions/node/v8.12.0/bin/node]
 7: 0xffc1c042fd
```

很明确的告诉了我们很多关键信息:

- 错误的类型: `JavaScript heap out of memory`
- 错误的链路、发生的位置: 具体到 xx 文件，xx 行
- 错误的原因是神马: 申请不了额外的空间存放老生代的变量
- 当前应用运行的环境、版本号等等
...

这个时候我们能够快速的定位到问题并分析、处理，但是如果在真实地生产环境中，应用要是崩溃退出了，我们是不能等的，需要瞬间立马重启并提供服务，因此这个场景在实际的生产环境中是很难直接捕获到。

#### 3. 仔细思考一下，通常我们遇到的问题极大可能性别人也遇到过并提供了解决思路

出现了前面的问题，难道就没救了吗？日志记录不了，无法稳定复现，无法 `DEBUG`，到底应该怎么办？

其实在日常开发的过程中，当我们遇上了疑难杂症、自己不清楚的问题而怀疑工具、语言甚至人生的时候，我们应该换个角度先想想这个问题出现的原因以及场景： 错误的原因是因为 `OOM`，那么当我们的业务、应用大到一定的程度时候，大大小小都应该遇到或发生过 `OOM` 或者类似导致应用 `Crash` 的问题，编程这么严谨的事情，容不得半点马虎和侥幸。

因此 `Google` 一下或者请教一下有经验的朋友，问题通常是有解的。

这一节一开始我就已经提到了，官方已经为我们提供了专门的命令 `--abort-on-uncaught-exception`，当程序出现的时候把类似的错误 `dump` 为文件存储下来以供我们分析；这里我就安利一下 [llnode](https://github.com/nodejs/llnode)：一个用于分析 `Node` 的 `lldb` 插件。

#### 4. 分析的过程

Node 会为我们生成一个 `core.pid` 的文件，因为是基于 V8，V8 又是用 `C++` 写的，因此免不了得像调试 `C++` 代码一样使用 `gdb`、`lldb` 等工具进行分析，当然如果使用这些工具的话我们应该是看见不了我们实际的JS代码相关的问题，因此基于 `lldb` 的插件 `llnode` 能够在标准的 `C/C++` 调试工具中检查 `JavaScript` 堆栈帧、对象、源代码等，这样作为大部分 js 的同学应该都能理解起来没问题了。

安装的过程我就不说了，`README` 讲得还是很详细的，着重描述一下过程。

我的本机系统是 MacOS，因此生成的文件是保存在 `/cores` 目录中的，步骤 `2` 中我运行的实例生成的文件叫做 `core.36270` 也就是 `core.进程号` 的命名。

运行:

```
// -c 是 --core 的缩写，后面跟 fileName
llnode node -c core.36270
```

我们会进入调试界面:

```
➜  /cores llnode node -c core.36270
(lldb) target create "node" --core "core.36270"
Core file '/cores/core.36270' (x86_64) was loaded.
(lldb) plugin load '/Users/jiangwei/.nvm/versions/node/v8.12.0/lib/node_modules/llnode/llnode.dylib'
(lldb) settings set prompt '(llnode) '
```

执行:

```
(llnode) v8
     Node.js helpers

Syntax: v8

The following subcommands are supported:

      bt                -- Show a backtrace with node.js JavaScript functions and their args. An optional
                           argument is accepted; if that argument is a number, it specifies the number of
                           frames to display. Otherwise all frames will be dumped.
                           Syntax: v8 bt [number]
      findjsinstances   -- List every object with the specified type name.
                           Flags:
                           * -v, --verbose                  - display detailed `v8 inspect` output for each
                           object.
                           * -n <num>  --output-limit <num> - limit the number of entries displayed to
                           `num` (use 0 to show all). To get next page repeat command or press
                           [ENTER].
                           Accepts the same options as `v8 inspect`
      findjsobjects     -- List all object types and instance counts grouped by type name and sorted by
                           instance count. Use -d or --detailed to get an output grouped by type name,
                           properties, and array length, as well as more information regarding each type.
      findrefs          -- Finds all the object properties which meet the search criteria.
                           The default is to list all the object properties that reference the specified
                           value.
                           Flags:
                           * -v, --value expr     - all properties that refer to the specified JavaScript
                           object (default)
                           * -n, --name  name     - all properties with the specified name
                           * -s, --string string  - all properties that refer to the specified JavaScript
                           string value
      getactivehandles  -- Print all pending handles in the queue. Equivalent to running
                           process._getActiveHandles() on the living process.
      getactiverequests -- Print all pending requests in the queue. Equivalent to running
                           process._getActiveRequests() on the living process.
      inspect           -- Print detailed description and contents of the JavaScript value.
                           Possible flags (all optional):
                           * -F, --full-string    - print whole string without adding ellipsis
                           * -m, --print-map      - print object's map address
                           * -s, --print-source   - print source code for function objects
                           * -l num, --length num - print maximum of `num` elements from
                           string/array
                           Syntax: v8 inspect [flags] expr
      nodeinfo          -- Print information about Node.js
      print             -- Print short description of the JavaScript value.
                           Syntax: v8 print expr
      settings          -- Interpreter settings
      source            -- Source code information

For more help on any particular subcommand, type 'help <command> <subcommand>'.
```

我们能够看到一大堆执行选项以及说明，在这个场景下，我们需要的是 `bt: Show a backtrace with node.js JavaScript functions and their args`

```
(llnode) v8 bt
 * thread #1: tid = 0x0000, 0x00007fff69957b86 libsystem_kernel.dylib`__pthread_kill + 10, stop reason = signal SIGSTOP
  * frame #0: 0x00007fff69957b86 libsystem_kernel.dylib`__pthread_kill + 10
    frame #1: 0x00007fff69a0dc50 libsystem_pthread.dylib`pthread_kill + 285
    frame #2: 0x00007fff698c11c9 libsystem_c.dylib`abort + 127
    frame #3: 0x00000001000285eb node`node::Abort() + 34
    frame #4: 0x00000001000287ba node`node::OnFatalError(char const*, char const*) + 74
    frame #5: 0x000000010015bec3 node`v8::internal::V8::FatalProcessOutOfMemory(char const*, bool) + 707
    frame #6: 0x00000001004a915c node`v8::internal::Factory::NewUninitializedFixedArray(int) + 284
    frame #7: 0x0000000100466819 node`v8::internal::(anonymous namespace)::ElementsAccessorBase<v8::internal::(anonymous namespace)::FastPackedSmiElementsAccessor, v8::internal::(anonymous namespace)::ElementsKindTraits<(v8::internal::ElementsKind)0> >::GrowCapacity(v8::internal::Handle<v8::internal::JSObject>, unsigned int) + 185
    frame #8: 0x0000000100721f1d node`v8::internal::Runtime_GrowArrayElements(int, v8::internal::Object**, v8::internal::Isolate*) + 365
    frame #9: 0x000000ffc1c042fd <exit>
    frame #10: 0x000000ffc20deeda func(this=0x27be5ed04f01:<Global proxy>) at /Users/jiangwei/Desktop/Teambition/Code/core/**.js:29:17 fn=0x000027be27b39f49
    frame #11: 0x000000ffc1cbd1d6 getTasksByTQL(this=0x27be5ed04f01:<Global proxy>, 0x27beb7082311:<hole>) at /Users/jiangwei/Desktop/Teambition/Code/core/**.js:14:23 fn=0x000027be8ede32b1
    frame #12: 0x000000ffc1cb8056 (anonymous)(this=0x27be5ed04f01:<Global proxy>, 0x27be27b4c029:<Object: Object>) at (no script) fn=0x000027be27b4c3b1
    frame #13: 0x000000ffc1c89cfc <builtin>
    frame #14: 0x000000ffc1c04239 <internal>
    frame #15: 0x000000ffc1c04101 <entry>
    frame #16: 0x000000010049dc03 node`v8::internal::(anonymous namespace)::Invoke(v8::internal::Isolate*, bool, v8::internal::Handle<v8::internal::Object>, v8::internal::Handle<v8::internal::Object>, int, v8::internal::Handle<v8::internal::Object>*, v8::internal::Handle<v8::internal::Object>, v8::internal::Execution::MessageHandling) + 675
    frame #17: 0x000000010049de1e node`v8::internal::Execution::TryCall(v8::internal::Isolate*, v8::internal::Handle<v8::internal::Object>, v8::internal::Handle<v8::internal::Object>, int, v8::internal::Handle<v8::internal::Object>*, v8::internal::Execution::MessageHandling, v8::internal::MaybeHandle<v8::internal::Object>*) + 222
    frame #18: 0x00000001005cf4fb node`v8::internal::Isolate::PromiseReactionJob(v8::internal::Handle<v8::internal::PromiseReactionJobInfo>, v8::internal::MaybeHandle<v8::internal::Object>*, v8::internal::MaybeHandle<v8::internal::Object>*) + 651
    frame #19: 0x00000001005d0099 node`v8::internal::Isolate::RunMicrotasksInternal() + 1353
    frame #20: 0x00000001005ceeaa node`v8::internal::Isolate::RunMicrotasks() + 42
    frame #21: 0x000000ffc1d94b87 <exit>
    frame #22: 0x000000ffc21e80fb _tickCallback(this=0x27be5ed028d1:<Object: process>) at (external).js:152:25 fn=0x000027be5ed05411
    frame #23: 0x000000ffc1c04239 <internal>
    frame #24: 0x000000ffc1c04101 <entry>
    frame #25: 0x000000010049dc03 node`v8::internal::(anonymous namespace)::Invoke(v8::internal::Isolate*, bool, v8::internal::Handle<v8::internal::Object>, v8::internal::Handle<v8::internal::Object>, int, v8::internal::Handle<v8::internal::Object>*, v8::internal::Handle<v8::internal::Object>, v8::internal::Execution::MessageHandling) + 675
    frame #26: 0x000000010049d8ce node`v8::internal::Execution::Call(v8::internal::Isolate*, v8::internal::Handle<v8::internal::Object>, v8::internal::Handle<v8::internal::Object>, int, v8::internal::Handle<v8::internal::Object>*) + 158
    frame #27: 0x0000000100178fbd node`v8::Function::Call(v8::Local<v8::Context>, v8::Local<v8::Value>, int, v8::Local<v8::Value>*) + 381
    frame #28: 0x0000000100027adc node`node::InternalCallbackScope::Close() + 524
    frame #29: 0x0000000100027c36 node`node::InternalMakeCallback(node::Environment*, v8::Local<v8::Object>, v8::Local<v8::Function>, int, v8::Local<v8::Value>*, node::async_context) + 120
    frame #30: 0x0000000100027de1 node`node::MakeCallback(v8::Isolate*, v8::Local<v8::Object>, v8::Local<v8::Function>, int, v8::Local<v8::Value>*, node::async_context) + 108
    frame #31: 0x000000010001be8c node`node::Environment::CheckImmediate(uv_check_s*) + 104
    frame #32: 0x00000001008e842f node`uv__run_check + 167
    frame #33: 0x00000001008e34ab node`uv_run + 329
    frame #34: 0x000000010003037f node`node::Start(v8::Isolate*, node::IsolateData*, int, char const* const*, int, char const* const*) + 805
    frame #35: 0x000000010002f8d8 node`node::Start(uv_loop_s*, int, char const* const*, int, char const* const*) + 461
    frame #36: 0x000000010002f036 node`node::Start(int, char**) + 522
    frame #37: 0x0000000100001534 node`start + 52
```

可以很清楚的看见，整个应用的生命周期完完全全展现在我们面前，倒叙来看，底层 node 的启动、uv_loop ...直至应用奔溃之前的生命周期被完整的记录下来，报错的关键信息和我们debug时候看见的一样，精确到特定的文件、行数及函数名称。

还记得我之前提到的解决的方法以及目的吗，现在我们达到了目的: 准确定位并分析问题。

## 总结

至此，我们应该已经掌握了使用 `--abort-on-uncaught-exception` 命令帮助我们生成 `core.pid` 文件，并使用 `llnode` 加以分析的方法，另辟蹊径解决了我们无法从代码层面直接捕获的 OOM 问题。

文尾呼应一下我方案中提到的一句话
> 找到了方案，却未应用至生产环境中去。 

这个方法乍一看很好、很不错啊，为什么不直接上生产环境，问题就出现在 `dump` 文件这个过程，如果你仔细的运行完了上述流程，你可能会发现，`dump` 文件还是需要花”一定“的时间，其实这个时间是和服务器具体的运行情况，比如系统、负载压力等因素相关的，如果花的时间足够长，那么我们的应用服务中断的时间也会顺延，如果集群中突发一定规模的问题势必会对应用的重启造成时序上的影响，同时 `dump` 文件对 `CPU` 造成的负载有多大暂时也没有数据上的报告，还需要运维同事协助分析并找到满足的条件，因此在没有足够的调研和准备的情况下暂时还不可以发到生产环境中尝试。

ps.分享的过程也是一个抛砖引玉的过程，本事不嫌多，如果你有更好或者落地的方案也请指教🤝。
