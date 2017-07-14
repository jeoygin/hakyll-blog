---
title: Hadoop基准测试
tags:
  - benchmark
  - Example
  - Hadoop
  - HiBench
  - Test
id: 1018
categories:
  - 计算机技术
  - Hadoop
date: 2012-12-14 18:29:03
---

测试对于验证系统的正确性、分析系统的性能来说非常重要，但往往容易被我们所忽视。为了能对系统有更全面的了解、能找到系统的瓶颈所在、能对系统性能做更好的改进，打算先从测试入手，学习Hadoop几种主要的测试手段。本文将分成两部分：第一部分记录如何使用Hadoop自带的测试工具进行测试；第二部分记录Intel开放的Hadoop Benchmark Suit: HiBench的安装及使用。

**<big>1\. Hadoop基准测试</big>**

Hadoop自带了几个基准测试，被打包在几个jar包中，如hadoop-*test*.jar和hadoop-*examples*.jar，在Hadoop环境中可以很方便地运行测试。本文测试使用的Hadoop版本是cloudera的hadoop-0.20.2-cdh3u3。

在测试前，先设置好环境变量：

    $ export $HADOOP_HOME=/home/hadoop/hadoop
    $ export $PATH=$PATH:$HADOOP_HOME/bin

使用以下命令就可以调用jar包中的类：

    $ hadoop jar $HADOOP_HOME/xxx.jar

<!--more-->


**(1). Hadoop Test**

当不带参数调用hadoop-test-0.20.2-cdh3u3.jar时，会列出所有的测试程序：

    $ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar
    An example program must be given as the first argument.
    Valid program names are:
      DFSCIOTest: Distributed i/o benchmark of libhdfs.
      DistributedFSCheck: Distributed checkup of the file system consistency.
      MRReliabilityTest: A program that tests the reliability of the MR framework by injecting faults/failures
      TestDFSIO: Distributed i/o benchmark.
      dfsthroughput: measure hdfs throughput
      filebench: Benchmark SequenceFile(Input|Output)Format (block,record compressed and uncompressed), Text(Input|Output)Format (compressed and uncompressed)
      loadgen: Generic map/reduce load generator
      mapredtest: A map/reduce test check.
      minicluster: Single process HDFS and MR cluster.
      mrbench: A map/reduce benchmark that can create many small jobs
      nnbench: A benchmark that stresses the namenode.
      testarrayfile: A test for flat files of binary key/value pairs.
      testbigmapoutput: A map/reduce program that works on a very big non-splittable file and does identity map/reduce
      testfilesystem: A test for FileSystem read/write.
      testipc: A test for ipc.
      testmapredsort: A map/reduce program that validates the map-reduce framework's sort.
      testrpc: A test for rpc.
      testsequencefile: A test for flat files of binary key value pairs.
      testsequencefileinputformat: A test for sequence file input format.
      testsetfile: A test for flat files of binary key/value pairs.
      testtextinputformat: A test for text input format.
      threadedmapbench: A map/reduce benchmark that compares the performance of maps with multiple spills over maps with 1 spill

这些程序从多个角度对Hadoop进行测试，TestDFSIO、mrbench和nnbench是三个广泛被使用的测试。

**TestDFSIO**

TestDFSIO用于测试HDFS的IO性能，使用一个MapReduce作业来并发地执行读写操作，每个map任务用于读或写每个文件，map的输出用于收集与处理文件相关的统计信息，reduce用于累积统计信息，并产生summary。TestDFSIO的用法如下：

```
  TestDFSIO.0.0.6
  Usage: TestDFSIO [genericOptions] -read | -write | -append | -clean [-nrFiles N] [-fileSize Size[B|KB|MB|GB|TB]] [-resFile resultFileName] [-bufferSize Bytes] [-rootDir]
```

以下的例子将往HDFS中写入10个1000MB的文件：

    $ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar TestDFSIO \
      -write -nrFiles 10 -fileSize 1000

结果将会写到一个本地文件TestDFSIO_results.log：

```
----- TestDFSIO ----- : write
            Date & time: Mon Dec 10 11:11:15 CST 2012
        Number of files: 10
 Total MBytes processed: 10000.0
      Throughput mb/sec: 3.5158047729862436
 Average IO rate mb/sec: 3.5290374755859375
 IO rate std deviation: 0.22884063705950305
     Test exec time sec: 316.615
```

以下的例子将从HDFS中读取10个1000MB的文件：

```
$ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar TestDFSIO \
   -read -nrFiles 10 -fileSize 1000
```

结果将会写到一个本地文件TestDFSIO_results.log：

```
----- TestDFSIO ----- : read
            Date & time: Mon Dec 10 11:21:17 CST 2012
        Number of files: 10
 Total MBytes processed: 10000.0
      Throughput mb/sec: 255.8002711482874
 Average IO rate mb/sec: 257.1685791015625
 IO rate std deviation: 19.514058659935184
     Test exec time sec: 18.459
```

使用以下命令删除测试数据：

    $ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar TestDFSIO -clean

**nnbench**

nnbench用于测试NameNode的负载，它会生成很多与HDFS相关的请求，给NameNode施加较大的压力。这个测试能在HDFS上模拟创建、读取、重命名和删除文件等操作。nnbench的用法如下：

```
 NameNode Benchmark 0.4
 Usage: nnbench <options>
 Options:
      -operation <Available operations are create_write open_read rename delete. This option is mandatory>
       * NOTE: The open_read, rename and delete operations assume that the files they operate on, are already available. The create_write operation must be run before running the other operations.
      -maps <number of maps. default is 1\. This is not mandatory>
      -reduces <number of reduces. default is 1\. This is not mandatory>
      -startTime <time to start, given in seconds from the epoch. Make sure this is far enough into the future, so all maps (operations) will start at the same time>. default is launch time + 2 mins. This is not mandatory
      -blockSize <Block size in bytes. default is 1\. This is not mandatory>
      -bytesToWrite <Bytes to write. default is 0\. This is not mandatory>
      -bytesPerChecksum <Bytes per checksum for the files. default is 1\. This is not mandatory>
      -numberOfFiles <number of files to create. default is 1\. This is not mandatory>
      -replicationFactorPerFile <Replication factor for the files. default is 1\. This is not mandatory>
      -baseDir <base DFS path. default is /becnhmarks/NNBench. This is not mandatory>
      -readFileAfterOpen <true or false. if true, it reads the file and reports the average time to read. This is valid with the open_read operation. default is false. This is not mandatory>
      -help: Display the help statement
```

以下例子使用12个mapper和6个reducer来创建1000个文件：

```
 $ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar nnbench \
     -operation create_write -maps 12 -reduces 6 -blockSize 1 \
     -bytesToWrite 0 -numberOfFiles 1000 -replicationFactorPerFile 3 \
     -readFileAfterOpen true -baseDir /benchmarks/NNBench-`hostname -s`
```

**mrbench**

mrbench会多次重复执行一个小作业，用于检查在机群上小作业的运行是否可重复以及运行是否高效。mrbench的用法如下：

```
 MRBenchmark.0.0.2
 Usage: mrbench [-baseDir <base DFS path for output/input, default is /benchmarks/MRBench>] [-jar <local path to job jar file containing Mapper and Reducer implementations, default is current jar file>] [-numRuns <number of times to run the job, default is 1>] [-maps <number of maps for each run, default is 2>] [-reduces <number of reduces for each run, default is 1>] [-inputLines <number of input lines to generate, default is 1>] [-inputType <type of input to generate, one of ascending (default), descending, random>] [-verbose]
```

以下例子会运行一个小作业50次：

    $ hadoop jar $HADOOP_HOME/hadoop-test-0.20.2-cdh3u3.jar mrbench -numRuns 50

运行结果如下所示：

```
 DataLines     Maps     Reduces     AvgTime (milliseconds)
 1          2     1     14237
```

以上结果表示平均作业完成时间是14秒。

**(2). Hadoop Examples**

除了上文提到的测试，Hadoop还自带了一些例子，比如WordCount和TeraSort，这些例子在hadoop-examples-0.20.2-cdh3u3.jar中。执行以下命令会列出所有的示例程序：

```
 $ hadoop jar $HADOOP_HOME/hadoop-examples-0.20.2-cdh3u3.jar
 An example program must be given as the first argument.
 Valid program names are:
   aggregatewordcount: An Aggregate based map/reduce program that counts the words in the input files.
   aggregatewordhist: An Aggregate based map/reduce program that computes the histogram of the words in the input files.
   dbcount: An example job that count the pageview counts from a database.
   grep: A map/reduce program that counts the matches of a regex in the input.
   join: A job that effects a join over sorted, equally partitioned datasets
   multifilewc: A job that counts words from several files.
   pentomino: A map/reduce tile laying program to find solutions to pentomino problems.
   pi: A map/reduce program that estimates Pi using monte-carlo method.
   randomtextwriter: A map/reduce program that writes 10GB of random textual data per node.
   randomwriter: A map/reduce program that writes 10GB of random data per node.
   secondarysort: An example defining a secondary sort to the reduce.
   sleep: A job that sleeps at each map and reduce task.
   sort: A map/reduce program that sorts the data written by the random writer.
   sudoku: A sudoku solver.
   teragen: Generate data for the terasort
   terasort: Run the terasort
   teravalidate: Checking results of terasort
   wordcount: A map/reduce program that counts the words in the input files.
```

WordCount在 [Running Hadoop On CentOS (Single-Node Cluster)](2012/02/running-hadoop-on-centos-single-node-cluster.html) 一文中已有介绍，这里就不再赘述。

**TeraSort**

一个完整的TeraSort测试需要按以下三步执行：

1. 用TeraGen生成随机数据
2. 对输入数据运行TeraSort
3. 用TeraValidate验证排好序的输出数据

并不需要在每次测试时都生成输入数据，生成一次数据之后，每次测试可以跳过第一步。

TeraGen的用法如下：

    $ hadoop jar hadoop-*examples*.jar teragen <number of 100-byte rows> <output dir>

以下命令运行TeraGen生成1GB的输入数据，并输出到目录/examples/terasort-input：

    $ hadoop jar $HADOOP_HOME/hadoop-examples-0.20.2-cdh3u3.jar teragen \
        10000000 /examples/terasort-input

TeraGen产生的数据每行的格式如下：

    <10 bytes key><10 bytes rowid><78 bytes filler>\r\n

其中：

1. key是一些随机字符，每个字符的ASCII码取值范围为[32, 126]
2. rowid是一个整数，右对齐
3. filler由7组字符组成，每组有10个字符（最后一组8个），字符从'A'到'Z'依次取值

以下命令运行TeraSort对数据进行排序，并将结果输出到目录/examples/terasort-output：

    $ hadoop jar $HADOOP_HOME/hadoop-examples-0.20.2-cdh3u3.jar terasort \
       /examples/terasort-input /examples/terasort-output

以下命令运行TeraValidate来验证TeraSort输出的数据是否有序，如果检测到问题，将乱序的key输出到目录/examples/terasort-validate

    $ hadoop jar $HADOOP_HOME/hadoop-examples-0.20.2-cdh3u3.jar teravalidate \
       /examples/terasort-output /examples/terasort-validate

**(3). Hadoop Gridmix2**

Gridmix是Hadoop自带的基准测试程序，是对其它几个基准测试程序的进一步封装，包括产生数据、提交作业、统计完成时间等功能模块。Gridmix自带了各种类型的作业，分别为streamSort、javaSort、combiner、monsterQuery、webdataScan和webdataSort。

**编译**

```
$ cd  $HADOOP_HOME/src/benchmarks/gridmix2
$ ant
$ cp build/gridmix.jar .
```

**修改环境变量**

修改gridmix-env-2文件：

```
export HADOOP_INSTALL_HOME=/home/jeoygin
export HADOOP_VERSION=hadoop-0.20.2-cdh3u3
export HADOOP_HOME=${HADOOP_INSTALL_HOME}/${HADOOP_VERSION}
export HADOOP_CONF_DIR=${HADOOP_HOME}/conf
export USE_REAL_DATASET=

export APP_JAR=${HADOOP_HOME}/hadoop-test-0.20.2-cdh3u3.jar
export EXAMPLE_JAR=${HADOOP_HOME}/hadoop-examples-0.20.2-cdh3u3.jar
export STREAMING_JAR=${HADOOP_HOME}/contrib/streaming/hadoop-streaming-0.20.2-cdh3u3.jar
```

如果USE_REAL_DATASET的值为TRUE的话，将使用500GB压缩数据（等价于2TB非压缩数据），如果留空将使用500MB压缩数据（等价于2GB非压缩数据）。

**修改配置信息**

配置信息在gridmix_config.xml文件中。gridmix中，每种作业有大中小三种类型：小作业只有3个输入文件（即3个map）；中作业的输入文件是与正则表达式{part-000*0,part-000*1,part-000*2}匹配的文件；大作业会处理处有数据。

**产生数据**

```
$ chmod +x generateGridmix2data.sh
$ ./generateGridmix2data.sh
```

generateGridmix2data.sh脚本会运行一个作业，在HDFS的目录/gridmix/data中产生输入数据。

**运行**

```
$ chmod +x rungridmix_2
$ ./rungridmix_2
```

运行后，会创建_start.out文件来记录开始时间，结束后，创建_end.out文件来记录完成时间。

**(4). 查看任务统计信息**

Hadoop提供非常方便的方式来获取一个任务的统计信息，使用以下命令即可作到：

    $ hadoop job -history all <job output directory>

这个命令会分析任务的两个历史文件（这两个文件存储在&lt;job output directory&gt;/_logs/history目录中）并计算任务的统计信息。

**<big>2\. HiBench</big>**

HiBench是Intel开放的一个Hadoop Benchmark Suit，包含9个典型的Hadoop负载（Micro benchmarks、HDFS benchmarks、web search benchmarks、machine learning benchmarks和data analytics benchmarks），主页是：** https://github.com/intel-hadoop/hibench **。

HiBench为大多数负载提供是否启用压缩的选项，默认的compression codec是zlib。

**Micro Benchmarks:**

* Sort (sort)：使用Hadoop RandomTextWriter生成数据，并对数据进行排序
* WordCount (wordcount)：统计输入数据中每个单词的出现次数，输入数据使用Hadoop RandomTextWriter生成
* TeraSort (terasort)：这是由微软的数据库大牛Jim Gray（2007年失踪）创建的标准benchmark，输入数据由Hadoop TeraGen产生

**HDFS Benchmarks:**

* 增强的DFSIO (dfsioe)：通过产生大量同时执行读写请求的任务来测试Hadoop机群的HDFS吞吐量

**Web Search Benchmarks:**

* Nutch indexing (nutchindexing)：大规模搜索引擎索引是MapReduce的一个重要应用，这个负载测试Nutch（Apache的一个开源搜索引擎）的索引子系统，使用自动生成的Web数据，Web数据中的链接和单词符合Zipfian分布
* PageRank (pagerank)：这个负载包含一种在Hadoop上的PageRank算法实现，使用自动生成的Web数据，Web数据中的链接符合Zipfian分布

**Machine Learning Benchmarks:**

* Mahout Bayesian classification (bayes)：大规模机器学习也是MapReduce的一个重要应用，这个负载测试Mahout 0.7（Apache的一个开源机器学习库）中的Naive Bayesian训练器，输入数据是自动生成的文档，文档中的单词符合Zipfian分布
* Mahout K-means clustering (kmeans)：这个负载测试Mahout 0.7中的K-means聚类算法，输入数据集由基于均匀分布和高斯分布的GenKMeansDataset产生

**Data Analytics Benchmarks:**

* Hive Query Benchmarks (hivebench)：这个负载的开发基于SIGMOD 09的一篇论文“A Comparison of Approaches to Large-Scale Data Analysis”和HIVE-396，包含执行典型OLAP查询的Hive查询（Aggregation and Join），使用自动生成的Web数据，Web数据中的链接符合Zipfian分布

下文将${HIBENCH_HOME}定义为HiBench的解压缩目录。

**(1). 安装与配置**

**建立环境：**

* HiBench-2.2：从https://github.com/intel-hadoop/HiBench/zipball/HiBench-2.2下载
* Hadoop：在运行任何负载之前，请确保Hadoop环境能正常运行，所有负载在Cloudera Distribution of Hadoop 3 update 4 (cdh3u4)和Hadoop 1.0.3上测试通过
* Hive：如果要测试hivebench，请确保已正确建立了Hive环境

**配置所有负载：**

需要在${HIBENCH_HOME}/bin/hibench-config.sh文件中设置一些全局的环境变量。

```
$ unzip HiBench-2.2.zip
$ cd HiBench-2.2
$ vim bin/hibench-config.sh

HADOOP_HOME      <The Hadoop installation location>
HADOOP_CONF_DIR  <The hadoop configuration DIR, default is $HADOOP_HOME/conf>
COMPRESS_GLOBAL  <Whether to enable the in/out compression for all workloads, 0 is disable, 1 is enable>
COMPRESS_CODEC_GLOBAL  <The default codec used for in/out data compression>
```

**配置单个负载：**

在每个负载目录下，可以修改conf/configure.sh这个文件，设置负载运行的参数。

**同步每个节点的时间**

**(2). 运行**

**同时运行几个负载：**

1. 修改**${HIBENCH_HOME}/conf/benchmarks.lst**文件，该文件定义了将要运行的负载，每行指定一个负载，在任意一行前可以使用#跳过该行
2. 运行**${HIBENCH_HOME}/bin/run-all.sh**脚本

**单独运行每个负载：**

可以单独运行每个负载，通常，在每个负载目录下有三个不同的文件：

```
conf/configure.sh   包含所有参数的配置文件，可以设置数据大小及测试选项等
bin/prepare*.sh   生成或拷贝作业输入数据到HDFS
bin/run*.sh       运行benchmark
```

1. 配置benchmark：如果需要，可以修改configure.sh文件来设置自己想要的参数
2. 准备数据：运行bin/prepare.sh脚本为benchmark准备输入数据
3. 运行benchmark：运行bin/run*.sh脚本来运行对应的benchmark

**(3). 小结**

HiBench覆盖了一些广被使用的Hadoop Benchmark，如果看过该项目的源码，会发现该项目很精悍，代码不多，通过一些脚本使每个benchmark的配置、准备和运行变得规范化，用起来十分方便。

**<big>3\. 参考资料</big>**

1. [Benchmarking and Stress Testing an Hadoop Cluster with TeraSort, TestDFSIO & Co.](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench)
2. [Hadoop Gridmix基准测试](http://www.michael-noll.com/blog/2011/04/09/benchmarking-and-stress-testing-an-hadoop-cluster-with-terasort-testdfsio-nnbench-mrbench)
3. [HiBench](https://github.com/intel-hadoop/HiBench)
