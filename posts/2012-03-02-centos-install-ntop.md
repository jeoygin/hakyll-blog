---
title: CentOS安装ntop
tags:
  - centos
  - network
  - ntop
id: 569
categories:
  - 计算机技术
  - 网络
date: 2012-03-02 17:08:17
---

## 简介 ##

ntop是网络监控的利器，可以用来统计网络流量，分析网络中存在的问题，提供友好的操作界面，可以生成图表。

## 安装环境 ##

操作系统：CentOS 5.6
内核：2.6.18

## 安装依赖包 ##

```
 yum install libpcap-devel
 yum install libtool
 yum install autoconf
 yum install automake
 yum install gdbm-devel
 yum install zlib-devel
 yum install ruby
 yum install GeoIP-devel
```

rrdtool在源上没有，只能在官网上下载，然后安装。

```
 wget http://packages.express.org/rrdtool/rrdtool-1.4.5-1.el5.wrl.x86_64.rpm
 wget http://packages.express.org/rrdtool/rrdtool-devel-1.4.5-1.el5.wrl.x86_64.rpm
 wget http://packages.express.org/rrdtool/rrdtool-perl-1.4.5-1.el5.wrl.x86_64.rpm
 rpm -ivh rrdtool-1.4.5-1.el5.wrl.x86_64.rpm rrdtool-devel-1.4.5-1.el5.wrl.x86_64.rpm rrdtool-perl-1.4.5-1.el5.wrl.x86_64.rpm
```


<!--more-->


## 编译、安装源码 ##

下载地址：http://sourceforge.net/projects/ntop/files/ntop/Stable/

我下载的是ntop-4.1.0.tar.gz，目前最新的稳定版，但我使用后怎么觉得不太稳定，时不时就崩溃了。

编译安装：

```
 tar zxvf ntop-4.1.0.tar.gz
 cd ntop-4.1.0
 ./autogen.sh
 ./configure
 make
 make install
```

## 准备环境 ##

添加用户：

```
 groupadd ntop
 useradd ntop -g ntop
```

创建目录：

```
 mkdir /var/log/ntop
 chown -R ntop.ntop /usr/local/share/ntop/
 chown -R ntop.ntop /var/log/ntop/
```

## 运行 ##

运行的命令是：

```
 ntop -P /var/log/ntop/ -u ntop
```

第一次运行要设置管理员密码。之后可以让ntop在后台运行，如果需要开始就运行ntop，在/etc/rc.local添加以下一行：

```
 ntop -P /var/log/ntop/ -u ntop > /dev/null 2>&1 &
```

运行ntop后，通过http://localhost:3000就可以访问ntop的web界面。

## 后记 ##

文中若有错误或疏漏之处，烦请批评指正。