---
title: 《Linux设备驱动程序》第二章 构造和运行模块读书笔记
tags:
  - Driver
  - Linux
  - module
  - Reading Note
id: 896
categories:
  - 学习笔记
date: 2012-06-15 18:18:02
---

* 设置测试系统
    * kernel.org网站获得一个“主线”内核
    * 2.6.x
* Hello World模块
    *  example

            #include <linux/init.h>
            #include <linux/module.h>
            MODULE_LICENSE("Dual BSD/GPL");

            static int hello_init(void)
            {
                printk(KERN_ALERT "Hello, world\n");
                return 0;
            }

            static void hello_exit(void)
            {
                printk(KERN_ALERT "Goodbye, cruel world\n");
            }

            module_init(hello_init);
            module_exit(hello_exit);

    * module_init和module_exit
    * MODULE_LICENSE


<!--more-->


* 核心模块与应用程序的对比
    * 模块预先注册自己以便服务于将来的某个请求
    * 我在这里，并且我能做这些工作
    * 我要离开啦，不要再让我做任何事情了
    * 模块仅仅被链接到内核，因此它能调用的函数仅仅是由内核导出的那些函数，而不存在任何可链接的函数库
    * include/linux
    * include/asm
    * 用户空间和内核空间
        * 每当应用程序执行系统调用或者被硬件中断挂起时，Unix将执行模式从用户空间切换到内核空间
    * 内核中的并发
        * 同一时刻，可能会有许多事情正在发生
        * 可能有多个进程同时使用驱动程序
        * 大多数设备能够中断处理器，而中断处理程序异步运行
        * Linux内核代码必须是可重入的
    * 当前进程
        * asm.current.h, current
        * linux/sched.h, struct task_struct
    * 其他一些细节
        * 内核具有非常小的栈，它可能只和一个4096字节大小的页那样小
        * 声明大的自动变量并不是一个好主意
        * 具有前缀__的函数名称通常是接口的底层组件，应谨慎使用
        * 内核代码不能实现浮点数运算

* 编译和装载
    * /proc/modules
    * /sys/module
    * 编译模块
        * Makefile

                obj-m := hello.o

                obj-m := module.o
                module-objs := file1.o file2.o

        * Compile

                make -C /usr/src/kernels/2.6.18-308.8.1.el5-i686/ M=`pwd` modules

    * 装载和卸载模块
        * insmod和ld有些类似，将模块的代码和数据装入内核，然后使用内核的符号表解析模块中任何未解析的符号
        * 与链接器不同，内核不会修改模块的磁盘文件，而仅仅修改内存中的副本
        * 依赖定义在kernel/module.c中的一个系统调用
        * sys_init_module给模块分配内核内存
        * 只有系统调用的名字前带有sys_前缀
        * modprobe
        * rmmod
        * lsmod
    * 版本依赖
        * linux/version.h
        * linux/module.h
            * UTS_RELEASE
            * LINUX_VERSION_CODE
            * KERNEL_VERSION(major, minor, release)

* 内核符号表
    * Linux内核头文件提供了一个方便的方法来管理符号对模块外部的可见性，从而减少了可能造成的名字空间污染
    * EXPORT_SYMBOL(name);
    * EXPORT_SYMBOL_GPL(name);

* 预备知识
    * 头文件：函数、数据类型和变量的定义
    * 所有模块代码中都包含的代码

            #include <linux/module.h>
            #include <linux/init.h>

    * module.h包含有可装载模块需要的大量符号和函数的定义
    * init.h的目的是指定初始化和清除函数
    * 内核能够识别的许可证
        * GPL
        * GPL v2
        * GPL and additional rights
        * Dual BSD/GPL
        * Dual MPL/GPL
        * Proprietary
        * 如果一个模块没有地标记为上述内核可识别的许可证，则会被假定是专有的
    * 描述性定义
        * MODULE_AUTHOR
        * MODULE_DESCRIPTION
        * MODULE_VERSION
        * MODULE_ALIAS
        * MODULE_DEVICE_TABLE

* 初始化和关闭
    * 初始化函数

            static int __int initialization_function(void)
            {
                /* 这里是初始化代码 */
            }
            module_init(initialization_function);

        * __init表明该函数仅在初始化期间使用
        * __initdata
    * 清除函数

            static void __exit cleanup_function(void)
            {
                /* 这里是清除代码 */
            }
            module_exit(cleanup_function);

        * __exit修饰词标记该代码仅用于模块卸载（编译器将把该函数放在特殊的ELF段中）
        * __exitdata
        * 如果一个模块未定义清除函数，则内核不允许卸载该模块
    * 初始化过程中的错误处理
        * 内核经常使用goto来处理错误
        * 不支持goto的使用，而是记录任何成功注册的设施，然后在出错的时候调用模块的清除函数
        * 模块的清除函数需要撤销初始化函数所注册的所有设施，并且习惯上以相反于注册的顺序撤销设施

* 模块参数
    * moduleparam.h
        * module_param
        * 变量的名称、类型以及用于sysfs入口项的访问许可掩码
    * 内核支持的模块参数类型
        * bool
        * invbool
        * charp
        * int
        * long
        * short
        * uint
        * ulong
        * ushort
    * module_param_array(name, type, num, perm);
    * 在用户空间编写驱动程序
        * 用户空间驱动程序优点
            * 可以和整个C库链接
            * 可以使用通常的调试器调试驱动程序代码
            * 如果用户空间驱动程序被挂起，则简单地杀掉它就行了
            * 和内核内存不同，用户内存可以换出
            * 良好设计的驱动程序仍然支持对设备的并发访问
            * 如果读者必须编写封闭源码的驱动程序，则用户空间驱动程序可更加容易地避免因为修改内核接口而导致的不明确的许可问题
    * libusb项目
        * libsub.sourceforge.net
    * gadgetfs
    * X服务器
    * 通常，用户空间的驱动程序被实现为一个服务器进程
    * 用户空间驱动程序缺点
        * 中断在用户空间中不可用
        * 只有通过mmap映射/dev/mem才能直接访问内存
        * 只有在调用ioperm或iopl后才可以访问I/O端口
        * 响应时间慢。需要上下文切换
        * 如果驱动程序被换出到磁盘，响应时间将令人难以忍受
        * 用户空间中不能处理一些非常重要的设备，包括网络接口和块设备等
