---
title: HDFS概况
tags:
  - Hadoop
  - HDFS
id: 537
categories:
  - 计算机技术
  - Hadoop
date: 2012-02-22 11:09:32
---

一个HDFS系统一般由一个namenode和多个datanode构成，可能还有一个secondary namenode。其中namenode负责管理目录和文件的元信息，对于文件夹来说，包含的信息有“复制级别”、修改时间和访问时间、访问许可、块大小、组成一个文件的块等；对于目录来说，包含的信息有修改时间、访问许可和配额元数据等信息。datanode负责管理块数据及其元信息（generation stamp和checksum），当datanode加入集群时，namenode根据datanode报告的块列表建立块映射关系，在datanode运行期间，会定时向namenode报告数据块的信息，以维护最新的块映射。

当datanode加入集群后，每隔一段时间会向namenode发送心跳，namenode会返回一些命令，比如发送块到另一datanode、删除或恢复块等。namenode与datanode是服务端/客户端结构，datanode通过RPC来向namenode发送请求；而datanode之间是对等结构，相互之间可以通过socket来进行通信、发送数据。

<!--more-->

以下将简单介绍namenode和datanode的存储目录结构。

## 1\. namenode的目录结构

namenode的存储目录由dfs.name.dir属性设置，目录的结构如下所示：

```
 ${dfs.name.dir}/current/VERSION
                        /edits
                        /fsimage
                        /fstime
```

VERSION文件是一个Java属性文件，其中包含正在运行的HDFS的版本信息。属性layoutVersion是一个负整数，描述HDFS永久性数据结构（也称布局）的版本。只要布局变更，版本号便会递减，HDFS也需要升级。

edits、fsimage和fstime等二进制文件使用Hadoop的Writable对象作为其序列化格式。

namenode每隔一小时（由fs.checkpoint.period属性设置）创建检查点；当编辑日志的大小达到64MB（由fs.checkpoint.size属性设置）时，也会创建检查点。

## 2\. Secondary Namenode的目录结构

辅助Namenode的存储目录由fs.checkpoint.dir属性设置，目录的结构如下所示：

```
 $(fs.checkpoint.dir}/current/VERSION
                             /edits
                             /fsimage
                             /fstime
                     /previous.checkpoint/VERSION
                                         /edits
                                         /fsimage
                                         /fstime
```

## 3\. Datanode的目录结构

datanode的存储目录由dfs.data.dir属性设置，该目录是datanode启动时自动创建的，不需要进行格式化，目录的结构如下所示：

```
 ${dfs.data.dir}/current/VERSION
                        /blk_<id_1>
                        /blk_<id_1>.meta
                        /blk_<id_1>
                        /blk_<id_1>.meta
                        /...
                        /blk_<id_64>
                        /blk_<id_64>.meta
                        /subdir0/
                        /subdir1/
                        /...
                        /subdir63/
                /previous/
                /detach/
                /tmp/
                /in_use.lock
                /storage
```

current是当前的工作目录，previous是升级HDFS之前的工作目录，在升级时，HDFS并不会将文件从previous拷贝到current目录中，而是遍历previous中的所有文件，在current目录中创建硬链接。

detach目录保存用于copy-on-write的文件，在Datanode重启时需要恢复。

tmp目录保存一些临时数据。

in_use.lock文件用于对datanode加锁，storage文件保存了布局版本及升级版本提示信息。

下面来看current目录的结构，目录中的文件都有blk_前缀，有两类文件：块文件和块元数据文件（.meta后缀）。当目录中数据块的数量增加到64个（由dfs.datanode.numblocks属性设置，子目录的数量也是由该属性设置），datanode会创建一个子目录来存放新的数据。采用树状结构的组织方式，datanode可以有效管理各个目录中的文件，避免将很多文件放在一个目录之中。

## 4\. HDFS配置

HDFS的配置在core-site.xml和hdfs-site.xml两个配置文件中，也可以通过命令行参数或在程序中进行设置，以下列出了两个文件中的重要配置。

**core-size.xml**

* fs.default.name: Hadoop的默认文件系统，默认值是“file:///”
* hadoop.tmp.dir: 临时目录的路径，默认值是“/tmp/hadoop-${user.name}”
* io.file.buffer.size: IO操作的缓冲区大小

**hdfs-site.xml**

* dfs.block.size: 数据块的大小，默认值是64MB
* dfs.replication: 数据块副本的数量，默认值是3 
* dfs.name.dir: namenode存储目录的路径，默认值是“${hadoop.tmp.dir}/dfs/name”
* dfs.data.dir: datanode存储目录的路径，默认值是“${hadoop.tmp.dir}/dfs/data”
* dfs.checkpoint.dir: secondary namenode存储目录的路径，默认值是“${hadoop.tmp.dir}/dfs/namesecondary”
* dfs.datanode.ipc.address: datanode的RPC服务器地址和端口，默认值是0.0.0.0:50020
* dfs.http.address: namenode的HTTP服务器地址和端口，默认值是0.0.0.0:50070
* dfs.datanode.http.address: datanode的HTTP服务器地址和端口，默认值是0.0.0.0:50075
* dfs.secondary.http.address: secondary namenode的HTTP服务器地址和端口，默认值是0.0.0.0:50090

## 5\. HDFS工具

### 5.1\. 命令行接口

可以使用调用hadoop fs来使用文件系统，大多数命令与Unix命令相似，主要的命令如下表所示：

|命令|说明|
|-help|获取所有命令的详细帮助文件|
|-ls|列举文件|
|-df|显示文件系统的容量、已用和可用空间|
|-du|显示文件的空间使用情况|
|-cp|复制文件或目录|
|-mv|移动文件或目录|
|-mkdir|创建目录|
|-rm|删除文件|
|-rmr|删除目录|
|-put|将本地文件复制到HDFS|
|-get|将HDFS上的文件复制到本地|
|-cat|取出文件内容并显示到标准输出|

### 5.2\. Web接口

访问<nowiki>http://namenode:50070</nowiki>页面，可以查看HDFS文件系统的使用情况、各datanode的状态以及浏览文件系统。

### 5.3\. dfsadmin工具

dfsadmin工具是多用途的，既可查找HDFS状态信息，又可以HDFS上执行管理操作，调用形式是hadoop dfsadmin，仅当用户具有超级用户权限，才可以使用这个工具修改HDFS的状态，下表列举了dfsadmin的一些命令：

|命令|说明|
|-help|获取所有命令的详细帮助文件|
|-report|显示文件系统的统计信息，以及连接的各个datanode的信息|
|-metasave|将某些信息存储到Hadoop日志目录中的一个文件中|
|-savemode|改变或查询安全模式|
|-saveNamespace|将内存中的文件系统映像保存为一个新的fsimage文件，重置edits文件|
|-refreshNodes|更新允许连接到namenode的datanode列表|
|-upgradeProgress|获取有关HDFS升级的进度信息，或强制升级|
|-finalizeUpgrade|移除datanode和namenode的存储目录上的旧版本数据|
|-setQuota|设置目录的配额，即设置以该目录为根的整个目录树最多包含多少个文件和目录|
|-clrQuota|清理指定目录的配额|
|-setSpaceQuota|设置目录的空间配额，以限制存储在目录树中的所有文件的总规模|
|-clrSpaceQuota|清理指定的空间配额|
|-refreshServiceAcl|刷新namenode的服务器授权策略文件|

## 6\. 参考资料

1. 《Hadoop权威指南》第2版