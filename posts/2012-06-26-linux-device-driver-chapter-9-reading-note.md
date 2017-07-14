---
title: 《Linux设备驱动程序》第九章 与硬件通信读书笔记
tags:
  - Commuication
  - Driver
  - Hardware
  - Linux
  - Reading Note
id: 949
categories:
  - 学习笔记
date: 2012-06-26 14:59:31
---

* 简介
    * 本章主要介绍对设备提供I/O访问的方法和函数，用于从设备读取数据或将数据写入到设备
    * 主要的方法有I/O端口和I/O内存
* I/O端口和I/O内存
    * 每种外设都通过读写寄存器进行控制
    * 在硬件层，内存区域和I/O区域没有概念上的区别：它们都通过向地址总线和控制总线发送电平信号进行访问，再通过数据总线读写数据
    * I/O寄存器和常规内存
        * I/O寄存器和RAM的最主要区别就是I/O操作具有边际效应，而内存操作则没有
            * 内存写操作的唯一结果就是在指定位置存储一个数值
            * 内存读操作则仅仅返回指定位置最后一次写入的数值
        * 由硬件自身缓存引起的问题很好解决：只要把底层硬件配置成在访问I/O区域时禁止硬件缓存即可
        * 由编译器优化和硬件重新排序引起的问题的解决办法是：对硬件必须以特定顺序执行的操作之间设置内存屏障
        * Linux提供了4个宏来解决所有可能的排序问题
            * &lt;linux/kernel.h&gt;
                * void barrier(void);
            * &lt;asm/system.h&gt;
                * void rmb(void);
                * void read_barrier_depends(void);
                * void wmb(void);
                * void mb(void);
                * void smp_rmb(void);
                * void smp_read_barrier_depends(void);
                * void smp_wmb(void);
                * void smp_mb(void);
        * 因为内存屏障会影响系统性能，所以应该只用于真正需要的地方

<!--more-->

* 使用I/O端口
    * I/O端口是驱动程序与许多设备之间的通信方式
    * I/O端口分配
        * &lt;linux/ioport.h&gt;
            * struct resource *request_region(unsigned long first, unsigned long n, const char *name);
            * void release_region(unsigned long start, unsigned long n);
            * int check_region(unsigned long first, unsigned long n);
        * 所有的端口分配可从/proc/ioports中得到
    * 操作I/O端口
        * 大多数硬件会把8位、16位和32位的端口区分开来
        * &lt;asm/io.h&gt;
            * unsigned inb(unsigned port);
            * void outb(unsigned char byte, unsigned port);
            * unsigned inw(unsigned port);
            * void outw(unsigned short word, unsigned port);
            * unsigned inl(unsigned port);
            * void outl(unsigned longword, unsigned port);
        * 即使在64位的体系架构上，端口地址空间也只使用最大32位的数据通路
    * 在用户空间访问I/O端口
        * &lt;sys/io.h&gt;
        * 如果要在用户空间代码中使用inb及其相关函数，必须满足下面的条件
            * 编译程序时必须带-O选项来强制内联函数的展开
            * 必须用ioperm或iopl系统调用来获取对端口进行I/O操作的权限。ioperm用来获取对单个端口的操作权限，而iopl用来获取对整个I/O空间的操作权限
            * 必须以root身份运行该程序才能调用ioperm或iopl，或者进程的祖先进程之一已经以root身份获取对端口的访问
    * 串操作
        * void insb(unsigned port, void *addr, unsigned long count);
        * void outsb(unsigned port, void *addr, unsigned long count);
        * void insw(unsigned port, void *addr, unsigned long count);
        * void outsw(unsigned port, void *addr, unsigned long count);
        * void insl(unsigned port, void *addr, unsigned long count);
        * void outsl(unsigned port, void *addr, unsigned long count);
    * 暂停式I/O
        * 在处理器试图从总线上快速传输数据时，某些平台会遇到问题
        * 当处理器时钟相比外设时钟快时就会出现问题，并且在设备板卡特别慢时表现出来
        * 解决办法是在每条I/O指令之后，如果还有其他类似指令，则插入一个小的延迟
        * 在x86平台上，这种暂停可通过对端口0x80的一条out b指定实现，或者通过使用忙等待实现
        * 暂停式的I/O函数：inb_p、outb_p等
    * 平台相关性
        * I/O指令是与处理器密切相关的
        * IA-32 (x86), x86_64
            * 该体系架构支持本章提到的所有函数，端口号的类型是unsigned short
        * IA-64 (itanium)
            * 支持所有函数，端口类型是unsigned long（映射到内存）
        * ARM
            * 端口映射到内存，支持所有函数，端口类型是unsigned int
* I/O端口示例
    * 数据I/O端口最常见的形式是一个字节宽度的I/O区域，它或者映射到内存，或者映射到端口
    * 并口简介
        * 并口的最小配置由3个8位端口组成
        * PC标准中第一个并口的I/O端口是从地址0x378开始，第二个端口是从地址0x278开始
        * 第一个端口是一个双向的数据寄存器，直接连接到物理连接器的2-9号引脚上
        * 第二个端口是一个只读的状态寄存器，当并口连接到打印机时，该寄存器报告打印机的状态
        * 第三个端口是一个只用于输出的控制寄存器，它的作用之一是控制是否启用中断
        * 在并行通信中使用的电平信号是标准的TTL电平：0伏和5伏，逻辑阈值大约为1.2伏
* 使用I/O内存
    * 和设备通信的另一种主要机制是通过使用映射到内存的寄存器或设备内存
    * I/O内存分配和映射
        * &lt;linux/ioport.h&gt;
            * struct resource *request_mem_region(unsigned long start, unsigned long len, char *name);
            * void release_mem_region(unsigned long start, unsigned long len);
            * int check_mem_region(unsigned long start, unsigned long len);
        * /proc/iomem
        * 获取I/O内存并不仅仅意味着可引用对应的指针，我们必须首先建立映射，映射的建立由ioremap函数完成
        * &lt;asm/io.h&gt;
            * void *ioremap(unsigned long phys_addr, unsigned long size);
            * void *ioremap_nocache(unsigned long phys_addr, unsigned long size);
            * void iounmap(void *addr);
    * 访问I/O内存
        * 访问I/O内存的正确方法是通过一组专用函数
        * &lt;asm/io.h&gt;
            * unsigned int ioread8(void *addr);
            * unsigned int ioread16(void *addr);
            * unsigned int ioread32(void *addr);
            * void iowrite8(u8 value, void *addr);
            * void iowrite16(u16 value, void *addr);
            * void iowrite32(u32 value, void *addr);
            * void ioread8_rep(void *addr, void *buf, unsigned long count);
            * void ioread16_rep(void *addr, void *buf, unsigned long count);
            * void ioread32_rep(void *addr, void *buf, unsigned long count);
            * void iowrite8_rep(void *addr, const void *buf, unsigned long count);
            * void iowrite16_rep(void *addr, const void *buf, unsigned long count);
            * void iowrite32_rep(void 8addr, const void *buf, unsigned long count);
            * void memset_io(void *addr, u8 value, unsigned int count);
            * void memcpy_fromio(void *dest, void *source, unsigned int count);
            * void memcpy_toio(void *dest, void *source, unsigned int count);
            * unsigned readb(address);
            * unsigned readw(address);
            * unsigned readl(address);
            * void writeb(unsinged value, address);
            * void writew(unsigned value, address);
            * void writel(unsigned value, address);
        * addr应该是从ioremap获得的地址
    * 像I/O内存一样使用端口
        * void *ioport_map(unsigned long port, unsigned int count);
            * 该函数重新映射count个I/O端口，使其看起来像I/O内存，驱动程序可在该函数返回的地址上使用ioread8及其同类函数
        * void ioport_unmap(void *addr);
    * 1MB地址空间之下的ISA内存
        * ISA内存段的内存范围在640KB到1MB之间，出现在常规RAM的中间
