---
title: Node.js 知多少
cover: https://pbs.twimg.com/profile_images/749981640609398784/-amtsDMY.jpg
category: 技术
tags:
  - Node.Js
  - Javascript
---

# #序言
---

自从开始接触 `Node` 起，就离不开查阅大大小小的书籍、课程等等，大部分书籍和网络教程其实多多少少都是讲到一些`框架`或者生态里的各类`工具库`的使用(生态是 Node 引以为‘豪’的一点)，偏向于速成，当然，我认为 `Node` 无论是在学习成本还是开发效率上都是数一数二的。

这些途径的最终目的都是好的，也是一个帮助初学者快速入门的办法:  学会一门语言（Javascript、Typescript...），通过框架的使用（Express、Koa...），快速上手搭建一个能够正常运行的`Web`应用，整个过程并不是很难，也容易让人产生满足感（至少不会像 Java 那一套得折腾老半天）。
<!-- more -->

​可以确定的是，无论是框架、还是各类代码库，都是为了快速解决问题而诞生的，网上「10分钟带你实现一个 Web 应用」、「10节课教你用 Node 搭建自己的博客」…这类的资料或者教程比比皆是，这些对初学者是非常友好的，因为他们只需要跟着教程，一步一步敲击命令就可以实现一个像模像样的 Demo，整个过程可能大家只会明白如何调用框架的 API 启动一个 `Web Service`，比如 `Express`

```javascript
const Express = require('express')

const app = new Express()

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(3000, () => {
  console.log('Example app listening on port 3000!');
});
```

执行 `node app.js`，浏览器中访问  `http://localhost:3000` 就能得到一个最简单的 Demo.

在整个学习过程中，可能仅仅知道引入 `express` 这个库，然后调用它的 API 就可以了，甚至很多人误以为这就是 `Node`。也有很多人觉得，我只需要知道怎么用这个框架就好，并不需要知道它是怎么实现的，这些都是框架作者需要去了解的事情。

​我认为上述两点都是错误的，是的 Node 是非常灵活并且原生(简单)的，它并不提供一套原生的 `Web Service `解决方案，而是提供了一个丰富、完整高效的运行环境，让人们能够在此基础上拓展以及构建自己想要的解决方案。如果在使用这些框架之前，你并不知道框架的实现原理、 `Node` 本身的运行原理，那么在进行实际功能开发的时候、遇到了框架无法或者还未解决的问题的时候，你将寸步难行，无法运用已有的知识和理论去尝试快速定位和解决问题。


# #正文
---

> 在这篇文章中，我将平时遇到或者搜寻到的一些 `Node` 相关问题，通过问答的形式，帮助自己总结以及分享给读者(持续更新...)。



## #Q1. Node 与 V8 引擎的关系是什么？Node 可以离开 V8 单独工作吗?

​官网有说明: *Node*.*js* 是一个基于Chrome V8 引擎的 JavaScript 运行环境。V8 引擎首先是用于 Google 的 Chrome 浏览器，来解释和实行 Javascript 代码，其中做了大量的优化。Node.js 的代码编译、执行的也是依靠了 V8 引擎。

但是并不表示 Node.js 只能依赖 V8 运行，`JXcore` 是Node 的一个分支，可以通过 Mozilla SpiderMonkey 在 iOS 设备上运行Node应用程序。

使用 V8 的几个关键的原因:

- V8是基于[BSD许可证](https://zh.wikipedia.org/wiki/BSD%E8%AE%B8%E5%8F%AF%E8%AF%81)的开源软件
- V8速度非常快
- V8专注于网络功能，在HTTP、DNS、TCP等方面更加成熟



## #Q2. 使用 Node modules 时，什么时候使用 export，什么时候使用 module.exports？

​export 是对 module.exports 的引用，当我们使用 require 来引用一个模块时，引用的是 module.exports 这个对象，不是直接引用 export ([官方文档有说明](https://nodejs.org/docs/latest/api/modules.html#modules_exports):  `A reference to the module.exports that is shorter to type`)， 如: `export.a = { say: 'Hello world!' }  =>  module.exports.a = { say: 'Hello world!' }`。

​既是引用关系，就得考虑传址和传值。

```javascript
// 可以这么理解
const module = {
    exports: {
        say: 'Hello world!'
    }
}

const export = module.exports

console.log(export) // { say: 'Hello world!'}

export.name = 'Node'

console.log(module.exports) // { say: 'Hello world!', name: 'Node'}

// 因为 export 与 module.exports 指向的是同一块内存地址，所以都为同一个内存地址的值
// 一旦将赋予新的对象，如:
export = function () {
    console.log('new')
}

module.exports = function () {
    console.log('new')
}

// export 将无法正常导出这个 function，因为指向的内存地址不一样了
// 既然是 export 是对 module.exports 的引用，那么如何指向同一块内存地址就很重要了，可以有如下解法

const func = function () {
    console.log('success!')
}

export.func = func
module.exports.func = func
```



## #Q3. 什么是事件循环？是 V8 的一部分吗？

​首先我们得理解，`事件驱动`是指在持续事务管理过程中进行决策的一种策略，即跟随当前时间点上出现的事件，调动可用资源，执行相关任务，使不断出现的问题得以解决，防止事务堆积，而不是 Node 特有的一个功能，它是一个概念的引入。这是 Node.js 在单线程的情况下异步编程的基本概念，也是 Node.js 实现高并发的绝招之一: 

​当我们的异步操作开始的时候，如`setTimeout `，Node 会将这个操作分发给别的线程来处理这个事件，在主线程中不造成阻塞继续执行随后的代码，在事件执行结束后，再把结果回调给主线程，整个过程节省了主线程同步等待的时间，完全可以利用这个时间去处理更多的事情，高效的利用了时间以及资源。在 Node 启动的时候，就已经启动了一个 `Event Loop` 一直在轮巡监听和捕获事件，整个过程是交给 libuv 处理的。



## #Q4. 什么是调用栈? 是 V8 的一部分吗？

​调用堆栈是 Javascript 代码执行的基本机制。 当我们调用一个函数时，我们将函数参数和返回地址推送到堆栈。 这允许运行时知道函数结束后继续执行代码的位置。 在Node.js中，调用堆栈由V8处理，我在网上找了一个例子:

![1_E3zTWtEOiDWw7d0n7Vp-mA](1_E3zTWtEOiDWw7d0n7Vp-mA.gif)



​栈和队列是数据结构中的概念，栈是一个**后进先出**(LIFO)的线性表，而队列则是**先进先出**，在语法解析完毕后，我们主函数首先会push到栈底，而文件头的第一个函数`foo()` 存在于栈顶，在执行的过程中，根据后进先出的原则一步一步执行: `foo()` => `bar()` => `main()`，整个过程中，一旦有哪个函数执行失败了，就会抛出错误栈，这就是我们查看堆栈信息的基本背景。

​毫无疑问，v8 提供了 Node 执行代码的能力，栈的执行和调用也离不开 V8



## #Q5. ``setImmediate`` 和 ``process.nextTick`` 是什么关系?

​学习 Node，这个问题是不得不提的，存在的历史也很久远了-.-。解释一下 Node 中的事件循环阶段的队列模型，[官方文档](https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick/)。

```
   ┌───────────────────────────┐
┌─>│           timers          │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     pending callbacks     │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │       idle, prepare       │
│  └─────────────┬─────────────┘      ┌───────────────┐
│  ┌─────────────┴─────────────┐      │   incoming:   │
│  │           poll            │<─────┤  connections, │
│  └─────────────┬─────────────┘      │   data, etc.  │
│  ┌─────────────┴─────────────┐      └───────────────┘
│  │           check           │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
└──┤      close callbacks      │
   └───────────────────────────┘
```

​简而言之就是，`setImmediate `在事件队列中已有的任何I / O事件回调后面排队一个函数。 `process.nextTick`将事件队列头部的函数排队，以便在当前运行的函数完成后立即执行。这个问题的背景在 Node 的[官方文档也有所解释](https://nodejs.org/en/blog/release/v0.10.0/#faster-process-nexttick):

>In v0.8 (and before), the process.nextTick() function scheduled its callback using a spinner on the event loop. This usually caused the callback to be fired before any other I/O. However, it was not guaranteed.
>
> As a result, a lot of programs (including some parts of Node's internals) began using process.nextTick as a "do later, but before any actual I/O is performed" interface. Since it usually works that way, it seemed fine.
>
> However, under load, it's possible for a server to have a lot of I/O scheduled, to the point where the nextTick gets preempted for something else. This led to some odd errors and race conditions, which could not be fixed without changing the semantics of nextTick.
>
> So, that's what we did. In v0.10, nextTick handlers are run right after each call from C++ into JavaScript. That means that, if your JavaScript code calls process.nextTick, then the callback will fire as soon as the code runs to completion, but before going back to the event loop. The race is over, and all is good.
>
> However, there are programs out in the wild that use recursive calls to process.nextTick to avoid pre-empting the I/O event loop for long-running jobs. In order to avoid breaking horribly right away, Node will now print a deprecation warning, and ask you to use setImmediate for these kinds of tasks instead.


​在 Node `v0.8` 版本之前，`process.nextTick()` 函数使用事件循环上的微调器(micro task)调度其回调。这通常导致回调在任何其他 I/O 之前被触发，是没有保证的…在大量 I/O 的情况下，以至于 nextTick 抢占了其他内容。这导致了一些奇怪的错误和竞争条件，如果不改变 nextTick 的语义就无法修复。在 v0.10中 nextTick 处理程序在每次从 C ++ 调用到 JavaScript 之后立即运行。这意味着如果 JavaScript 代码调用process.nextTick，那么一旦代码运行完成，又是在返回事件循环之前，回调将立即触发。



## #Q6. 如何在异步函数中返回一个值，而不是写 callback?

​这个问题类似于「如何避免回调地狱」。这个问题在“现代”来说，直接上 `Promise` 就好了~

```javascript
return Promise.resolve('end')

new Promise((resolve, reject) => {
    resolve('end!')
})
```



## #Q7. spawn, exec, 和 fork 的主要区别是什么？

​这三个属性其实是 Node 中创建子进程的三个方式，通过调用 `child_process` 模块创建出子进程进行一系列操作

- child_process.spawn() ：会异步地衍生子进程，且不会阻塞 Node.js 事件循环。
- child_process.spawnSync() ：则以同步的方式提供同样的功能，但会阻塞事件循环，直到衍生的子进程退出或被终止。
- child_process.exec() ：衍生一个 shell 并在 shell 上运行命令，当完成时会传入 `stdout` 和 `stderr` 到回调函数。
- child_process.fork() ：衍生一个新的 Node.js 进程，并通过建立 IPC 通讯通道来调用指定的模块，该通道允许父进程与子进程之间相互发送信息。

 [Nodejs进阶：如何玩转子进程（child_process）](https://www.cnblogs.com/chyingp/p/node-learning-guide-child_process.html)

 

## #Q8. cluster 模块是如何工作的？

> cluser 模块的基础还是通过 `child_process.fork()` 函数来复制工作进程

​因为 Node.js 是单线程的，无法充分利用服务器的多核处理器，为了解决这个问题，我们通常会启动多个 Node.js 进程来处理高负载， cluster 就是通过创建多个子进程来解决这个问题，并且共享端口。

​它的工作原理就是建立多个子进程，由主进程接收新的请求或连接，然后再通过循环的方式分发给子进程进行处理，从而做到简单的负载均衡。



## #Q9. 如何查看 Node.js 进程所占用的内存？

​这个问题应该是有多个答案，这里我只简单的列举两点，后续可以补充:

- 代码外，通过服务器自身的进程内存查看工具进行检测和探查

- 代码内，通过 [process.memoryUsage()](https://nodejs.org/api/process.html#process_process_memoryusage) 查看占用的内存

  ```json
  {
    rss: 4935680,
    heapTotal: 1826816,
    heapUsed: 650472,
    external: 49879
  }
  //heapTotal和heapUsed是指V8的内存使用情况。 external是指绑定到V8管理的JavaScript对象的C ++对象的内存使用情况
  ```



## #Q10. 什么是 libuv? Node.js 是如何使用它的？

> 这是一个可以用很大篇幅来说明其原理的问题，这里我只做背景介绍和我的粗浅理解

​libuv是一个高性能的，事件驱动的I/O库，并且提供了跨平台（如windows, linux）的API，它的核心工作是提供「事件循环(Event-Loop)」以及一些其他的事件通知和回调函数，提供了一些工具比如定时器，非阻塞的网络请求等等。 是 Node.js 很多复杂能力的提供方，比如事件循环



## #Q11. 如何在 Node 进程退出前做最后的操作？这个操作可以异步吗？ 

> ​这是一个很常见并且容易忽视的问题，在 Node 运行的过程中，难免会遇到因内部错误或者外部原因导致的 程序 crash 或进程退出，我们通常会需要监听这个信号并且记录下来。

可以通过注册 `process.on('exit')` 方法来监听整个「exit」事件，该操作是不可以异步的.

```javascript
function exitHandler(options, err) {
    console.log('clean');
}

process.on('exit', exitHandler.bind(null));
```



除此之外，process.on 所监听的事件还有很多种:

- process.on('beforeExit')
- process.on('disconnect')
- process.on('message')
- process.on('rejectionHandled')
- process.on('uncaughtException')
- process.on('unhandledRejection')
- process.on('warning')
- Signal Events



其中，unhandledRejection 与 uncaughtException 在我们的日常开发中会经常遇见，比如每当Promise被拒绝(reject)时都会发出'unhandledRejection'事件，如果没有被正常`catch()` 住，堆栈信息则会有`unhandledRejection` 的报错产生。



## #Q12. Node 除了依赖 v8 以及 libuv，还依赖了别的吗？

Node 官方 API 有提到: https://nodejs.org/en/docs/meta/topics/dependencies/

- Libraries
  - [V8](https://nodejs.org/en/docs/meta/topics/dependencies/#V8)
  - [libuv](https://nodejs.org/en/docs/meta/topics/dependencies/#libuv)
  - [http-parser](https://nodejs.org/en/docs/meta/topics/dependencies/#http-parser)
  - [c-ares](https://nodejs.org/en/docs/meta/topics/dependencies/#c-ares)
  - [OpenSSL](https://nodejs.org/en/docs/meta/topics/dependencies/#OpenSSL)
  - [zlib](https://nodejs.org/en/docs/meta/topics/dependencies/#zlib)
- Tools
  - [npm](https://nodejs.org/en/docs/meta/topics/dependencies/#npm)
  - [gyp](https://nodejs.org/en/docs/meta/topics/dependencies/#gyp)
  - [gtest](https://nodejs.org/en/docs/meta/topics/dependencies/#gtest)



## #Q13.  require 一个 module 的过程?

1. 检查 `module._cacahe` 是否已经缓存了模块.
2. 如果没有缓存，则创建一个新的模块实例并且存入缓存.
3. 根据所给的模块名调用 `module.load()` 方法，load 完毕后会调用 `module.compile()` 方法进行编译.
4. 如果装载/编译过程中出现了错误，则会抛出错误并且将错误的模块从缓存中移除.
5. 最后返回所依赖的模块: `module.exports`



## #Q14. Node 中模块的循环依赖是如何导致的？应该如何避免？

>  相信很多人在平时的开发中多多少少都会遇到循环依赖的问题，Node 官方也针对这个问题有特别的说明。

假设有这么一个情况:

`a.js`:

```javascript
console.log('a starting');
exports.done = false;
const b = require('./b.js');
console.log('in a, b.done = %j', b.done);
exports.done = true;
console.log('a done');
```

`b.js`:

```javascript
console.log('b starting');
exports.done = false;
const a = require('./a.js');
console.log('in b, a.done = %j', a.done);
exports.done = true;
console.log('b done');
```

`main.js`:

```javascript
console.log('main starting');
const a = require('./a.js');
const b = require('./b.js');
console.log('in main, a.done = %j, b.done = %j', a.done, b.done);
```



当 `main.js` 加载 `a.js` 时，`a.js` 依次加载 `b.js`， 此时，`b.js` 尝试加载 `a.js`， 为了防止无限循环，`a.js` 导出对象的未完成副本将返回到 `b.js` 模块。 然后`b.js` 完成加载，并将其 exports 对象提供给 `a.js` 模块。当 `main.js` 加载了两个模块时，它们都已完成。 因此会输出：

```shell
$ node main.js
main starting
a starting
b starting
in b, a.done = false
b done
in a, b.done = true
a done
in main, a.done = true, b.done = true
```

为了解决循环依赖的问题，我们可以在运行时依赖模块:

```javascript
// 抽象代码
function () {
    require('./a.js')
}
```



## #Q15. 接上一个问题，哪些拓展的文件能够被自动识别并 require 呢？

很多同学可能会查看阮一峰老师的文章来学习[ require 源码](http://www.ruanyifeng.com/blog/2015/05/require.html)，讲得很清晰，但是内容可能已经偏老了(基本概念不变)，源码有了一定的更新，最新地址: [loader.js](https://github.com/nodejs/node/blob/master/lib/internal/modules/cjs/loader.js)，这里我只列举片段查找路径的源码:

其中:

```javascript
module._findPath = function () {
  if (!filename && rc === 1) {  // Directory.
  // try it with each of the extensions at "index"
  if (exts === undefined)
    // 默认支持的拓展: .js、.json、.node
    exts = Object.keys(Module._extensions);
  filename = tryPackage(basePath, exts, isMain);
  if (!filename) {
    filename = tryExtensions(path.resolve(basePath, 'index'), exts, isMain);
  }
} 
}

// Native extension for .js
Module._extensions['.js'] = function(module, filename) {
  var content = fs.readFileSync(filename, 'utf8');
  module._compile(stripBOM(content), filename);
};


// Native extension for .json
Module._extensions['.json'] = function(module, filename) {
  var content = fs.readFileSync(filename, 'utf8');
  try {
    module.exports = JSON.parse(stripBOM(content));
  } catch (err) {
    err.message = filename + ': ' + err.message;
    throw err;
  }
};


// Native extension for .node
Module._extensions['.node'] = function(module, filename) {
  return process.dlopen(module, path.toNamespacedPath(filename));
};

if (experimentalModules) {
  if (asyncESM === undefined) lazyLoadESM();
  Module._extensions['.mjs'] = function(module, filename) {
    throw new ERR_REQUIRE_ESM(filename);
  };
}

```

可以看见，require 默认会加载`.js`、`.json`、`.node` 格式的文件。



## #Q16. 调用 http 启动一个服务并处理 request, response 请求时，为什么要调用 end() 方法?

http.ServerResponse 本身是一个可写流，在处理完所有的操作后，我们需要告诉它执行完毕：response.end()，此方法向服务器发出信号，表明已发送所有响应标头和正文，为了告诉服务器响应完毕，我们必须调用  response.end()。

题外话: 平时的开发学习过程中，使用 stream 时候，比如以流的方式传递一个文件，如果姿势不对，我们可能会遇到 `Error: write after end` ，这也就说明不可以在 end() 后再向 response 写入数据。



## #Q17. 如何输出多层嵌套对象？

```javascript
const obj = {
  a: "a",
  b: {
    c: "c",
    d: {
      e: "e",
      f: {
        g: "g",
      }
    }
  }
};    

const util = require('util');
console.log(util.inspect(obj, {depth: 0})); // prints: '{ a: \'a\', b: [Object]}'
console.log(util.inspect(obj, {depth: null})); // prints: '{ a: \'a\', b: { c: \'c\', d: { e: \'e\', f: { g: \'g\' } } } }'
```



为什么要提出这个问题？经常使用 `console.log` 进行调试的同学应该知道，如果我们只使用 `console.log(obj)` 则只会输出: `{ a: 'a', b: { c: 'c', d: { e: 'e', f: [Object] } } }` 看不见 f 里的内容，这是一个非常痛苦的事情！



## #Q18. node-gyp  模块有什么用处?

这个问题也是平时在 `npm install` 经常出现的一条信息，应该是在安装`grpc` 或者 `node-jieba` 的过程中需要编译一些底层文件，比如 c++ 文件等所使用的，直接搬砖介绍一下:

​	node-gyp是一个用Node.js编写的跨平台命令行工具，用于编译Node.js的本机插件模块。 它捆绑了Chromium团队使用的gyp项目，并消除了处理构建平台中各种差异的痛苦。 它是node-waf程序的替代品，为节点v0.8删除了该程序。 如果你有一个仍然有wscript文件的节点的本机插件，那么你一定要添加一个binding.gyp文件来支持最新版本的节点。



## #Q19. 如果在一个 js 文件里只有一行代码: console.log(arguments)，执行脚本将会输出什么？ 

看过之前问答的同学应该已经能够猜出个大概了，之前介绍 require 的过程的时候，我们已经知道，最后一步是执行 `module._compile` 也就是模块的编译，编译后会返回 `module.exports` 的内容，其实不仅仅是这个，我们查看一下源码:

```javascript
// Run the file contents in the correct scope or sandbox. Expose
// the correct helper variables (require, module, exports) to
// the file.
// Returns exception, if any.
Module.prototype._compile = function(content, filename) {

  content = stripShebang(content);

  // create wrapper function
  var wrapper = Module.wrap(content);

  var compiledWrapper = vm.runInThisContext(wrapper, {
    filename: filename,
    lineOffset: 0,
    displayErrors: true
  });

  var inspectorWrapper = null;
  if (process._breakFirstLine && process._eval == null) {
    if (!resolvedArgv) {
      // we enter the repl if we're not given a filename argument.
      if (process.argv[1]) {
        resolvedArgv = Module._resolveFilename(process.argv[1], null, false);
      } else {
        resolvedArgv = 'repl';
      }
    }

    // Set breakpoint on module start
    if (filename === resolvedArgv) {
      delete process._breakFirstLine;
      inspectorWrapper = process.binding('inspector').callAndPauseOnStart;
    }
  }
  var dirname = path.dirname(filename);
  var require = makeRequireFunction(this);
  var depth = requireDepth;
  if (depth === 0) stat.cache = new Map();
  var result;
  if (inspectorWrapper) {
    result = inspectorWrapper(compiledWrapper, this.exports, this.exports,
                              require, this, filename, dirname);
  } else {
    result = compiledWrapper.call(this.exports, this.exports, require, this,
                                  filename, dirname);
  }
  if (depth === 0) stat.cache = null;
  return result;
};
```



可以清楚地看见

```javascript
result = compiledWrapper.call(this.exports, this.exports, require, this,
                                  filename, dirname);
// 所以当我们运行 console.log(arguments) 的时候，将会输出
// { exports, require, module, __filename, __dirname }
```



## #Q20. 同样是实现异步操作，回调(callback) 与 事件(emitter) 有什么区别呢？

它们两最大的区别就是同样执行一个异步操作，emitter 可以将执行的过程发送到别的地方，只要有方法监听了这个事件就能够被收到，而 callback 只能写在当前函数或者文件中，例:

```javascript
// callback
(function () {
    setTimeout(() => {
    	console.log(1)
	})
})()

// Emitter
(function () {
	emitter.emit('print 1')
})()

emitter.on('print 1', () => {
    console.log(1)
})
```

在项目结构中，后者会更加实用和灵活。



## #Q21. console.time() 也是一个很实用的方法，常用在哪呢？

console.time() 通常不会单独使用，而是配合 console.timeEnd()来测量某个操作的耗时:

```javascript
console.time('100-elements');
for (let i = 0; i < 100; i++) {}
console.timeEnd('100-elements');
// prints 100-elements: 225.438ms
```



持续更新...