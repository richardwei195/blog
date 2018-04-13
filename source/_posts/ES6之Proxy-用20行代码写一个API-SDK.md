---
title: ES6之Proxy-用20行代码写一个API SDK
date: 2018-03-22 14:02:27
tags:
  - nodejs
  - excel
  - javascript
---

## ES6之Proxy-用20行代码写一个API SDK

### 目的

ES6 里新增了很多概念及语法，有很多我们日常开发都会用到，比如数组对象的解构，箭头函数，class 等等，但是类似 `Proxy` 这样的特性却很少用到(个人观点),  借这个机会, 简单的过一遍 `Proxy` 相关的概念及适用场景。

### 准备

完成这样一个任务，我们需要知道哪些知识点呢?

1.  [`Proxy` 的基本概念](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Proxy)
2.  `API`  基本设计及规范, 这里附上 Google的 [ `REST API` 设计规范](https://cloud.google.com/apis/design/resources)

### 内容

#### 一、Proxy的基本概念及用法case

> MDN 对它的定义:  **Proxy 对象用于定义基本操作的自定义行为（如属性查找，赋值，枚举，函数调用等）**。

简单来说，就是对即将处理的目标对象，在操作的中间过程实现一个**代理转发**，实现对目标对象的属性或者方法进行拦截、过滤甚至修改。

**语法说明**：

```js
const p = new Proxy(target, handler)
```

-  `target `  表示所要拦截的目标对象
- `handler ` 也是一个对象，用来定制拦截行为

其中 `handler`  也包含了许多的属性和方法，其中 `get()`、`set()` 、`construct()`、`apply()` 、`has()`方法是我们常用的几个方法



**技能一、无中生有**

​	`get` 方法 ，可以让我们轻松地对所操作的对象进行访问拦截、修改，即使它是不存的属性或者方法。

举个栗子:

```js
const extend = obj => {
  return new Proxy(obj, {
    get(target, propertyKey) {
      console.log(`New People:  "${propertyKey}"`)
      target[propertyKey] = 'Welcome to Teambition NG!'
      return target
    }
  })
}
const object = { L: 'Welcome to Teambition!' }
const extended = extend(object)
console.log('object', extended.W)
```

输出如下

```js
New People:  "W"
object { L: 'Welcome to Teambition!', W: 'Welcome to Teambition NG!' }
```

在这个例子中，我们在访问属性之前调用了 `get()`，使我们的对象除了原有的属性之外，实现了类似"抽象属性"的概念:  继承了原有的属性和方法的同时，派生及重载出新的 `key/value`。


值得一提的是: 如果一个属性`不可配置（configurable）` 和 `不可写（writable）`，则该属性不能被代理，通过 Proxy 对象访问该属性会报错。

```js
const target = Object.defineProperties({}, {
  foo: {
    value: 123,
    writable: false,
    configurable: false
  },
});

const handler = {
  get(target, propKey) {
    return 'abc';
  }
};

const proxy = new Proxy(target, handler);

proxy.foo
// TypeError: Invariant check failed
```



**技能二、偷梁换柱**

```
const extend = obj => {
  return new Proxy(obj, {
    set(target, propertyKey, value) {
      if (propertyKey === 'J') {
        target[propertyKey] = 'I agree'
      }
      return target
    }
  })
}
const object = { L: 'Welcome to Teambition!' }
const extended = extend(object)
extended.J = 'I refuse!'
console.log('extended', extended)
```

输出:

```
extended { L: 'Welcome to Teambition!', J: 'I agree' }
```



可以看见，在原有欢迎致辞对象中，角色 `J `原本给出的是拒绝的信息: `I refuse!`，但经过代理器内部的筛选及过滤，输出为 `I agree`。大家可以YY一下类似的场景，是不是可以用  `Proxy` 方法来更便捷实现呢？

除了以上两个技能之外，`Proxy` 还有这些技能能被我们应用

- 参数验证
- 属性替换
- 属性查找
- ...



#### 二、用20行代码写一个API SDK

​	实现这样一个 Demo，我们只需要理解，当我们在读取某个代理对象的属性或者方法的时候, `Proxy`  的get方法将被调用，通过 get 方法我们可以动态改变代理对象的属性和方法。 例如，我们可以有一个代理，当使用 `api.getUsers()` 调用代理时，它可以直接在 API 中实现 获取某个用户(GET: /users/ )，或者是获取某个用户喜欢的事(GET: /users/xxx/likes)。

​	有了这个约定，我们还可以实现一个 POST 请求，并且能够动态传入 body，比如`api.postItems（{name：'Item name'}）`将第一个参数作为请求体调用 POST / items



完整栗子:

```js
const { METHODS } = require('http')
const api = new Proxy({},
  {
    get(target, propKey) {
      const method = METHODS.find(method =>
        propKey.startsWith(method.toLowerCase()))
      if (!method) return
      const path =
        '/' +
        propKey
          .substring(method.length)
          .replace(/([a-z])([A-Z])/g, '$1/$2')
          .replace(/\$/g, '/$/')
          .toLowerCase()
      return (...args) => {
        const finalPath = path.replace(/\$/g, () => args.shift())
        const queryOrBody = args.shift() || {}
        console.log(method, finalPath, queryOrBody)
      }
    }
  }
)

api.get()
api.getUsers()
api.getUsers$Likes('1234')
api.getUsers$Likes('1234', { page: 2 })
api.postItems({ name: 'Item name' })
api.foobar()
```

输出:

```shell
GET / {}
GET /users {}
GET /users/1234/likes {}
GET /users/1234/likes { page: 2 }
POST /items { name: 'Item name' }
/Users/jiangwei/git/test/block/demo2.js:36
api.foobar()
    ^

TypeError: api.foobar is not a function
    at Object.<anonymous> (/Users/jiangwei/git/test/block/demo2.js:36:5)
    at Module._compile (module.js:643:30)
    at Object.Module._extensions..js (module.js:654:10)
    at Module.load (module.js:556:32)
    at tryModuleLoad (module.js:499:12)
    at Function.Module._load (module.js:491:3)
    at Function.Module.runMain (module.js:684:10)
    at startup (bootstrap_node.js:187:16)
    at bootstrap_node.js:608:3
```



这里我们代理的对象原本是一个空对象，所有的方法都是通过 get 属性动态实现。通过简单的 `Proxy` 相关属性和方法的运用，结合正则，解析出我们想要的数据结构并使用



参考文献:

http://es6.ruanyifeng.com/#docs/proxy

https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Proxy