---
title: CentOS安装netperf
tags:
  - centos
  - netperf
  - network
id: 572
categories:
  - 计算机技术
  - 网络
date: 2012-03-02 17:28:50
---

## 简介 ##

netperf是测试网络带宽和延迟的利器，可以测试TCP和UDP的性能。

## 安装环境 ##

操作系统：CentOS 5.6
内核：2.6.18
网络：千兆以太网

## 编译、安装源码 ##

下载地址：ftp://ftp.netperf.org/netperf/netperf-2.5.0.tar.gz

编译安装：

```
 tar zxvf netperf-2.5.0.tar.gz
 cd netperf-2.5.0
 ./configure
 make
 make install
```

<!--more-->

## netperf主要参数 ##

* -H：服务端地址
* -l：测试时间（秒）
* -p：监听端口
* -t：测试类型，有TCP_STREAM、UDP_STREAM、TCP_RR、TCP_CRR、UDP_RR，如果不指定类型，默认是TCP_STREAM
** TCP_STREAM：通过单个TCP连接传输批量数据
** UDP_STREAM：通过UDP传输批量数据
** TCP_RR：通过单个TCP连接发送请求/应答
** TCP_CRR：通过多个TCP连接发送请求/应答
** UDP_RR：通过UDP发送请求/应答

## 测试 ##

测试主要分服务端和客户端，在一台主机运行服务端netserver，在另一台枬运行客户端netperf就开始测试了。以下简单介绍一下怎么测试通过单个TCP连接传输批量数据。

**启动服务端：**

```
 netserver -D -p 4444
```

服务端开放4444端口用于监听。

**启动客户端：**

```
 netperf -H server -p 4444 -l 60
```

客户端连接服务端的4444端口，测试的时间为60秒。

**测试结果如下：**

```
 Recv   Send    Send                          
 Socket Socket  Message  Elapsed              
 Size   Size    Size     Time     Throughput  
 bytes  bytes   bytes    secs.    10^6bits/sec  

 87380  16384  16384    60.03     881.21
```

测试结果显示吞吐量是881.21Mb/s，大概是110MB/s。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。