---
title: 周总结
date: 2018-11-18 16:09:45
tags:
  - Summary
  - Share
---

一周过去了，从大学到工作一直有个习惯就是把每周琐碎、临时记下来的东西总结回顾一下，这两个月真的好忙好忙断了好久，好多不清楚的东西还是不清楚，重新踏上我的旅程吧~

## JS

### 一、JS 如何实现数组或对象的深拷贝

无意间在 SF 上看见一个同学问 `JS 如何实现数组或对象的深拷贝`，往下划了几个答案都挺常规，用 `lodash` 哇，`JSON.parse()&JSON.stringify()`，`[].concat()`、`递归` 等方式，不过有一条对数组的实现让我耳目一新(是我知识太浅薄了~): 用 ES6 的结构语法实现深拷贝。

```js
const a = [1,2,3,4]
const [...b] = a
a[1] = 1

a === b?
```
简单粗暴哈~，举一反三，脑袋里面在回想一下 `引用传递`, `值传递` 的那些坑-。-

### 二、JS 数组实现浅谈

看见一个淘汰算法 [hashlru](https://github.com/dominictarr/hashlru), 也是同事使用我看见的，和同事聊了一下，也看了一下实现原理，对 JS 的对象、数组实现有了一些新的认识，或者说是我以前了解得太少了，没事不晚赶紧记下~

```
源码注释:
// The JSArray describes JavaScript Arrays
//  Such an array can be in one of two modes:
//    - fast, backing storage is a FixedArray and length <= elements.length();
//       Please note: push and pop can be used to grow and shrink the array.
//    - slow, backing storage is a HashTable with numbers as keys.
class JSArray: public JSObject {
 public:
  // [length]: The length property.
  DECL_ACCESSORS(length, Object)

  // Number of element slots to pre-allocate for an empty array.
  static const int kPreallocatedArrayElements = 4;
};
```
JS 的数组实现有两种模式，一种是 “快” 模式，一种是 “慢” 模式，怎么理解呢，又去查了一下文章，其实“慢”模式比较好理解，就是通过哈希表的方式来进行存储查找，但是“快”模式中提到的 `FixedArray` 让我不太好从字面上来进行理解，只清楚和数组的长度可能有些联系，于是又去查了一下 `FixedArray` 的相关实现和解释：

其实翻译过来应该叫做 `固定数组大小` 的数组，也就是在编译的时候就已经知道具体大小的数组，其实就是声明一个数组的时候指明需要使用的长度，其实这么想想我也就明白了，原理还是一样的，其实我们都知道数组在内存里是连续的，如果我们预先指定了数组的长度，那么在查找或者更新某个元素的时候时间复杂度就是 O(1)，按`索引`进行排列，通过`索引`就可以找到了，如果我们预先不清楚数组的长度，那么当我们对数组进行插入或者删除操作的时候，超过了容量阈值，可能会进行“搬移操作”，以便内存地址能够连续并且足够“大”，但这样的话整个操作就会变慢。

所以当我们进行如下操作的时候，数组其实是一个“快”模式:

```js
const arr = new Array(3)
arr[0] = 1
// push、pos 也会在“快”模式的基础上进行长度的增加或减少
```

进行如下操作的时候，就是“慢”模式:
```js
const arr2 = new Array(2)

arr2[500] = 1
// 这个时候如果我们还是按索引顺序排列的话，将会是 0, 1, 2, ... 500 = 1 浪费了不少的空间并且还需要扩容，是没有必要的，
// 因此如果我们将只记住 0, 1, 500 的话，就能有效地节省开销了
```


## Node.JS

探讨一下 Node 的 GC 方面的知识吧，也是看了 (Node 案发现场揭秘 —— 如何利用 GC 日志不修改代码调优应用性能)[https://zhuanlan.zhihu.com/p/47425089] 这篇文章有所体会，还有张大神的视频分享: [https://www.youtube.com/watch?v=DSBLAG2IvsY](https://www.youtube.com/watch?v=DSBLAG2IvsY)，背景不说了，上结论:

- 我们可以通过设置一系列 flag 来实时获取到不同级别的 V8 GC 日志信息：
  - `--trace_gc`: 一行日志简要描述每次 GC 时的时间、类型、堆大小变化和产生原因
  - `--trace_gc_verbose`: 结合 --trace_gc 一起开启的话会展示每次 GC 后每个 V8 堆空间的详细状况
  - `--trace_gc_nvp`: 每一次 GC 的一些详细键值对信息，包含 GC 类型，暂停时间，内存变化等信息

- 老生代内存空间应该设置为 `--max-old-space-size=768` 
- GC 优化的点集中在 `scavenge` 回收阶段，即新生代的内存回收。这个阶段触发回收的条件是：`semi space allocation failed`, `--max-semi-space-size=64`，这样只要没有内存泄露，Node.js的服务是可以正常运行。

## K8s

网易云分享的 [k8s service](https://zhuanlan.zhihu.com/p/39909011) 一些基本背景知识，对 k8s 的负载均衡分发策略等等做了一些简单的介绍，多多了解也还是不错的~
