---
title: Past Projects
comments: false
date: 2014-11-05 14:43:14
---

## ICTBase：大规模实时数据分析系统

2011.11-2013.06

ICTBase是一款适用于大规模结构化数据高速存储和在线分析的新型数据平台。适用于以下场合：

- 大规模：单表记录大于1亿条；
- 高通量：大量的流式数据要高速的写入到系统中；
- 在线分析：实时获得查询结果同时能够满足大量用户并发查询。

Hbase是Hadoop开源项目的一个子项目，是NoSQL数据库的一种，是历史上继Linux之后最成功的开源软件之一。

ICTBase在HBase的基础上，进行了大量的改进和性能优化，加入了多索引列、服务端计算、性能隔离、系统管理、访问控制等一些技术使其能够更加高效实用。

ICTBase与HBase的关系如同RedHat Linux和Linux的关系一样，前者是后者的一个商业版本。

相比同类产品，ICTBase具有五大技术优势：

- 典型的NoSQL数据库：具有通常NoSQL数据库的海量存储、高并发读写、低成本使用等优点。
- 独有的多索引列技术：多索引列可以解决诸如HBase等当前主流的列簇式NoSQL数据库系统在多列查询上的功能缺失和性能低下的问题。解决了原有HBase只能有一个索引列的问题，增加了多索引列的支持，任何列都可以作为索引列，大大提升了系统的查询速度。
- 独有的服务端计算技术：利用数据服务器的计算能力，将查询结果的计算直接放到数据服务器上进行。一方面避免了把大量数据发送到客户端，只需把计算结果返回即可；另一方面又充分利用了数据服务器的计算能力，提升了运算效率，提高了硬件资源的利用率。
- 独有的性能隔离技术：通过在一个集群内将数据服务器和数据库表动态划分为不同的组，同时支持对数据服务器和数据库表进行性能的平衡。从而保证不同组可以获得相应的性能保证，使得系统能够以一个集群支持多个不同的应用，并且应用之间不会相互影响性能。
- 独有的硬件压缩技术：通过专用的硬件压缩卡实现对数据的透明压缩/解压缩。

* * *

## “凌云”云计算系统

2010.03-2011.11

LingCloud（凌云云计算系统）是中国科学院计算技术研究所研发的一套云计算系统软件，以Apache License 2.0授权开源发布。LingCloud提供一套同时支持物理机和虚拟机管理与租赁的云计算基础设施管理系统，支持在共享设施上接入高性能计算、大规模数据处理、海量存储等多种应用模式。LingCloud可用于构建组织内的私有云，以管理其基础设施。

LingCloud系统基于Xen虚拟化平台，使用OpenNebula管理虚拟机群。被OpenNebula认定为Cloud Solution Provider。

LingCloud的主要组件包括：

- Molva — LingCloud系统核心，一套弹性计算基础设施管理软件，提供异构资源管理与租赁框架，并作为面向基础设施与应用资源的单一控制点。
- Portal — 基于web的系统管理界面，其模块包括：基础设施（基于分区与机群技术的物理机与虚拟机管理）、应用封装（虚拟电器创建与管理）和系统监控（机群运行时信息监控）。 

已发表论文：Xiaoyi Lu, Jian Lin, Li Zha, Zhiwei Xu. Vega LingCloud: A Resource Single Leasing Point System to Support Heterogeneous Application Modes on Shared Infrastructure, ISPA 2011. Busan, Korea. May 2011.

 ![LingCloud](http://img.jeoygin.org/lingcloud.jpg)

LingCloud is a suite of open-source cloud computing system software developed by Institute of Computing Technology, Chinese Academy of Sciences. It is licensed under Apache License 2.0. LingCloud provides a resource single leasing point system for consolidated leasing physical and virtual machines, and supports various heterogeneous application modes including high performance computing, large scale data processing, massive data storage, etc. on shared infrastructure. LingCloud can help an organization to build private cloud to manage the computing infrastructure.

LingCloud is based on Xen virtualization platform and uses OpenNebula to manage the virtual infrastructure. It is accepted as an OpenNebula Cloud Solution Provider.

The main components of LingCloud release include:

- Molva — The core of LingCloud. It is an elastic computing infrastructure management software providing a heterogeneous resource management and leasing framework, and a single controlling point of both of the infrastructure and applications.
- Portal — System management interface via web. Current modules include: Infrastructure management (physical and virtual machines management by partitions and clusters), Application encapsulation (virtual appliance creation and management) and System monitor (clusters run-time information monitor).

Publication: Xiaoyi Lu, Jian Lin, Li Zha, Zhiwei Xu (May 2011). "Vega LingCloud: A Resource Single Leasing Point System to Support Heterogeneous Application Modes on Shared Infrastructure". ISPA 2011. Busan, Korea.

* * *

## 基于JAZZ的智能博弈对战平台

2009.11-2010.03

当今社会，信息技术的广泛普及使得网民的数量每日剧增，人们对娱乐产业的需求也日益增长，尤其对网络中棋类博弈的追捧热度更为高涨，因此，博弈队战平台已经成为娱乐业不可或缺的一部分，同时，在信息技术的大力推动下，构建这样的平台系统已经变得可行。

基于这样一种现实，我们团队选择博弈为切入点，利用JAZZ提供的平台，根据在日常生活中所需要的竞技活动，开发一套智能博弈系统。

该系统在设计开发过程中需要严格遵照软件工程相关规范进行，并且采用敏捷软件开发模式，在开发过程中强调开发人员之间的大量沟通以及对于需求变更的及时响应等思想，充分发挥Jazz平台协作开发的作用。

该系统提供一个基于Eclipse插件的博弈对战平台，整个系统建立在JAZZ平台的基础之上，能够通过远程连接的方式进行访问，从而实现博弈棋类的对战以及代码或程序的管理。

该系统旨在通过信息化的手段，让更多的人快速、便捷的了解博弈并对此产生兴趣，同时用户可根据爱好搭建自己的博弈程序，从而与他人进行对战。实现了共同游戏、共同学习、共同进步的目标。

基于JAZZ 的智能博弈对战平台在总体功能主要分为两大模块：对战模块以及代码项目管理模块。

当用户（如果是新用户可进行注册）远程登录平台后，可进行相应的操作，根据两大模块的划分，操作包括进行人机对战、机机对战，代码/程序的上传（远程存储）、下载、删除以及评论等。

该项目参加2009年IBM JAZZ创新大赛，获得二等奖。

* * *

## “中国深度”六子棋引擎

2008.06-2009.10

该引擎主要用于六子棋博弈，其主要模块包括招法生成、搜索、局面评估、开局库和VCF（Victory of Continuous Four）等，每个模块均有独到之处。“中国深度”以犀利的进攻及沉稳的防守在各赛事上赢得多项殊荣。

2008年10月，“中国深度”首次参加国际赛事就崭露头脚，以优异的表现在第十三届国际计算机博弈锦标赛中夺得六子棋项目亚军。

2009年，在西班牙潘普洛纳市举办的第十四届国际计算机博弈锦标赛，“中国深度”一举夺得六子棋项目冠军。

 ![竞赛队与“六子棋之父”，NCTU6总负责人台湾交通大学吴毅成教授合影](http://img.jeoygin.org/connect6.jpg)

竞赛队与“六子棋之父”，NCTU6总负责人台湾交通大学吴毅成教授合影

* * *

## XShiled Web服务器防护系统

2008.04-2008.09

XShield Web服务防护系统是一款小巧、安全、功能强大的Web服务器防护软件，可对服务器进行实时保护。系统的设计理念是将蜜罐技术与终端防护技术结合,突破目前蜜罐技术应用范围较窄，防御上变被动为主动。

系统具有虚拟服务、蜂蜜信标、Web目录监控、Web防护服务、防火墙五大功能，前两个功能是蜜罐思想的产物，后三个功能则为有效、实用的终端防护功能。系统能够有效识别攻击者的行为，包括恶意扫描服务器、猜解用户名密码、上传木马、扫描网站后台地址、SQL注入、使用蜂蜜信标等，并能对攻击者进行处理，使攻击者难以对服务器进行入侵。

系统具有以下三大特色：

- 设计理念突破了目前蜜罐技术应用范围较窄，将蜜罐技术和终端防护很好的结合在一起。蜜罐应用于防护，防护基于蜜罐，是一个理论上和技术上的创新；
- 设计过程中融入了传统的防火墙理念，克服了蜜罐技术的某些局限性；防火墙工作在驱动级别，有力的对整个操作系统进行防护，确保了整个系统的安全；
- 具有高性能反馈机制能和防护机制，及时对收集到的有效信息进行分析反馈，能在第一时间阻止可疑行为，将恶意攻击扼杀在试探阶段而不是实际入侵阶段，变被动为主动，真正的实现了“主动防御”！

该系统参加2008年全国大学生信息安全竞赛，获得二等奖。

![获奖后留念](http://img.jeoygin.org/security.jpg)

* * *

