---
title: 《Linux设备驱动程序》第三章 字符设备驱动程序读书笔记
ags:
  - Character Device
  - Driver
  - Linux
  - Reading Note
id: 902
categories:
  - 学习笔记
date: 2012-06-15 19:36:36
---

* 主设备号和次设备号
    * 那些名称被称为特殊文件、设备文件，或者简单称之为文件系统树的节点，它们通常位于/dev目录
    * 通常而言，主设备号标识设备对应的驱动程序
    * 一个主设备号对应一个驱动程序
    * 设备编号的内部表达
        * dev_t(&lt;linux/types.h&gt;)
        * dev_t是一个32位的数，12位表示主设备号，其余20位表示次设备号
        * &lt;linux/kdev_t.h&gt;
            * MAJOR(dev_t dev);
            * MINOR(dev_t dev);
            * MKDEV(int major, int minor);
    * 分配和释放设备编号
        * &lt;linux/fs.h&gt;
            * int register_chrdev_region(dev_t first, unsigned int count, char *name);
            * int alloc_chrdev_region(dev_t *dev, unsigned int firstminor, unsigned int count, char *name);
            * void u nregister_chrdev_resion(dev_t first, unsigned int count);
    * 动态分配主设备号
        * 驱动程序应该始终使用alloc_chrdev_region而不是register_chrdev_region函数
        * 缺点是：由于分配的主设备号不能保证始终一致，所以无法预先创建设备节点
        * /proc/devices
        * 分配主设备号的最佳方式
            * 默认采用动态分配，同时保留在加载甚至是编译时指定主设备号的余地


<!--more-->


* 一些重要的数据结构
    * 三个重要的内核数据结构
        * file_operations
        * file
        * inode
    * 文件操作
        * file_operations结构用来将驱动程序操作连接到设备编号
        * &lt;linux/fs.h&gt;
        * file_operations结构或者指向这类结构的指针称为fops
            * 每个字段必须指向驱动程序中实现特定操作的函数
        * struct module *owner
        * loff_t (*llseek) (struct file *, loff_t, int);
        * ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
        * ssize_t (*aio_read) (struct kiocb *, char __user *, size_t, loff_t);
        * ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
        * ssize_t (*aio_write) (struct kiocb *, const char __user *, size_t, loff_t *);
        * int (*readdir) (struct file *, ,void *, filldir_t);
        * unsigned int (*poll) (struct file *, struct poll_table_struct *);
        * int (*ioctl) (struct inode *, struct file *, unsigned int, unsigned long);
        * int (*mmap) (struct file *, struct vm_area_struct *);
        * int (*open) (struct inode *, struct file *);
        * int (*flush) (struct file *);
        * int (*release) (struct inode *, struct file *);
        * int (*fsync) (struct file *, struct dentry *, int);
        * int (*aio_fsync) (struct kiocb *, int);
        * int (*fasync) (int, struct file *, int);
        * int (*lock) (struct file *, int, struct file_lock *);
        * ssize_t (*readv) (struct file *, const struct iovec *, unsigned long, loff_t *);
        * ssize_t (*writev) (struct file *, const struct iovec *, unsigned long, loff_t *);
        * ssize_t (*sendfile) (struct file *, loff_t *, size_t, read_actor_t, void *);
        * ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
        * unsigned long (*get_unmapped_area) (struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
        * int (*check_flags) (int)
        * int (*dir_notify) (struct file *, unsigned long);
    * file结构
        * file结构代表一个打开的文件
        * &lt;linux/fs.h&gt;
        * 与用户空间程序中的FILE没有任何关联
        * 指向struct file的指针通常被称为file或filp
        * 字段
            * mode_t f_mode
            * loff_t f_pos
            * unsigned int f_flags
            * struct file_operations *f_op
            * void *private_data
            * struct dentry *f_dentry
    * inode结构
        * 内核用inode结构在内部表示文件
        * 对单个文件，可能会有许多个表示打开的文件描述符的file结构
        * 字段
            * dev_t i_rdev
            * struct cdev *i_cdev
* 字符设备的注册
    * &lt;linux/cdev.h&gt;
    * 获取一个独立的cdev结构
        * struct cdev *my_cdev = cdev_alloc();
        * my_cdev-&gt;ops = &my_fops;
        * owner
    * struct cdev *cdev_alloc(void);
    * void cdev_init(struct cdev *cdev, struct file_operations *fops);
    * int cdev_add(struct cdev *dev, dev_t num, unsigned int count);
    * void cdev_del(struct cdev *dev);
* open和release
    * open方法
        * 主要工作
            * 检查设备特定的错误
            * 如果设备是首次打开，则对其进行初始化
            * 如有必要，更新f_op指针
            * 分配并填写置于flip-&gt;private_data里的数据结构
        * int (*open)(struct inode *inode, struct file *filp);
        * &lt;linux/kernel.h&gt;
            * container_of(pointer, continer_type, container_field);
    * release方法
        * 主要工作
            * 释放由open分配的、保存在filp-&gt;private_data中的所有内容
            * 在最后一次关闭操作时关闭设备
* scull的内存使用
    * &lt;linux/slab.h&gt;
        * void *kmalloc(size_t size, int flags);
        * void kfree(void *ptr);
        * 不应该将非kmalloc返回的指针传递给kfree
        * 将NULL指针传递给kfree是合法的
* read和write
    * ssize_t read(struct file *filp, char __user *buff, size_t count, loff_t *offp);
    * ssize_t write(struct file *filp, const char __user *buff, size_t count, loff_t *offp);
    * 内核代码不能直接引用用户空间的指针
        * 随着驱动程序所运行的架构的不同或者内核配置的不同，在内核模式中运行时，用户空间的指针可能是无效的
        * 即使该指针在内核空间中代表相同的东西，但用户空间的内存是分页的，而在系统调用被调用时，涉及到的内存可能根本不在RAM中
        * 用户空间的指针由用户程序提供，该程序可能存在缺陷或者是个恶意程序
    * 访问用户空间的缓冲区应始终通过内核提供的专用函数完成
        * &lt;asm/uaccess.h&gt;
        * unsigned long copy_to_user(void __user *to, const void * from, unsigned long count)
        * unsigned long copy_from_user(void *to, const void __user *from, unsigned long count);
    * 访问用户空间的任何函数都必须是可重入的，必须能和其他驱动程序函数并发执行，必须处于能够合法休眠的状态
    * read方法
        * 如果返回值等于传递read系统调用的count参数，则说明所请求的字节数传输成功完成了
        * 如果返回值是正的，但比count小，说明部分数据传输成功
        * 如果返回值为，则表示已经到达了文件尾
        * 负值意味着发生了错误，该值指明了发生了什么错误，错误码在&lt;linux/error.h&gt;中定义
        * 现在还没有数据，但以后可能会有
    * write方法
    * readv和writev
        * ssize_t (*readv) (struct file * filp, const struct iovec *iov, unsigned long count, loff_t *ppos);
        * ssize_t (*writev) (struct file *filp, const struct iovec *iov, unsigned long count, loff_t *ppos);
        * iovec结构
            * void __user *iov_base;
            * __kernel_size_t iov_len;
* 试试新设备
    * printk
    * strace
