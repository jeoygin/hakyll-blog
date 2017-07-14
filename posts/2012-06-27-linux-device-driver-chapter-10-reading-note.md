---
title: 《Linux设备驱动程序》第十章 中断处理读书笔记
tags:
  - Driver
  - Interrupt
  - Linux
  - Reading Note
id: 952
categories:
  - 学习笔记
date: 2012-06-27 16:37:25
---

* 简介
    * 通常，很多设备的处理速度要比处理器慢得多，为了不让处理器一直等待外部事件，可以采用中断来让设备在产生事件时通知处理器
    * 中断仅仅是一个信号，由硬件发出
* 准备并口
    * 在没有节设定产生中断之前，并口是不会产生中断的
    * 并口的标准规定设置端口2（px37a、0x27a或者其它端口）的第4位将启用中断报告，0x10
    * 当处于启用中断状态，每当引脚10的电平发生从低到高改变时，并口就会产生一个中断
    * 引脚9是并口数据字节中的最高位
* 安装中断处理例程
    * 中断信号线是非常珍贵且有限的资源
    * 内核维护了一个中断信号线的注册表，该注册表类似于I/O端口的注册表
    * 模块在使用中断前要先请求一个中断通道，然后在使用后释放该通道
    * &lt;linux/sched.h&gt;
        * int request_irq(unsigned int irq, irqreturn_t (*handler) (int, void *, struct pt_regs *), unsigned long flags, const char *dev_name, void *dev_id);
            * 返回0表示申请成功
            * flags
                * SA_INTERRUPT
                    * 表明这是一个“快速”的中断处理例程
                * SA_SHIRQ
                    * 表示中断可以在设备之间共享
                * SA_SAMPLE_RANDOM
                    * 指出产生的中断能对/dev/random设备和/dev/urandom设备使用的熵池（entropy pool）有贡献
        * void free_irq(unsigned int irq, void *dev_id);
        * int can_request_irq(unsigned int irq, unsigned long flags);
    * 使用request_irq的正确位置应该是在设备第一次打开、硬件被告知产生中断之前
    * 调用free_irq的位置是最后一次关闭设备、硬件被告知不用再中断处理器之后
    * /proc接口
        * /proc/interrupts
            * 不依赖体系结构
        * /proc/stat
            * 依赖体系结构
        * 当前x86体系结构上定义的中断数量是224，可以从头文件include/asm-386/irq.h中得到解释
    * 自动检测IRQ号
        * 内核帮助下的探测
            * &lt;linux/interrupt.h&gt;
                * unsigned long probe_irq_on(void);
                * int probe_irq_off(unsigned long);
        * DIY探测
    * 快速和慢速处理例程
        * 快速中断执行时，当前处理器上的其他所有中断都被禁止
        * x86平台上中断处理的内幕
            * arch/i386/kernel/irq.c
            * arch/i386/kernel/apic.c
            * arch/i386/kernel/entry.S
            * arch/i386/kernel/i8259.c
            * include/asm-i386/hw_irq.h
            * IRQ的探测是通过为每个缺少中断处理例程的IRQ设置IRQ_WAITING状态位来完成的

<!--more-->

* 实现中断处理例程
    * 中断处理例程是在中断时间内运行的，因此它的行为会受到一些限制
        * 不能向用户空间发送或者接收数据
        * 不能做作任何可能发生休眠的操作
        * 不能调用schdule函数
    * 将有关中断接收到信息反馈给设备，并根据正在服务的中断的不同含义对数据进行相应的读或写
        * 通常做清除接口卡上的一个位，大多数硬件设备在它们的“interrupt-pending（中断挂起）”位被清除之前不会产生其他的中断
    * 中断处理例程的一个典型任务就是：如果中断通知进程所等待的事件已经发生，比如新的数据到达，就会唤醒在该设备上休眠的进程
    * 处理例程的参数及返回值
        * int irq是中断号
        * void *dev_id是一种客户数据类型（即驱动程序可用的私有数据）
        * struct pt_reg *regs很少使用，它保存了处理器进入中断代码之前的处理器上下文快照
        * 中断处理例程应该返回一个值，用来指明是否真正处理了一个中断，如果处理例程发现其设备的确需要处理，则应该返回IRQ_HANDLED，否则，返回值应该是IRQ_NONE
    * 启用和禁用中断
        * 有时设备驱动程序必须在一个时间段内阻塞中断的发出，如拥有自旋锁的时候阻塞中断
        * 禁用单个中断
            * &lt;asm/irq.h&gt;
                * void disable_irq(int irq);
                * void disable_irq_nosync(int irq);
                * void enable_irq(int irq);
            * diables_irq不但会禁止给定的中断，而且也会等待当前正在执行的中断处理例程完成
            * 如果调用disable_irq的线程拥有任何中断处理例程需要的资源（比如自旋锁），则系统会死锁
        * 禁用所有的中断
            * &lt;asm/system.h&gt;
                * void local_irq_save(unsigned long falsg);
                * void local_irq_disable(void);
                * void local_irq_restore(unsigned long flags);
                * void local_irq_enable(void)
* 顶半部和底半部
    * 顶半部，是实际响应中断的例程，也就是用request_irq注册的中断例程
    * 底半部，是一个被顶半部调度，并在稍后更安全的时间内执行的例程
    * 当底半部处理例程执行时，所有的中断都是打开的
    * 典型的情况是顶半部保存设备的数据到一个设备特定的缓冲区并调度它的底半部
    * tasklet
        * tasklet可以被多次调度运行，但tasklet的调度并不会累积
        * 如果驱动程序有多个tasklet，必须使用某种锁机制来避免彼此间的冲突
        * tasklet可确保和第一次调度它们的函数运行在同样的CPU上
        * 必须使用宏DECLARE_TASKLET声明tasklet
            * DECLARE_TASKLET(name, function, data);
            * void do_tasklet(unsigned long);
            * DECLARE_TASKLET(test_tasklet, do_tasklet, 0);
            * tasklet_schedule($test_tasklet);
    * 工作队列
        * 工作队列函数运行在进程上下文中，因此可以必要时休眠
        * 不能从工作队列向用户空间复制数据
* 中断共享
    * PC上的IRQ信号灯线不能为一个以上的设备服务
    * 现代硬件已经能谲诈中断的共享了，PCI总线就要求外设可共享中断
    * 安装共享的处理例程
        * 共享的中断也是通过request_irq安装的，但是有两处不同
            * 请求中断时，必须指定flags参数中的SA_SHIRQ位
            * dev_id参数必须是唯一的，任何指向模块地址空间的指针都可以使用，但dev_id不能设置成NULL
        * 请求一个共享中断时，如果满足下面条件之一，那么request_irq就会成功
            * 中断信号线空闲
            * 任何已经注册了该中断信号线的处理例程也标识了IRQ是共享的
        * 使用共享处理例程的驱动程序需要小心一件事情：不能使用enable_irq和disable_irq
    * 运行处理例程
        * 当内核收到中断时，所有已注册的处理例程都将被调用
        * 一个共享中断处理例程必须能够将要处理的中断和其他设备产生的中断区分开来
    * /proc接口和共享的中断
        * 在系统上安装共享的中断处理例程不会对/proc/stat造成影响，它甚至不知道哪些处理例程是共享的，但是，/proc/interrupts会稍许改变
* 中断驱动的I/O
    * 如果与驱动程序管理的硬件之间的数据传输因为某种原因被延迟的话，驱动程序作者就应该实现缓冲
    * 数据缓冲区有助于将数据的传送和接收与系统调用write和read分离开来，从而提高系统的整体性能
    * 一个好的缓冲机制需要用中断驱动的I/O
    * 要正确进行中断驱动的数据传输，要求硬件 应该能按照下面的语义来产生中断
        * 对于输入来说，当新的数据已经到达并且处理器准备接收它时，设备就中断处理器
        * 对于输出来说，当设备准备好接收新数据或者对成功的数据传送进行应答时，就要发出中断
