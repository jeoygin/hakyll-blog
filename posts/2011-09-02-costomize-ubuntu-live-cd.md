---
title: 定制Ubuntu Live CD
tags:
  - LiveCD
  - ubuntu
id: 376
categories:
  - 计算机技术
  - 操作系统
date: 2011-09-02 22:47:22
---

本文参考自：[LiveCDCustomizationFromScratch](https://help.ubuntu.com/community/LiveCDCustomizationFromScratch)

**一、准备ChRoot环境**

```
sudo apt-get install debootstrap
mkdir –p work/chroot
cd work
sudo debootstrap --arch=i386 lucid chroot
```

lucid是ubuntu 10.04，可以改为其它的版本

绑定/dev

```
sudo mount --bind /dev chroot/dev
```

拷贝系统配置以便可以上网及更新软件包

```
sudo cp /etc/hosts chroot/etc/hosts
sudo cp /etc/resolv.conf chroot/etc/resolv.conf
sudo cp /etc/apt/sources.list chroot/etc/apt/sources.list
```
<!--more-->

进入chroot

```
sudo chroot chroot

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
apt-get update
apt-get install --yes dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
```

安装live系统所需的软件包

```
apt-get install --yes ubuntu-standard casper lupin-casper
apt-get install --yes discover1 laptop-detect os-prober
apt-get install --yes linux-generic
```

接下来可以安装自己需要的软件了

如果制作Lucid系统需要安装grub2和plymouth-x11包

```
apt-get install --yes grub2 plymouth-x11
```

如果要使用gnome桌面，需要安装ubuntu-desktop这个包

```
apt-get install –yes Ubuntu-desktop
```

如果希望以后从LiveCD安装到硬盘上，要安装ubiquity

```
apt-get install ubiquity-frontend-gtk
```

清理ChRoot环境

```
rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf
umount -lf /proc
umount -lf /sys
umount -lf /dev/pts
exit
sudo umount chroot/dev
```

**二、制作光盘镜像**

安装需要的软件

```
sudo apt-get install syslinux squashfs-tools genisoimage sbm
```

创建光盘镜像目录结构

```
mkdir -p image/{casper,isolinux,install}
```

拷贝kernel和initrd

```
cp chroot/boot/vmlinuz-2.6.**-**-generic image/casper/vmlinuz
cp chroot/boot/initrd.img-2.6.**-**-generic image/casper/initrd.lz
```

拷贝isolinux和sbm

```
cp /usr/lib/syslinux/isolinux.bin image/isolinux/
cp /boot/memtest86+.bin image/install/memtest
cp /boot/sbm.img image/install/
```

在image/isolinux目录中创建启动向导文件isolinux.txt，文件开头必须是字符’\x18’

```
printf "\x18" > image/isolinux/isolinux.txt
```

编辑isolinux.txt文件

```
splash.rle

************************************************************************

This is an Ubuntu Remix Live CD.

For the default live system, enter "live".  To run memtest86+, enter "memtest"

************************************************************************
```

Bootloader的配置image/isolinux/isolinux.cfg

```
DEFAULT live
LABEL live
  menu label ^Start or install Ubuntu
  kernel /casper/vmlinuz
  append  file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd.lz quiet splash --
LABEL check
  menu label ^Check CD for defects
  kernel /casper/vmlinuz
  append  boot=casper integrity-check initrd=/casper/initrd.lz quiet splash --
LABEL memtest
  menu label ^Memory test
  kernel /install/memtest
  append -
LABEL hd
  menu label ^Boot from first hard disk
  localboot 0x80
  append -
DISPLAY isolinux.txt
TIMEOUT 300
PROMPT 1 

#prompt flag_val
# 
# If flag_val is 0, display the "boot:" prompt 
# only if the Shift or Alt key is pressed,
# or Caps Lock or Scroll lock is set (this is the default).
# If  flag_val is 1, always display the "boot:" prompt.
#  http://linux.die.net/man/1/syslinux   syslinux manpage
```

创建manifest

```
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE 
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done
```

压缩chroot

```
sudo mksquashfs chroot image/casper/filesystem.squashfs
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size
```

创建diskdefines

```
nano image/README.diskdefines
#define DISKNAME  Ubuntu 9.10 "Karmic Koala" - Release i386 **Remix**
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  i386
#define ARCHi386  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
```

创建一个空文件ubuntu和一个文件夹.disk，可以让USB Creator识别这个LiveCD

```
touch image/ubuntu

mkdir image/.disk
cd image/.disk
touch base_installable
echo "full_cd/single" > cd_type
echo 'Ubuntu 9.10 "Karmic Koala Remix" - i386 (20090429)' > info
echo "http//ubuntu-rescue-remix.org" > release_notes_url
cd ../..
```

计算MD5

```
sudo -s
(cd image && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt)
exit
```

创建ISO镜像

```
cd image
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-remix.iso .
cd ..
```