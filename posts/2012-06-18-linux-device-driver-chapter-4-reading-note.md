---
title: 《Linux设备驱动程序》第四章 调试技术读书笔记
tags:
  - Debug
  - Driver
  - Linux
  - Reading Note
id: 909
categories:
  - 学习笔记
date: 2012-06-18 17:22:13
---

* 内核中的调试支持
    * CONFIG_DEBUG_KERNEL
    * CONFIG_DEBUG_SLAB
    * CONFIG_DEBUG_PAGEALLOC
    * CONFIG_DEBUG_SPINLOCK
    * CONFIG_DEBUG_SPINLOCK_SLEEP
    * CONFIG_INIT_DEBUG
    * CONFIG_DEBUG_INFO
    * CONFIG_MAGIC_SYSRQ
    * CONFIG_DEBUG_STACKOVERFLOW
    * CONFIG_DEBUG_STACK_USAGE
    * CONFIG_KALLSYMS
    * CONFIG_IKCONFIG
    * CONFIG_IKCONFIG_PROC
    * CONFIG_ACPI_DEBUG
    * CONFIG_DEBUG_DRIVER
    * CONFIG_SCSI_CONSTANTS
    * CONFIG_INPUT_EVBUG
    * CONFIG_PROFILING


<!--more-->


* 通过打印调试
    * printk
        * 通过附加不同日志级别，可让printk对消息进行分类
        * &lt;linux/kernel.h&gt;
            * KERN_EMERG
            * KERN_ALERT
            * KERN_CRIT
            * KERN_ERR
            * KERN_WARNING
            * KERN_NOTICE
            * KERN_INFO
            * KERN_DEBUG
        * 默认级别是DEFAULT_MESSAGE_LOGLEVEL
            * 2.6.10内核中，默认级别是KERN_WARNING
        * /proc/sys/kernel/printk
            * 4个整数值
            * 当前的日志级别、未明确指定日志级别时的默认消息级别、最小允许的日志级别以及引导时的默认日志级别
    * 重定向控制台消息
    * 消息如何被记录
        * printk函数将消息写到一个长度为__LOG_BUF_LEN字节的循环缓冲区中
        * 唤醒正在等待消息的进程，或者正在读取/proc/kmsg的进程
        * 可以在任何地方调用printk，甚至在中断处理函数里也可以调用，而且对数据量的大小没有限制
        * klogd
        * syslogd
        * /etc/syslog.conf
    * 开启及关闭消息
        * 定义一个宏，在需要时，这个宏展开为一个printk(printf)调用
            * 可以通过在宏名字中删除或增加一个字母来启用或禁用每一条打印语句
            * 在编译前修改CFLAGS变量，则可以一次禁用所有消息
            * 同样的打印语句可以在内核代码中也可以在用户级代码使用
    * 速度限制
        * /proc/sys/kernel/printk_ratelimit
        * /proc/sys/kernel/printk_ratelimit_burst
    * 打印设备编号
        * &lt;linux/kdev_t.h&gt;
            * int print_dev_t(char *buffer, dev_t dev);
            * char *format_dev_t(char *buffer, dev_t dev);
* 通过查询调试
    * syslogd
        * 试图把每件事情都记录到磁盘上，以在系统万一崩溃时最后的记录信息能反应崩溃前的状况
    * 可以使用如下方法对系统进行查询
        * 在/proc文件系统中创建文件、使用驱动程序的ioctl方法，以及通过sysfs导出属性等
    * 使用/proc文件系统
        * /proc文件系统是一种特殊的、由软件创建的文件系统，内核使用它向外界导出信息
        * /proc下面的每个文件都绑定于一个内核函数，用户其中的文件时，该函数动态地生成文件的“内容”
        * 在/proc中实现文件
            * &lt;linux/proc_fs.h&gt;
            * 实现一个函数创建一个只读的/proc文件
                * int (*read_proc)(char *page, char **start, off_t offset, int count, int *eof, void *data);
                * 当没有数据可返回时，必须设置eof这个参数
                * 返回少量数据的简单read_proc方法可忽略start参数，复杂的read_proc方法会将*start设置为页面，并将所请求偏移量处的数据放到内存页中
                * seq_file
        * 创建自己的/proc文件
            * 需要经与一个/proc入口项连接起来
            * struct proc_dir_entry *create_proc_read_entry(const char *name, mode_t mode, struct proc_dir_entry *base, read_proc_t *read_proc, void *data);
            * remove_proc_entry(const char *name, struct proc_dir_entry *base);
            * 有个经常约定，要求把设备驱动程序对应的/proc入口项转移到子目录driver/中
            * 在卸载模块时，/proc中的入口项也应被删除
            * 不鼓励使用/proc文件
    * seq_file接口
        * 创建一个简单的迭代器对象
        * &lt;linux/seq_file.h&gt;
        * 建立四个迭代器对象：start、next、stop、show
            * void *start(struct seq_file *sfile, loff_t *pos);
            * void *next(struct seq_file *sfile, void *v, loff_t *pos);
            * void stop(struct seq_file *sfile, void *v);
            * int show(struct seq_file *sfile, void *v);
                * int seq_printf(struct seqfile *sfile, const char *fmt, ...);
                * int seq_putc(struct seqfile *sfile, char c);
                * int seq_puts(struct seqfile *sfile, const char *s);
                * int seq_escape(struct seqfile *m, const char *s, const char *esc);
                * int seq_path(struct seq_file *sfile, struct vfsmount *m, struct dentry *dentry, char *esc);
        * static struct seq_operations seq_ops ={.start=start, .next=next, .stop=stop, .show=show};
        * static int proc_open(struct inode *inode, struct file *file){return seq_open(file, &seq_ops);}
        * static struct file_operations proc_ops = {.owner=THIS_MODULE, .open=proc_open, .read=seq_read, .llseek=seq_lseek, .release=seq_release};
        * entry = create_proc_entry("seq", 0, NULL);
        * entry-&gt;proc_fops = &proc_ops;
        * struct proc_dir_entry *create_proc_entry(const char *name, mode_t mode, struct proc_dir_entry *parent);
    * ioctl方法
        * 接收一个“命令”号以及另一个（可选的）参数
* 通过监视调试
    * strace命令是一个功能非常强大的工具，它可以显示由用户空间程序所发出的所有系统调用
        * -t: 用来显示调用发生的时间
        * -T: 显示调用所花费的时间
        * -e: 限定被跟踪的调用类型
        * -o: 将输出重定向到一个文件中
        * 默认情况下，strace将跟踪信息打印到stderr上
        * strace也可以跟踪一个正在运行的进程
* 调试系统故障
    * oops消息
        * 因为对NULL指针取值或使用了其他不正确的指针值
    * 系统挂起
        * SysRq魔法键
            * ALT+RsyRq
            * /proc/sys/kernel/sysrq
            * /proc/sysrq-trigger
* 调试器和相关工具
    * 使用gdb
        * gdb /usr/src/linux/vmlinux /proc/kcore
            * 第一个参数是未经压缩的内核ELF可执行文件的名字
            * 第二个参数是core文件的名字
        * 为了让gdb使用内核的符号信息，我们必须在打开CONFIG_DEBUG_INFO选项的情况下编译内核
        * 对于调试会话来说，模块相关的代码段只有下面三个
            * .text: 包含了模块的可执行代码
            * .bss, .data: 这两个代码段保存模块的变量，编译时未初始化的变量保存在.bss段，经过初始化的保存在.data段
        * 代码段的地址：/sys/module/&lt;module name&gt;/sections/.*
        * (gdb) add-symbol-file hello.ko 0xe0a27000 -s .bss 0xe0a28d00 -s .data 0xe0a279e0
    * kdb内核调试器
        * 打补丁，oss.sgi.com下载
        * 在控制台上按下Pause（或Bread）键将启动调试
    * kgdb补丁
        * 将运行调试内核的系统和运行调试器的系统隔离开来而工具，而这两个系统之间通过串吕线连接
        * 两个独立的补丁
            * 第一个kgdb补丁可以-mm内核树中找到
            * 还可以使用http://kgdb.sf.net/上的补丁
    * 用户模式的Linux虚拟机
    * Linux跟踪工具包
        * LLT（Linux Trace Toolkit）是一个内核补丁，包含了一组可以用于内核事件跟踪的相关工具集
        * http://www.opersys.com/LTT
    * 动态探测
        * DProbes（Dynamic Probes）是IBM为基于IA-32架构的Linux发布的一种调试工具
        * http://dprobes.sourceforge.net/
