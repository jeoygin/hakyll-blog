---
title: 《Linux设备驱动程序》第八章 分配内存读书笔记
tags:
  - Allocating Memory
  - Driver
  - Linux
  - Reading Note
id: 946
categories:
  - 学习笔记
date: 2012-06-25 15:41:48
---

* kmalloc函数的内幕
    * 不对所获取的内存空间清零
    * 分配的区域在物理内存中也是连续的
    * flags参数
        * &lt;linux/slab.h&gt;
        * &lt;linux/gfp.h&gt;
            * GFP_KERNEL
                * 在空闲内存较少时把当前进程转入休眠以等待一个页面
                * 分配内存的函数必须是可重入的
            * GFP_ATOMIC
                * 用于在中断处理例程或其他运行于进程上下文之外的代码中分配内存，不会休眠
            * GFP_USER
                * 用于为用户空间页分配内存，可能会休眠
            * GFP_HIGHUSER
                * 类似于GFP_USER，不过如果有高端内存的话就从那里分配
            * GFP_NOIO, GFP_NOFS
                * 这两个标志的功能类似于GFP_KERNEL，但是为内核分配内存的工作方式添加了一些限制。具有GFP_NOFS标志的分配不允许执行任何文件系统调用，而GFP_NOIO禁止任何I/O的初始化。这两个标志主要在文件系统和虚拟内存代码中使用，这些代码中的内存分配可休眠，但不应该发生递归的文件系统调用
            * __GFP_DMA
                * 该标志请求分配发生在可进行DMA的内存区段中
            * __GFP_HIGHHEM
                * 这个标志表明要分配的内存可位于高端内存
            * __GFP_COLD
                * 这个标志请求尚未使用的“冷”页面，对于DMA读取的页面分配，可使用这个标志
            * __GFP_NOWARN
                * 很少使用，可以避免内核在无法满足分配请求时产生警告
            * __GFP_HIGH
                * 标记了一个高优先级的请求，它允许为紧急善而消耗由内核保留的最后一些页面
            * __GFP_REPEAT, __GFP_NOFAIL, __GFP_NORETRY
                * 告诉分配器在满足分配请求而遇到困难时应该采取何种行为
                * __GFP_REPEAT表示“努力再尝试一次”，它会重新尝试分配，但仍有可能失效
                * __GFP_NOFAIL标志告诉分配器始终不返回失败，它会努力满足分配请求，不鼓励使用这个标志
                * __GFP_NORETRY告诉分配器，如果所请求的内存不可获得，就立即返回
    * 内存区段
        * __GFP_DMA和__GFP_HIGHHEM的使用与平台相关
        * Linux内核把内存分为三个区段：可用于DMA的内存、常规内存以及高端内存
        * 可用于DMA的内存指存在于特别地址范围内的内存，外设可以利用这些内存执行DMA访问
        * 高端内存是32位平台为了访问大量的内存而存在的一种机制
        * 如果没有指定特定的标志，则kmalloc会在常规区段和DMA区段搜索
        * 如果设置了__GFP_HIGHHEM标志，则所有三个区段都会被搜索
        * 内存区段的背后机制在mm/page_alloc.c中实现
    * size参数
        * Linux处理内存分配的方法是，创建一系列的内存对象池，每个池中的内存块大小是固定一致的。处理分配请求时，就直接在包含有足够大的内存块的池中传递一个整块给请求者
        * kmalloc能处理的最小的内存块是32或者64
        * 如果希望代码具有完整的可移植性，则不应该分配大于128KB的内存
<!--more-->
* 后备高速缓存
    * Linux内核的调整缓存管理有时称为“slab分配器”
    * slag分配器实现的高速缓存具有kmem_cache_t类型
    * kmem_cache_t *kem_cache_create(const char *name, size_t size, size_t offset, unsigned long flags, void (*constructor) (void *, keme_cache_t *, unsigned long flags), void (*destructor) (void *, kmem_cache_t *, unsigned long flags));
    * 参数flags控制如何完成分配
        * SLAB_NO_REAP
            * 可以保护高速缓存在系统寻找内存的时候不会被减少
        * SLAB_HWCACHE_ALIGN
            * 要求所有数据对象跟调整缓存行（cache line）对齐，实际的操作则依赖于主要平台的硬件调整缓存布局
        * SLAB_CACHE_DMA
            * 要求每个数据对象都从可用于DMA的内存区段中分配
    * mm/slab.c
    * 可以使用同一个函数同时作为constructor和destructor使用，当调用的是一个constructor函数的时候，slab分配器总是传递SLAB_CTOR_CONSTRUCTOR标志
    * void *kmem_cache_alloc(kmem_cache_t *cache, int flags);
    * void kmem_cache_free(kmem_cache_t *cache, const void *obj);
    * int kmem_cache_destroy(kmem_cache_t *cache);
    * 高速缓存的使用统计情况可以从/proc/slabinfo获得
    * 内存池
        * 内存池其实就是某种形式的后备高速缓存，它试图始终保存空闲的内存，以便把在紧急状态下使用
        * 内存池对象的类型为mempool_t
        * &lt;linux/mempool.h&gt;
            * mempool_t *mempool_create(int min_nr, mempool_alloc_t *alloc_fn, mempool_free_t *free_fn, void *pool_data);
            * typedef void *(mempool_alloc_t) (int gfp_mask, void *pool_data);
            * typedef void (mempool_free_t) (void *element, void *pool_data);
            * void *mempool_alloc(mempool_t *pool, int gfp_mask);
            * void mempool_free(void *element, mempool_t *pool);
            * int mempool_resize(mempool_t *pool, int new_min_nr, int gfp_mask);
            * void mempool_destroy(mempool_t *pool);
        * example
            * cache = kmem_cache_create(...);
            * pool =- mempool_create(MY_POOL_MINIMUM, mempool_alloc_slab, mempool_free_slab, cache);
        * mempool会分配一些内存块，空闲且不会真正得到使用
        * 应尽量避免在驱动程序代码中使用mempool
* get_free_page和相关函数
    * get_zeroed_page(unsigned int flags);
        * 返回指向新页面的指针并将页面清零
    * __get_free_page(unsigned int flags);
        * 类似于get_zeroed_page，但不清零页面
    * __get_free_pages(unsigned int flags, unsigned int order);
        * 分配若干（物理连续的）页面，并返回指向该内在区域第一个字节的指针，但不清零页面
        * 参数order是要申请或释放的页面数的以2为底的对数
    * void free_page(unsigned long addr);
    * void free_pages(unsigned long addr, unsigned long order);
    * alloc_pages接口
        * struct page *alloc_pages_node(int nid, unsigned int flags, unsigned int order);
            * nid是NUMA节点的ID号
        * struct page *alloc_page(unsigned int flags, unsigned int order);
        * struct page *alloc_page(unsigned int flags);
        * void __free_page(struct page *page);
        * void __free_pages(struct page *page, unsigned int order);
        * void free_hot_page(struct page *page);
        * void free_code_page(struct page *page);
    * Subtopic 7
* vmalloc及其辅助函数
    * 分配虚拟地址空间的连续区域，这段区域右物理上可能是不连续的，内核却认为它们在地址上是连续的
    * vmalloc获得的内存使用起来效率不高
    * &lt;linux/vmalloc.h&gt;
        * void *vmalloc(unsigned long size);
        * void vfree(void *addr);
        * void *ioremap(unsigned long offset, unsigned long size);
        * void iounmap(void *addr);
    * vmalloc可以获得的地址在VMALLOC_START到VMALLOC_END的范围中，这两个符号都在&lt;asm/pgtable.h&gt;中定义
    * 使用vmalloc函数的正确场合是在分配一大块连续的、只在软件中存在的、用于缓冲的内存区域的时候
    * ioremap更多用于映射（物理的）PCI缓冲区地址到（虚拟的）内核空间
* per-CPU变量
    * 当建立一个per-CPU变量时，系统中的每个处理器都会拥有该变量的特有副本
    * 不需要锁定
    * 可以保存在对应处理器的高速缓存中
    * &lt;linux/percpu.h&gt;
        * DEFINE_PER_CPU(type, name);
        * get_cpu_var(variable);
        * put_cpu_var(variable);
        * per_cpu(variable, int cpu_id);
        * void *alloc_percpu(type);
        * void *__alloc_percpu(size_t size, size_t align);
        * per_cpu_ptr(void *per_cpu_var, int cpu_id);
        * EXPORT_PER_CPU_SYMBOL(per_cpu_var);
        * EXPORT_PER_CPU_SYMBOL_GPL(per_cpu_var);
        * DECLARE_PER_CPU(type, name);
* 获取大的缓冲区
    * 在引导时获得专用缓冲区
        * &lt;linux/bootmem.h&gt;
            * void *alloc_bootmem(unsigned long size);
            * void *alloc_bootmem_low(unsigned long size);
            * void *alloc_bootmem_pages(unsigned long size);
            * void *alloc_bootmem_low_pages(unsigned long size);
            * void free_bootmem(unsigned long addr, unsigned long size);
        * 这些函数要么分配整个页，要么分配不在页面边界上对齐的内存区
        * 除非使用具有_low后缀的版本，否则分配的内存可能会是高端内存
