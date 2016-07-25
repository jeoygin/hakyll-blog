---
title: HDFS源码分析（8）：FileSystem
tags:
  - filesystem
  - Hadoop
  - HDFS
id: 983
categories:
  - 计算机技术
  - Hadoop
date: 2012-07-14 16:54:19
---

## 前提 ##

Hadoop版本：hadoop-0.20.2

## 概述 ##

之前已对HDFS的datanode部分的源码进行了分析，还剩client和namenode这个最最重要的部分，本着从简单入手，打算继续把namenode当成是一个黑盒，先分析client的代码，毕竟client的代码行数与namenode相比要少得多。

很粗地把client的代码浏览了一下，发现client暴露给用户的接口是DistributedFileSystem这个东东，该类实现了FileSystem这个通用文件系统的抽象类。FileSystem位于core中，并不是HDFS专用的，先对FileSystem进行分析，有助于从宏观上去剖析DFS。

本以为把FileSystem这个类的代码看一遍应该就差不多了，看着看着才发觉FileSystem这个类好庞大、关联依赖的类好多，从下面的类图就可以看出来。虽说类多、方法多，但逻辑相对简单，比较容易理解。

[![](http://lh5.googleusercontent.com/-0fKCkmsgF6w/UAAFk2S5BjI/AAAAAAAAAPE/7a1NVOlX-p8/s1030/FileSystem.png)](https://lh5.googleusercontent.com/-0fKCkmsgF6w/UAAFk2S5BjI/AAAAAAAAAPE/7a1NVOlX-p8/s2061/FileSystem.png "看大图可能需要越过某座墙")
<!--more-->
本文所涉及到的类的包结构如下：

* org.apache.hadoop.fs
    * BlockLocation
    * ContentSummary
    * FileChecksum
    * FileSystem
    * FileStatus
    * FSDataInputStream
    * FSDataOutputStream
    * FSPermission
    * GlobExpander
    * Path
    * PositionedReadable
    * Seekable
    * Syncable
* org.apache.hadoop.fs.permission
    * FsAction
    * FsPermission

下面将简单介绍几个重要的类。

## FileSystem ##

上文已说过FileSystem是一个通用文件系统的抽象基类，它可能被实现为分布式文件系统或本地文件系统。

先来看其重要成员：

* CACHE: 静态成员，对打开的文件系统实例做cache，在计算机领域里面，cache是非常重要的，做文件系统怎么能少得了它呢！
* statisticsTable: 静态成员，保存各文件系统实例的统计信息
* key: 文件系统实例在CACHE中的键
* statistics: 文件系统实例在读写统计
* deleteOnExit: 退出时需要删除的文件，这个功能很实用，Java里的文件也有这么个功能
* clientFinalizer: 一个线程，用于在退出时关闭所有缓存的文件系统

从其成员，我们可以看到FileSystem有两个功能：缓存和统计。

下面我们来瞧瞧FileSystem的方法，总共有70多个，够吓人的，不过不能被吓倒了，要硬着头皮去看看究竟在做些什么事情，传统的文件系统里都会有的创建目录、创建文件、打开文件、列举目录的文件、重命名文件、关闭文件等功能都覆盖到，除此还有其它一些重要的方法：

* getFileBlockLocations: 取得文件中某个区域的内容所在块（可能会存储在多个块中）的位置
* exists: 检查路径是否存在
* isFile: 检查给定路径是否是一个文件
* getContentSummary: 取得给定路径的统计情况，包括文件总大小、文件数目和目录数目，会递归统计子目录的情况
* listStatus: 如果给定路径是目录，列举该目录的文件和子目录的状态
* globStatus: 返回匹配特定模式的所有文件，跟Linux的命令行很像，可以使用通配来扩展
* getHomeDirectory: 取得用户的主目录
* *etWorkingDirectory: 设置和取得当前工作目录
* copyFromLocalFile: 将文件从本地文件系统拷贝到当前文件系统
* copyToLocalFile: 将文件从当前文件系统拷贝到本地文件系统
* moveFromLocalFile: 将文件从本地文件系统移动到当前文件系统
* moveToLocalFile: 将文件从当前文件系统移到到本地文件系统
* getFileStatus: 取得文件的状态
* setPermission: 设置文件的访问权限，该方法为空
* setOwner: 设置文件所属的用户和组，该方法为空
* setTimes: 设置文件的修改时间和访问时间，该方法为空
* getAllStatistics: 取得所有文件系统的统计情况
* getStatistics: 取得某个特定文件系统的统计情况

细心的读者是否发现漏了两个重要的静态方法：

* get: 根据URI取得一个FileSystem实例，如果允许缓存，会中从缓存中取出，否则将调用createFileSystem创建一个新实例
* createFileSystem: 以URI的scheme为键从配置中得到实现该scheme的类名的值，然后创建一个新的FileSystem实例

在Hadoop生态系统中，可能会经常用到HDFS，也可能会经常见到如下代码：

	FileSystem fs = FileSystem.get(URI.create(uri), conf);

上述代码的作用是通过一个uri来取得对应文件系统的实例。

## FileSystem.Cache ##

用于缓存创建的文件系统，实现并不复杂，使用一个HashMap，Map的键类型是Key，值类型是FileSystem。

Key有三个属性：

* scheme: 该属性从URI中取得，比如一个URI“http://server/index.html”，那么scheme就是http
* authority: 该属性也从URI中取得，在上述的例子中，authority就是server，authority包括用户信息、主机以及端口
* username: 当前登陆的用户，具体细节可见org.apache.hadoop.security.UserGroupInformation，这个类我没细看

由此可见，缓冲使用scheme、authority和username来标识文件系统。

## FileSystem.Statistics ##

用于统计文件系统的情况，有三个属性：

* scheme: 标识文件系统，像HDFS文件系统该属性就为hdfs
* bytesRead: 记录目前读取的字节数，类型为AtomicLong，以避免数据不同步问题
* bytesWritten: 记录目前写入的字节数，类型为AtomicLong，以避免数据不同步问题

## Path ##

用于描述文件或目录的路径，路径使用斜线（/）作为目录的分隔符，如果一个路径以斜线开头则是绝对路径。主要是封装了URI，增添一些检查和处理，使该类能正确处理不同文件系统的路径和目录分隔符。

该类方法名比较直接观，处理逻辑也不复杂，这里就不作一一介绍。

## BlockLocation ##

用于保存文件中一个块的信息，这块和HDFS中的Block是一致的。看其属性就能大概知道其用途：

* hosts: datanode的主机名
* names: datanode的名字，样式为“hostname:portNumber”
* topologyPaths: 在网络拓扑中的完整路径名，没看到用它来做啥事
* offset: 该块在文件中的位置
* length: 该块的大小

## FileStatus ##

用于记录文件/目录的信息，记录的内容和Unix、Linux系统很像：

* path: 文件/目录路径
* length: 文件/目录大小
* isdir: 是否是目录
* block_replication: 块的副本数，这个值难道不是整个系统一致？
* blocksize: 块的大小，这个值难道不是整个系统一致？
* modification_time: 文件/目录最后修改时间
* access_time: 文件/目录最后访问时间
* permission: 文件/目录的访问权限，下文会介绍
* owner: 文件/目录的所有者
* group: 文件/目录所属的组

## FsPermission ##

用于控制文件/目录的访问权限，使用POSIX权限方式，控制用户、组、其它的权限，权限有读、写、执行，相信大家都很熟悉。

## FSDataOutputStream ##

在文件系统中用于输出数据的流，继承DataOutputStream，实现Syncable接口，因此，必须支持sync操作。

这个类很简单，当实现一个具体的文件系统时，需要自己定制一个输出流，实现特定的功能，只要继承自FSDataOutputStream，就能符合FileSystem的接口。

## FSDataInputStream ##

在文件系统中用于输入数据的流，继承DataInputStream，实现Seekable和PositionReadable接口，因此，必须支持seek和从某个位置开始读取的操作。

这个类也是很简单，当实现一个具体的文件系统时，需要自己定制一个输入流，实现特定的功能，只要继承自FSDataInputStream，就能符合FileSystem的接口。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。