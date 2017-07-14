---
title: 《Linux设备驱动程序》第十一章 内核的数据类型读书笔记
tags:
  - Data Types
  - Driver
  - Kernel
  - Linux
  - Reading Note
id: 955
categories:
  - 学习笔记
date: 2012-06-27 19:06:38
---

* 简介
    * 由于Linux的多平台特性，任何一个重要的驱动程序都应该是可移植的
    * 与内核代码相关的核心问题是应该能够同时访问已知长度的数据项，并充分利用不同处理器的能力
    * 内核使用的数据类型主要被分成三类
        * 类似int这样的标准C语言类型
        * 类似u32这样的有确定大小的类型
        * 像pid_t这样的用于特定内核对象的类型
    * 本章将讨论在什么情况下使用这三种类型以及如何使用
* 使用标准C语言类型
    * 当我们需要“两个字节的填充符”或者“用四个字节字符串表示的某个东西”时，我们不能使用标准类型，因为在不同的体系架构上，普通C语言的数据类型所占空间在大小并不相同
    * 内核中的普通内存地址通常是unsigned long，在当前Linux支持的所有平台上，指针和long整形的大小总是相同的
    * C99标准定义了intptr_t和uintptr_t类型，它们是能够保存指针值的整形变量
* 为数据项分配确定的空间大小
    * &lt;asm/types.h&gt;
    * &lt;linux/types.h&gt;
    * u8, s8
    * u16, s16
    * u32, s32
    * u64, s64
    * 如果一个用户空间程序需要使用这些类型，它可以在名字前加上两个下划线作为前缀
    * __u8
    * __u32
    * 使用新编译器的系统将支持C99标准类型，如uint8_t和uint32_t

<!--more-->

* 接口特定的类型
    * 内核中最常用的数据类型由它们自己的typedef声明，这样可以防止出现任何移植性问题
    * “接口特定（interface-specific）”是指由某个库定义的一种数据类型，以便为某个特定的数据结构提供接口
    * 完整的_t类型在&lt;linux/types.h&gt;中定义
    * _t数据项的主要问题是在我们需要打印它们的时候，不太容易选择正确的printk或者printf的输出格式
* 其他有关移植的问题
    * 一个通用的原则是要避免使用显式的常量值
    * 时间间隔
        * 使用jiffies计算时间间隔的时候，应该用HZ来衡量
    * 页大小
        * 内存页的大小是PAGE_SIZE字节
        * PAGE_SHIFT
        * &lt;asm/page.h&gt;
        * getpagesize库函数
        * get_order函数
    * 字节序
        * &lt;asm/byteorder.h&gt;
            * __BIG_ENDIAN
            * __LITTLE_ENDIAN
        * u32 cpu_to_le32 (u32);
        * u32 le32_to_cpu(u32);
        * be64_to_cpu
        * le16_to_cpus
        * cpu_to_le32p
    * 数据对齐
        * &lt;asm/unaligned.h&gt;
            * get_unaligned(ptr);
            * put_unaligned(val, ptr);
    * 指针和错误值
        * 许多内核接口通过把错误值编码到一个指针值中来返回错误信息
        * &lt;linux/err.h&gt;
            * void *ERR_PTR(long error);
            * long IS_ERR(const void *ptr);
            * long PTR_ERR(const void *ptr);
* 链表
    * &lt;linux/list.h&gt;
        * struct list_head
            * struct list_head *next, *prev;
        * INIT_LIST_HEAD(&list);
        * LIST_HEAD(list);
        * list_add(struct list_head *new, struct list_head *head);
        * list_add_tail(struct list_head *new, struct list_head *head);
        * list_del(struct list_head *entry);
        * list_del_init(struct list_head *entry);
        * list_move(struct list_head *entry, struct list_head *head);
        * list_move_tail(struct list_head *entry, struct list_head *head);
        * list_empty(struct list_head *head);
        * list_splice(struct list_head *list, struct list_head *head);
        * list_entry(struct list_head *ptr, type_of_struct, field_name);
        * list_for_each(struct list_head *cursor, struct list_head *list)
        * list_for_each_prev(struct list_head *cursor, struct list_head *list)
        * list_for_each_safe(struct list_head *cursor, struct list_head *next, struct list_head *list)
        * list_for_each_entry(type *cursor, struct list_head *list, member)
        * list_for_each_entry_safe(type *cursor, type *next, struct list_head *list, member)
