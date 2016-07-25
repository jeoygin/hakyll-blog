---
title: 制作使用Lilo引导的启动光盘或硬盘映像
tags:
  - boot
  - cd
  - disk
  - lilo
  - loader
id: 370
categories:
  - 计算机技术
  - 操作系统
date: 2011-07-18 23:25:56
---

一、安装Lilo

下载lilo-23.2

```
# wget http://lilo.alioth.debian.org/ftp/sources/lilo-23.2.tar.gz
```

编译并安装lilo

```
# tar zxvf lilo-23.2.tar.gz
# cd lilo-23.2
# make all
# make install
```

以下制作映像均在虚拟机中操作，方便虚拟硬盘和软盘，hypervisor使用xen 3.4。

<!--more-->

二、制作可启动硬盘映像

假如虚拟硬盘设备为/dev/sdb，/dev/sdb1分区是可以启动的，并且将/dev/sdb1挂载到/data/。

修改lilo的配置

```
# vim /etc/lilo.conf
boot=/dev/sdb			# 将lilo安装到硬盘的MBR
map=/data/boot/map		# lilo的映射信息
vga=normal
default=LingCloud		# 默认的启动项
prompt
nowarn
timeout=100			# 10秒超时
message=/data/boot/message	# 启动提示信息，须手动建立

other=/dev/sdb1
label=LingCloud
```

安装lilo

```
# /sbin/lilo -v -v -v
```

如果没提示错误即安装成功，将/dev/sdb对应的硬盘映像作为第一硬盘启动系统就能看到lilo的启动界面。

三、制作可启动光盘映像

先制作软盘映像，虚拟出floppy设备/dev/fd0，并将/dev/fd0挂载到/data。

格式化软盘

```
# mkfs -V -t msdos /dev/fd0
```

修改lilo的配置

```
# vim /etc/lilo.conf
boot=/dev/fd0			# 将lilo安装到软盘中
map=/data/boot/map		# lilo的映射信息
vga=normal
default=LingCloud		# 默认的启动项
prompt
nowarn
timeout=100			# 10秒超时
message=/data/boot/message	# 启动提示信息，须手动建立

other=/dev/fd0
label=LingCloud
```

安装lilo

```
# /sbin/lilo -v -v -v
```

使用软盘制作可启动光盘，假如软盘映像为boot.img，创建目录bootcd，在bootcd中创建目录boot，将boot.img拷贝到boot目录中，执行以下命令

```
# mkisofs -pad -b boot/boot.img -R -o /tmp/bootcd.iso .
```

将生成可启动光盘映像bootcd.iso