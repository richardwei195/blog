---
title: nodejs通过tb-excel自定义解析Excel
date: 2017-08-11 10:40:35
category: 技术
tags:
  - Node.Js
  - Javascript
---
> 众多的库中，能够很轻松的找到解析xlsx, csv格式文件的第三方库，并且有许多质量不错的库，如 `node-xlsx` , `excel-parser`,  `excel-export`等，都能够帮助我们解析或者生成xlsx, csv文件，但是大部分都局限于文件
<!-- more -->
[GitHub](https://github.com/richardwei195/tb-excel)

# 背景

在实际的生产环境中，为了避免大量的io和并发等性能压力，我们通常不会将文件直接上传或者生成到本地，比如我们要解析一个excel文件(xlsx)，我们通常会将文件上传到文件服务器(OSS,  Striker)，然后通过访问文件服务器拿到我们想要的资源进行处理

在网上看了几个库, 做的事情大同小异，但是都满足不了我们想要的结果:

- 除了能够直接读取文件，我们还希望能够直接塞buffer进行数据解析(UTF8+BOM)
- 我们希望解析出来的数据不需要我们额外造轮子进行格式转换:  通常解析出来是一个二维数组, 希望能够把每个地址的值赋给我们约定好的key，然后转为数组对象
- 通过http请求拿到的数据能够直接解析
- 高度可定制化

# 撸起袖子干

## 净化原始数据

> 我们将Excel一行约定为 `row` , 列约定为 `cel`

若一个Excel中一个sheet的内容如下:

|  三餐  |  主菜  |  副菜  |
| :--: | :--: | :--: |
|  早餐  |  油条  |  豆浆  |
|  午餐  | 小炒肉  | 鸡蛋汤  |
|  晚餐  | 大炒肉  | 番茄汤  |

我并不希望拿到第一行的列标题`三餐`, `主菜`, `副菜`, 它应该作为每一组对象的key。

我希望的是这样的, 约定一套规则:

```javascript
[
  'dinner(三餐)',
  'mail(主菜)',
  'sub(副菜)'
]
```

能够直接生成我想要的数组对象

```javascript
[
  {
    dinner: "早餐",
    mail: "油条",
    sub: "豆浆"
  },
  {
    dinner: "午餐",
    mail: "小炒肉",
    sub: "鸡蛋汤"
  },
  {
    dinner: "晚餐",
    mail: "大炒肉",
    sub: "番茄汤"
  }
]
```

xlsx默认是 `utf8+BOM(EF BB BF)` 或 `utf16` 编码，通常我们readFile或者http.request收到的数据会长这样:

```shell
<Buffer 50 4b 03 04 14 00 06 00 08 00 00 00 21 00 42 3b 3e c9 59 01 00 00 90 04 00 00 13 00 08 02 5b 43 6f 6e 74 65 6e 74 5f 54 79 70 65 73 5d 2e 78 6d 6c 20 ... >
```

这些数据我们可以通过exceljs的内部方法xlsx.load进行加载解析，拿到我们想要的格式:

```javascript
workbook.xlsx.load(data)
```

我们可以拿到这样的数据:

```javascript
[
  []，
  ['三餐', '主菜', '副菜'],
  ['早餐', '油条', '豆浆'],
  ['午餐', '小炒肉', '鸡蛋汤'],
  ['晚餐', '大炒肉', '番茄汤']
]
```

是一个二维数组, 并且以一个空数组打头，其实这一样默认是Excel中的 "列标题"

[A, B, C, D, ……]，我们称他为脏数据，或者说是一个索引。

>  当然这组数据是一个非常理想化的数据，为什么这么说？

Excel中单元格的格式及其丰富, 比如日期格式，货币格式，超链接格式，富文本格式等等, 比如，我们有个单元格的内容为 [百度](wwww.baidu.com) 这样的超链接格式，则会load出这样格式的数据:

```javascript
[
    [
      {
        text:'百度', 
        link:{
          text: 'www.baidu.com', 
          url: 'www.baidu.com'
        }
      }
    ]
]
```

可以看出，这绝不是我们想要的结果，而这仅仅是所有格式中的一种(超链接), 也是比较常见的一种，因此在load完毕后，我们还需要对拿到的数据进行过滤和筛选，过滤掉无用的信息:

```js
const _ = require('lodash')

function cellToString (cell) {
  if (_.isDate(cell)) {
    return cell.toISOString()
  } else if (_.isBoolean(cell)) {
    return `${cell}`
  } else if (_.isObject(cell) && _.isArray(cell.richText)) {
    return cell.richText.map((ele) => {
      return cellToString(ele.text)
    }).join('')
  } else if (_.isObject(cell) && _.isObject(cell.text)) {
    return cellToString(cell.text)
  } else if (_.isObject(cell) && _.isString(cell.text)) {
    return `${cell.text}`
  } else if (_.isString(cell)) {
    return cell
  } else if (_.isNumber(cell)) {
    return `${cell}`
  } else if (_.isUndefined(cell) || _.isNull(cell)) {
    return ''
  } else {
    throw new Error(`unknown type ${cell.constructor.name}`)
  }
}
```

通过这样一个递归函数，我们可以过滤掉大部分常用的格式，包括Mac下Number中使用到的格式，而对于未知的格式，我们应该手动抛出一个Error，这样我们就可以拿到一个较为干净的数据

## 数据格式化

> 对一手数据进行再加工，价值最大化

一个毫无规则的二位数组对我们来说并没有产生其应有的价值，我们并不知道每组数据应该长成什么样，怎么对应起来，因此我们还需要对其加工，再造……

假设我们拿到的二维数组是这样:

```js
[
    ['a', 'b'],
  	['c', 'd']
]
```

而我们最终希望数据能够张这样:

```js
[
    {
        first: 'a',
      	last: 'b'
    },
  	{
        first: 'c',
      	last: 'd'
    }
]
```

这样我们便知道了a, b, c, d分别对应什么变量

想要达到这样的结果其实也不难，我们只需要事先定义好我们的规则，然后在遍历数组的时候进行赋值即可:

```js
for (let index = 0; index < this.rows.length; index++) {
  let row = this.rows[index]
  // Remove the serial number of the first column of each row
  // 与列的格式一样，每一行的第一位也是索引，也是脏数据，去掉
  row = _.drop(row, 1)
  let _data = {}
  for (let index = 0; index < this.rule.length; index++) {
    const rule = this.rule[index]
    _data[rule] = row[index] || ''
  }
  if (_.compact(_.values(_data)).length !== 0) {
   	this.jsonArray.push(_data)
  }
}
```

在Excel中，可能需要过滤掉开头的第一行或者几行，我们也可以写出相应的方法进行过滤

## 优化

我们通常会把以上的每一步封装成为一个工具类进行调用，其中每一步都是环环相扣，我们需要考虑更多的场景以及优化相关的问题：

- 原始数据没有解析并允许调用格式化的方法


- 原始数据解析后进行缓存
- 解析出错抛出异常(针对开发者)
- 对解析的数量进行限制
- ……

```js
'use strict'

const Excel = require('exceljs')
const _ = require('lodash')

function cellToString (cell) {
  if (_.isDate(cell)) {
    return cell.toISOString()
  } else if (_.isBoolean(cell)) {
    return `${cell}`
  } else if (_.isObject(cell) && _.isArray(cell.richText)) {
    return cell.richText.map((ele) => {
      return cellToString(ele.text)
    }).join('')
  } else if (_.isObject(cell) && _.isObject(cell.text)) {
    return cellToString(cell.text)
  } else if (_.isObject(cell) && _.isString(cell.text)) {
    return `${cell.text}`
  } else if (_.isString(cell)) {
    return cell
  } else if (_.isNumber(cell)) {
    return `${cell}`
  } else if (_.isUndefined(cell) || _.isNull(cell)) {
    return ''
  } else {
    throw new Error(`unknown type ${cell.constructor.name}`)
  }
}

class ExcelParser {
  constructor (data, rule, limit) {
    this.rule = rule
    this.data = data
    this.limit = limit
    this.headerline = 2
    this.rows = []
    this.hasParsed = false
    this.hastoArray = false
    this.jsonArray = []
  }

  setHeaderline (headerline) {
    this.headerline = headerline
  }

  get isExccedLimit () {
    return this.rows.length > this.limit
  }

  parse () {
    if (this.hasParsed) return this.rows
    let workbook = new Excel.Workbook()
    return new Promise((resolve, reject) => {
      workbook.xlsx.load(this.data).then((data) => {
        let worksheet = data.getWorksheet(1)
        this.rows = worksheet.getSheetValues()

        // the first row include(A,B,C,D...), its useless
        this.rows = _.drop(this.rows, this.headerline + 1)
        this.hasParsed = true
        this.rows = this.rows.map((row) => {
          return row.map((cell) => {
            return cellToString(cell)
          })
        })
        resolve(this.rows)
      }).catch((err) => {
        reject(err)
      })
    })
  }

  toArray () {
    if (!this.hasParsed) throw new Error('need parse before')
    if (this.hastoArray) return this.jsonArray
    for (let index = 0; index < this.rows.length; index++) {
      let row = this.rows[index]
      // Remove the serial number of the first column of each row
      row = _.drop(row, 1)
      let _data = {}
      for (let index = 0; index < this.rule.length; index++) {
        const rule = this.rule[index]
        _data[rule] = row[index] || ''
      }
      if (_.compact(_.values(_data)).length !== 0) {
       this.jsonArray.push(_data)   
      }
    }
    this.hastoArray = true
    return this.jsonArray
  }
}

module.exports = ExcelParser
```



以上就是整个实现过程，源码已经上传到[GitHub](https://github.com/richardwei195/tb-excel) 和发布到 `npm`