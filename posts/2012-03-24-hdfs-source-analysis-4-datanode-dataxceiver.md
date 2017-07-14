---
title: HDFS源码分析（4）：datanode DataXceiver
tags:
  - datanode
  - DataXceiver
  - Hadoop
  - HDFS
id: 635
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-24 21:01:55
---

## 前提 ##

Hadoop版本：hadoop-0.20.2

## 概述 ##

之前已经对datanode的结构和存储进行了分析，本文将分析datanode的行为，能明确数据在datanode之间如何传输。在datanode中，块数据的接收和发送主要是通过DataXceiver，这部分的网络传输没有采用RPC，而是传输的TCP连接，这部分所涉及到的类的包结构如下所示  ：

* org.apache.hadoop.hdfs.server.datanode
** BlockMetadataHeader
** BlockReceiver
** BlockSender
** BlockTransferThrottler
** DataXceiver
** DataXceiverServer

以下是DataXceiver相关的类图：

![](http://lh4.googleusercontent.com/-DwaU7IjrspM/T2xPpQ9WscI/AAAAAAAAAMw/G1hU7rXlFzY/s1047/DatanodeDataXceiver.jpg)

<!--more-->

## DataXceiver ##

在datanode上由DataXceiver来负责数据的接收与发送，我们先来看DataXceiverServer和DataXceiver这两个类。

DataXceiverServer相对比较简单，创建一个ServerSocket来接受请求，每接受一个连接，就创建一个DataXceiver用于处理请求，并将Socket存在一个名为childSockets的Map中。此外，还创建一个BlockBalanceThrottler对象用来控制DataXceiver的数目以及流量均衡。

DataXceiver才是真正处理请求的地方，支持六种操作，相关操作在DataTransferProtocol中定义，如下所示：

```
public static final byte OP_WRITE_BLOCK = (byte) 80;
public static final byte OP_READ_BLOCK = (byte) 81;
public static final byte OP_READ_METADATA = (byte) 82;
public static final byte OP_REPLACE_BLOCK = (byte) 83;
public static final byte OP_COPY_BLOCK = (byte) 84;
public static final byte OP_BLOCK_CHECKSUM = (byte) 85;
```

操作的状态也在DataTransferProtocol中定义，如下所示：

```
public static final int OP_STATUS_SUCCESS = 0;  
public static final int OP_STATUS_ERROR = 1;  
public static final int OP_STATUS_ERROR_CHECKSUM = 2;  
public static final int OP_STATUS_ERROR_INVALID = 3;  
public static final int OP_STATUS_ERROR_EXISTS = 4;  
public static final int OP_STATUS_CHECKSUM_OK = 5;  
```

客户端请求的头部数据是这样的：

```
 +----------------------------------------------+
 |   2 bytes version    |      1 byte OP        |
 +----------------------------------------------+
```

最开始的两个字节是版本信息，接着的1个字节表示上述的操作。

**OP_READ_BLOCK**是读块数据操作，客户端请求的头部数据如下所示，DataXceiver会创建一个BlockSender对象用来向客户端发送数据。

```
 +-----------------------------------+
 | 8 byte Block ID | 8 byte genstamp | 
 +-----------------------------------+
 | 8 byte start offset|8 byte length |
 +-----------------------------------+
 |  4 byte length  |  <DFSClient id> |
 +-----------------------------------+
```

其中第二个length是&lt;DFSClient id&gt;的长度。

如果处理过程中出错，那么发送后状态信息后中断连接，返回的数据如下所示：

```
 +----------------------------------------------+
 |            2 byte OP_STATUS_ERROR            |
 +----------------------------------------------+
```

如果操作成功，返回的数据如下所示：

```
 +----------------------------------------------+
 | 2 byte OP_STATUS_SUCCESS |   actual data     |
 +----------------------------------------------+
```

**OP_WRITE_BLOCK**是写块数据操作，客户端请求的头部数据如下所示，DataXceiver会创建一个BlockReceiver对象用来接收客户端的数据。

```
 +------------------------------------------------+
 |   8 byte Block ID     |   8 byte genstamp      |
 +------------------------------------------------+
 |   4 byte num of datanodes in entire pipeline   |
 +------------------------------------------------+
 |   1 byte is recovery  |   4 byte  length       |
 +------------------------------------------------+
 |   <DFSClient id>      |  1 byte has src node   |
 +------------------------------------------------+
 |   src datanode info   |  4 byte num of targets |
 +------------------------------------------------+
 |   target datanodes    |
 +-----------------------+
```

写块数据是一个比较复杂的操作，头部信息就不少：其中length是<DFSClient id>的长度；当有src node时，才有src datanode info数据；datanode信息的格式见<a hef="http://jeoygin.org/2012/03/07/hdfs-source-analysis-2-datanode-protocol/">HDFS源码分析（2）：datanode协议</a>数据结构一节中的相关类图。

HDFS的写操作需要多个datanode来参与，默认是3个，这些datanode形成一个pipeline，如[HDFS源码分析（1）：datanode概况](http://blog.jeoygin.org/archives/589)中client写数据图中所示，这些datanode在这里被称为target datanode，客户端发送的数据会由一个datanode传送到另一个datanode，直到最后一个datanode，对请求的response是从最后一个datanode开始，按数据传送的相反路径逐一传送，每经过一个datanode，该datanode会将收到的及其自已的response发给下一个datanode，当到达客户端时，客户端就能知道所有datanode的response。

**OP_READ_METADATA**是读块元数据操作，客户端请求的头部数据如下所示：

```
 +------------------------------------------------+
 |   8 byte Block ID     |   8 byte genstamp      |
 +------------------------------------------------+
```

返回的数据如下所示：

```
 +------------------------------------------------+
 |   1 byte status  |  4 byte length of metadata  |
 +------------------------------------------------+
 |   meta data      |              0              |
 +------------------------------------------------+
```

**OP_REPLACE_BLOCK**是替换块数据操作，主要用于负载均衡，DataXceiver会接收一个块并写到磁盘上，操作完成后通知namenode删除源数据块，客户端请求的头部数据如下所示：

```
 +------------------------------------------------+
 |   8 byte Block ID     |   8 byte genstamp      |
 +------------------------------------------------+
 |   4 byte length       |   source node id       |
 +------------------------------------------------+
 |   source data node    |
 +-----------------------+
```

具体的处理过程是这样的：向source datanode发送拷贝块请求，然后接收source datanode的响应，创建一个BlockReceiver用于接收块数据，最后通知namenode已经接收完块数据。返回的数据以下所示：

```
 +----------------------------------------------+
 |                 2 byte status                |
 +----------------------------------------------+
```

**OP_COPY_BLOCK**是复制块数据操作，主要用于负载均衡，将块数据发送到发起请求的datanode，DataXceiver会创建一个BlockReceiver对象用来发送数据，请求的头部数据如下所示：

```
 +------------------------------------------------+
 |   8 byte Block ID     |   8 byte genstamp      |
 +------------------------------------------------+
```

返回的数据如下所示：

```
 +------------------------------------------------+
 |      block data       |           d            |
 +------------------------------------------------+
```

**OP_BLOCK_CHECKSUM**是获得块checksum操作，对块的所有checksum做MD5摘要，客户端请求的头部数据如下所示：

```
 +------------------------------------------------+
 |   8 byte Block ID     |   8 byte genstamp      |
 +------------------------------------------------+
```

返回的数据如下所示：

```
 +------------------------------------------------+
 |   2 byte status       |   4 byte bytes per CRC |
 +------------------------------------------------+
 |   8 byte CRC per block|   16 byte md5 digest   |
 +------------------------------------------------+
```

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。