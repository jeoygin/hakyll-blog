---
title: Linux bonding（网卡绑定）
tags:
  - bonding
  - Linux
  - network
id: 609
categories:
  - 计算机技术
  - 网络
date: 2012-03-08 19:55:18
---

## 介绍 ##

Linux网卡绑定的实现就是使用多块网卡虚拟成为一块网卡，这个虚拟网卡看起来是一个单独的以太网接口设备，通俗点讲就是多块网卡具有相同的IP地址而并行链接聚合成一个逻辑链路工作。这项技术在Sun和Cisco被称为Trunking和Etherchannel技术，在 Linux的2.4.x的内核中也采用这这种技术，被称为bonding。bonding技术的最早应用是在集群——beowulf上，为了提高集群节点间的数据传输而设计的。什么是bonding需要从网卡的混杂(promisc)模式说起，在正常情况下，网卡只接收目的硬件地址(MAC地址)是自身Mac地址的以太网帧，对于别的数据帧都滤掉，以减轻驱动程序的负担。但是网卡也支持另外一种被称为混杂promisc的模式，可以接收网络上所有的帧，比如说tcpdump，就是运行在这个模式下。bonding也运行在这个模式下，将接收到的数据帧传送给bond驱动程序处理。

## 配置 ##

网卡绑定的配置见[网络链路聚合测试](http://jeoygin.org/2012/03/03/link-aggregation-test/)。
<!--more-->
## 加载bonding模块 ##

加载bonding模块有两种做法：

**1\. 在模块配置文件/etc/modprobe.conf中添加以下内容：**

```
alias bond0 bonding
options bond0 miimon=100 mode=0
```

**2\. 在终端输入以下命令：**

	modprobe bonding miimon=100 mode=0

其中mode表示bonding的策略：

* 0是Round-robin策略：实现负载均衡，按顺序选择可用的设备进行传输，绑定的所有网卡都在工作，如果有一网卡出问题了，不影响网络传输；
* 1是Active-backup策略：主备工作方式，默认情况下只有一张网卡在工作，另一张网卡用于备份，实现高可用性；
* 2是XOR策略：根据公式（(src mac addr XOR dst mac addr) % slave cnt）计算出用于传输的slave，对于每个目的MAC地址，会选择相同的slave，提供负载均衡和容错；
* 3是Broadcast策略：任意数据会通过所有slave发送出去，提供容错；
* 4是802.3ad：IEEE 802.3ad Dynamic link aggregation，LCAP协议，要求交换机支持802.3ad动态链路汇聚；
* 5是Adaptive transmit load balancing策略：实现自适应发送负载均衡，不要求任何特殊的交换机支持，外出的流量会根据当前负载分担到每个slave上，进入的流量由当前的slave接收，如果当前slave出故障，另一slave接管该slave的MAC地址；
* 6是Adaptive load balancing策略：实现自适应负载均衡，包括发送负载均衡和接收负载均衡，不要求任何特殊的交换机支持，接收负载均衡由ARP协商达成，bonding驱动截获本地系统发出的ARP答复并用某一slave的MAC地址重写ARP答复的MAC地址，从而每一slave可以有不同的MAC地址。

最常用的是前4种策略。

当mode=0, 2, 3, 4时，被绑定的网卡的MAC地址一样，需要在交换机配置链路聚合，否则可能会造成MAC地址表的动荡。

当mode=1, 5, 6时，网卡使用各自的MAC地址，因此不需要在交换机做任何配置。

## bond管理 ##

**将eth0作为bond0的slave：**

	ifenslave bond0 eth0

**将eth0从bond0分离：**

	ifenslave -d bond0 eth0

## 参考资料 ##

1. [双网卡绑定与端口聚合](http://eryk.iteye.com/blog/1178067)
2. [Bonding (Port Trunking)](http://www.linuxhorizon.ro/bonding.html)

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。