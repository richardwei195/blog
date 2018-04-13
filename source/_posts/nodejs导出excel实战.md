---
title: nodejs导出excel实战
date: 2017-06-23 17:38:39
tags:
  - nodejs
  - javascript
---



我们都知道nodejs的内存由于v8内存分配机制的原因十分有限

![](http://blog.richardwei.cn/asset/V8%E7%9A%84%E5%86%85%E5%AD%98%E5%88%86%E9%85%8D.png)

64位系统也只能占1.4G左右, 因此当我们要生成或者读取大文件的时候内存的吃紧会给我们造成极大的困扰, 遇到这样的情况Node给了我们一个很好的解决方法 `stream`

# 简单的了解一下流

> 流是数据的集合 —— 就像数组或字符串一样。区别在于流中的数据可能不会立刻就全部可用，并且你无需一次性地把这些数据全部放入内存。这使得流在操作大量数据或是数据从外部来源逐段发送过来的时候变得非常有用

管道与流的结合在linux中运用得非常多, 也使得linux能够通过 `pipe` 组合多个命令实现复杂的功能, 其实通俗一点来说, `stream` 就是把我们需要一口气吃下的东西分成多次按量的吃下去, 避免一口气吃撑, 在吃的过程中, 我们甚至可以边 ”吃“ 边 ”排“（transform）, 使我们的身体能够保持一个均衡低负荷的状态, 同时, 也就是保证node进程内存不会太吃紧的条件.

## nodejs中的流

因为先天的原因, 流在node中通常被我们用来处理大文件, 甚至说在nodejs的各类模块中均采用了 `stream`

- 在server中的 `http request` 是可读流(`Readable Stream`), `http response`是一个可写流(`Writable Stream`), 这也就是为什么我们通常在request中读取client传回的值, 而通过response写入数据返回
- fs则是一个可读可写的流(`Duplex Stream`), 我们可以对一个文件进行写入和读取的操作

以上这些模块只是nodejs中流应用的一小部分场景, 在其官方API中流的类型和解释则是
 
> - `Readable` - streams from which data can be read (for example [fs.createReadStream()](https://nodejs.org/dist/latest-v8.x/docs/api/fs.html#fs_fs_createreadstream_path_options)).
- `Writable` - streams to which data can be written (for example [fs.createWriteStream()](https://nodejs.org/dist/latest-v8.x/docs/api/fs.html#fs_fs_createwritestream_path_options)).
- `Duplex` - streams that are both Readable and Writable (for example [net.Socket](https://nodejs.org/dist/latest-v8.x/docs/api/net.html#net_class_net_socket)).
- `Transform` - Duplex streams that can modify or transform the data as it is written and read (for example [zlib.createDeflate()](https://nodejs.org/dist/latest-v8.x/docs/api/zlib.html#zlib_zlib_createdeflate_options)).

没错也就是四种类型, 其中transform继承自duplex

## 流的典型例子

在nodejs中读取和写入大文件通常是流应用得最广泛、最重要的场景之一, 这也是写这篇博客的原因之一, 因此以一个简单的文件读取的例子作为我们了解流的小Demo

读取一个大小为160M的文件, 采用fs.readFile()方法

```javascript
const fs = require('fs')
const server = require('http').createServer()

server.on('request', (req, res) => {
  fs.readFile('./Demo.txt', (err, result)=>{
  	if(err){
  	  throw err
  	}
  	res.end(result)
  })
})

server.listen(3000)
```

启动这样一个node进程, 内存占用约为8m, 当我们执行请求 `curl localhost:3000`时, 会发现内存暴增到160m, 差不多是我们读取的文件的大小

![](http://blog.richardwei.cn/asset/yuansheng.png)

![](http://blog.richardwei.cn/asset/160.png)

采用流读取的方式

```javascript
const fs = require('fs')
const server = require('http').createServer()

server.on('request', (req, res) => {
  let data = fs.createReadStream('./Demo.txt')
  data.pipe(res)
})

server.listen(3000)

```

![](http://blog.richardwei.cn/asset/10.png)

可以看见内存基本稳定在11m, 这证明了采用读取流方式在内存上给我们带来了极大的优化, 当然这只是一个小Demo, 我们可以尝试着去读取1G 甚至超过2G的文件, fs.readFile()的方式可能就会突破内存的限制而导致进程crash掉, 假如在生产环境中, 请求多并发相对较高的环境下, 这种方式是行不通的


# 通过流的方式导出Excel文件

## 背景

需求是希望能够将项目下的所有分组以一个项目excel文件包含多个分组sheet导出

如果是导出csv文件, 我们完全可以通过流的方式导出, 但是在excel中, 由于文件类型的限制, 我们很难把excel通过流的方式直接导出, 最终选择了[exceljs](https://github.com/guyonroche/exceljs)

## 编码格式

- node.js支持 `ascii` 、`utf8`、`base64`、`binary` 编码方式，不支持 `utf-8 + BOM(字节顺序标记)` 格式, 而微软给utf8加了BOM头(在windows下不管是utf8还是utf16(Unicode)都有BOM, utf16自带BOM头), 因此excel会出现中文乱码, 因此我们需要在文件头加上三个标识字节, 由于utf8对应的BOM是 `EF BB BF` [传送门](https://zh.wikipedia.org/wiki/%E4%BD%8D%E5%85%83%E7%B5%84%E9%A0%86%E5%BA%8F%E8%A8%98%E8%99%9F), 因此这么实现: `res.write(Buffer.from('\xEF\xBB\xBF', 'binary'))` 

- 既然是导出excel文件, 那文件内容('Content-Type')是什么, 最终在StackOverflow上找到了答案, 传送门[StackOverflow](https://stackoverflow.com/questions/4212861/what-is-a-correct-mime-type-for-docx-pptx-etc), 文件类型有专属的Office套件: `'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'`


## 实现

使用exceljs最重要的原因是支持伪流

>The interface to the streaming workbook and worksheet is almost the same as the document versions with a few minor practical differences:

> - Once a worksheet is added to a workbook, it cannot be removed.
- Once a row is committed, it is no longer accessible since it will have been dropped from the worksheet.
- unMergeCells() is not supported.

从文档的说明来看, exceljs是支持将每一个sheet写入excel document中, 然后立马pipe出去, 这是相对可行的一个方案, 但是当每个sheet数据量过大怎么办？ 同样会导致我们内存的暴增, 导致进程的crash, 而源码也确实是这样实现了[exceljs Stream](https://github.com/guyonroche/exceljs#streaming-io), 所以这是一个伪流, 它并没有解决我们的根本问题, 但是很大程度的舒缓了我们遇到的问题, 问题的根本原因还是在excel中我们需要区别每一个sheet, 导致我们不能持续的进行读写, 还是需要先把这部分的数据先读取到内存中进行写入。 这也导致我们在业务代码中需要添加一些数据量上的限制针对每一个sheet

部分代码, Demo.coffee

```javascript
res.set('Content-Type','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

res.setHeader('Content-Disposition', filename)
res.set('Set-Cookie', 'fileDownload=true; path=/')

excel = require('exceljs')

options = {
	stream: res,
	useStyles: true,
	useSharedStrings: true
}

workbook = new excel.stream.xlsx.WorkbookWriter(options)

worksheet = workbook.addWorksheet(tasklist.title)
headers = [
  { header: 'csv.content', width: 15 }
  { header: 'csv.ancestor', width: 10 }
  { header: 'csv.note',  width: 20 }
  { header: 'csv.priority', width: 10 }
  { header: 'csv.executor', width: 10 }
  { header: 'csv.startDate', width: 20 }
  { header: 'csv.dueDate', width: 20 }
  { header: 'csv.creator', width: 20 }
  { header: 'csv.created', width: 20 }
  { header: 'csv.isDone', width: 10 }
  { header: 'csv.accomplished', width: 20 }
  { header: 'csv.tasklist', width: 10 }
  { header: 'csv.stage', width: 10 }
  { header: 'csv.delayDays', width: 10 }
  { header: 'csv.delayed', width: 10 }
  { header: 'csv.totaltime', width: 10 }
  { header: 'csv.usedtime', width: 10 }
  { header: 'csv.tag', width: 10 }
]

// 生成标题头
worksheet.columns = headers

rows = [
    [5,'Bob',new Date()], // row by array
    {id:6, name: 'Barbara', dob: new Date()}
]
worksheet.addRows rows

worksheet.commit()
workbook.commit()

```

## 总结

导出excel仅仅是`stream`一个小小的体现和应用, 真正要掌握它的整个实现背景和场景应用还是需要我们去实践以及查看源码的实现, 这里仅仅是一个读、写的单向实现, 可以去尝试transform从一个文件读取数据进行相关处理之后写入一个新的文件, 这样更能感受它给我们带来的性能上优化和简便, 以上

