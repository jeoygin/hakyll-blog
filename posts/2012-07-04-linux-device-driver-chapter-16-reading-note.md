---
title: 《Linux设备驱动程序》第十六章 块设备驱动程序读书笔记
tags:
  - Block Drivers
  - Driver
  - Linux
  - Reading Note
id: 971
categories:
  - 学习笔记
date: 2012-07-04 15:10:21
---

* 简介
    * 一个块设备驱动程序主要通过传输固定大小的随机数据来访问设备
    * Linux内核视块设备为与字符设备相异的基本设备类型
    * Linux块设备驱动程序接口使得块设备可以发挥其最大的功效，但是其复杂程序又是编程者必须面对的一个问题
    * 一个数据块指的是固定大小的数据，而大小的值由内核确定
    * 数据块的大小通常是4096个字节，但是可以根据体系结构和所使用的文件系统进行改变
    * 与数据块对应的是扇区，它是由底层硬件决定大小的一个块，内核所处理的设备扇区大小是512字节
    * 如果要使用不同的硬件扇区大小，用户必须对内核的扇区数做相应的修改
* 注册
    * 注册块设备驱动程序
        * &lt;linux/fs.h&gt;
        * int register_blkdev(unsigned int major, const char *name);
            * 如果需要的话分配一个动态的主设备号
            * 在/proc/devices中创建一个入口项
        * int unregister_blkdev(unsigned int major, const char *name);
    * 注册磁盘
        * struct block_device_operations
            * int (*open) (struct inode *inode, struct file *filp);
            * int (*release) (struct inode *inode, struct file *filp);
            * int (*ioctl) (struct inode *inode, struct file *filp, unsigned int cmd, unsigned long arg);
            * int (*media_changed) (struct gendisk *gd);
            * int (*revalidate_disk) (struct gendisk *gd);
            * struct module *owner;
        * gendisk结构
            * &lt;linux/genhd.h&gt;
            * struct gendisk
                * int major;
                * int first_minor;
                * int minors;
                    * 常取16
                * char disk_name[32]
                    * 显示在/proc/partitions和sysfs中
                * struct block_device_operations *fops;
                * struct request_queue *queue;
                * int flags;
                * sector_t capacity;
                * void *private_data;
            * struct gendisk *alloc_disk(int minors);
            * void del_gendisk(struct gendisk *gd);
            * void add_disk(struct gendisk *gd);

<!--more-->

* 块设备操作
    * open和release函数
        * 对于那些操作实际硬件设备的驱动程序，open和release函数可以设置驱动程序和硬件的状态。这些操作包括使磁盘开始或者停止旋转，锁住可移动介质的仓门以及分配DMA缓存等
        * 有一些操作能够让块设备在用户空间内被直接打开，这些操作包括给磁盘分区，或者在分区上创建文件系统，或者运行文件系统检查程序
    * 对可移动介质的支持
        * 调用media_changed函数以检查介质是否被改变
        * 在介质改变后将调用revalideate函数
    * ioctl函数
        * 高层的块设备子系统在驱动程序获得ioctl命令前，已经截取了大量的命令
        * 实际上在一个现代驱动程序中，许多ioctl命令根本就不用实现
* 请求处理
    * 每个块设备驱动程序的核心是它的请求函数
    * request函数介绍
        * void request(request_queue_t *queue);
            * 当内核需要驱动程序处理读取、写入以及其他对设备的操作时，就会调用该函数
        * 每个设备都有一个请求队列
            * dev-&gt;queue = blk_init_queue(test_request, &dev-&gt;lock);
        * 对request函数的调用是与用户空间进程中的动作完全异步的
    * 一个简单的request函数
        * struct request * elv_next_request(request_queue_t queue);
        * void end_request(struct request *req, int succeeded);
        * struct request
            * sector_t secotr;
            * unsigned long nr_sectors;
            * char *buffer
            * rq_data_dir(struct request *req);
    * 请求队列
        * 一个块设备请求队列可以这样描述：包含块设备I/O请求的序列
        * 请求队列跟踪未完成的块设备的I/O请求
        * 请求队列还实现了插件接口
        * I/O调度器还负责合并邻近的请求
        * 请求队列拥有request_queue或request_queue_t结构类型
        * &lt;linux/blkdev.h&gt;
        * 队列的创建与删除
            * request_queue_t *blk_init_queue(request_fn_proc *request, spinlock_t *lock);
            * void blk_cleanup_queue(request_queue_t *queue);
        * 队列函数
            * struct request *elv_next_request(request_queue_t *queue);
            * void blkdev_dequeue_request(struct request *req);
            * void elv_requeue_request(request_queue_t *queue, struct request *req);
        * 队列控制函数
            * void blk_stop_queue(request_queue_t *queue);
            * void blk_start_queue(request_queue_t *queue);
            * void blk_queue_bounce_limit(request_queue_t *queue, u64 dma_addr);
            * void blk_queue_max_sectors(request_queue_t *queue, unsigned short max);
            * void blk_queue_max_phys_segments(request_queue_t *queue, unsigned short max);
            * void blk_queue_max_hw_segments(request_queue_t *queue, unsigned short max);
            * void blk_queue_max_segment_size(request_queue_t *queue, unsigned short max);
            * void blk_queue_segment_boundary(request_queue_t *queue, unsigned long mask);
            * void blk_queue_dma_alignment(request_queue_t *queue, int mask);
            * void blk_queue_hardsect_size(request_queue_t *queue, unsigned short max);
        * 请求过程剖析
            * 从本质上讲，一个request结构是作为一个bio结构的链表实现的
            * bio结构
                * bio结构包含了驱动程序执行请求的全部信息，而不必与初始化这个请求的用户空间的进程相关联
                * &lt;linux/bio.h&gt;
                * struct bio
                    * sector_t bi_sector;
                    * unsigned int bi_size;
                    * *以字节为单位所需要传输的数据大小
                    * unsigned long bi_flags;
                    * unsigned short bio_phys_segments;
                    * unsigned short bio_hw_segments;
                    * struct bio_vec *bi_io_vec
                * struct bio_vec
                    * struct page *vb_page;
                    * unsigned int bv_len;
                    * unsigned int bv_offset;
                * example
                    * int segno;
                    * struct bio_vec *bvec;
                    * bio_for_each_segment(bvec, bio, segno)
                    * {
                    * */* 使用该段进行一定的操作 */
                    * }
                * char *__bio_kmap_atomic(struct bio *bio, int i, enum km_type type);
                * void __bio_kunmap_atomic(char *buffer, enum km_type type):
                * struct page *bio_page(struct bio *bio);
                * int bio_offset(struct bio *bio);
                * int bio_cur_sectors(struct bio *bio);
                * char *bio_data(struct bio *bio);
                * char *bio_kmap_irq(struct bio *bio, unsigned long *flags);
                * void bio_kunmap_irq(char *buffer, unsigned long *flags);
            * request结构成员
                * struct request
                    * sector_t hard_sector;
                    * unsigned long hard_nr_sectors;
                    * unsigned int hard_cur_sectors;
                    * struct bio *bio;
                    * char *buffer;
                    * unsigned short nr_phys_segments;
                    * struct list_head queuelist;
            * 屏障请求
                * 在驱动程序接收到请求前，块设备层重新组合了请求以提高I/O性能
                * 出于同样的目的，驱动程序也可以重新组合请求
                * 但在无限制重新组合请求时面临了一个问题：一些应用程序的某些操作，要在另外一些操作开始前完成
                * 2.6版本的块设备层使用屏障（barrier）请求来解决这个问题
                * 如果一个请求被设置了REQ_HARDBARRER标志，那么在其他后续请求被初始化前，它必须被写入驱动器
                * void blk_queue_ordered(request_queue_t *queue, int flag);
                * int blk_barrier_rq(sruct request *req);
                    * 如果返回一个非零值，该请求是一个屏障请求
            * 不可重试请求
                * int blk_noretry_request(struct request *req);
        * 请求完成函数
            * int end_that_request_first(struct request *req, int success, int count);
            * void end_that_request_last(struct request *req);
            * example
                * void end_request(struct request *req, int uptodate)
                * {
                    * if (!end_that_request(req, uptodate, req-&gt;hard_cur_sectors)
                    * {
                    * *add_disk_randomness(req-&gt;rq_disk);
                    * *blkdev_dequeue_request(req);
                    * *end_that_request_last(req);
                    * }
                * }
            * 使用bio
                * example
                    * struct request *req
                    * struct bio *bio;
                    * rq_for_each_bio(bio, req) 
                    * {
                    * */* 使用该bio结构进行一定的操作 */
                    * }
            * 块设备请求和DMA
                * int blk_rq_map_sg(request_queue_t *queue, struct request *req, struct scatterlist *list);
                * clear_bit(QUEUE_FLAG_CLEAR, &queue-&gt;queue_flags);
            * 不使用请求队列
                * typedef int (make_request_fn) (request_queue_t *q, struct bio *bio);
                * void bio_endio(struct bio *bio, unsigned int bytes, int error);
                * request_queue_t *blk_alloc_queue(int flags);
                    * 并未真正地建立一个保存请求的队列
                * void blk_queue_make_request(request_queue_t *queue, make_request_fn *func);
                * drivers/block/ll_rw_block.c
* 其他一些细节
    * 命令预处理
        * typedef int (prep_rq_fn) (request_queue_t *queue, struct request *req);
            * 该函数要能返回下面的值之一
                * BLKPREP_OK
                * BLKPREP_KILL
                * BLKPREP_DEFER
        * void blk_queue_prep_rq(request_queue_t *queue, prep_rq_fn *func);
    * 标记命令队列
        * 同时拥有多个活动请求的硬件通常支持某种形式的标记命令队列（Tagged Command Queueing, TCQ）
        * TCQ只是为每个请求添加一个整数（标记）的技术，这样当驱动器完成它们中的一个请求后，它就可以告诉驱动程序完成的是哪个
        * int blk_queue_int_tags(request_queue_t *queue, int depth, struct blk_queue_tag *tags);
        * int blk_queue_resize_tags(request_queue_t *queue, int new_depth);
        * int blk_queue_start_tag(request_queue_t *queue, struct request *req);
        * void blk_queue_end_tag(request_queue_t *queue, struct request *req);
        * struct request *blk_queue_find_tag(request_queue_t *queue, int tag);
        * void blk_queue_invalidate_tags(request_queue_t *queue);
