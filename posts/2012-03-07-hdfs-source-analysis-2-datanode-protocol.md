---
title: HDFS源码分析（2）：datanode协议
tags:
  - datanode
  - HDFS
  - protocol
  - source
id: 602
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-07 18:04:40
---

## 前提 ##
Hadoop版本：hadoop-0.20.2

## 概述 ##

datanode协议包括基本的数据结构、调用接口以及通信的内容，本文中将简单分析这几部分内容，所涉及到的类的包结构如下所示：

* org.apache.hadoop.hdfs.protocol
** Block
** ClientDatanodeProtocol
** DatanodeID
** DatanodeInfo
** LocatedBlock
* org.apache.hadoop.hdfs.server.protocol
** BlockCommand
** BlockMetaDataInfo
** DatanodeCommand
** DatanodeProtocol
** DatanodeRegistration
** InterDatanodeProtocol
** UpgradeCommand

<!--more-->

## 数据结构 ##

datanode涉及的数据结构包括datanode信息、块、块元数据、datanode命令等，这些结构均实现Writable接口，可进行序列化。

**与datanode信息相关的类图如下所示：**

![](http://lh5.googleusercontent.com/-qjCw67iHqtk/T1cvieUk5eI/AAAAAAAAAK8/m9qD1F_BnlI/s1033/DatanodeInfo.jpg)

DatanodeInfo保存着datanode的详细信息，如名字、ID、端口、容量、已使用空间、剩余空间、DataXceiver的个数、位置、状态等，namenode、balancer和管理工具都会使用到这些信息。

DatanodeRegistration包含标识datanode的所有信息，datanode在启动时，向namenode进行注册，之后在与namenode通信时会发送这些信息验证datanode的身份。

StorageInfo是关于存储的，后继会介绍。

**与块相关的类图如下所示：**

![](http://lh5.googleusercontent.com/-UQyvFp275Zo/T1cvibIowzI/AAAAAAAAALE/0CJFbVVIVcQ/s591/DatanodeBlock.jpg)

与块相关的类主要有块、块元数据以及带位置信息的块。

Block保存块的信息，有块ID、块文件大小以及由namenode生成的时间戳，由ID和时间戳唯一确定一个块。

BlockMetaDataInfo保存块元数据的信息，比块多了一个最后扫描时间。

LocatedBlock的主要属性有块信息、该块在文件中的偏移量以及存储该块的datanode节点的信息，主要用在HDFS客户端，它告诉客户端去哪找到块文件。

**与datanode命令相关的类图如下所示：**

![](http://lh4.googleusercontent.com/-7dSVbW6rvGk/T1cxo26hMRI/AAAAAAAAALk/vne4P9Fz2gI/s592/DatanodeCommand.jpg)

DatanodeCommand是datanode向namenode发送心跳、报告块后会返回的结构，datanode会对收到的命令进行相应的操作，该结构的主要属性是action，是命令对应的操作，这些操作在DatanodeProtocol中定义：

* DNA_UNKNOWN = 0：未知操作
* DNA_TRANSFER = 1：传输块到另一个datanode
* DNA_INVALIDATE = 2：不合法的块
* DNA_SHUTDOWN = 3：停止datanode
* DNA_REGISTER = 4：重新注册
* DNA_FINALIZE = 5：完成前一次更新
* DNA_RECOVERBLOCK = 6：请求块恢复

Register、Finalize、BlockCommand和UpgradeCommand是DatanodeCommand的子类。

BlockCommand额外保存了块和datanode的信息，用于通知datanode错误的块或将指定的块发送到另一个datanode。

UpgradeCommand用于升级HDFS。

## 接口 ##

这部分主要分析通信过程中需要遵守的一些协议，主要是几个接口，如下类图所示：

![](http://lh5.googleusercontent.com/-jj4vZabhxdQ/T1cviwRyFfI/AAAAAAAAALU/EbrciOlqDq0/s552/DatanodeProtocol.jpg)

VersionedProtocol是所有使用Hadoop RPC的协议的父类，该接口定义了获得协议版本的方法。

DatanodeProtocol是datanode用来和namenode通信的协议，用于上传当前的负载信息和块报告，namenode只能通过该接口定义的方法的返回值与datanode通信，主要方法有注册、发送心跳、报告块信息、通知已接收到的块、报告错误、报告坏块和获得时间戳等。

InterDatanodeProtocol是一个datanode之间的协议，用于更新时间戳。

ClientDatanodeProtocol是一个client-datanode之间的协议，用于恢复块。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。