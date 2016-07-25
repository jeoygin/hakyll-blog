---
title: Linux开启VirtualBox的USB支持
tags:
  - Linux
  - USB
  - VirtualBox
id: 390
categories:
  - 计算机技术
  - 虚拟化
date: 2011-09-04 17:10:30
---

用了挺久的VirtualBox，但似乎从没有过在虚拟机中使用USB设备的需求，由于网银的U盾基本只能在Windows使用，所以只能在虚拟机中用了，但插入USB设备后竟然没半点反应，一下子就感觉这点没VMWare好，上Google找解决方法，有些方法很复杂，估计是以前老版本解决这个问题比较麻烦吧，现在方法挺简单的，只要把当前用户添加到组vboxusers中，重启一下系统，再打开VirtualBox就可以找到USB设备了。

将用户添加到vboxusers组：

```
usermod -a -G vboxusers username
```
