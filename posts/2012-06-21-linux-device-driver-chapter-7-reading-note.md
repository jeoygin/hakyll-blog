---
title: 《Linux设备驱动程序》第七章 时间、延迟及延缓操作读书笔记
tags:
  - Driver
  - Latency
  - Linux
  - Reading Note
  - time
  - Timer
id: 936
categories:
  - 学习笔记
date: 2012-06-21 20:42:50
---

* 度量时间差
    * 内核通过定时器中断来跟踪时间流
    * 时钟中断由系统定时硬件以周期性的间隔产生，这个间隔由内核根据HZ的值设定，在常见的x86 PC平台上，默认定义为1000
    * &lt;linux/param.h&gt;
    * &lt;linux/timex.h&gt;
    * jiffies_64
    * unsigned long jiffies
    * 使用jiffies计数器
        * &lt;linux/jiffies.h&gt;
            * int time_after(unsigned long a, unsigned long b);
            * int time_before(unsigned long a, unsigned long b);
            * int time_after_eq(unsigned long a, unsigned long b);
            * int time_before_eq(unsigned long a, unsigned long b);
        * 通常只需要包含&lt;linux/sched.h&gt;
        * diff = (long)t2  -(long)t1
        * msec = diff * 1000 / HZ
        * &lt;linux/times.h
            * unsigned long timespec_to_jiffies(struct timespec *value);
            * void jiffies_to_timespec(unsigned long jiffies, struct timespec *value);
            * unsigned long timeval_to_jiffies(struct timeval *value);
            * void jiffies_to_timeval(unsigned long jiffies, struct timeval *value);
        * u64 get_jiffies_64(void);
        * &lt;linux/types.h&gt;
        * proc/interrupts
    * 处理器特定的寄存器
        * 最有名的计数器寄存器就是TSC
        * &lt;asm/msr.h&gt;
            * rdtsc(low32, high32);
            * rdtscl(low32);
            * rdtscl1(var64);
        * &lt;linux/timex.h&gt;
            * cycles_t get_cycles(void);
        * \#define rdtscl(dest) __asm__ __volatile__("mfs0 %0,$9; nop" : "=r" (dest))
<!--more-->
* 获取当前时间
    * 内核提供将墙钟时间转换为jiffies值的函数
    * &lt;linux/time.h&gt;
        * unsigned long mktime(unsigned int year, unsigned int mon, unsigned int day, unsigned int hour, unsigned int min, unsigned int sec);
        * void do_gettimeofday(struct timeval *tv);
        * struct timespec current_kernel_time(void);
* 延迟执行
    * 长延迟
        * 忙等待
            * while (time_before(jiffies, j1)) cpu_relax();
        * 让出处理器
            * 在不需要CPU时主动释放CPU
            * &lt;linux/sched.h&gt;
            * while (time_before(jiffies, j1)) schedule();
        * 超时
            * &lt;linux/wait.h&gt;
                * long wait_event_timeout(wait_queue_head_t q, condition c, long timeout);
                * long wait_event_interruptible_timeout(wait_queue_head_t q, condition c, long timeout);
                * timeout值表示的是要等的jiffies值，而不是绝对时间值
                * 如果超时到期，两个函数返回0；如果进程由其他事件唤醒，则返回剩余的延迟实现
            * &lt;linux/sched.h&gt;
                * signed long schedule_timeout(signed long timeout);
                * set_current_state(TASK_INTERRUPTIBLE);
                * schedule_timeout(delay);
    * 短延迟
        * &lt;linux/delay.h&gt;
            * void ndelay(unsigned long nsecs);
            * void udelay(unsigned long usecs);
            * void mdelay(unsigned long msecs);
            * 这三个延迟函数均是忙等待函数
            * unsigned long msleep_interruptible(unsigned int millisecs);
            * void ssleep(unsigned int seconds);
* 内核定时器
    * 一个内核定时器是一个数据结构，它告诉内核在用户定义的时间点使用用户定义的参数来执行一个用户定义的函数
    * 内核定时器常常是作为“软件中断”的结果而运行的
    * 如果处于进程上下文之外，则必须遵守如下规则
        * 不允许访问用户空间
        * current指针在原子模式下是没有任何意义的，也是不可用的
        * 不能执行休眠或调度
    * &lt;asm/hardirq.h&gt;
        * in_interrupt()
        * in_atomic()
    * 任务可以将自己注册以在稍后的时间重新运行
    * 即使在单处理器系统上，定时器也会是竞态的潜在来源
    * 定时器API
        * &lt;linux/timer.h&gt;
            * struct timer_list
                * unsigned long expires;
                * void (*function)(unsigned long);
                * unsigned long data;
            * void init_timer(struct timer_list *time);
            * struct timer_list TIMER_INITIALIZER(_function, _expires, _data);
            * void add_timer(struct timer_list *timer);
            * int del_timer(struct timer_list *timer);
            * expires字段表示期望定时器执行的jiffies值
            * int mod_timer(struct timer_list *timer, unsigned long expires);
            * int del_timer_sync(struct timer_list *timer);
            * int timer_pending(const struct timer_list *timer);
    * 内核定时器的实现
        * 内核定时器的实现要满足如下需求及假定
            * 定时器的管理必须尽可能做到轻量级
            * 其设计必须在活动定时器大量增加时具有很好的伸缩性
            * 大部分定时器会在最多几秒或者几分钟内到期，而很少存在长期延迟的定时器
            * 定时器应该在注册它的同一CPU上运行
        * 不管何时内核代码注册了一个定时器，其操作最终会由internal_add_timer（定义在kernel/timer.c）执行
        * 级联表的工作方式如下
            * 如果定时器在接下来的0～255的jiffiew中到期，由该定时器就会被添加到256个链表中的一个（取决于expires字段的低8位值）
            * 如果定时器在较远的未来到期（但在16384个jiffies之前），则该定时器会被添加到64个链表之一（取决于expires字段的9～14位）
            * 对更远将来的定时器，相同的技巧用于15~20位、21~26位以及27～31位
            * 如果定时器的expires字段代表了更远的未来，则利用延迟0xfffffff做散列运算，而在过去时间内到期的定时器会在下一个定时器滴答时被调度
        * 当__run_times被激发时，它会执行当前定时器滴答上的所有挂起的定时器
* tasklet
    * 中断管理中大量使用了这种机制
    * 始终在中断期间运行，始终会在调度它的同一CPU运行，接收一个unsigned long参数
    * 不能要求tasklet在某个给定时间执行
    * &lt;linux/interrupt.h&gt;
        * struct tasklet_struct
            * void (*func)(unsigned long);
            * unsigned long data;
        * void tasklet_init(struct tasklet_struct *t, void (*func)(unsigned long), unsigned long data);
        * DECLARE_TASKLET(name, func, data);
        * DECLARE_TASKLET_DISABLED(name, func, data);
    * 有意思的特性
        * 一个tasklet可以稍后被禁止或者重新启用；只有启用的次数和禁止的次数相同时，tasklet才会被执行
        * 和定时器类似，tasklet可以注册自己本身
        * tasklet可被调度以在通常的优先级或者高优先级执行
        * 如果系统负荷不重，则tasklet会立即得到执行，但始终不会晚于下一个定时器滴答
        * 一个tasklet可以和其他tasklet并发，但对自身来讲是严格串行处理的
    * void tasklet_disable(struct tasklet_struct *t);
    * void tasklet_disable_nosync(struct tasklet_struct *t);
    * void tasklet_enable(struct tasklet_struct *t);
    * void tasklet_schedule(struct tasklet_struct *t);
    * void tasklet_hi_schedule(struct tasklet_struct *t);
    * void tasklet_kill(struct tasklet_struct *t);
    * tasklet的实现在kernel/softirq.c中
* 工作队列
    * 与tasklet区别
        * tasklet在软件中断上下文中运行，因此，所有的tasklet代码都必须是原子的。相反，工作队列函数在一个特殊内核进程的上下文中运行，因此它们具有更好的灵活性。尤其是，工作队列函数可以休眠
        * tasklet始终运行在被初始提交的同一处理器上，但这只是工作队列的默认方式
        * 内核代码可以请求工作队列函数的执行延迟给定的时间间隔
    * 工作队列函数可具有更长的延迟并且不必原子化
    * &lt;linux/workqueue.h&gt;
        * struct workqueue_struct
        * struct workqueue_struct *create_workqueue(const char *name);
        * struct workqueue_struct *create_singlethread_workqueue(const char *name);
        * struct work_struct
        * DECLARE_WORK(name, void (*function)(void*), void *data);
        * INIT_WORK(struct work_struct *work, void (*function)(void *), void *data);
        * PREPARE_WORK(struct work_struct *work, void (*function)(void *), void *data);
        * int queue_work(struct workqueue_struct *queue, struct work_struct *work);
        * int queue_delayed_work(struct workqueue_struct *queue, struct work_struct *work, unsigned long delay);
        * 以上两个函数返回值为非零时意味着给定的work_struct结构已经等待在该队列中
        * int cancel_delayed_work(struct work_struct *work);
            * 该入口项在开始执行前被取消，则返回非零值
        * void flush_workqueue(struct workqueue_struct *queue);
        * void destroy_workqueue(struct workqueue_struct *queue);
    * 共享队列
        * int schedule_work(struct work_struct *work);
        * void flush_scheduled_work(void)
