---
title: HDFS源码分析（7）：datanode的启动与服务
tags:
  - datanode
  - Hadoop
  - HDFS
  - service
  - source
  - startup
id: 807
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-30 19:47:40
---

## 前提 ##

Hadoop版本：hadoop-0.20.2

## 概述 ##

datanode在启动后，会定期向namenode发送心跳报告，并处理namenode返回的命令，经过前面的分析，已经基本弄清楚datanode相关的类，本文将分三部分对剩下的Datanode这个类进行分析，分别是datanode的启动、公共接口和运行。Datanode位于org.apache.hadoop.hdfs.server.datanode这个包，类图如下所示：

![](http://lh6.googleusercontent.com/-FN08G720B1c/T3WbExutqWI/AAAAAAAAAN0/jG871Qf2Fcc/s852/Datanode.jpg)

<!--more-->

## datanode的启动 ##

首先，先看看Datanode的静态初始化块：

```
  static{
    Configuration.addDefaultResource("hdfs-default.xml");
    Configuration.addDefaultResource("hdfs-site.xml");
  }
```

也就是说，datanode在启动时会加载hdfs-default.xml和hdfs-site.xml这两个配置文件，默认的配置文件hdfs-default.xml位于src/hdfs目录，非hadoop-0.20.2可能路径会不相同，最终会跟生成的class文件一起打包进hadoop-core-*.jar，一般与datanode相关的配置放在hdfs-site.xml这个配置文件中。

下面，从入口main方法开始，逐步分析datanode的初始化与启动。

**1\. main：**

* 调用createDataNode方法创建datanode
* 等datanode线程结束

**2\. createDataNode：**

* 调用instantiateDataNode方法初始化datanode
* 调用runDatanodeDaemon方法运行datanode线程

**3\. instantiateDataNode：**

* 解析启动参数
* 如果设置了机架配置${dfs.network.script}，退出程序
* 通过配置${dfs.data.dir}得到datanode的存储目录
* 调用makeInstance方法创建实例

**4.makeInstance：**

* 检查数据存储目录的合法性
* 初始化DataNode对象

**5.DataNode：**

* 调用startDataNode方法启动datanode
* 如果启动出错，调用shutdown方法关闭datanode

**6.startDataNode：**

* 获得本地主机名和namenode的地址
* 连接namenode，本地datanode的名称为：“machineName:port”
* 从namenode得到version和id信息
* 初始化存储目录结构，如果有目录没有格式化，对其进行格式化
* 打开datanode监听端口ss，默认端口是50010
* 初始化DataXceiverServer后台线程，使用ss接收请求
* 初始化DataBlockScanner，块的校验只支持FSDataset
* 初始化并启动datanode信息服务器infoServer，默认访问地址是http://0.0.0.0:50075，如果允许https，默认https端口是50475
* infoServer添加DataBlockScanner的Servlet，访问地址是http://0.0.0.0:50075/blockScannerReport
* 初始化并启动ipc服务器，用于RPC调用，默认端口是50020

## datanode的接口 ##

**getProtocolVersion：**

取得datanode的协议版本。

**getBlockMetaDataInfo：**

取得块元数据信息。

**updateBlock：**

更新块信息，这个方法会更改块的时间戳，所有会重命令元数据信息文件，如果块文件的长度有变，会改变块文件和元数据信息文件的内容。

**recoverBlock：**

恢复一个块，先检查块的时间戳，对时间戳比本地块要新的datanode做同步块操作，在同步时，调用namenode的nextGenerationStamp方法来得到一个新的时间戳，对每个datanode通过RPC调用updateBlock方法来更新远程datanode的块，最后调用namenode的commitBlockSynchronization方法来提交块的更新。

## datanode的运行 ##

首先会启动DataXceiverServer，然后进入datanode的正常运行：

* 检查是否需要升级
* 调用offerService方法提供服务

来看看offerService这个方法是如何执行的：

* 检查心跳间隔是否超时，如是向namenode发送心跳报告，内容是dfs的容量、剩余的空间和DataXceiverServer的数量等，调用processCommand方法处理namenode返回的命令
* 通知namenode已经接收的块
* 检查块报告间隔是否超时，如是向namenode发送块报告，调用processCommand方法处理namenode返回的命令
* 如果没到下个发送心跳的时候，休眠

接下来看processCommand方法是如何处理命令的，关于这些命令对应的操作，之前的文章中已经提到过，这些操作在DatanodeProtocol中定义：

* DNA_UNKNOWN = 0：未知操作
* DNA_TRANSFER = 1：传输块到另一个datanode，创建DataTransfer来传输每个块，请求的类型是OP_WRITE_BLOCK，使用BlockSender来发送块和元数据文件，不对块进行校验
* DNA_INVALIDATE = 2：不合法的块，将所有块删除
* DNA_SHUTDOWN = 3：停止datanode，停止infoServer、DataXceiverServer、DataBlockScanner和处理线程，将存储目录解锁，DataBlockScanner结束可能需要等待1小时
* DNA_REGISTER = 4：重新注册
* DNA_FINALIZE = 5：完成升级，调用DataStorage的finalizeUpgrade方法完成升级
* DNA_RECOVERBLOCK = 6：请求块恢复，创建线程来恢复块，每个线程服务一个块，对于每个块，调用recoverBlock来恢复块信息

除了以上的操作，还支持UpgradeCommand.UC_ACTION_START_UPGRADE这个操作，主要用于HDFS的升级。

## datanode的相关配置 ##

以下是与datanode相关的配置，括号中是配置的默认值：

* slave.host.name
* dfs.block.size (67108864 B)：块的大小
* dfs.blockreport.intervalMsec (3600000 ms)：发送块报告的时间间隔
* dfs.blockreport.initialDelay (0)：启动datanode后首次发送块报告的时间
* dfs.heartbeat.interval (3 s)：发送心跳报告的时间间隔
* dfs.support.append (true)：是否支持块文件的追加操作
* dfs.network.script：机架配置，datanode不允许对rack进行配置
* dfs.socket.timeout (1 min)
* dfs.write.packet.size (64*1024 B)：datanode写或读数据的packet大小
* dfs.datanode.startup：启动选项
* dfs.data.dir (${hadoop.tmp.dir}/dfs/data)：datanode存储目录
* dfs.datanode.dns.interface(default)
* dfs.datanode.dns.nameserver (default)
* dfs.datanode.socket.write.timeout (8min)
* dfs.datanode.transferTo.allowed (true)
* dfs.datanode.bindAddress
* dfs.datanode.port
* dfs.datanode.address (0.0.0.0:50010)：datanode接受数据请求的地址和端口
* dfs.datanode.info.bindAddress
* dfs.datanode.info.port
* dfs.datanode.http.address (0.0.0.0:50075)：datanode信息服务器的地址和端口用于查看dfs使用情况
* dfs.https.enable (false)
* dfs.https.need.client.auth (false)
* dfs.https.server.keystore.resource (ssl-server.xml)
* dfs.datanode.https.address (0.0.0.0:50475)
* dfs.datanode.ipc.address 0.0.0.0:50020：RPC服务的地址和端口
* dfs.datanode.simulateddatastorage
* dfs.datanode.scan.period.hours：扫描块的周期
* dfs.datanode.handler.count (3)：处理RPC服务的线程数
* dfs.datanode.max.xcievers (256)：DataXceiver的数量
* dfs.datanode.numblocks (64)：每个目录能容纳的最多块数以及子目录数
* dfs.datanode.du.reserved (0)：dfs的预留空间

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。