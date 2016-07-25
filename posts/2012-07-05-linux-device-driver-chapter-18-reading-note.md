---
title: 《Linux设备驱动程序》第十八章 TTY驱动程序读书笔记
tags:
  - Driver
  - Linux
  - Reading Note
  - TTY
id: 980
categories:
  - 学习笔记
date: 2012-07-05 19:00:34
---

* 简介
    * tty设备的名称是从过去的电传打字机缩写而来，最初是指连接到Unix系统上的物理或虚拟终端
    * Linux tty驱动程序的核心紧挨在标准字符设备驱动层之下，并提供了一系列的功能，作为接口被终端类型设备使用
    * 有三种类型的tty驱动程序：控制台、串口和pty
    * /proc/tty/drivers
    * 当前注册并存在于内核的tty设备在/sys/class/tty下都有自己的子目录
* 小型TTY驱动程序
    * &lt;linux/tty_driver.h&gt;
    * struct tty_driver
    * tiny_tty_driver = alloc_tty_driver(TINY_TTY_MINORS);
    * static struct tty_operations serial_ops = {.open=tiny_open, .close=tiny_close, .write=tiny_write, .write_room=tiny_write_room, .set_termios=tiny_set_termios,}
    * tiny_tty_driver-&gt;owner=THIS_MODULE;
    * tiny_tty_driver-&gt;driver_name="tiny_tty";
    * tiny_tty_driver-&gt;name="ttty";
    * tiny_tty_driver-&gt;devfs_name="tty/ttty%d";
    * tiny_tty_driver-&gt;major=TINY_TTY_MAJOR;
    * tiny_tty_driver-&gt;type=TTY_DRIVER_TYPE_SERIAL;
    * tiny_tty_driver-&gt;subtype=SERIAL_TYPE_NORMAL;
    * tiny_tty_driver-&gt;flags=TTY_DRIVER_REAL_RAW|TTY_DRIVER_NO_DEVFS;
    * tiny_tty_driver-&gt;init_termios=tty_std_termios;
    * tiny_tty_driver-&gt;init_termios.c_cflag=B9600|CS8|CREAD|HUPCL|CLOCAL;
    * tty_set_operaions(tiny_tty_driver, &serial_ops);
    * retval = tty_register_driver(tiny_tty_driver);
    * for (i=0;i&lt;TINY_TTY_MINORS; ++i) tty_unregister_device(tiny_tty_driver, i);
    * tty_unregister_driver(tiny_tty_driver);
    * termios结构
        * 用来提供一系列安全的设置值
        * struct termios
            * tcflag_t c_iflag;
            * tcflag_t c_oflag;
            * tcflag_t c_cflag;
            * tcflag_c c_lflag;
            * cc_t c_line;
<!--more-->
* tty_driver函数指针
    * open和close
        * 当用户使用open打开由驱动程序分配的设备节点时，tty核心将调用open函数
        * 当调用open函数时，tty驱动程序或者将数据保存到传递给它的tty_struct变量中
    * 数据流
        * 当数据要发送给硬件时，用户调用write函数
        * 首先tty核心接收到了该调用，然后内核将数据发送给tty驱动程序的write函数
        * tty驱动程序在中断上下文中时，它不会调用任何可能休眠的函数
        * 当tty子系统本身需要将一些数据传送到tty设备之外时，可以调用write函数
        * 当tty核心想知道由tty驱动程序提供的可用写入缓冲区大小时，就会调用write_room函数
    * 其他缓冲函数
        * flush_chars
        * wait_until_sent
        * flush_buffer
    * 怎么没有read函数
        * 当tty驱动程序接收到数据后，它将负责把从硬件获取的任何数据传递给tty核心，而不使用传统的read函数
        * tty核心将缓冲数据直到接到来自用户的请求
        * 在一个名为tty_flip_buffer的结构中，tty核心缓冲从tty驱动程序接收的数据
        * tty_insert_flip_char
        * tty_flip_buffer_push
* TTY线路设置
    * set_termios
        * 大部分termios的用户空间函数将会被库转换成对驱动程序节点的ioctl调用
        * 大量的不同tty ioctl调用会被ttyp核心转换成一个对tty驱动程序的set_termios函数调用
        * tty驱动程序必须能够对在termios结构中所有不同的设置进行解码，并对任何需要的改变做出响应
    * tiocmget和tiocmset
        * 在2.4及更早的内核中，使用了大量的tty ioctl调用来获得及设置不同的控制线路参数
        * 这通过常量TIOCMGET、TIOCMBIS、TIOCMBIC和TIOCMSET来完成
        * TIOCMGET用来获得内核的线路设置值，在2.6.版本的内核中，该ioctl调用被tty驱动程序中的tiocmget回调函数所代替
        * 剩下的三个ioctl现在被简化成tty驱动程序中的一个tiocmset回调函数了
        * int (*tiocmget) (struct tty_struct *tty, struct file *file);
        * int (*tiocmset) (struct tty_struct *tty, struct file *file, unsigned int set, unsigned int clear);
* ioctls
    * 当ioctl为一个设备节点被调用时，tty核心将调用tty_driver结构中的ioctl回调函数
    * 常用词tty ioctl的列表
        * TIOCSERGETLSR
            * 获得这个tty设备线路状态寄存器（LSR）的值
        * TIOCGSERIAL
            * 获得串行线路信息
        * TIOCSSERIAL
            * 设置串行线路信息
        * TIOCMIWAIT
            * 等待MSR的变化
        * TIOCGICOUNT
            * 获得中断计数
* proc和sys对TTY设备的处理
    * tty核心为任何tty驱动程序都提供了非常简单的办法，用来维护在/proc/tty/driver目录中的一个文件
    * 如果驱动程序定义了read_proc或者write_proc函数，将创建该文件，接着任何对该文件的读写将被发送给驱动程序
* tty_driver结构详解
    * tty_driver结构用来向tty核心注册一个tty驱动程序
    * struct tty_driver
        * struct module *owner;
        * int magic;
            * 幻数
        * const char *driver_name;
            * 在/proc/tty和sysfs中使用，表示驱动程序的名字
        * const char *name;
            * 驱动程序节点的名字
        * int name_base;
            * 为创建设备名字而使用的开始编号
        * short major;
            * 驱动程序的主设备号
        * short minor_start;
            * 驱动程序使用的最小次设备号
        * short num;
            * 可以分配驱动程序次设备号的个数
        * short type;
            * TTY_DRIVER_TYPE_SYSTEM
            * TTY_DRIVER_TYPE_CONSOLE
            * TTY_DRIVER_TYPE_SERIAL
            * TTY_DRIVER_TYPE_PTY
        * short subtype;
            * 描述向tty核心注册的是何种tty驱动程序
        * struct termios init_termios;
            * 当被创建时，含有初始值的termios结构
        * int flags;
            * 驱动程序标志位
        * struct proc_dir_entry *proc_entry;
            * 该驱动程序的/proc入口结构体
        * struct tty_driver *other;
            * 指向tty从属设备驱动程序的指针
        * void *driver_state;
            * tty驱动程序内部的状态
        * struct tty_driver *next;
        * struct tty_driver *prev;
            * 链接变量
* tty_operations结构详解
    * tty_operations结构中包含所有的回调函数，它们被tty驱动程序设置，并被tty核心调用
    * struct tty_operations
        * int (*open) (struct tty_struct *tty, struct file *filp);
        * int (*close) (struct tty_struct *tty, struct file *filp);
        * int (*write) (struct tty_struct *tty, const unsigned char *buf, int count);
        * void (*put_char) (struct tty_struct *tty, unsigned char ch);
        * void (*flush_chars) (struct tty_struct *tty);
        * void (*wait_until_sent) (struct tty_struct *tty, int timeout);
        * int (*write_room) (struct tty_struct *tty);
        * int (*chars_in_buffer) (struct tty_struct *tty);
        * int (*ioctl) (struct tty_struct *tty, struct file *file, unsigned int cmd, unsigned long arg);
        * void (*set_termios) (struct tty_struct *tty, struct termios *old);
        * void (*throttle) (struct tty_struct *tty);
        * void (*unthrottle) (struct tty_struct *tty);
        * void (*stop) (struct tty_struct *tty);
        * void (*start) (struct tty_struct *tty);
        * void (*hangup) (struct tty_struct *tty);
        * void (*bread_ctl) (struct tty_struct *tty, int state);
        * void (*flush_buffer) (struct tty_struct *tty);
        * void (*set_ldisc) (struct tty_struct *tty);
        * void (*send_xchar) (struct tty_struct *tty, char ch);
        * int (*read_proc) (char *page, char **start, off_t off, int count, int *eof, void *data);
        * int (*write_proc) (struct file *file, const char *buffer, unsigned long count, void *data);
        * int (*tiocmget) (struct tty_struct *tty, struct file *file);
        * int (*tiocset) (struct tty_struct *tty, struct file *file, unsigned int set, unsigned int clear);
* tty_struct结构详解
    * tty核心使用tty_struct保存当前特定tty端口的状态
    * struct tty_struct
        * unsigned long flags;
            * 当前tty设备的状态
            * TTY_THROTTLED
            * TTY_IO_ERROR
            * TTY_OTHER_CLOSED
            * TTY_EXCLUSIVE
            * TTY_DEBUG
            * TTY_DO_WRITE_WAKEUP
            * TTY_PUSH
            * TTY_CLOSING
            * TTY_DONT_FLIP
            * TTY_HW_COOK_OUT
            * TTY_HW_COOK_IN
            * TTY_PTY_LOCK
            * TTY_NO_WRITE_SPLIT
        * struct tty_flip_buffer flip;
            * tty设备的交替缓冲区
        * struct tty_ldisc ldisc;
            * tty设备的线路规程
        * wait_queue_head_t write_wait;
            * 用于tty写函数的wait_queue
        * struct termios *termios;
            * 指向设置tty设备的termios结构指针
        * unsigned char stopped:1;
            * 表示tty设备是否已经停止
        * unsigned char hw_stopped:1
            * 表示tty设备硬件是否已经停止
        * unsigned char low_latency:1
            * 表示tty设备是否是个慢速设备
        * unsigned char closing:1
            * 表示tty设备是否正在关闭端口
        * struct tty_driver driver;
            * 控制tty设备的当前tty_driver结构
        * void *driver_data;
            * tty_driver用来把数据保存在tty驱动程序中的指针
