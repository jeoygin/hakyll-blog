---
title: HDFS源码分析（1）：datanode概况
tags:
  - datanode
  - HDFS
  - source
id: 589
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-05 19:44:37
---

## 前提 ##
Hadoop版本：hadoop-0.20.2

## 概况  ##

HDFS（Hadoop Distributed File System）是一个复杂的项目，大体上分为namenode、datanode、client三部分。namenode是核心部分，管理着文件的信息、数据块的映射关系、checkpoint、编辑日志等，处理HDFS的主要逻辑，作为服务端接收datanode、client的请求并进行处理。datanode主要管理文件的数据块，datanode与namenode是客户端/服务端结构，每隔一段时间会向namenode发送心跳，namenode会返回一些命令；datanode之间是对等结构，相互之间可以通过socket来进行通信、发送数据；datanode与client之间是服务端/客户端结构，接受client的读、写请求。

client读数据如下图所示：

![](http://lh3.googleusercontent.com/-sDM0DudHusI/T1SjsOqGoWI/AAAAAAAAAKk/5cbvbe9Aj_o/s551/HDFS%2520Read.JPG)

client写数据如下图所示：

![](http://lh3.googleusercontent.com/-X2MYfZqRcis/UZH_x1M-P8I/AAAAAAAAARA/bmjM0Bv59aE/s780/HDFS%2520Write.JPG)

由datanode直接与操作系统的文件系统打交道，处理文件的操作，因而自底向上，先从datanode的源码开始分析。

## datanode源码结构 ##

在hadoop-0.20.2中，datanode相关的代码大约1万行左右，主要代码在以下几个包中：

* org.apache.hadoop.hdfs.protocol
* org.apache.hadoop.hdfs.server.common
* org.apache.hadoop.hdfs.server.datanode
* org.apache.hadoop.hdfs.server.protocol

后续将会对datanode的数据结构、协议、存储、数据、行为等进行分析。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。