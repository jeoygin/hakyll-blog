---
title: 《Linux设备驱动程序》第六章 高级字符驱动程序操作读书笔记
tags:
  - Advanced Character
  - Driver
  - Linux
  - Operation
  - Reading Note
id: 932
categories:
  - 学习笔记
date: 2012-06-21 15:48:34
---

* ioctl
    * 支持的操作
        * 简单数据传输
        * 用户空间请求设备锁门
        * 弹出介质
        * 报告错误信息
        * 改变波特率
        * 执行自破坏
    * int ioctl(int fd, unsigned long cmd, ...);
    * 每个ioctl命令就是一个独立的系统调用，而且是非公开的
    * 驱动程序的ioctl方法原型
        * int (*ioctl) (struct inode *inode, struct file *filp, unsigned int cmd, unsigned long arg);
    * 选择ioctl命令
        * 为方便程序员创建唯一的ioctl命令号，每一个命令号被分为多个位字段
        * Linux内核的约定方法为驱动程序选择ioctl编号
            * include/asm/ioctl.h
                * 定义了要使用的位字段
                    * 类型（幻数）
                    * 序数
                    * 传送方向
                    * 参数大小
            * Documentation/ioctl-number.txt
                * 罗列了内核所使用的幻数
        * &lt;linux/ioctl.h&gt;
            * type
                * 幻数，这个字段有8位宽（_IOC_TYPEBITS）
            * number
                * 序数，8位宽（_IOC_NRBITS）
            * direction
                * _IOC_NONE（没有数据传输）
                * _IOC_READ
                * _IOC_WRITE
                * _IOC_READ | _IOC_WRITE（双向传输数据）
            * size
                * 所涉及的用户数据大小
                * 通常是13位或14位
                * _IOC_SIZEBITS
        * &lt;asm/ioctl.h&gt;
            * _IO(type, nr)
                * 用于构造无参数的命令编号
            * _IOR(type, nr, datatype)
                * 用于构造从驱动程序中读取数据的命令编号
            * _IOW(type, nr, datatype)
                * 用于构造写入数据的命令
            * _IOWR(type, nr, datatype)
                * 用于双向传输
            * _IOC_DIR(nr)
            * _IOC_TYPE(nr);
            * _IOC_NR(nr)
            * _IOC_SIZE(nr);
    * 返回值
        * ioctl的实现通常就是一个基于命令号的switch语句
        * 不能匹配任何合法的操作？
            * 有些内核函数会返回-EINVAL
            * POSIX标准规定，如果使用了不合适的ioctl命令参数，应该返回-ENOTTY
    * 预定义命令
        * 预定义命令分为三组
            * 可用于任何文件（普通、设备、FIFO和套接字）的命令
            * 只用于普通文件的命令
            * 特定于文件系统类型的命令
        * 设备驱动程序开发人员只对第一组感兴趣，它们的幻数都是“T"
        * FIOCLEX
            * 设置执行时关闭标志
        * FIONCLEX
            * 清除执行时关闭标志
        * FIOASYNC
            * 设置或复位文件异步通知
            * 这两个动作都可以通过fcntl完成，实际上没有人会使用FIOASYNC
        * FIOQSIZE
            * 返回文件或目录的大小
        * FIONBIO
            * 文件ioctl非阻塞型I/O
    * 使用ioctl参数
        * &lt;asm/uaccess.h&gt;
            * int access_ok(int type, const void *addr, unsigned long size);
            * type
                * VERIFY_READ
                * VERIFY_WRITE
            * addr
                * 用户地址空间
            * size
                * 字节数
            * 返回一个布尔值：1表示成功，0表示失败
            * 如果返回失败，驱动程序通常要返回-EFAULT给调用者
            * put_user(datum, ptr);
            * __put_user(datum, ptr);
            * get_user(local, ptr);
            * __get_user(local, ptr);
    * 权能与受限操作
        * 基于权能（capability）的系统把特权操作划分为独立的组
        * capget
        * capset
        * &lt;linux/capability.h&gt;
            * CAP_DAC_OVERRIDE
                * 超过文件或目录的访问限制的能力
            * CAP_NET_ADMIN
                * 执行网络管理任何的能力
            * CAP_SYS_MODULE
                * 载入或卸除内核模块的能力
            * CAP_SYS_RAWIO
                * 执行“裸”I/O操作的能力
            * CAP_SYS_ADMIN
                * 截获的能力
            * CAP_SYS_TTY_CONFIG
                * 执行tty配置任务的能力
        * &lt;sys/sched.h&gt;
            * int capable(int capability);
<!--more-->
* 阻塞型I/O
    * 休眠的简单介绍
        * 当一个进程被置入休眠时，它会被标记为一种特殊状态并从调度器的运行队列中移走
        * 永远不要在原子上下文中进入休眠
        * 如果代码在拥有信号量时休眠，任何其他等待该信号量的线程也会休眠，因此任何拥有信号量而休眠的代码必须很短，并且还要确保拥有信号量并不会阻塞唤醒我们自己的那个进程
        * 当我们被唤醒时，我们永远无法知道休眠了多长时间，或者休眠期间都发生了些什么事情
        * 在Linux中，一个等待队列通过一个“等待队列头（wait queue head）”来管理
            * &lt;linux/wait.h&gt;
            * wait_queue_head_t
            * DECLARE_WAIT_QUEUE_HEAD(name);
            * wait_queue_head_t my_queue;
            * init_waitqueue_head(&my_queue);
    * 简单休眠
        * wait_event(queue, condition);
        * wait_event_interruptible(queue, condition);
        * wait_event_timeout(queue, condition, timeout);
        * wait_event_interruptible_timeout(queue, condition, timeout);
        * void wake_up(wait_queue_head_t *queue);
        * void wake_up_interruptible(wait_queue_head_t *queue);
    * 阻塞和非阻塞型操作
        * 显式的非阻塞I/O由filp-&gt;f_flags中的O_NONBLOCK标志决定
        * &lt;linux/fcntl.h&gt;
            * 自动包含在&lt;linux/fs.h&gt;中
        * 在执行阻塞型操作的情况下，应该实现下列动作以保持和标准语义一致
            * 如果一个进程调用了read但是还没有数据可读，此进程必须阻塞
            * 如果一个进程调用了write但缓冲区没有空间，此进程必须阻塞，而且必须休眠在与读取进程不同的等待队列上
    * 高级休眠
        * 进程如何休眠
            * 将进程置于休眠的第一个步骤通常是分配并初始化一个wait_queue_t结构，然后将其加入到对应的等待队列
            * 第二个步骤是设置进程的状态，将其标记为休眠
                * &lt;linux/sched.h&gt;
                * TASK_RUNNING
                * TASK_INTERRUPTIBLE
                * TASK_UNINTERRUPUTIBLE
                * void set_current_state(int new_state);
            * 放弃处理器是最后的步骤，但在此之前还要做另外一件事情：我们必须首先检查休眠等待的条件
                * if (!condition) schedule();
        * 手工休眠
            * &lt;linux/sched.h&gt;
            * DEFINE_WAIT(my_wait);
            * wait_queue_t my_wait;
            * init_wait(&my_wait);
            * void prepare_to_wait(wait_queue_head_t *queue, wait_queue_t *wait, int state);
                * state是进程的新状态，应该是TASK_INTERRUPTIBLE或TASK_UNINTERRUPTIBLE
            * schedule();
            * void finish_wait(wait_queue_head_t *queue, wait_queue_t *wait);
        * 独占等待
            * 当某个进程在等待队列上调用wake_up时，所有等待在该队列上的进程都被置为可运行状态
            * 只会有一个被唤醒的进程可以获得期望的资源，而其他被唤醒的进程只会再次休眠
            * 一个独占等待的行为和通常的休眠类似，但有如下两个重要的不同
                * 等待队列入口设置了WQ_FLAG_EXCLUSIVE标志时，则会被添加到等待队列的尾部
                * 在某个等待队列上调用wake_up时，它会在唤醒第一个具有WQ_FLAG_EXCLUSIVE标志的进程之后停止唤醒其他进程
            * 如果满足下面两个条件，在驱动程序中利用独占等待是值得考虑的
                * 对某个资源存在严重竞争，并且唤醒单个进程就能完整消耗该资源
            * void prepare_to_wait_exclusive(wait_queue_head_t *queue, wait_queue_t *wait, int state);
        * 唤醒的相关细节
            * &lt;linux/wait.h&gt;
            * wake_up(wait_queue_head_t *queue);
                * 唤醒队列上所有非独占等待的进程，以及单个独占等待者
            * wake_up_interruptible(wait_queue_head_t *queue);
                * 会跳过不可中断休眠的那些进程
            * wake_up_nr(wait_queue_head_t *queue, int nr);
                * 只会唤醒nr个独占等待进程
            * wake_up_interruptible_nr(wait_queue_head_t *queue, int nr);
                * 只会唤醒nr个独占等待进程
            * wake_up_all(wait_queue_head_t *queue);
            * wake_up_interruptible_all(wait_queue_head_t *queue);
            * wake_up_interruptible_sync(wait_queue_head_t *queue);
        * 旧的历史：sleep_on
            * void sleep_on(wait_queue_head_t *queue);
            * void interruptible_sleep_on(wait_queue_head_t *queue);
            * 永远不要使用它们
* poll和select
    * poll、select和epoll系统调用
    * poll、select和epoll的功能本质上是一样的：都允许进程决定是否可以对一个或多个打开的文件做非阻塞的读取或写入
    * select在BSD Unix中引入
    * poll由System V引入
    * unsigned int (*poll) (struct file *filp, poll_table *wait);
    * poll_table结构，用于在内核中实现poll、select及epool系统调用
    * &lt;linux/poll.h&gt;
    * void poll_wait(struct file *, wait_queue_head_t *, poll_table *);
    * poll方法执行的第二项任务是返回描述哪个操作可以立即执行的位掩码
        * &lt;linux/poll.h&gt;
        * POLLIN
            * 如果设备可以无阻塞地读取，就设置该位
        * POLLRDNORM
            * 如果“通常”的数据已经就绪，可以读取，就设置该位
            * 一个可读设备返回（POLLIN|POLLRDNORM）
        * POLLRDBAND
            * 这一位指示可以从设备读取out-of-band的数据
        * POLLPRI
            * 可以无阻塞地读取高优先级的数据
        * POLLHUP
            * 当读取设备的进程到达文件尾时，驱动程序必须设置POLLHUP位
        * POLLERR
            * 设备发生了错误
        * POLLOUT
            * 如果设备可以无阻塞地写入，就在返回值中设置该位
        * POLLWRNORM
            * 该位和POLLOUT的意义一样，有时其实就是同一个数字
            * 一个可写的设备将返回（POLLOUT|POLLWRNORM）
        * POLLWRBAND
            * 与POLLRDBAND类似，这一位表示具有非零优先级的数据可以被写入设备
        * POLLRDBAND和POLLWRBAND只在与套接字相关的文件描述符中才是有意义的，设备驱动程序通常用不到这两个标志
    * 与read和write的交互
        * 从设备读取数据
            * 如果输入缓冲区有数据，那么即使就绪的数据比程序所请求的少，并且驱动程序保证剩下的数据马上就能到达，read调用仍然应该以难以察觉的延迟立即返回
            * 如果缓冲区中没有数据，那么默认情况下read必须阻塞等待，直到至少有一个字节到达；如果设置了O_NONBLOCK标志，read应立即返回，返回值是-EAGAIN。poll必须报告设备不可读
            * 如果已经到达文件尾，read应该立即返回0，此时poll应该报告POLLHUP
        * 向设备写数据
            * 如果输出缓冲区中有空间，则write应该无延迟地立即返回，在这种情况下，poll报告设备可写
            * 如果输出缓冲区已满，那么默认情况下write被阻塞直到有空间释放；如果设置了O_NONBLOCK标志，write应立即返回，返回值是-EAGAIN。poll必须报告设备不可写
            * 永远不要让write调用在返回前等待数据的传输结束
        * 刷新待处理输出
            * int (*fsync) (struct file *file, struct dentry *dentry, int datasync);
            * 如果应用程序需要确保数据已经被传送到设备上，就必须fsync方法
            * datasync用于区分fsync和fdatasync这两个系统调用
    * 底层的数据结构
        * poll_table结构是构成实际数据结构的一个简单封装，包含poll_table_entry结构的内存页链表
        * 每个poll_table_entry结构包括一个指向被打开设备的struct file类型的指针、一个wait_queue_head_t指针以及一个关联的等待队列入口
        * 如果轮询（poll）时没有一个驱动程序可以进行非阻塞I/O，这个poll调用者就进入休眠，直到休眠在其上的某个（或多个）等待队列唤醒它为止
        * poll实现中的珍上有趣之处是，驱动程序的poll方法在被调用者时为plol_table参数传递NULL指针。
        * 在poll调用结束时，poll_table结构被重新分配，所有的先前添加到poll表中的等待队列入口都会从这个表以及等待队列中移除
* 异步通知
    * 为了启用文件袋异步通知机制，用户程序必须执行两个步骤
        * 首先，它们指定一个进程作为文件的属主，当进程使用fcntl系统调用执行F_SETOWN命令时，属主进程的进程ID号就被保存在filp-&gt;f_owner中
        * 然后，用户程序必须在设备中设备FASYNC标志，通过fcntl的F_SETFL命令完成的
    * 例子
        * struct sigaction action;
        * memset(&action, 0, sizeof(action));
        * action.sa_handler = sighandler;
        * action.sa_flags = 0;
        * sigaction(SIGIO, &action, NULL);
        * fcntl(STDIN_FILENO, F_SETOWN, getpid());
        * oflags = fcntl(STDIN_FILENO, F_GETFL);
        * fcntl(STDIN_FILENO, F_SETFL, oflags | FASYNC);
    * 从驱动程序的角度考虑
        * 从内核角度来看的详细操作过程
            * F_SETOWN被调用时对filp-&gt;f_owner赋值，此外什么也不做
            * 在执行F_SETFL启用FASYNC时，调用驱动程序的fasync方法，只要filp-&gt;f_flags中的FASYNC标志发生了变化，就会调用该方法，以便把这个变化通知驱动程序，使其能正确响应
            * 当数据到达时，所有注册为异步通知的进程都会被发送一个SIGIO信号
        * &lt;linux/fs.h&gt;
        * struct fasync_struct
        * int fasync_helper(int fd, struct file *filp, int mode, struct fasync_struct **fa);
        * void kill_fasync(struct fasync_struct **fa, int sig, int band);
            * sig通常是SIGIO
            * band通常是POLL_IN，等价于POLLIN|POLLRDNORM
        * 某些设备也针对设备可写入而实现了异步通知，在这种情况下，kill_fasync必须以POLL_OUT为模式调用
        * 当文件关闭时必须的调用fasync方法
* 定位设备
    * llseek实现
        * 如果设备操作未定义llseek方法，内核默认通过修改filp-&gt;f_pos而执行定位
        * 如果定位操作对应于设备的一个物理操作，可能就需要提供自己的llseek方法
        * 如果定位设备是没有意义的，应该在open方法中调用nonseekable_open，通知内核设备不支持llseek
        * int nonseekable_open(struct inode *inode, struct file *filp);
        * 还应该将file_operations结构中的llseek方法设置为特殊的辅助函数no_llseek
* 设备文件的访问控制
    * 独享设备
        * 最生硬的访问控制方法是一次只允许一个进程打开设备
    * 限制每次只由一个用户访问
        * 需要两个数据项
            * 一个打开计数
            * 设备属主的UID
        * current-&gt;uid
        * current-&gt;euid
    * 替代EBUSY的阻塞型open
        * 当设备不能访问时返回一个错误，通常这是最合理的方式，但有些情况下可能需要让进程等待设备
    * 在打开时复制设备
        * 另一个实现访问控制的方法是，在进程打开设备时创建设备的不同私有副本
