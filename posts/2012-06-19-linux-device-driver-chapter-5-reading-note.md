---
title: 《Linux设备驱动程序》第五章 并发和竞态读书笔记
tags:
  - Concurrency
  - Driver
  - Linux
  - Race Conditions
  - Reading Note
id: 915
categories:
  - 学习笔记
date: 2012-06-19 16:09:45
---

* 并发及其管理
    * 竞态通常作为对资源的共享访问结果而产生
    * 当两个执行线程需要访问相同的数据结构（或硬件资源）时，混合的可能性就永远存在
    * 只要可能就应该避免资源的共享
    * 共享通常是必需的，硬件资源本质上就是共享的
    * 访问管理的常见技术称为“锁定”或者“互斥”
* 信号量和互斥体
    * 建立临界区：在任意给定的时刻，代码只能被一个线程执行
    * 可以使用一种锁定机制，当进程在等待对临界区的访问时，此机制可让进程进入休眠状态
    * 最合适的机制是信号量（semaphore）
    * 一个信号量本质上是一个整数值，它和一对函数联合使用，这一对函数通常称为P和V
    * 当信号量用于互斥时，信号量的值应初始化为1，这种信号量有时也称为“互斥体（mutex）”
    * Linux信号量的实现
        * &lt;asm/semaphore.h&gt;
        * struct semaphore;
        * void sema_init(struct semaphore *sem, int val);
        * DECLARE_MUTEX(name);
            * 称为name的信号量变量被初始化为1
        * DECLARE_MUTEX_LOCKED(name);
            * 称为name的信号量变量被初始化为0
        * void init_MUTEX(struct semaphore *sem);
        * void init_MUTEX_LOCKED(struct semaphore *sem);
        * void down(struct semaphore *sem);
            * 一直等待
        * int down_interruptible(struct semaphore *sem);
            * 操作是可中断的
            * 如果操作被中断，该函数会返回非零值
        * int down_trylock(struct semaphore *sem);
            * 永远不会休眠
            * 如果信号量在调用时不可获得，会立即返回一个非零值
        * void up(struct semaphore *sem);
    * 读取者/写入者信号量
        * 一些任务只需要读取受保护的数据结构，而其他的则必须做出修改
        * Linux内核提供了一种特殊的信号量类型，称为“rwsem”
        * &lt;linux/rwsem.h&gt;
        * struct rw_semaphore;
        * void init_rwsem(struct rw_semaphore *sem);
        * void down_read(struct rw_semaphore *sem);
            * 只读访问，可和其他读取者并发地访问
        * int down_read_trylock(struct rw_semaphore *sem);
            * 在授予访问时返回非零，其他情况下返回零
        * void up_read(struct rw_semaphore *sem);
        * void down_write(struct rw_semaphore *sem);
        * int down_write_trylock(struct rw_semaphore *sem);
        * void up_write(struct rw_semaphore *sem);
        * void downgrade_write(struct rw_semaphore *sem);
        * 最好在很少需要写访问且写入者只会短期拥有信号量的时候使用rwsem


<!--more-->


* completion
    * 内核编程中常见的一种模式是，在当前线程之外初始化某个活动，然后等待该活动的结束
    * &lt;linux/completion.h&gt;
    * DECLARE_COMPLETION(my_completion);
    * init_completion(struct completion *c);
    * void wait_for_completion(struct completion *c);
        * 非中断的等待
    * void complete(struct completion *c);
    * void complete_all(struct completion *c);
    * 一个completion通常是一个单次（one-shot）设备
    * 如果没有使用complete_all，可以重复使用一个complete结构
    * 如果使用了complete_all，则必须在重复使用该结构之前重新初始化它
    * INIT_COMPLETE(struct completion c);
    * void complete_and_exit(struct completion *c, long retval);
* 自旋锁
    * 自旋锁可在不能休眠的代码中使用，比如中断处理例程
    * 可提供比信号量更高的性能
    * 一个自旋锁是一个互斥设备，它只能有两个值：锁定和解锁
    * 通常实现为某个整数值中的单个位
    * 如果锁可用，则“锁定”位被设置，而代码继续进入临界区
    * 如果锁被其他人获得，则代码进入忙循环并重复检查这个锁，直到该锁可用为止，这个循环就是自旋锁的“自旋”部分
    * “测试并设置”的操作必须以原子方式完成
    * 在超线程处理器上，还必须仔细处理以避免死锁，超线程处理器可实现多个虚拟的CPU，它们共享单个处理器核心及缓存
    * 自旋锁API介绍
        * &lt;linux/spinlock.h&gt;
        * spinlock_t
        * spinlock_t my_lock = SPIN_LOCK_UNLOCKED;
        * void spin_lock_init(spinlock_t *lock);
        * void spin_lock(spinlock_t *lock);
            * 不可中断
            * 在获得锁之前一直处于自旋状态
        * void spin_unlock(spinlock_t *lock);
    * 自旋锁和原子上下文
        * 任何拥有自旋锁的代码都必须是原子的，不能休眠，不能因为任何原因放弃处理器，除了服务中断之外
    * 自旋锁函数
        * void spin_lock(spinlock_t *lock);
        * void spin_lock_irqsave(spinlock_t *lock, unsigned long flags);
            * 在获得自旋锁之前禁止中断，而先前的中断状态保存在flags中
        * void spin_lock_irq(spinlock_t *lock);
        * void spin_lock_bh(spinlock_t *lock);
            * 在获得锁之前禁止软件中断
        * void spin_unlock(spinlock_t *lock);
        * void spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags);
            * flags参数必须是传递给spin_lock_irqsave的同一个变量
        * void spin_unlock_irq(spinlock_t *lock);
        * void spin_unlock_bh(spinlock_t *lock);
        * int spin_trylock(spinlock_t *lock);
            * 成功时返回非零值，否则返回零
        * int spin_trylock_bh(spinlock_t *lock);
            * 成功时返回非零值，否则返回零
    * 读取值/写入者自旋锁
        * &lt;linux/spinlock.h&gt;
        * rwlock_t
        * rwlock_t my_rwlock = RW_LOCK_UNLOCKED;
        * void rwlock_init(rwlock_t * lock);
        * void read_lock(rwlock_t *lock);
        * void read_lock_irqsave(rwlock_t *lock, unsigned long flags);
        * void read_lock_irq(rwlock_t *lock);
        * void read_lock_bh(rwlock_t *lock);
        * void read_unlock(rwlock_t *lock);
        * void read_unlock_irqrestore(rwlock_t *lock, unsigned long flags);
        * void read_unlock_irq(rwlock_t *lock);
        * void read_unlock_bh(rwlock_t *lock);
        * void write_lock(rwlock_t *lock);
        * void write_lock_irqsave(rwlock_t *lock, unsigned long flags);
        * void write_lock_irq(rwlock_t *lock);
        * void write_lock_bh(rwlock_t *lock);
        * int write_trylock(rwlock_t *lock);
        * void write_unlock(rwlock_t *lock);
        * void write_unlock_irqrestore(rwlock_t *lock, unsigned long flags);
        * void write_unlock_irq(rwlock_t *lock);
        * void write_unlock_bh(rwlock_t *lock);
        * 读取者/写入者锁可能造成读取者饥饿
* 锁陷阱
    * 不明确的规则
        * 不论是信号量还是自旋锁，都不允许锁拥有者第二次获得这个锁，如果试图这样做，系统将挂起
    * 锁的顺序规则
        * 在必须获取多个锁时，应该始终以相同的顺序获得
        * 如果必须获得一个局部锁以及一个属于内核更中心位置的锁，则应该首先获取自己的局部锁
        * 如果拥有信号量和自旋锁的组合，则必须首先获得信号量
    * 细粒度锁和粗粒度锁的对比
        * 细粒度锁具有良好的伸缩性
        * 细粒度锁将带来某种程序的复杂性
        * 应该在最初使用粗粒度的锁
        * 使用lockmeter工具可度量内核花费在锁上的时间
            * http://oss.sgi.com/projects/lockmeter/
* 除了锁之外的方法
    * 免锁算法
        * 经常用于免锁的生产者/消费者任务的数据结构之一是循环缓冲区
    * 原子变量
        * &lt;asm/atomic.h&gt;
        * atomic_t
        * 一个atomic_t变量保存一个int值，但不能记录大于24位的整数
        * void atomic_set(atomic_t *v, int i);
        * atomic_t v = ATOMIC_INIT(0);
        * int atomic_read(atomic_t *v);
        * void atomic_add(int i, atomic_t *v);
        * void atomic_sub(int i, atomic_t *v);
        * void atomic_inc(atomic_t *v);
        * void atomic_dec(atomic_t *v);
        * int atomic_inc_and_test(atomic_t *v);
        * int atomic_dec_and_test(atomic_t *v);
        * int atomic_sub_and_test(int i, atomic_t *v);
        * int atomic_add_negative(int i, atomic_t *v);
        * int atomic_add_return(int i, atomic_t *v);
        * int atomic_sub_return(int i, atomic_t *v);
        * int atomic_inc_return(atomic_t *v);
        * int atomic_dec_return(atomic_t *v);
        * 需要多个atomic_t变量的操作，仍然需要某种类型的锁
    * 位操作
        * &lt;asm/bitops.h&gt;
        * nr参数通常被定义为int，但在少数架构上被定义为unsigned long
        * void set_bit(nr, void *addr);
        * void clear_bit(nr, void *addr);
        * void change_bit(nr, void *addr);
        * test_bit(nr, void *addr);
        * int test_and_set_bit(nr, void *addr);
        * int test_add_clear_bit(nr, void *addr);
        * int test_and_change_bit(nr, void *addr);
    * seqlock
        * 允许读取者对资源的自由访问，但需要读取者检查是否和写入者发生冲突
        * &lt;linux/seqlock.h&gt;
        * seqlock_t
        * seqlock_t lock1 = SEQLOCK_UNLOCKED;
        * void seqlock_init(seqlock_t *lock);
        * unsigned int read_seqbegin(seqlock_t *lock);
        * int read_seqretry(seqlock_t *lock, unsigned int seq);
        * unsigned int read_seqbegin_irqsave(seqlock_t *lock, unsigned long flags);
        * int read_seqretry_irqrestore(seqlock_t *lock, unsigned int seq, unsigned long flags);
        * void write_seqlock(seqlock_t *lock);
        * void write_sequnlock(seqlock_t *lock);
        * void write_seqlock_irqsave(seqlock_t *lock, unsigned long flags);
        * void write_seqlock_irq(seqlock_t *lock);
        * void write_seqlock_bh(seqlock_t *lock);
        * void write_sequnlock_irqrestore(seqlock_t *lock, unsigned long flags);
        * void write_sequnlock_irq(seqlock_t *lock);
        * void write_sequnlock_bh(seqlock_t *lock);
    * 读取-复制-更新
        * read-copy-update（RCU）也是一种高级的互斥机制
        * 很少在驱动程序中使用
        * http://www.rdrop.com/users/paulmck/rclock/intro/rclock_intro.html
        * 针对经常发生读取而很少写入的情形做了优化
        * 被保护的资源应该通过指针访问
        * 在需要修改该数据结构时，写入线程首先复制，然后修改副本，之后用新的版本替代相关指针。当确信老的版本没有其他引用时，就可释放老的版本
        * &lt;linux/rcupdate.h&gt;
        * rcu_read_lock
        * rcu_read_unlock
        * void call_rcu(struct rcu_head *head, void (*func)(void *arg), void *arg);
