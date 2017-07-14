---
title: Running Hadoop On CentOS (Multi-Node Cluster)
tags:
  - centos
  - Hadoop
  - Multi
id: 562
categories:
  - 计算机技术
  - Hadoop
date: 2012-02-22 19:41:37
---

本文将介绍如何在CentOS系统安装Hadoop机群，Hadoop版本为0.20.2，安装方法参考http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-multi-node-cluster/。

## 准备 ##

首先，在每个节点安装一个单节点机群，参照[Running Hadoop On CentOS (Single-Node Cluster)](archives/556)。

## 网络 ##

现在，我们有多个机群启动并正在运行，我们需要修改Hadoop配置使其中一个节点作为master节点，其它节点作为slave节点

假设我们现在有一个master节点和两个slave节点，master节点的主机名为master，slave节点的主机名分别为slave1和slave2，在所有机器的/etc/hosts文件中添加以下内容：

```
 192.168.0.1    master
 192.168.0.2    slave1
 192.168.0.3    slave2
```


<!--more-->


## SSH无密码登陆 ##

要确保master节点的hadoop用户能够不需要密码SSH登陆slave节点的hadoop用户，可以手动将master节点的/home/hadoop/.ssh/id_rsa.pub文件的内容添加到所有slave节点的/home/hadoop/.ssh/authorized_keys文件中，或是执行以下命令：

```
 $ ssh-copy-id -i $HOME/.ssh/id_rsa.pub hadoop@slave1
 $ ssh-copy-id -i $HOME/.ssh/id_rsa.pub hadoop@slave2
```

## 机群概况 ##

在一个Hadoop机群中，master节点将运行master守护进程：用于HDFS存储的NameNode和用于MapReduce处理的JobTracker；所有的节点都运行slave守护进程：用于HDFS存储的DataNode和用于MapReduce处理的TaskTracker。

## Hadoop配置 ##

**conf/masters**

在master节点上，更新conf/masters文件，如下所示：

 master

**conf/slaves**

在master节点上，更新conf/slaves文件，如下所示：

 master
 slave

**conf/core-site.xml**

在所有节点上，修改core-site.xml文件：

```
 <!-- In: conf/core-site.xml -->
 <property>
   <name>fs.default.name</name>
   <value>hdfs://master:54310</value>
   <description>The name of the default file system.  A URI whose
   scheme and authority determine the FileSystem implementation.  The
   uri's scheme determines the config property (fs.SCHEME.impl) naming
   the FileSystem implementation class.  The uri's authority is used to
   determine the host, port, etc. for a filesystem.</description>
 </property>
```

**conf/mapred-site.xml**

在所有节点上，修改mapred-site.xml文件：

```
 <!-- In: conf/mapred-site.xml -->
 <property>
   <name>mapred.job.tracker</name>
   <value>master:54311</value>
   <description>The host and port that the MapReduce job tracker runs
   at.  If "local", then jobs are run in-process as a single map
   and reduce task.
   </description>
 </property>
```

**conf/hdfs-site.xml**

在所有节点上，修改hdfs-site.xml文件：

```
 <!-- In: conf/hdfs-site.xml -->
 <property>
   <name>dfs.replication</name>
   <value>3</value>
   <description>Default block replication.
   The actual number of replications can be specified when the file is created.
   The default is used if replication is not specified in create time.
   </description>
 </property>
```

## 在NameNode格式化HDFS文件系统 ##

在启动多节点机群前，我们需要为NameNode格式化HDFS，此操作仅在初次建立Hadoop机群时执行，因为该操作会擦除HDFS文件系统上的数据。HDFS的naming信息存储在NameNode本地文件系统的指定目录，由属性dfs.name.dir设置。

```
 $ /opt/hadoop/bin/hadoop namenode -format
```

## 启动机群 ##

* bin/start-dfs.sh: 启动NameNode
* bin/start-mapred.sh: 启动JobTracker
* bin/start-all.sh: 启动NameNode和JobTracker
* bin/hadoop-daemon.sh start [namenode | secondarynamenode | datanode | jobtracker | tasktracker]: 手动启动守护进程

启动机群有两个步骤。第一，启动HDFS守护进程：在master节点启动NameNode守护进程，在所有slave节点启动DataNode守护进程。第二，启动MapReduce守护进程：在master节点启动JobTracker守护进程，在所有slave节点启动JobTracker守护进程。

* HDFS守护进程

在master节点运行bin/start-dfs.sh命令，将会启动HDFS机群，在master节点运行NameNode守护进程，在conf/slaves文件列出的节点上运行DataNode守护进程。

此时，master节点上运行的Java进程有：

```
 $ jps
 24262 NameNode
 4925 Jps
 24403 DataNode
 24601 SecondaryNameNode
```

在slave1节点上，可能检查logs/hadoop-hadoop-datanode-slave1.log日志文件来判断命令的执行是否成功。DataNode会自动格式化其存储目录（由dfs.data.dir属性设置）

此时，slave节点上运行的Java进程有：

```
 $ jps
 2364 Jps
 27955 DataNode
```

* MapReduce守护进程

在master节点运行bin/start-mapred.sh命令，将会启动MapReduce机群，在master节点运行JobTracker守护进程，在conf/slaves文件列出的节点上运行TaskTrackers守护进程。

此时，master节点上运行的Java进程有：

```
 $ jps
 24262 NameNode
 24848 TaskTracker
 5011 Jps
 24403 DataNode
 24601 SecondaryNameNode
 24704 JobTracker
```

在slave1节点上，可能检查logs/hadoop-hadoop-tasktracker-slave1.log日志文件来判断命令的执行是否成功。

此时，slave节点上运行的Java进程有：

```
 $ jps
 28130 TaskTracker
 2401 Jps
 24403 DataNode
```

## 停止机群 ##

同启动机群一样，停止机群也分两步。第一，停止MapReduce守护进程：在master节点停止JobTracker守护进程，在所有slave节点停止JobTracker守护进程。第二，停止HDFS守护进程：在master节点停止NameNode守护进程，在所有slave节点停止DataNode守护进程。

* MapReduce守护进程

在master节点运行bin/stop-mapred.sh命令，将会停止运行在master节点上的JobTracker守护进程，停止运行在conf/slaves文件列出的节点上的TaskTrackers守护进程。

* HDFS守护进程

在master节点运行bin/stop-dfs.sh命令，将会停止运行在master节点上的NameNode守护进程，停止运行在conf/slaves文件列出的节点上的DataNodes守护进程。