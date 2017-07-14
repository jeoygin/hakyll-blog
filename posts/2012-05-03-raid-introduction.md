---
title: Raid原理解剖
tags:
  - Availability
  - Parity
  - RAID
  - Reliability
  - storage
  - Striping
id: 836
categories:
  - 计算机技术
  - 分布式系统
date: 2012-05-03 19:20:51
---

## 概述 ##

最近在看Erasure Code，多篇论文中总是提到RAID，以前倒是知道RAID是用于做啥的，却没有深刻地认识，本文将去深入地了解RAID的原理。

RAID是一种将多个磁盘合成一个逻辑单元的存储技术，数据可以通过多种不同的方式分布在磁盘上，这些方式称为“RAID levels”，具体采用哪个level取决于需要的冗余级别和性能。

最初，RAID的提出是为了满足磁盘IO性能提升与CPU、内存性能提升相匹配，才能充分利用CPU、内存，避免资源浪费。

RAID是存储虚拟化的一个例子，最初由David Patterson等人在1987年定义为“Redundant Arrays of Inexpensive Disks”，直译过来就是廉价硬盘冗余阵列。后来，工业界试图重新定义该术语，将其描述为“a redundant array of independent disks”，即独立磁盘的冗余阵列，将低成本从RAID技术中分离，商人追求利益最大化，这也是情有可原的。

现在，RAID是能在多块物理磁盘之间分割和复制数据的计算机数据存储方案的总称，这些物理磁盘被称为一个RAID阵列，操作系统将其视为一个单一磁盘。目前有多种不同的方案（比如RAID 0、RAID 1、RAID 2等），每种方案在数据可靠性和读写性能做出不同的权衡。


<!--more-->


## 数据分割 ##

在计算机数据存储领域，数据分割（data striping）是将逻辑上连续的数据进行分片的技术，对连续数据片断的访问可能会被分发给不同的物理存储设备。如果数据的访问速率快于一个存储设备所提供的最大速率，数据分割将非常有用，因为数据片断存储在多个设备上，那么能够并发地访问多个数据片断，这将提供更多的数据访问吞吐量，减少CPU等待数据访问的时间。在RAID存储中，数据分割可用于聚合多个磁盘驱动器。

一种数据分割的方法是采用round-robin方式将连续的数据片断交错地放到存储设备上，对于流式数据，这种方式能很好地工作，但如果是连续随机访问将要求知道哪个设备包含特定的数据。其它的方法，连续的数据片断可能不存在连接的设备上。

优点：能够提升性能和吞吐量。

不足：数据的不同片断被存在不同的存储设备上，一个设备的故障将导致整个数据序列的损坏，实际上，存储设备阵列的故障率等于每个存储设备故障率之和。数据分割的这个不足能通过用于纠错的冗余信息来克服，比如使用奇偶校验信息（parity）。

## 可靠性与可用性 ##

将阵列分成多个组，每个组有额外的包含冗余信息的校验磁盘，当一个磁盘出故障了，我们假设在一个很短的时间内，出故障的磁盘能被替换并且磁盘上的信息能在新磁盘上利用冗余信息重建，我们假设每个磁盘的故障率服从指数分布并且是相互独立的。

我们可以使用以下指标来衡量RAID系统的可靠性与可用性：

* **Mean Time To Repair(MTTR)**：平均修复时间，从出故障到恢复使用这段时间。MTTR主要包括两方面：替换故障磁盘的时间及重修故障磁盘内容的时间。
* **Mean Time To Failure(MTTF)**：平均无故障时间，磁盘正常使用多长时间才出现一次故障。
* 一个有n个相同组件的系统的平均无故障时间为**MTTF/n**。
* 单个磁盘的故障率**λ=1/MTTF**。
* 一个有n个相同组件的系统的故障率为**λ/n**。
* 可靠性（reliability）：**MTTF+MTTR**
* 可用性（availability）：**MTTF/(MTTF+MTTR)*100%**

先来看看后面会使用的符号：

* **D**：所有数据磁盘的数量（不包括校验磁盘）
* **G**：每个group中数据磁盘的数量（不包括校验磁盘）
* **C**：每个group中校验磁盘的数量
* **n<sub>G</sub>**：group的数量（D/G）
* **F<sub>G</sub>**：一个磁盘组的故障率
* **MTTF<sub>D</sub>**：单个磁盘的平均无故障时间
* **MTTF<sub>G</sub>**：一个磁盘组的平均无故障时间
* **MTTF<sub>R</sub>**：Raid系统的平均无故障时间
* **F<sub>1</sub>**：在一个磁盘组中，单个磁盘出故障的频率
* **P<sub>2</sub>**：在磁盘组出现单个磁盘故障并且在未完成修复时出现第二个故障的概率

先来看看同组磁盘中，一个故障的修复过程中出现第二个故障的概率，因为磁盘故障率是指数分布的，因此在MTTR这段时间内，出故障的磁盘个数X服从指数分布，积累分布函数F(x) = P(X&lt;=x) = 1-e<sup>-λx</sup>，其中λ = MTTR/MTTF<sub>D</sub>，于是有

P<sub>2</sub> = P(MTTR这段时间内剩下的磁盘至少有一个出故障) = F(G+C-1) = 1 - (e<sup>-MTTR/MTTF<sub>D</sub>*(G+C-1)</sup>)

在实际的情况中，MTTR &lt;&lt; MTTF<sub>D</sub>/(G+C)，并且当0&lt;X&lt;&lt;1时，(1-e<sup>-X</sup>)近似于X，所以有：

P<sub>2</sub> ≈ MTTR*(G+C-1)/MTTF<sub>D</sub>

我们将出现磁盘故障看作是一次抛硬币的过程：正面朝上表示系统崩溃，因为在一次故障修复之前出现了另一个故障；反面朝上表示修复故障并继续运行系统。那么，可以把磁盘组的故障率看成是在第n次伯努利试验才得到第一次成功的概率，P(正面）是成功的概率，表示第一次成功的试验次数的随机变量X服从几何分布，E[X] = 1/P(正面)。

那么一个磁盘组的平均无故障时间：

MTTF<sub>G</sub> = Expected[故障间隔时间] * Expected[第一次正面朝上前抛硬币次数] 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;= Expected[故障间隔时间]*1/P(正面) 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;= MTTF<sub>D</sub>/(G+C)*1/P<sub>2</sub> 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;≈ MTTF<sub>D</sub>/((G+C)*MTTR*(G+C-1)/MTTF<sub>D</sub>) 

MTTF<sub>G</sub> ≈ MTTF<sub>D</sub><sup>2</sup>/((G+C)*(G+C-1)*MTTR)

在"Lec-23:PracticalReliability:RAID."中，有另外一种求MTTF<sub>G</sub>的方法，其实过程是差不多的，只是从不同的角度来求解问题。

F<sub>1</sub> = (G+C)*1/MTTF<sub>D</sub>

F<sub>G</sub> = F<sub>1</sub> * P<sub>2</sub>

MTTF<sub>G</sub> = 1/F<sub>G</sub> ≈ MTTF<sub>D</sub><sup>2</sup>/((G+C)*(G+C-1)*MTTR)

因此，Raid系统的平均无故障时间：

MTTF<sub>R</sub> = MTTF<sub>G</sub>/n<sub>G</sub> 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;≈ MTTF<sub>D</sub><sup>2</sup>/((G+C)*n<sub>G</sub>*(G+C-1)*MTTR)  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;≈ MTTF<sub>D</sub><sup>2</sup>/((D+C*n<sub>G</sub>)*(G+C-1)*MTTR)

## 预设参数 ##

* D = 100
* MTTR = 1 hr
* MTTF<sub>D</sub> = 30,000 hr

## RAID 0 ##

RAID 0是一种将多个磁盘当成一个逻辑磁盘来使用的方法，能有效利用多个磁盘的读写带宽，使得顺序读写比单个磁盘要更加高效，能有效提高性能，但不能容错是其一大诟病，因为当磁盘组中的一个磁盘出故障了，整个磁盘组也就不可再使用，而且故障硬盘上的数据也无法重建（除非磁盘本身是可以修复的）。

RAID系统的相关参数如下：

* G = 100
* C = 0
* n<sub>G</sub> = 1

MTTF<sub>R</sub> = MTTF<sub>D</sub>/G = 300 hr

## RAID 1: Mirrored Disks ##

这是一种传统的用来增强可靠性的方法，也是最昂贵的选择，每个磁盘组有两个磁盘，一个数据盘，一个镜像盘，即做RAID 1至少需要两块磁盘。写数据时将同样的数据往两个盘上写，但读数据时只从一个盘上读。

RAID系统的相关参数如下：

* G = 1
* C = 1
* n<sub>G</sub> = 100

MTTF<sub>R</sub> ≈ MTTF<sub>D</sub><sup>2</sup>/((D+C*n<sub>G</sub>)*(G+C-1)*MTTR) ≈ 4,500,000 hr

## RAID 2: Hamming Code ##

与RAID 1相比，通过减少校验磁盘的数量来减少成本。做RAID 2至少需要3块磁盘。

同组内的所有数据位同时读或写，对性能没有影响。如果读的数据小于一个组的大小，需要读取整个组的数据以确保信息是正确的。写数据时，每个数据磁盘写入一位，并且生成用于纠错的Hamming Codes写入到校验磁盘，主要有三个步骤：读-改-写

1. 读取剩余的所有数据
2. 合并新老数据，重新计算奇偶校验信息
3. 将整个组（包括奇偶校验信息）写入磁盘

Hamming Code对于校验磁盘有如下限制：

G+C+1 &lt;= 2<sup>C</sup>

假定磁盘组中有10个数据盘，RAID系统的相关参数如下：

* G = 10
* C = 4
* n<sub>G</sub> = 10

MTTF<sub>R</sub> ≈ MTTF<sub>D</sub><sup>2</sup>/((D+C*n<sub>G</sub>)*(G+C-1)*MTTR) ≈ 494,500 hr ≈ 56 yr

## RAID 3-5 ##

* 至少需要3块磁盘
* 磁盘将数据存储在512字节的扇区中
* 由磁盘控制器检测故障磁盘
* 数据传输单元超过一个扇区

## RAID 3: Single Check Disk Per Group  ##

在RAID 2中，大部分的校验磁盘被用来确定哪个磁盘出故障，只有一个校验磁盘用来检测错误，这些额外的磁盘是真正多余的，因为磁盘控制器能检测磁盘故障。相比RAID 2，RAID 3只需要一个校验磁盘，传输单元的各个位交错分布在多个磁盘上，一个奇偶校验位由一个磁盘组内的G个数据磁盘计算出来，检验位存储在检验磁盘上。

如果校验磁盘出故障，读取数据磁盘上的数据并重新生成奇偶校验位。如果数据磁盘出故障，使用如下的重建算法：

1. 对数据磁盘和校验磁盘上的数据位做异或运算（XOR）
2. 如果结果是1，那么丢失的数据是1；如果结果是0，那么丢失的数据是0

假定磁盘组中有10个数据盘，RAID系统的相关参数如下：

* G = 10
* C = 1
* n<sub>G</sub> = 10

MTTF<sub>R</sub> ≈ MTTF<sub>D</sub><sup>2</sup>/((D+C*n<sub>G</sub>)*(G+C-1)*MTTR) ≈ 820,000 hr ≈ 93 yr

## RAID 4: Independent  Reads/Writes  ##

RAID 2和RAID 3都有一个共同的不足：向一个磁盘组内的一个磁盘读/写数据需要读/写整个组的所有磁盘，在同一时刻，每个组只能执行一次I/O操作。RAID 4旨在通过并行化来增强小数据传输的性能：同一时刻，每个组能执行多次I/O操作；不再将数据分散在多个磁盘上，而是将每个单独的单元放在一个磁盘上。

按位交错的好处是容易计算用于检测和纠错的Hamming Code。如果我们将独立的传输单元存储在一个扇区，我们就能在不访问其它磁盘的情况下检测单次读取的错误。

RAID4以扇区为粒度将数据交错分布在多个磁盘，使用一个校验磁盘。对于小数据访问，只需要访问两个磁盘：数据磁盘和校验磁盘。新的校验信息可以通过老的校验信息、老数据和新数据计算出来：parity<sub>new</sub> = data<sub>old</sub> XOR data<sub>new</sub> XOR parity<sub>old</sub>。那么完成小数据的写需要以下三步：

1. 从将要写入的数据磁盘读出老数据
2. 从校验磁盘读出老的校验信息
3. 计算新的校验信息：data<sub>old</sub> XOR data<sub>new</sub> XOR parity<sub>old</sub>

这样，RAID 4简化了写小数据的read-modify-write流程，能并行地处理多个读操作。当然，不足也是挺明显的：所有的读和写必须访问校验磁盘，校验磁盘成了瓶颈。

## RAID 5: No Single Check Disk  ##

RAID 5为了克服RAID4校验磁盘瓶颈的问题，将数据和校验信息分布在所有的磁盘上，没有专用的校验磁盘，支持同组内的多个独立写操作。

## RAID 6 ##

与RAID 5的最大不同是：有两个独立的奇偶校验信息块，两个独立的奇偶系统使用不同的算法，允许两个磁盘同时出现故障。做RAID 6至少需要4块磁盘。

## 例子 ##

假设我们现在要写入4个传输单元：A、B、C和D，每个传输单元有4个字节，RAID2、RAID3和RAID4的数据以及校验信息在磁盘上的存放如下图所示：

![](http://lh3.googleusercontent.com/-ocYngvD-5MM/T6JJVV0bFBI/AAAAAAAAAOQ/PQXLPJdypak/s809/raid2-4.png)

假设写入6个扇区的数据，RAID4和RAID5的数据以及校验信息在磁盘上的存放如下图所示：

![](http://lh6.googleusercontent.com/-3lNSLprFcEI/T6JJVhaZWYI/AAAAAAAAAOY/R5vrwvdIlqo/s1191/raid4-5.png)

## 参考资料 ##

1. [wikipedia RAID](http://en.wikipedia.org/wiki/RAID)
2. [wikipedia Data_striping](http://en.wikipedia.org/wiki/Data_striping)
3. Patterson, David A., Garth Gibson, and Randy H. Katz. “A case for redundant arrays of inexpensive disks (RAID).” SIGMOD Rec. 17.3 (1988): 109–116.
4. MarkAagaard. "Lec-23:PracticalReliability:RAID." University of Waterloo. ECE 427: Digital Systems Engineering. 2001-Fall.
5. Shahram Ghandeharizadeh. "Lecture 3:  A Case for RAID (Part 1)". University of Southern California. CSCI 585: Database Systems. 2009-Spring. 
6. Shahram Ghandeharizadeh. "Lecture 4:  A Case for RAID (Part 2)". University of Southern California. CSCI 585: Database Systems. 2009-Spring. 

## 后记 ##

许久没碰数学，看几篇论文很是吃力，花了不少时间才搞懂各种作者认为显而易见的公式，理论功底还是要不断巩固加强。

文中若有错误或疏漏之处，烦请批评指正。