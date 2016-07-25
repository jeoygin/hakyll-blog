---
title: CentOS安装iftop
tags:
  - centos
  - iftop
  - network
id: 583
categories:
  - 计算机技术
  - 网络
date: 2012-03-03 20:20:01
---

## 简介 ##

iftop是一个实时流量监控工具，不具有统计功能，跟top类似，看起来比较直观。

## 安装环境 ##

操作系统：CentOS 5.6

内核：2.6.18

网络：千兆以太网

## 安装依赖包 ##

	yum install gcc flex byacc libpcap libpcap-devel ncurses ncurses-devel

## 编译、安装源码 ##

下载地址：http://www.ex-parrot.com/pdw/iftop/download/iftop-0.17.tar.gz

编译安装：

```
 tar zxvf iftop-0.17.tar.gz
 cd iftop-0.17
 ./configure
 make
 make install
```

## 运行 ##

	iftop

## iftop重要参数 ##

* -i：指定网卡
* -B：以bytes为单位显示流量
* 按q退出

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。