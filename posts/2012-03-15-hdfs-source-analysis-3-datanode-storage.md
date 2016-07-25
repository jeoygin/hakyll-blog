---
title: HDFS源码分析（3）：datanode存储
tags:
  - datanode
  - Hadoop
  - HDFS
  - source
  - storage
id: 617
categories:
  - 计算机技术
  - Hadoop
date: 2012-03-15 20:16:14
---

## 前提 ##
Hadoop版本：hadoop-0.20.2

## 概述 ##

datanode的存储结构如下所示：

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

datanode的存储大体上可以分为两部分：与Storage相关的类从宏观上刻画了每个存储目录的组织结构，管理由HDFS属性dfs.data.dir指定的目录，如current、previous、detach、tmp、storage等目录和文件，并定义了对整个存储的相关操作；与Dataset相关的类描述了块文件及其元数据文件的组织方式，如current目录中的文件组织结构，以及对块文件的相关操作。因为namenode也会用到Storage，而namenode并不存储块文件，因而将存储分成这两部分。
<!--more-->
本文中将简单分析这两部分内容，所涉及到的类的包结构如下所示：

* org.apache.hadoop.hdfs.protocol
** Block
* org.apache.hadoop.hdfs.server.common
** Storage
** StorageInfo
* org.apache.hadoop.hdfs.server.datanode
** DataStorage
** FSDataset
** FSDatasetInterface
** DatanodeBlockInfo

## Storage ##

与Storage相关的类描述了存储的信息、类型、状态、目录，类图如下所示：

![](http://lh3.googleusercontent.com/-5tSXqYa06bE/T2GX3Z1c3FI/AAAAAAAAAMM/Ry49Gisehnc/s810/DatanodeStorage.jpg)

存储的信息由类StorageInfo来表示，该类有3个属性：

* layoutVersion: 从storage文件中读出，是HDFS文件结构布局
* namespaceID: 存储的namespace id
* cTime: 创建的时间戳

Storage类管理着所有的存储目录，存储目录由StorageDirectory类来表示，通过DirIterator这个类来遍历存储目录，主要有两个属性：

* storageType: 存储类型，可以是NAME_NODE或DATA_NODE
* storageDirs: 存储目录

StorageDirectory是一个重要的类，描述了存储目录的组织结构及其状态，首先，我们来看看存储目录的状态。

StorageState表示存储的状态，与存储目录的结构、升级、回滚、做checkpoint息息相关，存储目录的所有状态如下：

* NON_EXISTENT: 目录不存在
* NOT_FORMATTED: 目录未格式化
* COMPLETE_UPGRADE: 升级完成
* RECOVER_UPGRADE: 撤销升级
* COMPLETE_FINALIZE: 提交完成
* COMPLETE_ROLLBACK: 回滚完成
* RECOVER_ROLLBACK: 撤销回滚
* COMPLETE_CHECKPOINT: checkpoint完成
* RECOVER_CHECKPOINT: 撤销checkpoint
* NORMAL: 正常

存储目录的结构如下所示：

* current：保存当前版本的文件
* current/VERSION：包含正在运行的HDFS的版本信息
* previous：升级后，保存前一版本的文件
* previous/VERSION：前一版本的HDFS的版本信息
* previous.tmp：升级过程中，保存当前版本的文件
* removed.tmp：回滚过程中，保存当前版本的文件
* finalized.tmp：提交过程中，保存文件
* lastcheckpoint.tmp：用于导入一个checkpoint
* previous.checkpoint：前一个checkpoint
* in_use.lock：对目录加锁

VERSION文件的例子如下所示：

```
#Tue Mar 13 17:22:19 CST 2012
namespaceID=1845340702
storageID=DS-641781551-*.*.*.*-50010-1330961440921
cTime=0
storageType=DATA_NODE
layoutVersion=-19
```

StorageDirectory与状态和目录结构相关的方法是doRecover，用于恢复系统状态，根据系统当前的状态，完成的操作如下：

* COMPLETE_UPGRADE: previous.tmp -> previous
* RECOVER_UPGRADE: 删除current，previous.tmp -> current
* COMPLETE_FINALIZE: 删除finalized.tmp
* COMPLETE_ROLLBACK: 删除removed.tmp
* RECOVER_ROLLBACK: removed.tmp -> current
* COMPLETE_CHECKPOINT: 删除previous.checkpoint，lastcheckpoint.tmp -> previous.checkpoint
* RECOVER_CHECKPOINT: 删除current，lastcheckpoint.tmp -> current

StorageDirectory还有一个重要的方法是analyzeStorage，用于在启动namenode或datanode时检查存储目录的一致性，并返回系统当前的状态

DataStorage是与datanode相关的存储类，定义了几种文件的前缀和datanode的几个操作，linkBlocks方法用于创建硬链接，recoverTransitionRead方法用于将系统恢复到正常状态，在有必要时升级系统。

3种文件前缀：

* subdir：子目录前缀
* blk_：块文件前缀
* dncp_：拷贝文件前缀

4种操作：

* format：创建VERSION文件
* doUpgrade：升级系统
** 删除previous
** current -> previous.tmp
** previous.tmp做硬链接到current
** 写VERSION文件
** previous.tmp -> previous
* doRollback：回滚
** current -> removed.tmp
** previous -> current
** 删除removed.tmp
* doFinalize：提交存储目录升级
** previous -> finalized.tmp
** 删除finalized.tmp

## Dataset ##

与块相关的操作由Dataset相关的类处理，存储结构由大到小是卷（FSVolume）、目录（FSDir）和文件（Block和元数据等），类图如下所示：

![](http://lh4.googleusercontent.com/-eIMPDBGgjJ4/T2GX5NE2TxI/AAAAAAAAAMU/Y1gZ1_IrD3M/s1409/DatanodeDataset.jpg)

Block是datanode的基本数据结构，表示一个数据块的信息，每个Block都有1个数据文件和1个元数据文件。与Block相关的类有DatanodeBlockInfo，该类有3个属性：volume是块所属的卷；file是块对应的数据文件；detached表示块是否完成copy-on-write。DatanodeBlockInfo有一个重要方法detachFile用于分离文件，先将指定文件拷贝到临时目录，再将临时文件替换原来的文件，这样使得所有到原文件的硬链接被删除。

FSDir用来表示文件的组织结构，默认情况下，每个目录下最多有64个子目录，最多能存储64个块。在初始化一个目录时，会递归扫描该目录下的目录和文件，从而形成一个树状结构。addBlock方法用来添加块到当前目录，如果当前目录不能容纳更多的块，那么将块添加到一个子目录中，如果没有子目录，则创建子目录。getBlockInfo和getVolumeMap方法用于递归扫描当前目录下所有块的信息。clearPath方法用于删除文件时，更新文件路径中所有目录的信息。

FSVolume用来管理块文件，统计存储目录的使用情况，有如下6个属性：

* dataDir：数据目录，current
* tmpDir：临时目录，tmp
* detachDir：detach，使用于实现块的写时复制
* usage：已使用的空间
* dfsUsage：dfs使用的空间
* reserved：保留的空间

FSVolume在初始化时会恢复detach和tmp目录中的文件，如果detach或tmp不存在，则创建目录。createTmpFile方法用于创建临时文件。createDetachFile方法创建用于copy-on-write的文件。addBlock方法用于在当前卷中添加块。

FSVolumeSet类封装了多个FSVolume，提供获得所有容量、剩余空间、dfs使用空间和块信息的方法。getNextVolume方法采用round-robin策略选择下一个FSVolume，达到负载均衡的效果，将IO负载分到多个磁盘上，提高IO处理能力。

FSDataset类封装了FSVolumeSet，实现FSDatasetInterface接口，向外提供获得DFS使用情况及操作块的方法。

FSDatasetInterface接口应实现的方法如下：

* getMetaDataLength(Block b)：获得块元数据文件大小
* getMetaDataInputStream(Block b)：获得块元数据文件输入流
* metaFileExists(Block b)：检查元数据文件是否存在
* getLength(Block b)：获得块数据文件大小
* getStoredBlock(Block b)：根据块ID得到块信息
* getBlockInputStream(long blkid)：获得块数据文件输入流
* getBlockInputStream(Block b, long seekOffset)：获得位于块数据文件特定位置的输入流
* getTmpInputStreams(Block b, long blkoff, long ckoff)：获得位于块数据文件特定位置的输入流，块文件还位于临时目录中
* writeToBlock(Block b, boolean isRecovery)：创建块文件，并获得文件输出流
* updateBlock(Block oldblock, Block newblock)：更新块
* finalizeBlock(Block b)：完成块的写操作
* unfinalizeBlock(Block b)：关闭块文件的写，删除与块相关的临时文件
* getBlockReport()：得到块的报告
* isValidBlock(Block b)：检查块是否正常
* invalidate(Block invalidBlks[])：检查多个块是否正常
* checkDataDir()：检查存储目录是否正常
* shutdown()：关闭FSDataset
* getChannelPosition(Block b, BlockWriteStreams stream)：获得在数据输出流中的当前位置
* setChannelPosition(Block b, BlockWriteStreams stream, long dataOffset, long ckOffset)：设置在数据输出流中的位置
* validateBlockMetadata(Block b)：验证块元数据文件

FSDataset有以下几个主要属性：

* volumes: 卷集合
* ongoingCreates: 当前正在活动的文件
* maxBlocksPerDir: 每个目录能保存的最大块数
* volumeMap: 块的信息

FSDataset在创建输出流或位于特定位置的输入流时，使用RandomAccessFile，这样可以随机寻址，可以得到或设置流的位置。当完成块的写操作时，将块添加到volumeMap，并从ongoingCreates中删除。比较复杂的方法是writeToBlock，其处理过程如下所示：

* 如果块数据文件已经存在并且当前要进行恢复，将块数据文件跟与其硬链接的文件分离，需要对文件进行恢复有两种情况：客户端重新打开连接并重新发送数据包；往块追加数据
* 如果块在ongoingCreates中，将其删去
* 如果不是恢复操作，获得存放块文件的卷，创建临时文件，将块添加到volumeMap中
* 对于恢复操作，如果块临时文件存在，重用临时文件，将块添加到volumeMap中；如果块临时文件不存在，将块数据文件和对应的元数据文件移动到临时目录中，将块添加到volumeMap中
* 将块添加到ongoingCreates中
* 返回块文件输出流

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。