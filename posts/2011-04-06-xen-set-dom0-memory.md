---
title: xen设置dom0的内存
tags:
  - dom0
  - memory
  - xen
id: 355
categories:
  - 计算机技术
  - 虚拟化
date: 2011-04-06 22:23:17
---

在使用XEN的过程中，我们有时可能会因创建过多的domU而导致dom0内存不足，最后导致服务器运行缓慢，即使将domU删除了也没把释放的内存分配给dom0，此时需要修改dom0的内存才能增加系统可利用的内存。


<!--more-->


使用“xm info”命令，查看内存池中可用的内存，如下图所示：

![](http://lh3.googleusercontent.com/_Npc6IElQ2gU/TZx0hFAux5I/AAAAAAAAAJ0/P0Z7l1rUw7k/2011_04_xm_info.jpg)

其中的free_memory为可用的内存，确认domU的内存已释放。

使用“xm mem-set 0 [megabytes]”命令设置dom0的内存，设置后运行“free -m”看看内存是不是增加了。

为避免dom0的内存过低使系统的性能降低，可以在xend的配置文件/etc/xen/xend-config.sxp中修改dom0-min-mem参数，在配置文件中找到dom0-min-mem，如下图所示：

![](http://lh6.googleusercontent.com/_Npc6IElQ2gU/TZx0gw1CIUI/AAAAAAAAAJw/I0gWp_3aFB4/2011_04_xend_config.jpg)

dom0-min-mem后面的参数为dom0最低的内存，单位是MB，如果dom0的内存不足dom0-min-mem，当domU的内存释放时，会给dom0增加不足的内存。
