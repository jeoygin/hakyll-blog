---
title: HDFS源码分析（6）：datanode DataBlockScanner
tags:
  - DataBlockScanner
  - datanode
  - Hadoop
  - HDFS
  - source
id: 799
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-29 22:11:48
---

## 前提 ##

Hadoop版本：hadoop-0.20.2

## 概述 ##

DataBlockScanner是datanode上很重要的部分，用于周期性地对块文件进行校验，当客户端读取整个块时，也会通知DataBlockScanner校验结果。这个类位于包org.apache.hadoop.hdfs.server.datanode中，与DataBlockScanner相关的类图如下所示：

![](http://lh3.googleusercontent.com/-_MMtjdUyAvQ/T3QScRxVatI/AAAAAAAAANg/TbHDOD1Xbic/s851/DatanodeDataBlockScanner.jpg)

<!--more-->

## 相关参数 ##

**与扫描相关的参数有：**

* 最大扫描速度是8 MB/s，通过BlockTransferThrottler来限制流量
* 最小扫描速度是1 MB/s
* 默认扫描周期是3周，扫描周期可通过配置${dfs.datanode.scan.period.hours}来设置

**与扫描日志相关的参数有：**

* 日志文件名前缀是dncp_block_verification.log
* 共有两个日志：当前日志，文件后缀是.curr；前一个日志，文件后缀是.prev
* minRollingPeriod：日志最小滚动周期是6小时
* minWarnPeriod：日志最小警告周期是6小时，在一个警告周期内只有发出一个警告
* minLineLimit：日志最小行数限制是1000

采用滚动日志方式，只有当前行数curNumLines超过最大行数maxNumLines，并且距离上次滚动日志的时间
超过minRollingPeriod时，才将dncp_block_verification.log.curr重命名为dncp_block_verification.log.prev，将新的日志写到dncp_block_verification.log.curr中。

## 扫描过程 ##

块的信息用BlockScanInfo来表示，在比较时先对比最后扫描时间，如果扫描时间一样，再比较块的信息，这样，能保证从blockInfoSet中取出的第一个元素的最后扫描时间距离现在最久。

将块添加到扫描集合中时，为其在上个扫描周期中随机选择一个时间作为最后扫描时间，避免所有块在同一时间进行扫描。

扫描的过程如下：

* 检查blockInfoSet中的第一个块的最后扫描时间距离现在是否超过一个扫描周期，如果不超过，休眠１秒后开始下次检查
* 如果超过一个扫描周期，那么对该块进行校验，校验使用BlockSender这个类来读取一个完整的块，读取的数据输出到NullOutputStream这个流，我们知道BlockSender在读取数据时，可以检查checksum，以此来判断是否校验成功。如果校验失败，进行第二次校验，如果两次都失败，说明该块有错误，通知namenode块坏了。

除了DataBlockScanner本身会校验块，DataXceiver在处理读请求时，如果读取整个块的数据，也对块进行校验，并通知DataBlockScanner校验结果。DataXceiver在处理写请求时，将块写入磁盘后，会将块添加到扫描列表中。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。