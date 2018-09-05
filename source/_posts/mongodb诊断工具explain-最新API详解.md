---
title: mongodb诊断工具explain()最新API详解
date: 2016-12-26 11:20:02
cover: https://webassets.mongodb.com/_com_assets/cms/MongoDB-Logo-5c3a7405a85675366beb3a5ec4c032348c390b3f142f5e6dddf1d78e2df5cb5c.png
author: 
  nick: Richardwei
  link: https://github.com/richardwei195
tags:
  - mongodb
---
###起因

---

> 说道explain()我就不得不吐槽一下被坑的经过（假设你已知晓索引相关概念）

在数据量和吞吐量越发庞大的今天，优化查询速度是提高系统性能的一个关键点，而获取这类相关信息的重要诊断工具之一就是explain()，引用用《MongoDb权威指南》书中的解释：

> 通过查看一个查询（find）的explain()输出信息，可以知道查询使用了哪个索引，以及是如何使用的。
> 最常见的输出有两种类型：使用索引的查询和没有使用索引的查询
<!-- more -->
当然了，没有使用索引的查询的explain()的输出类型是最基本的类型，而没有使用索引的查询并不是胡乱查询，而是使用了基本游标：BasicCursor，同理，使用索引的查询就是BtreeCursor。

既然提到了输出信息，就不得不强调大部分书籍和资料所提供的API，以查询users集合为例：

	db.users.find({gender:"M"},{user_name:1,_id:0}).explain()

大部分资料会给出如下输出信息

	{
	   "cursor" : "BtreeCursor gender_1_user_name_1",
	   "isMultiKey" : false,
	   "n" : 1,
	   "nscannedObjects" : 0,
	   "nscanned" : 1,
	   "nscannedObjectsAllPlans" : 0,
	   "nscannedAllPlans" : 1,
	   "scanAndOrder" : false,
	   "indexOnly" : true,
	   "nYields" : 0,
	   "nChunkSkips" : 0,
	   "millis" : 0,
	   "indexBounds" : {
	      "gender" : [
	         [
	            "M",
	            "M"
	         ]
	      ],
	      "user_name" : [
	         [
	            {
	               "$minElement" : 1
	            },
	            {
	               "$maxElement" : 1
	            }
	         ]
	      ]
	   }
	}
暂时先不说为什么这个Demo有什么问题，借这个机会也来普及一下其中的一些关键信息。

 - isMultiKey ：本次查询是否使用了多键、复合索引
 - n : 查询返回的数量
 - nscannedObjects ：数据库按照索引去磁盘上查找实际文档的次数
 - nscanned：查找过的索引条目的数量
 - scanAndOrder ： 是否在内存中对结果进行了排序
 - indexOnly : 是否仅仅使用索引完成了本次查询
 - nYields : 本次查询的暂停次数
 - millis : ```执行本次查询所花费的时间，以毫秒计算，这也是判断查询效率的一个重点```
 - indexBounds : 描述索引的使用情况。
 
那么再复杂的例子我就不说了，介绍完输出的主键之后，就讲讲为什么会被这些数据“坑呢”？

###经过

---

依照着资料所提供的查询方法

>  db.collection.method(...).explain()

我尝试着在本地的数据库进行相关尝试，而结果是

	db.pages.find().explain()
	{
		"queryPlanner" : {
			"plannerVersion" : 1,
			"namespace" : "qukenotepro.pages",
			"indexFilterSet" : false,
			"parsedQuery" : {
				"$and" : [ ]
			},
			"winningPlan" : {
				"stage" : "COLLSCAN",
				"filter" : {
					"$and" : [ ]
				},
				"direction" : "forward"
			},
			"rejectedPlans" : [ ]
		},
		"serverInfo" : {
			"host" : "",
			"port" : 27017,
			"version" : "3.2.8",
			"gitVersion" : ""
		},
		"ok" : 1
	}

打印出了这么长一串的信息，我想我应该是成功了。但仔细一瞧却发现最为关键的"million"，"n"等主键都没有返回，返回的都是一些与mongo和collection相关的表层数据。

相同的方法尝试了好几个数据库包括生产服务器我也尝试了一遍返回的信息大同小异，这是为什么，难道是数据库版本的问题？

###结果

---

通常当我们无法通过google、QA获得想要的答案时，我想最好的方法就是去查询官方API（所以英语的重要性可想而知，千万别指着翻译工具-。-）。

在查询API之前我先查看了我本地数据库的版本

	$ mongo -version
	MongoDB shell version: 3.2.8

---
进入explain()的API：
https://docs.mongodb.com/manual/reference/method/db.collection.explain/

基本的描述是这么写的
>db.collection.explain()
Changed in version 3.2: Adds support for db.collection.distinct()

也就是说这个方法在3.2版本之后进行了一些方法和支持的变动（我的version正好是3.2.8），在意识到版本的问题的同时我也发现语法上也有一定的不同

> 老版本、大部分资料：db.collection.method().explain()
> 
> 当前的API：db.collection.explain().method()

从方法表面来看是链式写法的顺序发生了变化，但以往的资料中有提到explain()只能跟在method的后面

![这里写图片描述](http://img.blog.csdn.net/20161226135840306?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcXFfMTc0NzUxNTU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
	
否则会出错，经过测试貌似推翻了资料所说

![这里写图片描述](http://img.blog.csdn.net/20161226135915465?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcXFfMTc0NzUxNTU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

依然能够得到返回的结果只是主键并不是原来的配方。

那么要得到"million","n"等相关重要信息应该怎么做呢？官方给出了答案

![这里写图片描述](http://img.blog.csdn.net/20161226140157157?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvcXFfMTc0NzUxNTU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


> 也就是说最新的explain()方法制定了一个新的输出解释模式，分别是"queryPlanner", "executionStats", 和"allPlansExecution".

我认为分别指的是：概要模式，执行状态模式，所有信息模式，默认的是概要模式。而我们所需要查看的参数通常是包含在“执行状态模式”中，实际的操作验证了我的猜测

	> db.pages.explain("executionStats").find()
	{
		"queryPlanner" : {
			"plannerVersion" : 1,
			"namespace" : "qukenotepro.pages",
			"indexFilterSet" : false,
			"parsedQuery" : {
				"$and" : [ ]
			},
			"winningPlan" : {
				"stage" : "COLLSCAN",
				"filter" : {
					"$and" : [ ]
				},
				"direction" : "forward"
			},
			"rejectedPlans" : [ ]
		},
		"executionStats" : {
			"executionSuccess" : true,
			"nReturned" : 2,
			"executionTimeMillis" : 0,
			"totalKeysExamined" : 0,
			"totalDocsExamined" : 2,
			"executionStages" : {
				"stage" : "COLLSCAN",
				"filter" : {
					"$and" : [ ]
				},
				"nReturned" : 2,
				"executionTimeMillisEstimate" : 0,
				"works" : 4,
				"advanced" : 2,
				"needTime" : 1,
				"needYield" : 0,
				"saveState" : 0,
				"restoreState" : 0,
				"isEOF" : 1,
				"invalidates" : 0,
				"direction" : "forward",
				"docsExamined" : 2
			}
		},
	}

这次我们成功的查询到了我们所需要的信息，但是主键名字可替换得不少。

 - executionSuccess : 执行是否成功
 - nReturned ：返回的文档数
 - executionTimeMillis ：执行的时间
 - totalDocsExamined ：总共检查了多少个文档
 - advanced ：过程中应该返回的文档数量
 - isEOF ：指定查询阶段是否已经结束
 - needYield ：过程中被打断的次数
 - direction ：查询方式

###结语

---

技术都是在飞速的迭代和更新，而explain()的改动能够让我们获得更多与查询有关的信息，及时的查阅stable API有助于我们及时了解官方对相关方式进行的优化，话不多说，我爱mongo！