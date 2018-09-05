---
title: '细说javascript中的“指针”'
date: 2018-01-17 14:05:23
author: 
  nick: Richardwei
  link: https://github.com/richardwei195
tags:
  - nodejs
  - javascript
---

### 故事背景

> 最近有朋友问我为什么我运行js代码会抛出如下异常

```js
const Hoek = require(&#39;hoek&#39;);
^^^^^
SyntaxError: Use of const in strict mode.
} 
```
<!-- more -->
代码中有些乱码咱们就不细看，如果我们了解ES5的话，这是ES5所提供的`严格模式`, 解决方法可以是在文件或代码前加上"use strict"，如果不是很了解，可以参考文章[Javascript 严格模式详解](http://www.ruanyifeng.com/blog/2013/01/javascript_strict_mode.html)

很久没有遇到这类问题啦，所以就联想到当初遇到的一个大坑:关于js变量指向的内存地址和指针(有朋友会问，js中有指针的概念吗，js是有传址这一概念的-。-)。

### 结合栗子我们讲讲概念

刚开始学习js或者说ES6的时候，会遇到这样一个问题(默认你的环境已经能够正确兼容ES6)
```js
const a = 1
a = 2
// 这里比较好理解，`const`声明的是一个常量，
// 如果要更改常量的值，编译过程肯定会抛出错误`TypeError: Assignment to constant variable`
// 告诉你声明的变量是一个常量,不可被改变
```

就简单的提一下`const`，顾名思义，`const`所声明的变量值不能被改变，那么在变量被声明的时候就应该被赋予了一个正确的值，可以是字符串，整型等(仔细想想，不赋予值，以后改不了了呀)

```js
const a
// SyntaxError: Missing initializer in const declaration
// 变量没有被初始化
```

**那么我们是不是就可以安然无忧的用`const`来声明我们的常量了呢，答案是可以的，但前提你应该知道这个**

```js
const obj = {}
obj.name = 'allen'

console.log(obj.name) // 'allen'
```

是的，对象的值被改变了，说好的`const`说声明的值不能被改变呢？(感觉受到了欺骗)，所以这个时候我们就应该怀疑，`const`它实际所保证的是变量的值不能被改变的吗？我们再举一个例子

```js
const obj = { name: 'allen' }
const _obj = obj

console.log(_obj) // { name: 'allen' }

obj.name = 'melo'

console.log(_obj) // { name: 'melo' }
```

走到这里我们能够猜测到，`const`所保证的应该是变量指向的**内存地址**不能够被改变，也就是保存的指针, 并不是保证变量的值不可以被改变，同理，当我们操作数组的时候，也会出现类似的情况，这就是`引用传递`(`指针传递`)

**所以，在常量声明中，我们应该特别注意声明的变量如果是对象或数组类型，他实际上是可以被改变的**

如果需要保证原本的对象本身不被改变，我们可以使用`Object.freeze()`来冻结所声明的对象变量

```js
const obj = Object.freeze({})

obj.name = 'allen'
```
这一方法的解释是
> Object.freeze() 方法可以冻结一个对象，冻结指的是不能向这个对象添加新的属性，不能修改其已有属性的值，不能删除已有属性，以及不能修改该对象已有属性的可枚举性、可配置性、可写性。也就是说，这个对象永远是不可变的。该方法返回被冻结的对象。

### 类似的问题，再举一个我们平常可能会遇到的坑

对于数组，我们有`map()`方法能够遍历原来的数组，改变原始数组的元素，并生成一个新的数组，通用的方法是

```js
let array = [1, 2, 3]
let newArray = array.map(item => ++item)
console.log('newArray', newArray) // newArray: [2, 3, 4]
```
这是我们最常见的`map()`用法，但是请注意, 如果你操作的是一个对象数组, 那么原数组就可能被改变，原因就是我们之前提到的，实际改变的，是对象在被声明时所分配的内存地址的值，所以会发生指针没有被改变，但是指向的数据结构可以被改变

```js
const array = [{ name: 'allen' }]
const _arr = array

console.log(_arr) // [{ name: 'allen' }]

array.map(item => item.name = 'melo')

console.log(_arr) // [{ name: 'melo' }]
console.log(array) // [{ name: 'melo' }]
```
因为array指针所指向的值被改变了，那么相应的变量所指向的那块内存地址所保存的指针也就被改变了，这也是一个比较经典的例子

### 结语

所以在实际的学习和开发的过程我们很有可能遇见这样的情况，那么这个时候我们就必须要留意指针所带给我们的便利性和风险，只要充分的理解了这一概念，这一类的错误我们就可以轻松避免或者排查出问题所在。

很久没有写博客了，最近工作任务比较繁重，没能坚持产出，新的一年必须得有所改变了，不忘初心