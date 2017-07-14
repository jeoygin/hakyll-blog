---
title: 《Linux设备驱动程序》第十五章 内存映射和DMA读书笔记
tags:
  - DMA
  - Driver
  - Linux
  - Memory Mapping
  - Reading Note
id: 965
categories:
  - 学习笔记
date: 2012-07-03 17:40:07
---

* 简介
    * 许多类型的驱动程序编程都需要了解一些虚拟内存子系统如何工作的知识
    * 当遇到更为复杂、性能要求更为苛刻的子系统时，本章所讨论的内容迟早都要用到
    * 本章的内容分成三个部分
        * 讲述mmap系统调用的实现过程
        * 讲述如何跨越边界直接访问用户空间的内存页
        * 讲述了直接内存访问（DMA）I/O操作，它使得外设具有直接访问系统内存的能力
* Linux的内存管理
    * 地址类型
        * Linux是一个虚拟内存系统，这意味着用户程序所使用的地址与硬件使用的物理地址是不等同的
        * 有了虚拟内存，在系统中运行的程序可以分配比物理内存更多的内存，甚至一个单独的进程都能拥有比系统物理内存更多的虚拟地址空间
        * 下面是一个Linux使用的地址类型列表
            * 用户虚拟地址
                * 这是在用户空间程序所能看到的常规地址
            * 物理地址
                * 该地址在处理器和系统内存之间使用
            * 总线地址
                * 该地址在外围总线和内存之间使用，通常它们与处理器使用的物理地址相同
            * 内核逻辑地址
                * 内核逻辑地址组成了内核的常规地址空间
                * 在大多数体系架构中，逻辑地址和与其相关联的物理地址不同，仅仅在它们之间存在一个固定的偏移量
                * kmalloc返回的内存就是内核逻辑地址
            * 内核虚拟地址
                * 和内核逻辑地址的相同之处在于，它们都将内核空间的地址映射到物理地址上
                * 内核虚拟地址与物理地址的映射不必是线性的一对一的
                * 所有的逻辑地址都是内核虚拟地址，但是很多内核虚拟地址不是逻辑地址
                * vmalloc分配的内存具有一个虚拟地址
        * &lt;asm/page.h&gt;
            * __pa()
                * 返回其对应的物理地址
            * __va()
                * 将物理地址逆向映射到逻辑地址，但这只对低端内存页有效
    * 物理地址和页
        * 物理地址被分成离散的单元，称之为页
        * &lt;asm/page.h&gt;
            * PAGE_SIZE
        * 目前大多数系统都使用每页4096个字节
    * 高端与低端内存
        * 使用32位系统只能在4GB的内存中寻址
        * 内核将4GB的虚拟地址空间分割为用户空间和内核空间，一个典型的分割是将3GB分配给用户空间，1GB分配给内核空间
        * 低端内存
            * 存在于内核空间上的逻辑地址内存
        * 高端内存
            * 那些不存在逻辑地址的内存
    * 内存映射和页结构
        * &lt;linux/mm.h&gt;
        * struct page
            * atomic_t count;
                * 对该页的访问计数。当计数值为0时，该页将返回给空闲链表
            * void *virtual;
                * 如果页面被映射，则指向页的内核虚拟地址；如果未被映射则为NULL
            * unsigned long flags;
                * 描述页状态的一系列标志
                * PG_locked表示内存中的页已经被锁住
                * PG_reserved表示禁止内存管理系统访问该页
        * struct page *virt_to_page(void *kaddr);
        * struct page *pfn_to_page(int pfn);
            * 针对给定的页帧号，返回page结构指针
        * void *page_address(struct page *page);
            * 返回页的内核虚拟地址
        * &lt;linux/highmem.h&gt;
            * &lt;asm/kmap_types.h&gt;
            * void *kmap(struct page *page);
                * 对于低端内存页来说，返回页的逻辑地址
                * 对于高端内存，在专用的内核地址空间创建特殊的映射
            * void kunmap(struct page *page);
            * void *kmap_atomic(struct page *page, enum km_type type);
            * void kunmap_atomic(void *addr, enum km_type type);
    * 页表
        * 处理器必须使用某种机制同，将虚拟地址转换为相应的物理地址，这种机制被称为页表
        * 它基本上是一个多层树形结构，结构化的数据中包含了虚拟地址到物理地址的映射和相关的标志位
    * 虚拟内存区
        * 虚拟内存区（VMA）用于管理进程地址空间中不同区域的内核数据结构
        * 进程的内存映射包含下面这些区域
            * 程序的可执行代码区域
            * 多个数据区，其中包含初始化数据、非初始化数据以及程序堆栈
            * 与每个活动的内存映射对应的区域
        * /proc/&lt;pid&gt;/maps
            * start-end perm offset major:minor inode image
        * vm_area_struct结构
            * &lt;linux/mm.h&gt;
            * struct vm_area_struct
                * unsigned long vm_start;
                * unsigned long vm_end;
                * struct file *vm_file;
                * unsigned long vm_pgoff;
                * unsigned long vm_flags;
                * struct vm_operations_struct *vm_ops;
                * void *vm_private_data;
            * struct vm_operations_struct
                * void (*open) (struct vm_area_struct *vma);
                * void (*close) (struct vm_area_struct *vma);
                * struct page *(*nopage) (struct vm_area_struct *vma, unsigned long address, int *type);
                * int (*populate) (struct vm_area_struct *vm, unsigned long address, unsigned long len, pgprot_t prot, unsigned long pgoff, int nonblock);
    * 内存映射处理
        * &lt;linux/sched.h&gt;
            * struct mm_struct
        * current-&gt;mm

<!--more-->

* mmap设备操作
    * 内存映射可以提供给用户程序直接访问设备内存的能力
    * 映射一个设备意味着将用户空间的一段内存与设备内存关联起来
    * 像串口和其他面向流的设备就不能进行mmap抽象
    * 必须以PAGE_SIZE为单位进行映射
    * mmap方法是file_operations结构的一部分
    * mmap (caddr_t addr, size_t len, int prot, int flags, int fd, off_t offset)
    * int (*mmap) (struct file *filp, struct vm_area_struct *vma);
    * 有两种建立页表的方法
        * 使用remap_pfn_range函数一次全部建立
        * 通过nopage VMA方法每次建立一个页表
    * 使用remap_pfn_range
        * int rempa_pfn_range(struct vm_area_struct *vma, unsigned long virt_addr, unsigned long pfn, unsigned long size, pgprot_t prot);
        * int io_remap_page_range(struct vm_area_struct *vma, unsigned long virt_addr, unsigned long phys_addr, unsigned long size, pgprot_t prot);
        * vma
            * 虚拟内存区域
        * virt_addr
            * 重新映射时的起始用户虚拟地址
        * pfn
            * 与物理内存对应的页帧号，虚拟内存将要被映射到该物理内存
            * 页帧号只是将物理地址右移PAGE_SHIFT位
        * size
            * 以字节为单位
        * prot
            * 新VMA要求的“保护（protection）”属性
    * 一个简单的实现
        * drivers/char/mem.c
        * remap_pfn_range(vma, vma-&gt;vm_start, vm_.vm_pgoff, vma-&gt;vm_end - vma-&gt;vm_start, vma-&gt;vm_page_prot)
    * 为VMA添加操作
        * struct vm_operations_struct simple_remap_vm_ops = {.open = simple_vma_open, .close = simple_vma_close,}
    * 使用nopage映射内存
        * 如果要支持mremap系统调用，就必须实现nopage函数
        * struct page *(*nopage) (struct vm_area_struct *vma, unsigned long address, int *type);
        * get_page(struct page *pageptr);
        * static int simple_nopage_mmap(struct file *filp, struct vm_area_struct *vma)
        * {
            * unsigned long offset = vma-&gt;vm_pgoff &lt;&lt; PAGE_SHIFT;
            * if (offset &gt;= __pa(high_memory) || (filp-&gt;f_flags & O_SYNC))
                * vm-&gt;vm_flags |= VM_IO
            * vm-&gt;vm_flags |= VM_RESERVED;
            * vm-&gt;vm_ops = &simple_nopage_vm_ops;
            * simple_vma_open(vma);
            * return 0;
        * }
        * struct page *simple_vma_nopage(struct vm_area_struct *vma, unsigned long address, int *type)
        * {
            * struct page *pageptr;
            * unsigned long offset = vma-&gt;vm_pgoff &lt;&lt; PAGE_SHIFT;
            * unsigned long physaddr = address - vma-&gt;vm_start + offset;
            * unsigned long pageframe = physaddr &gt;&gt; PAGE_SHIFT;
            * if (!pfn_valid(pageframe))
                * return NOPAGE_SIGBUS;
            * pageptr = pfn_to_page(pageframe);
            * get_page(pageptr);
            * if (type)
                    * type = VM_FAULT_MINOR;
            * return pageptr;
        * }
    * 重新映射RAM
        * 对remap_pfn_range函数的一个限制是：它只能访问保留页和超出物理内存的物理地址
        * remap_pfn_range不允许重新映射常规地址
        * 使用nopage方法重新映射RAM
            * 使用vm_ops-&gt;nopage一次处理一个页错误
    * 重新映射内核虚拟地址
        * page = vmalloc_to_page(pageptr);
        * get_page(page);
* 执行直接I/O访问
    * 如果需要传输的数据量非常大，直接进行数据传输，而不需要额外地从内核空间拷贝数据操作的参与，这将会大大提高速度
    * 设置直接I/O的开销非常巨大
        * 使用直接I/O需要write系统调用同步执行
        * 在每个写操作完成之前不能停止应用程序
    * &lt;linux/mm.h&gt;
        * int get_user_pages(struct task_struct *tsk, struct mm_struct *mm, unsigned long start, int len, int write, int force, struct page **pages, struct vm-area_struct **vmas);
            * tsk
                * 指向执行I/O的任务指针，该参数几乎是current
            * mm
                * 指向描述被映射地址空间的内存管理结构的指针
                * 对驱动程序来说，该参数总是current-&gt;mm
            * force
                * 如果write非零，对映射的页有写权限
                * 驱动程序对该参数总是设置为0
            * pages
                * 如果调用成功，pages中包含了一个描述用户空间缓冲区page结构的指针列表
            * vmas
                * 如果调用成功，vmas包含了相应VMA的指针
    * 使用直接I/O的设备通常使用DMA操作
    * 一旦直接I/O操作完成，就必须释放用户内存页
    * &lt;linux/page-flags.h&gt;
        * void SetPageDirty(struct page *page);
    * void page_cache_release(struct page *page);
    * 异步I/O
        * &lt;linux/aio.h&gt;
        * ssize_t (*aio_read) (struct kiocb *iocb, char *buffer, size_t count, loff_t offset);
        * ssize_t (*aio_write) (struct kiocb *iocb, const char *buffer, size_t count, loff_t offset);
        * int (*aio_fsync) (struct kiocb *iocb, int datasync);
        * int is_sync_kiocb(struct kiocb *iocb);
        * int aio_complete(struct kiocb *iocb, long res, long res2);
* 直接内存访问
    * DMA是一种硬件机制同，它允许外围设备和主内存之间直接传输它们的I/O数据，而不需要系统处理器的参与
    * 使用这种机制可以大大提高与设备通信的吞吐量
    * DMA数据传输概览
        * 有两种方式引发数据传输
            * 软件对数据的请求
                * 当进程调用read，驱动程序函数分配一个DMA缓冲区，并让硬件将数据传输到这个缓冲区中，进程处于睡眠状态
                * 硬件将数据写入到DMA缓冲区中，当写入完毕，产生一个中断
                * 中断处理程序获得输入的数据，应答中断，并且唤醒进程，该进程现在即可读取数据
            * 硬件异步地将数据传递给系统
                * 硬件产生中断，宣告新数据的到来
                * 中断处理程序分配一个缓冲区，并且告诉硬件向哪里传输数据
                * 外围设备将数据写入缓冲区，完成后产生另外一个中断
                * 处理程序分发新数据，唤醒任何相关进程，然后执行清理工作
    * 分配DMA缓冲区
        * 使用DMA缓冲区的主要问题是：当大于一页时，它们必须占据连接的物理页，这是因为设备使用ISA或者PCI系统总线传输数据，而这两种方式使用的都是物理地址
        * DIY分配
            * get_free_pages函数可以分配多达几M字节的内存，但是对较大数量的请求，甚至是远少于128KB的请求也通常会失败，这是因为此时系统内存中充满了内存碎片
            * 当内核不能返回请求数量的内存或需要超过128KB内存时，除了返回-ENOMEM，另外一个方法是在引导时分配内存或是为缓冲区保留顶部物理RAM
            * 还有一个方法是使用GFP_NOFAIL分配标志来为缓冲区分配内存
    * 总线地址
        * 使用DMA的设备驱动程序将与连接到总线接口上的硬件通信，硬件使用的是物理地址，而程序代码使用的是虚拟地址
        * &lt;asm/io.h&gt;
            * unsigned long virt_to_bus(volatile void *address);
            * void *bus_to_virt(unsigned long address);
    * 通用DMA层
        * 内核提供了一个与总线体系架构无关的DMA层
        * &lt;linux/dma-mapping.h&gt;
        * 处理复杂的硬件
            * int dma_set_mask(struct device *dev, u64 mask);
                * 该掩码显示与设备能寻址能力对应的位
                * 如果dma_set_mask返回0，则对该设备不能使用DMA
        * DMA映射
            * 一个DMA映射是要分配的DMA缓冲区与为该缓冲区生成的、设备可访问地址的组合
            * DMA映射建立了一个新的结构类型——dma_addr_t来表示总线地址
            * 根据DMA缓冲区期望保留的时间长短，PCI代码区分两种类型的DMA映射
                * 一致性DMA映射
                    * 这种类型的映射存在于驱动程序生命周期中
                    * 一致性映射的缓冲区必须可同时被CPU和外围设备访问
                    * 建立和使用一致性映射的开销是很大的
                * 流式DMA映射
                    * 通常为单独的操作建立流式映射
                    * 内核开发者建议尽量使用流式映射，然后再考虑一致性映射
                    * *在支持映射寄存器的系统中，每个DMA映射使用总线上的一个或者多个映射寄存器
                    * *在一些硬件中，流式映射可以被优化，但优化的方法对一致性映射无效
        * 建立一致性DMA映射
            * void *dma_alloc_coherent(struct device *dev, size_t size, dma_addr_t *dma_handle, int flag);
                * 返回值是缓冲区的内核虚拟地址
                * 与其相关的总线地址，保存在dma_handle中
            * void dma_free_coherent(struct device *dev, size_t size, void *vaddr, dma_addr_t dma_handle);
        * DMA池
            * DMA池是一个生成小型、一致性DMA映射的机制
            * &lt;linux/dmapool.h&gt;
                * struct dma_pool *dma_pool_create(const char *name, struct device *dev, size_t size, size_t align, size_t allocation);
                    * allocation不为零，表示内存边界不能超越allocation
                * void dma_pool_destroy(struct dma_pool *pool);
                * void *dma_pool_alloc(struct dma_pool *pool, int mem_flags, dma_addr_t *handle);
                    * 返回的DMA缓冲区的地址是内核虚拟地址
                * void dma_pool_free(struct dma_pool *pool, void *vaddr, dma_addr_t addr);
        * 建立流式DMA映射
            * 当建立流式映射时，必须告诉内核数据流动的方向
            * enum dma_data_direction
                * DMA_TO_DEVICE
                * DMA_FROM_DEVICE
                * DMA_BIDIRECTIONAL
                * DMA_NONE
            * dma_addr_t dma_map_single(struct device *dev, void *buffer, size_t size, enum dma_data_direction direction);
            * void dma_unmap_single(struct device *dev, dma_addr_t dma_addr, size_t size, enum dma_data_direction direction);
            * 有几条非常重要的原则用于流式DMA映射
                * 缓冲区只能用于这样的传送，即其传送方向匹配于映射时给定的方向wfhg
                * 一旦缓冲区被映射，它将属于设备，而不是处理器
                * 在DMA处于活动期间内，不能撤销对缓冲区映射，否则会严重破坏系统的稳定性
            * void dma_sync_single_for_cpu(struct device *dev, dma_handle_t bus_addr, size_t size, enum dma_data_direction direction);
            * void dma_sync_single_for_device(struct device *dev, dma_handle_t bus_addr, size_t size, enum dma_data_direction direction);
        * 单页流式映射
            * dma_addr_t dma_map_page(struct device *dev, struct page *page, unsigned long offset, size_t size, enum dma_data_direction direction);
            * void dma_unmap_page(struct device *dev, dma_addr_t dma_address, size_t size, enum dma_data_direction direction);
        * 分散/聚焦映射
            * 这是一种特殊的流式DMA映射
            * 假设有几个缓冲区，它们需要与设备双向传输数据
            * 有几种方式能产生这种情形
                * 从raedv或者writev系统调用产生
                * 从集群的磁盘I/O请求产生
                * 从映射的内核I/O缓冲区中的页面链表产生
            * 许多设备都能接受一个指针数组的分散表，以及它的长度，然后在一次DMA操作中把它们全部传输走
            * 映射分散表的第一步是建立并填充一个描述被传送缓冲区的scatterlist结构的数组
            * &lt;linux/scatterlist.h&gt;
            * struct scatterlist
                * struct page *page;
                * unsigned int length;
                * unsigned int offset;
            * int dma_map_sg(struct device *dev, struct scatterlist *sg, int nents, enum dma_data_direction direction);
                * nents是传入的分散表入口的数量
                * 返回值是要传送的DMA缓冲区数
            * 驱动程序应该传输由dma_map_sg函数返回的每个缓冲区
            * dma_addr_t sg_dma_address(struct scatterlist *sg);
            * unsinged int sg_dma_len(struct scatterlist *sg);
            * void dma_unmap_sg(struct device *dev, struct scatterlist *list, int nents, enum dma_data_direction direction);
                * nents一定是先前传递给dma_map_sg函数的入口项的数量
            * void dma_sync_sg_for_cpu(struct device *dev, struct scatterlist *sg, int nents, enum dma_data_direction direction);
            * void dma_sync_sg_for_device(struct device *dev, struct scatterlist *sg, int nents, enum dma_data_direction direction);
        * PCI双重地址周期映射
            * 通常DMA支持层使用32位总线地址，其为设备的DMA掩码所约束
            * PCI总线还支持64位地址模式，既双重地址周期（DAC）
            * 如果设备需要使用放在高端内存的大块缓冲区，可以考虑实现DAC支持
            * &lt;linux/pci.h&gt;
            * int pci_dac_set_dma_mask(struct pci_dev *pdev, u64 mask);
                * 返回0时，才能使用DAC地址
            * dma64_addr_t pci_dac_page_to_dma(struct pci_dev *pdev, struct page *page, unsigned long offset, int direction);
                * direction
                    * PCI_DMA_TODEVICE
                    * PCI_DMA_FROMDEVICE
                    * PCI_DMA_BIDIRECTIONAL
            * void pci_dac_dma_sync_single_for_cpu(struct pci_dev *pdev, dma64_addr_t dma_addr, size_t len, int direction);
            * void pci_dac_dma_sync_single_for_device(struct pci_dev *pdev, dma64_addr_t dma_addr, size_t len, int direction);
    * ISA设备的DMA
        * ISA总线允许两种DMA传输：本地（native）DMA和ISA总线控制（bus-master）DMA
        * 本地DMA使用主板上的标准DMA控制器电路来驱动ISA总线上的信号线
        * ISA总线控制DMA完全由外围设备控制
        * 有三种实现涉及到ISA总线上的DMA数据传输
            * 8237 DMA控制器（DMAC)
            * 外围设备
                * 当设备准备传送数据时，必须激活DMA请求信号
            * 设备驱动程序
                * 需要驱动程序完成的工作很少，它只是负责提供DMA控制器的方向、总线地址、传输量的大小等等
        * 注册DMA
            * &lt;asm/dma.h&gt;
                * int request_dma(unsigned int channel, const char *name);
                    * 返回0表示执行成功
                * void free_dma(unsigned int channel);
        * 与DMA控制器通信
            * unsigned long claim_dma_lock();
            * 必须被装入控制器的信息包含三个部分：RAM的地址、必须被传输的原子项个数以及传输的方向
            * void set_dma_mode(unsigned int channel, char mode);
                * mode
                    * DMA_MODE_READ
                    * DMA_MODE_WRITE
                    * DMA_MODE_CASCADE
                    * *释放对总线的控制
            * void set_dma_addr(unsigned int channel, unsigned int addr);
            * void set_dma_count(unsigned int channel, unsigned int count);
            * void disable_dma(unsigned int channel);
            * void enable_dma(unsigned int channel);
            * int get_dma_residue(unsigned int channel);
                * 返回还未传输的字节数
            * void clear_dma_ff(unsigned int channel);
