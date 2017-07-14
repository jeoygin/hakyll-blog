---
title: Ubuntu 11.04(natty) 安装Xen 4.0.1
tags:
  - natty
  - source
  - ubuntu
  - xen
id: 360
categories:
  - 计算机技术
  - 虚拟化
date: 2011-04-29 23:15:54
---

最近在看Xen 4.0.1的源码，总得编译出来玩玩吧，于是又开始了Xen的编译之旅。去年差不多这个时候也在学习Xen，算是有点经验了，不过之前的一周也真够折腾的，装了多个系统，编译出来的内核不是启动不了Xen就是Xen不正常工作，最后还是用了刚发布的Ubuntu 11.04。编译过程有点挫折，将安装过程记录如下。


<!--more-->


我的安装是从网上两篇文章参考的：
1. [Xen4.0 - Xen Wiki](http://wiki.xensource.com/xenwiki/Xen4.0)
2. [在 Ubuntu 上源码安装 Xen](http://www.vpsee.com/2010/04/install-xen-on-ubuntu-from-source/)

一、准备源码

首先，为系统安装需要的包：

```
sudo apt-get install bcc bin86 gawk bridge-utils iproute libcurl3 \
libcurl4-openssl-dev bzip2 module-init-tools transfig tgif texinfo \
texlive-latex-base texlive-latex-recommended texlive-fonts-extra \
texlive-fonts-recommended pciutils-dev mercurial build-essential \
make gcc g++ libc6-dev zlib1g-dev python python-dev python-twisted \
libncurses5-dev patch libvncserver-dev libsdl-dev libjpeg62-dev iasl \
libbz2-dev e2fslibs-dev git-core uuid-dev ocaml libx11-dev bison flex \
libssl-dev gettext libgcrypt11-dev pkg-config fakeroot crash kexec-tools \
makedumpfile libncurses5
sudo apt-get build-dep linux
apt-get install gcc-multilib 
apt-get install xz-utils
```

下载源码：

* Xen 4.0.1： http://bits.xensource.com/oss-xen/release/4.0.1/xen-4.0.1.tar.gz
* Linux Kernel 2.6.38.4： http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.38.4.tar.gz

还需要下载内核的xen补丁：

xen-patches-2.6.38-2： http://gentoo-xen-kernel.googlecode.com/files/xen-patches-2.6.38-2.tar.bz2

将所有包移动到/usr/src后展开各个包：

```
sudo tar zxvf linux-2.6.38.4.tar.gz
sudo tar zxvf xen-4.0.1.tar.gz
sudo mkdir xen-patches
cd xen-patches
tar jxvf ../xen-patches-2.6.38-2.tar.bz2
```

进入linux-2.6.38.4目录，打上补丁：

```
sudo cat ../xen-patches/*.patch1 | patch -p1
```

二、编译Xen

```
make xen tools stubdom
make install-xen
make install-tools PYTHON_PREFIX_ARG=
make install-stubdom
```

在编译的过程中可能会遇到如下问题：

```
In file included from tapdisk.h:62:0,
                 from blk_linux.c:4:
../lib/blktaplib.h:199:0: error: "WRITE" redefined
/usr/include/linux/fs.h:160:0: note: this is the location of the previous definition
```

这个问题请打补丁：[blk_linux.patch1](http://file.jeoygin.org/virtualization/xen-4.0.1/blk_linux.patch1)

```
netfront.c:41:32: error: variably modified 'tx_freelist' at file scope 
netfront.c:44:34: error: variably modified 'rx_buffers' at file scope 
netfront.c:45:34: error: variably modified 'tx_buffers' at file scope 

lib/math.c: In function '__qdivrem': 
lib/math.c:196:9: error: 'tmp.ul[1]' may be used uninitialized in this function 

mm.c: In function 'set_readonly': 
mm.c:321:46: error: taking address of expression of type 'void' 
```

这个问题请打补丁：[gcc-4.5.patch1](http://file.jeoygin.org/virtualization/xen-4.0.1/gcc-4.5.patch1)

如果使用xm命令报以下错误：

```
AttributeError: HTTPUnix instance has no attribute 'getresponse'
```

请打补丁：[xmlrpc.patch1](http://file.jeoygin.org/virtualization/xen-4.0.1/xmlrpc.patch1)

三、编译内核

先准备一个编译配置，可以下载我使用的配置[.config](http://file.jeoygin.org/virtualization/xen-4.0.1/.config)，执行make menuconfig命令，配置好内核参数后，保存配置文件，之后就可以开始编译了：

```
sudo make
sudo make install
sudo make modules_install
sudo update-initramfs -c -k 2.6.38.4
sudo depmod 2.6.38.4
```

将Xen的内核模块加入/etc/modules文件，使系统启动时自动加载：

```
sudo vi /etc/modules
...
netbk
blkbk
blktap
```

四、修改grub

Ubuntu 11.04 使用了Grub2,Grub2与Xen是不兼容的，于是将grub2降级到grub：

```
sudo apt-get purge grub-pc
sudo rm /boot/grub/*
sudo apt-get install grub
sudo grub-install --recheck /dev/sda
sudo update-grub
```

手动添加启动菜单,在/boot/grub/menu.lst中添加以下内容：

```
title	Xen 4.0.1 / Linux 2.6.38.4
kernel	/boot/xen-4.0.gz
module	/boot/vmlinuz-2.6.38.4 root=[root-location] ro cnsole=tty0
module	/boot/initrd.img-2.6.38.4
```

重启，不出意外的话xen应该是启动了,可以使用以下命令查看：

```
ps -ef | grep xend
xm list
```
