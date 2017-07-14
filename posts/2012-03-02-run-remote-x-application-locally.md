---
title: 运行远程X应用程序
tags:
  - Application
  - Linux
  - Remote
  - Window
  - X
id: 578
categories:
  - 计算机技术
  - 操作系统
date: 2012-03-02 17:35:47
---

## 场景 ##

你在使用两台计算机：在计算机A上使用X-Window系统来显示图形界面，可以输入或查看信息；计算机B是一台服务器或没有显示器的计算机。你想要在计算机B上运行的程序显在计算机A上。

## 可用方案 ##

在很多时候，需要在服务器上运行一些图形应用程序，用于调试或查看信息，一般会使用VNC或其它远程桌面协议来连接。

X-Window不是C/S架构吗？突发奇想，如果让远端运行的程序显示在我的窗口上，不是更友好，更酷吗？于是试验了一下。为达到此目的，有两件事情需要做：

1. 通知本地display（X server）接收远程计算的连接
2. 通知远程应用（X client）将输出定向到本地display


<!--more-->


## X Window小常识 ##

X Window系统中有一个重要的概念是display，一个display包含键盘、鼠标和屏幕，由X server管理，与环境变量$DISPLAY相关。变量$DISPLAY的表示如下：

	host:D.S

这表示host主机display D上的屏幕S，X server会在TCP端口6000+D上监听该display。

## 通知X server ##

**xhost:**

默认情况下，X server不允许远程连接，必须使用xhost来授予远程主机访问权限。而且xhost命令只能在本地执行，即不能使用ssh连接到主机后执行该命令。

允许主机连接：

	xhost +hostname

禁止主机连接：

	xhost -hostname

允许所有主机连接：

	xhost +

禁止所有主机连接：

	xhost -

**ssh:**

使用-X参数会建立一条X转向隧道来进行连接，远端的ssh服务器会自动设置DISPLAY，并将之后在远端运行的应用的输出通过X隧道定向到本地的display。

	ssh -X host

## 通知X client ##

如果在本地，使用以下方式运行程序即可：

```
 export DISPLAY=host:0
 xapplication
```

或

	xapplication -display host:0

 如果使用ssh -X连接到主机，直接运行程序即可。

## Else ##

还可以运行远程窗口管理器，还有好多好多的问题，我不研究这个的，就不折腾了。