---
title: 网络链路聚合测试
tags:
  - link aggregation
  - Linux
  - network
  - 链路聚合
id: 586
categories:
  - 计算机技术
  - 网络
date: 2012-03-03 20:58:32
---

最近在对系统调优，首先要找系统的瓶颈，CPU、Memory、IO都有可能，IO还分磁盘IO和网络IO。在网络IO方面，由于使用链路聚合，每条物理链路带宽是1Gbps，4条物理链路即是4Gbps，带宽肯定是没问题，但在实际测试中网络速率不是很高，那就先从网络IO抓起。本文主要对以太网中的网络传输进行测试及分析。

## 测试环境 ##

交换机：H3C 1000Mbps交换机，带宽为192Gbps，支持链路聚合

服务器网卡：1000Mbps网卡4块

服务器操作系统：CentOS 5.6

服务器内核：2.6.18

## 链路聚合 ##

可能很多人对“链路聚合”比较陌生，顾名思义，“链路聚合”就是把多条物理链路合成一条逻辑链路，该逻辑链路的带宽为多条物理链路的带宽之和，这一点听起来很吸引人，但在实际应用中，却不容易达到最大带宽。物理链路的使用率取决于逻辑链路两端设备的负载均衡策略。

逻辑链路两端可以是路由器、交换机或服务器等支持链路聚合的设备，交换机按照使用说明书对端口进行链路聚合即可，服务器对多个网卡进行绑定步骤稍微多点。

<!--more-->

## 多网卡绑定 ##

假定要对eth0和eth1两块网卡进行绑定，步骤如下：

**1\. 修改网卡配置文件**

vi /etc/sysconfig/network-scripts/ifcfg-eth0

```
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
TYPE=Ethernet
MASTER=bond0
SLAVE=yes
```

vi /etc/sysconfig/network-scripts/ifcfg-eth1

```
DEVICE=eth1
BOOTPROTO=none
ONBOOT=yes
TYPE=Ethernet
MASTER=bond0
SLAVE=yes
```

vi /etc/sysconfig/network-scripts/ifcfg-bond0

```
DEVICE=bond0
BOOTPROTO=none
BROADCAST=10.0.0.255
IPADDR=10.0.0.1
NETMASK=255.255.255.0
NETWORK=10.0.0.0
ONBOOT=yes
GATEWAY=10.0.0.254
TYPE=Ethernet
```

**2\. 在模块配置文件/etc/modprobe.conf中添加以下内容**

```
alias bond0 bonding
options bond0 miimon=100 mode=0
```

mode表示bonding的策略：

* 0是Round-robin策略：实现负载均衡，按顺序选择可用的设备进行传输，绑定的所有网卡都在工作，如果有一网卡出问题了，不影响网络传输；
* 1是Active-backup策略：主备工作方式，默认情况下只有一张网卡在工作，另一张网卡用于备份，实现高可用性；
* 2是XOR策略：根据公式（(src mac addr XOR dst mac addr) % slave cnt）计算出用于传输的slave，对于每个目的MAC地址，会选择相同的slave，提供负载均衡和容错；
* 3是Broadcast策略：任意数据会通过所有slave发送出去，提供容错；
* 4是802.3ad：IEEE 802.3ad Dynamic link aggregation，LCAP协议，要求交换机支持802.3ad动态链路汇聚；
* 5是Adaptive transmit load balancing策略：实现自适应发送负载均衡，不要求任何特殊的交换机支持，外出的流量会根据当前负载分担到每个slave上，进入的流量由当前的slave接收，如果当前slave出故障，另一slave接管该slave的MAC地址；
* 6是Adaptive load balancing策略：实现自适应负载均衡，包括发送负载均衡和接收负载均衡，不要求任何特殊的交换机支持，接收负载均衡由ARP协商达成，bonding驱动截获本地系统发出的ARP答复并用某一slave的MAC地址重写ARP答复的MAC地址，从而每一slave可以有不同的MAC地址。

**3\. 在启动文件/etc/rc.d/rc.local中添加以下内容**

	ifenslave bond0 eth0 eth1

**4\. 重启网络服务**

	/etc/init.d/network restart

## 工具安装 ##

网络带宽测试使用netperf，安装见：[CentOS安装netperf](http://blog.jeoygin.org/archives/572)

网络流量分析使用ntop，安装见：[CentOS安装ntop](http://blog.jeoygin.org/archives/569)

网络流量监控使用iftop，安装见：[CentOS安装iftop](http://blog.jeoygin.org/archives/583)

## 测试 ##

**单连接：**

该测试主要测试两个节点间单个TCP连接的吞吐量，在节点A启动netperf服务端，在节点B启动netperf客户端，测试时间为60秒，在两个节点使用iftop查看网络流量的情况。

测试结果：吞吐量为110 MB/s左右，并没有预想中的400MB/s。

结果分析：节点A主要是接收数据，通过iftop可以看到数据是在4块网卡中的1块传输，而其它3块处于闲置状态，那么总的带宽就是一块网卡的带宽；节点B主要是发送数据，通过iftop可以看到4块网卡都在发送数据，每块网卡的传输速率都差不多。

**多连接：**

该测试主要测试两个节点间多个TCP连接的吞吐量，在节点A启动netperf服务端，在节点B启动4个netperf客户端，测试时间为60秒，在两个节点使用iftop查看网络流量的情况。

测试结果：吞吐量为110 MB/s左右。

结果分析：节点A主要是接收数据，虽然有4条TCP连接，但通过iftop可以看到依旧只有1块网卡在接收数据，经过查阅相关资料，得知交换机的链路聚会的负载分担策略是根据MAC地址；节点B主要是发送数据，通过iftop可以看到4块网卡都在发送数据，每块网卡的传输速率都差不多。

**单点到多点：**

该测试主要测试从单个节点发送数据到多个节点的吞吐量，在4个节点启动netperf服务端，在节点A启动8个netperf客户端，分别往其它4个节点发送数据，每个节点使用两个netperf客户端，测试时间为60秒，在节点A使用iftop查看网络流量的情况。

测试结果：吞吐量为440 MB/s左右。

结果分析：节点A主要是发送数据，通过iftop可以看到4块网卡都在发送数据，每块网卡的传输速率都差不多，基本到达每块网卡带宽上限。

结论：从单个节点往多个节点发送数据时，总吞吐量与接收数据的节点数量相关，当节点数量大于3时能接近逻辑链路带宽的上限。

**多点到单点**

该测试主要测试从多个节点发送数据到单个节点的吞吐量，在节点A启动netperf服务端，在其它4个节点启动netperf客户端，每个节点启动2个，同时往节点A发送数据，测试时间为60秒，在节点A使用iftop查看网络流量的情况。

测试结果：吞吐量与节点的MAC地址有关，吞吐量440 MB/s左右。

结果分析：节点A主要是接收数据，通过iftop可以正在接收数据网卡的数量是不定的，跟发送数据的节点相关，使用不同的节点进行测试，结果可能会不一样，最好的情况是每块网卡分别接收一个节点的数据，吞吐量能接近逻辑链路带宽的上限。

结论：当多个节点向单个节点发送数据时，数据报文在经过交换机时，只有能经过逻辑链路中的所有物理链路时，才能充分利用网络带宽，否则就有会闲置的物理链路。

## 几个假想结论 ##

* 操作系统采用round-robin方式做网卡绑定，发出的包将轮流从多块网卡发送出去，将负载均衡分到多块网卡上。
* 交换机将多个端口进行链路聚合后，报文根据MAC地址进行聚合负载分担，即根据MAC地址将报文送到某一端口。为什么不采用round-robin呢？
* 基于以上结论可以得出以下结论：两个节点间的网络带宽是单条链路的带宽。
* 链路聚会在并发数比较大时，可以均衡负载，提高总的吞吐量，却不能在并发数较少时显著提高吞吐量，这点跟分布式系统有点想像，考虑的是规模扩展问题。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。