---
title: Ubuntu 9.10(Karmic) 安装Xen 3.4
tags:
  - ubuntu
  - xen
  - 虚拟化
id: 276
categories:
  - 计算机技术
  - 虚拟化
date: 2010-04-18 03:53:00
---

Ubuntu 9.10(Karmic) 安装Xen 3.4

前几天把Ubuntu 9.04给搞崩了，于是就装了个9.10，在网上找如何在9.10装xen的文章，发现比较少，弄了几天，编译好几个linux 2.6的内核，但在启动时显示[End trace ****]后就卡住了，没能进入到系统，经过多次尝试，终于在ubuntu 9.10上，编译了linux 2.6.31.5和xen 3.4.2。由于毕设做的是与虚拟化相关的工作，所以要研究一下在linux下用虚拟机，之所以用xen而不用vmware，是因为xen是开源的，据说开100台虚拟机对虚拟机的影响不会太大，但这还没测试过，不过在windows下用惯了vmware，对它还是情有独钟。


<!--more-->


我的安装是从网上两篇文章参考的：

1. [编译Xen 3.4 Dom0 using Linux Kernel 2.6.31 on Ubuntu 9.10 (Karmic)](http://blog.csdn.net/EmeraldDream_HUST/archive/2009/11/02/4758443.aspx)
2. [ubuntu 9.10上（linux 2.6.33.1内核）安装xen3.4.2](http://forum.ubuntu.org.cn/viewtopic.php?f=65&t=264130)

一、准备源码

首先，为系统安装没有打上的包：

```
$ sudo apt-get install libx11-dev gettext bin86 texinfo \
bcc bridge-utils build-essential zlib1g-dev libncurses5-dev \
python-dev gawk mercurial libssl-dev libcurl4-openssl-dev
```

下载源码：

* Xen 3.4.2： http://bits.xensource.com/oss-xen/release/3.4.2/xen-3.4.2.tar.gz
* Linux Kernel 2.6.31.5： http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.31.5.tar.gz

还需要下载内核的xen补丁：

xen-patches-2.6.31-7： http://gentoo-xen-kernel.googlecode.com/files/xen-patches-2.6.31-7.tar.bz2

将所有包移动到/usr/src后展开各个包：

```
sudo tar zxvf linux-2.6.31.5.tar.gz
sudo mv linux-2.6.31.5 linux-2.6.31.5-xen
sudo tar zxvf xen-3.4.2.tar.gz
sudo mkdir xen-patches
cd xen-patches
tar jxvf ../xen-patches-2.6.31-7.tar.bz2
```

进入linux-2.6.31.5-xen目录，打上补丁：

```
sudo cat ../xen-patches/*.patch1 | patch -p1
```

二、编译Xen

先用 xen-3.4.2/tools/check/chk build 和 chk install 检查一下有没有需要的软件包是否齐备,chesk通过的话就可以编译了，直接make world是可以的，不过会编译一个2.6.18的内核，中间还会到服务器上下载相应的包，耗时比较长。

```
make dist-xen dist-tools dist-stubdom
make install-xen install-tools install-stubdom
```

这样可以安装xen 3.4，不过我安装后进入Dom0后有点问题，用xm命令时报出这样的错误：

```
ImportError: No module named xen.xm
```

google查了一下，说安装python-xen-3.x就能解决这个问题，但用apt-get找不到python-xen-3.4，只能安装python-xen-3.3将就一下，安装之后这个问题果然解决了，再用xm命令时报出另一个错误：

```
libxenctrl.so.3.2: cannot open shared object file
```

再去google查了一下，说是xenner的问题，用apt-get 安装了xenner，之后就能正常使用xm命令了，这样也不知道会不会有问题，因为还没创建虚拟机和运行虚拟机，有人说用make world和make install就不会有这样的问题。

三、编译内核

先准备一个编译配置，我直接copy了当前系统所用内核的配置,进入linux-2.6.31.5-xen目录，因为我用的是桌面版，所以是generic,如果是服务器版就把generic改成server:

```
sudo cp /boot/config-2.6.31-14-generic .config
```

用make menuconfig修改一下配置，主要修改以下配置：

```
processor type and features->
[*]enable xen compatible kernel
networking supprot->
networking options->
<*>802.1d Ethernet Bridging
device drivers->
xen->
[*]Privileged Guest (domain 0)
xen version compatibilty (3.0.2 and later) -> 3.3.0 and later
```

修改配置后就可以编译了：

```
sudo make
sudo make install
sudo make modules_install
```

安装后，将生成的/boot/vmlinuz-2.6.31.5改名：

```
sudo mv /boot/vmlinuz-2.6.31.5 /boot/vmlinuz-2.6.31.5-xen
```

生成initrd:

```
sudo mkinitramfs -o /boot/initrd.img-2.6.31.5-xen 2.6.31.5
```

四、修改grub

Ubuntu 9.10 使用了1.97版本的Grub，也就是Grub2,Grub2与Xen是不兼容的，于是将grub2降级到grub，具体可参考：http://ubuntuforums.org/showpost.php?p=8071880&postcount=18。

用update-grub不会把xen内核添加到grub中，只能手动添加,在/boot/grub/menu.lst中添加以下内容：

```
title	Xen 3.4.2 / Linux 2.6.31.5
kernel	/boot/xen-3.4.2.gz
module	/boot/vmlinuz-2.6.31.5-xen root=[root-location] ro cnsole=tty0
module	/boot/initrd.img-2.6.31.5-xen
```

重启，不出意外的话xen应该是启动了,可以使用以下命令查看：

```
ps -ef | grep xend
xm list
```

整个编译过程大概需要3－4小时，当然，这要看你的CPU能力啦，期间可以去干点别的事情。
