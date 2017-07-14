---
title: HDFS源码分析（10）：HDFS输入/输出流
tags:
  - DFSInputStream
  - DFSOutputStream
  - Hadoop
  - HDFS
id: 1003
categories:
  - 计算机技术
  - Hadoop
date: 2012-07-31 20:49:21
---

## 前提 ##

Hadoop版本：hadoop-0.20.2

## 概述 ##

在上一篇文章中[HDFS源码分析（9）：DFSClient](http://jeoygin.org/2012/07/hdfs-source-analysis-dfs-client.html)初步介绍了HDFS客户端的相关内容，但由于篇幅关系，没有对HDFS的输入/输出流进行介绍，而这正是本文的重点。数据的读取和写入是客户端最重要的功能，也是最主要的逻辑，本文将分成输入和输出两部分对HDFS的文件流进行分析。主要的类位于org.apache.hadoop.hdfs.DFSClient类中。

## DFSInputStream ##

DFSInputStream的主要功能是向namenode获取块信息，并且从datanode读取数据，但涉及到的问题也不少：一个文件被分割成多个块，每个块可能存储在不同的datanode；如果一个datanode挂了，要尝试另一个datanode；文件损坏了……因此，我们必须仔细地进行分析，那么，当要在客户端添加或修改功能时才不至于无从下手。

先来看看类图，从总体上把握类之间的关系，由于类比较多，所以略去了不少类，只剩下一些重要的类，因此下面的类图并不完整：

[![看大图可能需要越过某座墙](http://lh3.googleusercontent.com/-BHKBJT4Ed4A/UBJFqsjWjtI/AAAAAAAAAQM/jPg-mI7kvTw/s725/DFSInputStream.png)](https://lh3.googleusercontent.com/-BHKBJT4Ed4A/UBJFqsjWjtI/AAAAAAAAAQM/jPg-mI7kvTw/s1450/DFSInputStream.png "看大图可能需要越过某座墙")

<!--more-->

DataChecksum这个类的说明可见[HDFS源码分析（5）：datanode数据块的读与写](http://jeoygin.org/2012/03/hdfs-source-analysis-datanode-block-read-write.html)。

**1\. FSInputChecker**

FSInputChecker是一个通用的输入流，继承FSInputStream，用于在返回数据给用户之前校验数据checksum。关键的属性有如下这些：

* file：读取的数据所在的文件
* buf：数据缓冲区
* checkum：checksum缓冲区
* pos：数据缓冲区的当前位置
* count：数据缓冲区中数据的长度
* chunkPos：输入流的位置

为了做得更通用，有两个与具体的实现细节相关的抽象方法将由子类去实现：

* readChunk： 从文件中读取一个chunk放到数据缓冲区，并把该chunk的checksum放到checksum缓冲区
* getChunkPosition：得到包含位置pos的chunk的起始位置

剩下的比较重要的操作有read、skip和seek。

read操作有两种方式：一种是一次只读取一个字节，只需要从缓冲区中读出一个字节即可，如果缓冲区空了，就从输入流中读取一批数据到缓冲区；一种是一次读取多个字节，并把数据存到用户缓冲区，会重复调用更底层的读取方法来读取尽可能多的数据。

无论是使用哪种方式的read方法，都会调用readChecksumChunk这个方法。readChecksumChunk方法又会进一步调用readChunk来从输入流中读出chunk和checksum，如果需要，可以对checksum进行验证，如果读数据失败，可以尝试另一副本，重新读取数据。

skip操作会从输入流中跳过和忽略指定数量的字节，在实现上调用了seek操作。

如果seek的位置所在的chunk在当前缓冲区内，那么只要修改当前的位置pos即可；否则需要重新计算chunkPos，并跳过从chunk起始位置到指定位置之间的数据。

**2\. BlockReader**

BlockReader继承FSInputChecker，封装了Client和Datanode之间的连接，知道块的checksum、offset等信息。关键的属性有如下这些：

* in：数据输入流
* checksum：
* lastChunkOffset：最后一个读取的chunk的偏移量
* lastChunkLen：最后一个读取的chunk的长度
* lastSeqNo：最后一个packet的编号
* startOffset：欲读取数据在块中的偏移量
* firstChunkOffset：读取的第一个chunk在块中的偏移量
* bytesPerChecksum：chunk的大小
* checksumSize：checksum的大小
* isLastPacket：是否是最后一个packet

BlockReader覆盖了父类的很多方法，但不支持seekToNewSource、seek、getChunkPosition及读取单个字节。

首先，我们来看看如何创建一个新的BlockReader实例，所做的事情其实很简单，只是向datanode请求一个OP_READ_BLOCK操作，如果操作成功，那么创建一个数据输入流并根据返回的数据创建一个DataChecksum实例。

read方法只比FSInputChecker多了一些检查。在读取第一个chunk时，可能需要跳过startOffset之前的一些字节。如果到了块的结尾并且需要验证checksum，要向datanode发送OP_STATUS_CHECKSUM_OK，以确认块未损坏。

skip方法通过读取当前位置到目标位置之间的字节来路过这些数据，而不是调用seek。

好了，只剩下最重要的readChunk方法：

* 如果到达块结尾，将startOffset置为-1，返回-1
* 计算新chunk的偏移量
* 如果前一个包的数据已读取完毕，读取下一个packet的头部及checksum
* 从输入流中读取一个chunk，多缓冲区中读出该chunk的checksum
* 如果当前packet是最后一个并且当前packet的数据已全部读完，将gotEOS置为true，标志着到达块结尾

**3\. DFSInputStream**

经过前面的预热，我们可以正式进入输入流的主题，DFSInputStream从文件中读取数据，在必要时与namenode和不同的datanode协商。关键的属性有如下这些：

* closed：流是否已关闭
* src：文件
* prefetchSize：从namenode预取数据的大小，默认是10个块，可以通过配置项dfs.read.prefetch.size来设置
* blockReader：用于读取块的数据
* verifyChecksum：是否验证数据的checksum
* locatedBlocks：存储块的信息
* currentNode：当前读取数据的datanode
* currentBlock：当前块
* pos：文件偏移量
* blockEnd：当前块末尾在文件中的位置
* failures：失败次数
* deadNodes：已经崩溃的datanode

下面将对重要的方法一一讲解。

getBlockAt方法的功能是获取在特定位置offset的块，首先检查offset所在的块是否在缓存中，如果没有就从namenode取回大小为prefetchSize的数据所在的块，更新pos、blockEnd和currentBlock。

getBlockRange方法的功能是获取从特定位置offset开始，长度为length的数据所在块的列表，如果块本地没有缓存，就从namenode取回这些数据所在的块，并与本地已有的块合并。

blockSeekTo方法的功能是获得包含位置target所在的块的datanode，按以下步骤处理：

* 关闭blockReader
* 关闭与当前datanode的连接
* 计算target所在的块
* 选择包含块的一个datanode，并进行连接，如果连接失败，将datanode加入deadNodes，重试其它的datanode
* 创建新的BlockReader

readBuffer方法的功能是读取数据到用户缓冲区，调用BlockReader来读取数据，如果读取失败会重试。

read(byte buf[], int off, int len)方法是为用户提供的读取数据接口，如果读完一个块，会找开下一个块继续读取，调用readBuffer来读数据到缓冲区。

chooseDataNode方法的功能是为块选择一个datanode，如果没能找到，清空deadNodes，重新从namenode获取块列表。

fetchBlockByteRange方法的功能是读取一个块从start到end之间的数据，调用BlockReader来读取。

read(long position, byte[] buffer, int offset, int length)方法是读取从文件的position位置开始，长度为length的数据。

seek方法是作用是定位到任意的位置，只有当目标位置在当前块中，并且与当前位置的距离不超过TCP窗口大小才调用BlockReader的skip方法，跳过部分字节，否则只修改相应的属性值。

seekToBlockSource和seekToNewSource方法都调用blockSeekTo来定位到目标位置，可以重新选择datanode。

**4\. DFSDataInputStream**

这个类比较简单，只是封装了DFSDataInputStream的几个方法。

## DFSOutputStream ##

DFSOutputStream的主要功能是通过namenode获取块的信息，并将用户写的数据发送到datanode。客户端写的数据将被缓存在流中，数据被分割成一个个packet，每个packet默认大小为64KB。每个packet由trunk组成，每个trunk通常是512B，并且带有相关的checksum。当客户端填满当前的packet，这个packet会被放到dataQueue中排队。DataStreamer线程会从dataQueue中挑选packet，将其发送给一个datanode，并将其从dataQuque转移到ackQueue。ResponseProcessor接收datanode的ack，当接收到所有datanode对一个packet成功的ack，ResponseProcessor从ackQueue中删除相应的packet。在出错时，从ackQueue中删除packet，通过从原来的pipeline删除坏的datanode来建立新的pipeline。

先来看看类图，从总体上把握类之间的关系，由于类比较多，所以略去了不少类，只剩下一些重要的类，因此下面的类图并不完整：

[![看大图可能需要越过某座墙](http://lh4.googleusercontent.com/-9tXdzHDkEJU/UA50DfTEOzI/AAAAAAAAAPY/n3jMjQSkwMU/s680/DFSOutputStream.png)](http://lh4.googleusercontent.com/-9tXdzHDkEJU/UA50DfTEOzI/AAAAAAAAAPY/n3jMjQSkwMU/s1360/DFSOutputStream.png "看大图可能需要越过某座墙")

**1\. Packet**

DFSOutputStream是以packet为单位发送数据，每个packet默认大小为64KB，关键的属性有如下这些：

* buffer：ByteBuffer缓冲区
* buf：byte数组缓冲区，只有一个buffer或buf不为空
* seqno：packet在块中的编号
* offsetInBlock：在块中的偏移量
* lastPacketInBlock：是否是块的最后一个packet
* numChunks：当前块中的chunk数
* maxChunks：packet中最大的chunk数
* dataStart：数据在缓冲区中的开始位置
* dataPos：数据在缓冲区中的写入位置
* checksumStart：checksum在缓冲区中的开始位置
* checksumPos：checksum在缓冲区中的写入位置

Packet有三个方法：

* writeData：将数据写入到缓冲区中
* writeChecksum：将checksum写入到缓冲区中
* getBuffer：将数据从buf拷贝到buffer

**2\. DataStreamer**

DataStreamer负责发送数据包（packet）到pipeline上的datanode，它从namenode取回块的id和位置，并将packet发送给datanode。当所有的packet发送完毕，并收到每个块的ack，DataStreamer关闭当前块。 DataStreamer是一个线程，我们来看看它的处理过程是怎样的：

1. 如果DataStreamer关闭了或客户端没在运行，停止处理过程
2. 如果检查到错误，关闭response
3. 从dataQueue取出一个packet
4. 从namenode得到新的块
5. 将packet放入ackQueue
6. 将数据写入datanode
7. 如果当前packet是块的最后一个，写入整数0，标志着块的结束
8. 如果当前packet是块的最后一个，等待ackQueue的所有packet处理完，然后将response、blockStream和blockReplyStream关闭

**3\. ResponseProcessor**

ResponseProcessor负责处理datanode返回的应答，当一个packet的应答到达时，该packet从ackQueue中删除。关键的属性有如下这些：

* closed：ResponseProcessor是否关闭
* targets：目标datanode，每个packet只有收到targets所表示的所有datanode的ack才算数据发送成功
* lastPacketInBlock：是否是块的最后一个packet

下面来看看ResponseProcessor的处理过程：

1. 如果DataStreamer关闭了、客户端没在运行或已处理了块的最后一个packet，停止处理过程
2. 从pipeline读出ack
3. 处理所有datanode的应答状态

**4\. FSOutputSummer**

这是一个通用的输出流，用于在数据被写入下层输出流之前产生checksum。关键的属性有如下这些：

* sum：数据checksum
* buf：存储数据的内部缓冲区
* checksum：存储checksum的内部缓冲区
* count：数据缓冲区中的合法字节数

下面来看看有什么方法。

有一个抽象方法名为writeChunk，顾名思义，这个方法的功能是将一个数据块及其checksum写入到下层的输出流。

write(int b)方法的功能是写入单个字节。

write(byte b[], int off, int len)方法的功能是写入固定长度的字节，与普通write方法不同的地方是该方法会将所有的字节写入而不是返回已写入的字节数。

write1是内部的写入方法，将用户缓冲区的数据拷贝到内部缓冲区，如果内部缓冲区，将数据刷新到输出流。

flushBuffer方法的功能是将数据及其checksum写入到输出流中。

writeChecksumChunk方法的功能是将数据和checksum写入下层的输出流。

**5\. DFSOutputStream**

这个类才是输出部分的重头戏，涵盖客户端向HDFS写文件的大部分逻辑，封装了与namenode和datanode通信的逻辑，关键的属性有如下这些：

* closed：是否关闭
* src：文件名
* blockStream：连接datanode的块输出流
* blockReplyStream：来自datanode的应答输入流
* block：当前块
* blockSize：块大小
* checksum：校验和
* dataQueue：数据队列，等待发送的所有packet
* ackQueue：应答队列，已发送，等待应答的所有packet
* currentPacket：当前的packet
* maxPackets：最大packet数
* streamer：用于发送packet到datanode
* response：用于处理datanode发送的应答
* currentSeqno：当前packet的编号
* bytesCurBlock：当前块已写入的字节数
* packetSize：packet的大小（包括header）
* chunksPerPacket：每个packet的chunk数
* nodes：存放当前块的所有datanode
* hasError：是否出错
* errorIndex：出错的datanode索引
* lastException：上一个异常
* lastFlushOffset：上次flush的位置
* persistBlocks：是否向namenode持久化块
* recoveryErrorCount：恢复错误的次数
* maxRecoveryErrorCount：最大恢复错误次数
* appendChunk：是否追求数据到部分块
* initialFileSize：文件打开时的大小

下面来看看一些方法。

processDatanodeError方法用于处理datanode的错误，当调用返回后需要休眠一段时间时，返回true。调用这个方法前，需要确保response已关闭。下面是其简单的处理流程：

1. 关闭blockStream和blockReplyStream
2. 将packet从ackQueue移到dataQueue
3. 删除坏datanode
4. 通过RPC调用datanode的recoverBlock方法来恢复块，如果有错，返回true
5. 如果没有可用的datanode，关闭DFSOutputStream和streamer，返回false
6. 创建块输出流，如果不成功，转到3

computePacketChunkSize方法根据packet和chunk的实际大小来计算在HDFS中当前块packet的大小和一个packet中chunk的数量。

nextBlockOutputStream方法打开一个写往datanode的输出流，调用locateFollowingBlock请求下一个块，再调用createBlockOutputStream创建块输出流，如果出错可以重试，重试次数可以由配置参数createBlockOutputStream来设置，默认值是3。

createBlockOutputStream方法会与pipeline中的第一个datanode建立连接，为后继写数据做准备：

* 将persistBlocks设为true，以便在下次flush时在namenode上持久化块
* 与datanode建立socket连接
* 向datanode发送OP_WRITE_BLOCK请求
* 接收ack，检查是否有坏的datanode

locateFollowingBlock方法的主要功能定位下一个块，通过向namenode请求为文件添加新的块来实现，如果出现错误可以重试，重试次数可以由配置参数dfs.client.block.write.locateFollowingBlock.retries来设置，默认值是5。

writeChunk方法的主要功能是将一个chunk的数据和checksum写入到输出流中，处理流程以下：

1. 如果dataQueue和ackQueue的总大小超过maxPackets，一直等待
2. 如果currentPacket为空，创建一个新的packet
3. 将数据和checksum写入当前packet
4. 如果当前packet的chunk数达到最大chunk数或者当前块的大小等于块的大小，将currentPacket放入dataQueue
5. 调用computePacketChunkSize重新计算packetSize和chunksPerPacket的值

sync方法的主要功能是将所有数据写到datanode，并等待收到datanode的ack，如果persistBlocks为true，调用namenode的fsync方法同步文件。

flushInternal方法的主要功能是等待dataQueue的packet都发送完毕，并等待ackQueue中的packet都接收到ack。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。