---
title: 《Linux设备驱动程序》第十七章 网络驱动程序读书笔记
tags:
  - Driver
  - Linux
  - network
  - Reading Note
id: 977
categories:
  - 学习笔记
date: 2012-07-05 18:56:46
---

* 简介
    * 网络接口是第三类标准Linux设备，本章将描述网络接口是如何与内核其余的部分交互的
    * 网络接口必须使用特定的内核数据结构注册自身，以备与外界进行数据线包交换时调用
    * 对网络接口的常用文件操作是没有意义的，因此在它们身上无法体现Unix的“一切都是文件”的思想
    * 网络驱动程序异步自外部世界的数据包
    * 网络设备向内核请求把外部获得的数据包发送给内核
    * Linux内核中的网络子系统被设计成完全与协议无关
    * 在网络世界中使用术语“octet”指一组8个的数据位，它是能为网络设备和协议所能理解的最小单位
    * 协议头（header）是在数据包中的一系列字节，它将通过网络子系统的不同层
* 连接到内核
    * loopback.c、plip.c和e100.c
    * 设备注册
        * 驱动程序对每个新检测到的接口，向全局的网络设备链表中插入一个数据结构
        * &lt;linux/netdevice.h&gt;
        * struct net_device
        * struct net_device *alloc_netdev(int sizeof_priv, const char *name, void (*setup) (struct net_device *));
            * name是接口的名字，这个名字可以使用类似printf中%d的格式，内核将用下一个可用的接口号替代%d
        * &lt;linux/etherdevie.h&gt;
            * struct net_device *alloc_etherdev(int sizeof_priv);
        * 光纤通道设备使用alloc_fcdev（&lt;linux/fcdevice.h&gt;）
        * FDDI设备使用alloc_fddidev（&lt;linux/fddidevice.h&gt;）
        * 令牌环设备使用alloc_trdev（&lt;linux/trdevice.h&gt;）
        * register_netdev函数
    * 初始化每个设备
        * example
            * ether_setup(dev);
            * dev-&gt;open = open_function;
            * dev-&gt;stop = release_function;
            * dev-&gt;set_config = config_function;
            * dev-&gt;hard_start_xmid = tx_function;
            * dev-&gt;do_ioctl = ioctl_function;
            * dev-&gt;get_stats = stats_function;
            * dev-&gt;rebuild_header = rebuild_header_function;
            * dev-&gt;hard_header = header_function;
            * dev-&gt;tx_timeout = tx_timeout_function;
            * dev-&gt;watchdog_timo = timeout;
            * dev-&gt;flags |= IFF_NOARP;
            * dev-&gt;features |= NETIF_F_NO_CSUM;
            * dev-&gt;hard_header_cache = NULL;
        * priv = netdev_priv(dev);
    * 模块的卸载
        * unregister_netdev函数从系统中删除接口
        * free_netdev函数将net_device结构返回给系统
<!--more-->
* net_device结构细节
    * 全局信息
        * char name[IFNAMSIZ];
        * unsigned long state;
        * struct net_device *next;
        * int (*init) (struct net_device *dev);
    * 硬件信息
        * unsigned long rmem_end;
        * unsigned long rmem_start;
        * unsigned long mem_end;
        * unsigned long mem_start;
        * unsigned long base_addr;
        * unsigned char irq;
        * unsigned char if_port;
        * unsigned char dma;
    * 接口信息
        * drivers/net/net_init.c
        * void ltalk_setup(struct net_device *dev);
        * void fs_setup(struct net_device *dev);
        * void fddi_setup(struct net_device *dev);
        * void hippi_setup(struct net_device *dev);
        * void tr_setup(struct net_device *dev);
        * unsigned short hard_header_len;
            * 对以太网接口，该值是14
        * unsigned mtu;
            * 最大传输单元，以太网的MTU是1500个octet
        * unsigned long tx_queue_len;
        * unsigned short type;
            * ARP使用type成员判断接口所支持的硬件地址类型
            * &lt;linux/if_arp.h&gt;
        * unsigned char addr_len;
        * unsigned char broadcast[MAX_ADDR_LEN];
        * unsigned char dev_addr[MAX_ADDR_LEN];
        * unsigned short flags;
        * int features;
            * 该标志成员是一个位掩码
            * IFF_前缀表示“接口标志”，有效的标志定义在&lt;linux/if.h&gt;
    * 设备方法
        * 网络接口的设备方法可划分为两个类型：基本的和可选的
        * 基本方法
            * int (*open) (struct net_device *dev);
            * int (*stop) (struct net_device *dev);
            * int (*hard_start_xmit) (struct sk_buff *skb, struct net_device *dev);
            * int (*hard_header) (struct sk_buff *skb, struct net_device *dev, unsigned short type, void *daddr, void *saddr, unsigned len);
            * int (*rebuild_header) (struct sk_buff *skb);
            * void (*tx_timeout) (struct net_device *dev);
            * struct net_device_stats *(*get_stats) (struct net_device *dev);
            * int (*set_config) (struct net_device *dev, struct ifmap *map);
        * 可选方法
            * int (*poll) (struct net_device *dev, int *quota);
            * void (*poll_controller) (struct net_device *dev);
            * int (*do_ioctl) (struct net_device *dev, struct ifreq *ifr, int cmd);
            * void (*set_multicast_list) (struct net_device *dev);
            * int (*set_mac_address) (struct net_device *dev, void *addr);
            * int (*change_mtu) (struct net_device *dev, int net_mtu);
            * int (*header_cache) (struct neighbour *neigh, struct hh_cache *hh);
            * int (*header_cache_update) (struct hh_cache *hh, struct net_device *dev, unsigned char *haddr);
            * int (*hard_header_parse) (struct sk_buff *skb, unsigned char *haddr);
    * 工具成员
        * unsigned long trans_start;
        * unsigned long last_rx;
        * int watchdog_timeo;
        * void *priv;
        * struct dev_mc_list *mc_list;
        * int mc_count;
        * spinlock_t xmit_lock;
        * int xmit_lock_owner;
* 打开和关闭
    * 在使用ifconfig向接口赋予地址时，要执行两个任务
        * 首先，通过ioctl(SIOCSIFADDR)赋予地址
        * 然后，通过ioctl(SIOCSIFFLAGS)设置dev-&gt;flag中的IFF_UP标志以打开接口
    * 对设备而言，无需对ioctl（SIOCSIFADDR）做任何工作，后一个命令会调用设备的open方法
    * 在接口被关闭时，ifconfig使用ioctl(SIOSIFFLAGS)来清除IFF_UP标志，然后调用stop函数
    * 此外，还要执行其他一些步骤
        * 首先，在接口有够和外界通讯之前，要将硬件地址（MAC）从硬件设备复制到dev-&gt;dev_addr
        * 应该启动接口的传输队列
            * void netif_start_queue(struct net_device *dev);
* 数据包传输
    * 无论何时内核要传输一个数据包，它都会调用驱动程序的hard_start_transmit函数将数据放入外发队列
    * 内核处理的每个数据包位于一个套接字缓冲区结构（sk_buff）中，该结构定义在&lt;linux/skbuff.h&gt;中
    * 传递经全hard_start_xmit的套接字缓冲区包含了物理数据包，并拥有完整的传输层数据包头
    * 该传输函数只执行了对数据包的一致性检查，然后通过硬件相关的函数传输数据
    * 如果执行成功，则hard_start_xmit返回0
    * 控制并发传输
        * 通过net_device结构中的一个自旋锁获得并发调用时的保护
        * 实际的硬件接口是异步传输数据包的，而且可用来保存外发数据包的存储空间非常有限
        * void netif_wake_queu(struct net_device *dev);
            * 通知网络系统可再次开始传输数据包
        * void netif_tx_disable(struct net_device *dev);
            * 禁止数据包的传送
    * 传输超时
        * 如果当前的系统时间超过设备的trans_start时间至少一个超时周期，网络层将最终调用驱动程序的tx_timeout函数
    * Scatter/Gather I/O
        * 在网络上为传输工作创建数据包的过程，包括了组装多个数据片段的过程
        * 如果负责发送数据包的网络接口实现了分散/聚焦I/O，则数据包就不用组装成一个大的数据包
        * 分散/聚焦I/O还能用“零拷贝”的方法，把网络数据直接从用户缓冲区内传输出来
        * 如果在device结构中的feature成员内设置了NETIF_F_SG标志位，内核才将分散的数据包传递给hard_start_xmit函数
        * struct skb_frag_struct
            * struct page *page;
            * __u16 page_offset;
            * __u16 size;
* 数据包的接收
    * 从网络上接收数据要比传输数据复杂一点，因为必须在原子上下文中分配一个sk_buff并传递给上层处理
    * 网络驱动程序实现了两种模式接收数据包：中断驱动方式和轮询方式
    * 过程
        * 第一步是分配一个保存数据包的缓冲区
            * dev_alloc_skb
        * 检查dev_alloc_skb函数的返回值
        * 一旦拥有一个合法的skb指针，则调用memcpy将数据包数据拷贝到缓冲区内
        * 最后，驱动程序更新其统计计数器
    * 接收数据包过程中的最后一个步骤由netif_rx执行
* 中断处理例程
    * 接口在两种可能的事件下中断处理器
        * 新数据包到达
        * 外发数据包的传输已经完成
    * 通常中断例程通过检查物理设备中的状态寄存器，以区分新数据包到达中断和数据传输完毕中断
    * 传输结束时，统计信息要被更新，而且要将套接字缓冲区返回全系统
        * dev_kfree_skb(struct sk_buff *skb);
        * dev_kfree_skb_irq(struct sk_buff *skb);
        * dev_kfree_skb_any(struct sk_buff *skb);
* 不使用接收中断
    * 为了能提高Linux在宽带系统上的性能，网络子系统开发者创建了另外一种基于轮询方法的接口（称之为NAPI）
    * 停止使用中断会减轻处理器的负荷
    * struct net_device的poll成员必须设置为驱动程序的轮询函数
    * 当接口通知数据到达的时候，中断程序不能处理该数据包，相反它还要禁止接收中断，并且告诉内核，从现在开始启动轮询接口
    * 用netif_receive_skb函数将数据包传递给内核，而不是使用netif_rx
    * 调用netif_rx_complete关闭轮询函数
* 链路状态的改变
    * 大多数涉及实际的物理连接的网络技术提供载波状态信息，载波的存在意味着硬件功能是正常的
    * void netif_carrier_off(struct net_device *dev);
    * void netif_carrier_on(struct net_device *dev);
    * int netif_carrier_ok(struct net_device *dev);
        * 用来检测当前的载波状态
* 套接字缓冲区
    * &lt;linux/skbuff.h&gt;
    * 重要的成员
        * struct net_device *dev
        * union { /* ... */ } h;
        * union { /* ... */ } nh;
        * union { /* ... */ } mac;
        * unsigned char *head;
        * unsigned char *data;
        * unsigned char *tail;
        * unsigned char *end;
        * unsigned int len;
        * unsigned int data_len;
        * unsigned char ip_summed;
        * unsigned char pkt_type;
        * shinfo (struct sk_buff *skb);
        * unsigned int shinfo(skb)-&gt;nr_frags;
        * skb_frag_t shinfo(skb)-&gt;frags;
    * 操作套接字缓冲区的函数
        * struct sk_buff *alloc_skb(unsigned int len, int priority);
        * struct sk_buff *dev_alloc_skb(unsigned int len);
        * void kfree_skb(struct sk_buff *skb);
        * void dev_kfree_skb(struct sk_buff *skb);
        * void dev_kfree_skb_irq(struct sk_buff *skb);
        * void dev_kfree_skb_any(struct sk_buff *skb);
        * unsigned char *skb_put(struct sk_buff *skb, int len);
        * unsigned char *__skb_put(struct sk_buff *skb, int len);
        * unsigned char *skb_push(struct sk_buff *skb, int len);
        * unsigned char *__skb_push(struct sk_buff *skb, int len);
        * int skb_tailroom(struct sk_buff *skb);
        * int skb_headroom(struct sk_buff *skb);
        * void skb_reserve(struct sk_buff *skb, int len);
        * unsigned char *skb_pull(struct sk_buff *skb, int len);
        * int skb_is_nonlinear(struct sk_buff *skb);
        * int skb_headlen(struct sk_buff *skb);
        * void *kmap_skb_frag(skb_frag_t *frag);
        * void kunmap_skb_frag(void *vaddr);
* MAC地址解析
    * 在以太网中使用ARP
        * ARP由内核维护，而以太网接口不需要做任何特殊工作就能支持ARP
    * 重载ARP
        * 如果设备希望使用常用的硬件头，而不运行ARP，则需要重载默认的dev-&gt;hard_header函数
    * 非以太网头
        * 硬件头中除目标地址之外，还包含其他一些信息，其中最重要的是通信协议
        * drivers/net/appletalk/cops.c
        * drivers/net/irda/smc_ircc.c
        * drivers/net/pp_generic.c
* 定制ioctl命令
    * 当为某个套接字使用ioctl系统调用时，命令号是定义在&lt;linux/sockios.h&gt;中的某个符号
    * 函数sock_ioctl直接调用一个协议相关的函数
    * 任何协议层不能识别的ioctl命令都会传递到设备层
    * 这些设备相关的ioctl命令从用户空间接受第三个参数，即一个struct ifreq *指针
        * &lt;linux/if.h&gt;
* 统计信息
    * 驱动程序需要的最后一个函数是get_stats，这个函数返回设备统计结构的指针
    * struct net_device_stats
        * unsigned long rx_packets;
        * unsigned long tx_packets;
        * unsigned long rx_bytes;
        * unsigned long tx_bytes;
        * unsigned long rx_errors;
        * unsigned long tx_errors;
        * unsigned long rx_dropped;
        * unsigned long tx_dropped;
        * unsigned long collisions;
        * unsigned long multicast;
* 组播
    * 对以太网而言，组播地址在目标地址的第一个octet的最低位设置为1,而所有设备板卡将自己的硬件地址的相应位清零
    * 内核在任意给定时刻均要跟踪组播地址
    * 驱动程序实现组播清单的方法，在某种程序上依赖于底层硬件的工作方式
    * 通常来说，考虑组播时，硬件可划分为三类
        * 不有处理组播的接口
        * 能够区分组播数据包和其他数据包的接口
        * 能够为组播地址进行硬件检测的接口
    * 对组播的内核支持
        * 对组播数据包的支持由如下几项组成：一个设备函数、一个数据结构以及若干设备标志
        * void (*dev_set_multicast_list) (struct net_device *dev);
        * struct dev_mc_list *dev-&gt;mc_list;
        * int dev-&gt;mc_count;
        * &lt;linux/netdevice.h&gt;
        * struct dev_mc_list
            * struct dev_mc_list *next
            * __u8 dmi_addr[MAX_ADDR_LEN];
            * unsigned char dmi_addrlen;
            * int dmi_users;
            * int dmi_gusers;
* 其他知识点详解
    * 对介质无关接口的支持
        * 介质无关接口（Media Independent Interface, MII）是一个IEEE802.3标准，它描述了以太网收发器是如何与网络控制器连接的
        * &lt;linux/mii.h&gt;
        * int (*mdio_read) (struct net_device *dev, int phy_id, int location);
        * void (*mdio_write) (struct net_device *dev, int phy_id, int location, int val);
        * drivers/net/mii.c
    * ethtool支持
        * ethtool是为系统管理员提供的用于控制网络接口的工具
        * 只有当驱动程序支持ethtool时，使用ethtool才能控制包括速度、介质类型、双工操作、DMA设置、硬件检验、LAN唤醒操作在内的许多接口参数
        * http://sf.net/projects/gkernel/
        * &lt;linux/ethtool.h&gt;
        * struct ethtool_ops
    * Netpoll
        * 它出现的目的是让内核在网络和I/O子系统尚不能完整可用时，依然能发送和接收数据包
        * 用于网络控制台和远程内核调试
        * 实现netpoll的驱动程序需要实现poll_controller函数，作用是在缺少设备中断时，还能对控制器做出响应
