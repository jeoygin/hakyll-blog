---
title: Running Hadoop On CentOS (Single-Node Cluster)
tags:
  - centos
  - Hadoop
  - Single
id: 556
categories:
  - 计算机技术
  - Hadoop
date: 2012-02-22 17:28:49
---

本文将介绍如何在CentOS系统安装单节点Hadoop机群，Hadoop版本为0.20.2，安装方法参考http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-multi-node-cluster/。

## 安装java运行环境 ##

```
# yum install java-1.6.0-openjdk-devel
```

JDK将安装在/usr/lib/jvm/java-1.6.0-openjdk.x86_64

## 添加专用的Hadoop系统用户 ##

```
# groupadd hadoop
# useradd -g hadoop
```

<!--more-->

## 配置SSH ##

```
# su - hadoop
$ ssh-keygen -t rsa -P ""
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

## 安装Hadoop ##

```
# cd /opt
# tar xzf hadoop-0.20.2.tar.gz
# ln -s hadoop-0.20.2 hadoop
# chown -R hadoop:hadoop hadoop
```

## 设置环境变量 ##

```
# su - hadoop
$ vim ~/.bashrc

export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk.x86_64
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:$HADOOP_HOME/bin
```

## 配置 ##

**hadoop-env.sh:**

打开/opt/hadoop/conf/hadoop-env.sh，设置JAVA_HOME环境变量

```
export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk.x86_64

# mkdir -p /app/hadoop/tmp
# chown hadoop:hadoop /app/hadoop/tmp
```

**conf/core-site.xml:**

```
 <!-- In: conf/core-site.xml -->
 <property>
    <name>hadoop.tmp.dir</name>
    <value>/app/hadoop/tmp</value>
    <description>A base for other temporary directories.</description>
 </property>

 <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:54310</value>
    <description>The name of the default file system.  A URI whose
    scheme and authority determine the FileSystem implementation.  The
    uri's scheme determines the config property (fs.SCHEME.impl) naming
    the FileSystem implementation class.  The uri's authority is used to
    determine the host, port, etc. for a filesystem.</description>
 </property>
```

**conf/mapred-site.xml:**

```
 <!-- In: conf/mapred-site.xml -->
 <property>
   <name>mapred.job.tracker</name>
    <value>localhost:54311</value>
    <description>The host and port that the MapReduce job tracker runs
    at.  If "local", then jobs are run in-process as a single map
    and reduce task.
    </description>
 </property>
```

**conf/hdfs-site.xml:**

```
 <!-- In: conf/hdfs-site.xml -->
  <property>
    <name>dfs.replication</name>
    <value>1</value>
    <description>Default block replication.
    The actual number of replications can be specified when the file is created.
    The default is used if replication is not specified in create time.
    </description>
 </property>
```

## 通过namenode格式化HDFS文件系统 ##

```
$ /opt/hadoop/bin/hadoop namenode -format
```

## 启动机群 ##

```
$ /opt/hadoop/bin/start-all.sh
```

检查进程是否在运行：

```
 $ jps
 31317 NameNode
 31755 SecondaryNameNode
 32110 TaskTracker
 32177 Jps
 31540 DataNode
 31900 JobTracker
```

```
$ netstat -plten | grep java
```

## 停止机群 ##

```
$ /opt/hadoop/bin/stop-all.sh
```

## 运行一个MapReduce任务 ##

**准备数据：**

找几个文本文件保存到/tmp/test目录中

**复制数据到HDFS：**

```
$ /opt/hadoop/bin/hadoop dfs -copyFromLocal /tmp/test /user/hadoop/test
```

**运行wordcound任务：**

```
$ cd /opt/hadoop/
$ bin/hadoop jar hadoop*examples*.jar wordcount /user/hadoop/test /user/hadoop/test-output
```

这个命令会读取HDFS目录/user/hadoop/test目录中的所有文件，处理后，将结果保存在/user/hadoop/test-output目录中。

用以下命令查看HDFS目录/user/hadoop/test-output目录中的文件

```
$ bin/hadoop dfs -ls /user/hduser/test-output
```

如果想要修改Hadoop的设置，可以使用-D选项，如下所示：

```
$ bin/hadoop jar hadoop*examples*.jar wordcount -D mapred.reduce.tasks=16 /user/hadoop/test /user/hadoop/test-output
```

**查看结果：**

```
$ bin/hadoop dfs -cat /user/hadoop/test-output/part-r-00000
```

**取回结果：**

```
$ mkdir /tmp/test-output
$ bin/hadoop dfs -copyToLocal /user/hadoop/test-output /tmp/test-output
```

## Hadoop Web界面 ##

* 在conf/hadoop-default.xml中配置
* http://localhost:50030/ – MapReduce job tracker(s) Web界面
* http://localhost:50060/ – task tracker(s) Web界面
* http://localhost:50070/ – HDFS name node(s) Web界面