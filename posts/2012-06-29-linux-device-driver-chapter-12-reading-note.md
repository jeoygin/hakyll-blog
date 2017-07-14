---
title: 《Linux设备驱动程序》第十二章 PCI驱动程序读书笔记
tags:
  - Driver
  - Linux
  - PCI
  - Reading Note
id: 958
categories:
  - 学习笔记
date: 2012-06-29 19:21:37
---

* 简介
    * 本章给出一个高层总线架构的综述
    * 讨论重点是用于访问Peripheral Component Interconnect（PCI，外围设备互联）外设的内核函数
    * PCI总线是内核中得到最好支持的总线
    * 本章主要介绍PCI驱动程序如果寻找其硬件和获得对它的访问
    * 本章也会介绍ISA总线
* PCI接口
    * PCI是一组完整的规范，定义了计算机的各个不同部分之间应该如何交互
    * PCI规范涵盖了与计算机接口相关的大部分问题
    * PCI架构被设计为ISA标准的替代品，有三个主要目标
        * 获得在计算机和外设之间传输数据时更好的性能
            * 通过使用比ISA更高的时钟频率，PCI总线获得了更好的性能，它的时钟频率一般是25或者33MHz（实际的频率是系统时钟的系数），最新的实现达到了66MHz甚至133MHz
            * 配备了32位的数据总线，而且规范已经包括了64位的扩展
        * 尽可能的平台无关性
        * 简化往系统中添加和删除外设的工作
    * PCI设备是无跳线设备，可以引导阶段自动配置

<!--more-->

    * PCI寻址
        * 每个PCI外设由一个总线编号、一个设备编号及一个功能编号来标识
        * PCI规范允许单个系统拥有高达256个总线，但是256个总线对于许多大型系统而言是不够的，因此，Linux目前支持PCI域
        * 每个PCI域可以拥有最多256个总线
        * 每个总线上可支持32个设备，每个设备可以是多功能板，最多可有八种功能
        * 每种功能都可以在硬件级由一个16位的地址来标识
        * 为Linux编写的设备驱动程序可以使用一种特殊的数据结构（pci_dev）来访问设备
        * 当前的工作站一般配置有至少两个PCI总线，在单个系统中插入多个总线，可通过桥（bridge）来完成，它是用来连接两个总线的特殊PCI外设
        * PCI系统的整体布局组织为树型，其中每个总线连接到上一线总线，直到树根的0号总线
        * lspci
        * proc/pci
        * /proc/bus/pci/
            * 查看PCI设备清单和设备的配置寄存器
        * /sys/bus/pci/devices
        * 每个外设板的硬件电路对如下三种地址空间的查询进行应答
            * 内存位置
            * I/O端口
            * 配置寄存器
        * 前两种地址空间由同一PCI总线上的所有设备共享
        * 配置空间利用了地理寻址
        * 配置查询每次只对一个槽寻址
        * 每个PCI槽有四个中断引脚，每个设备功能可使用其中的一个
        * PCI总线中的I/O空间使用32位地址总线，而内存空间可通过32位或64位地址来访问
    * 引导阶段
        * 当PCI设备上电时，硬件保持未激活状态
            * 不会有内存和I/O端口映射到计算机的地址空间
            * 禁止中断报告
        * 每个PCI主板均配备有能够处理PCI的固件，称为BIOS、NVRAM或PROM，固件通过读写PCI控制器中的寄存器，提供了对设备配置地址空间的访问
        * 系统引导时，固件在每个PCI外设上执行配置事务，以便为它提供的每个地址区域分配一个安全的位置
    * 配置寄存器和初始化
        * 所有的PCI设备都有至少256字节的地址空间
            * 前64字节是标准化的，而其余的是设备相关的
        * PCI寄存器始终是小端的
        * 驱动程序编写者在访问多字节的配置寄存器时，要十分注意字节序，因为能够在PC上工作队的代码到其他平台上可能就无法工作
        * vendorID、deviceID和class是常用的三个寄存器
            * vendorID
                * 16位寄存器，用于标识硬件制造商
                * PCI Special Interest Group维护有一个全球的厂商编号注册表，制造商必须申请一个唯一编号并赋于它们的寄存器
            * deviceID
                * 16位寄存器，由制造商选择，该ID通常和厂商ID配对生成生成一个唯一的32位硬件设备标识符
            * class
                * 每个外部设备属于某个类
                * 16位寄存器，高8位标识了“基类（base class）”或者组
            * subsystem vendorID、subsystem deviceID
                * 这两个字段可用来进一步识别设备
        * struct pci_device_id用于定义驱动程序支持的不同类型的PCI设备列表
            * __u32 vendor;
            * __u32 device;
                * 以上两字段指定了设备的PCI厂商和设备ID，如果驱动程序可以处理任何厂商或者设备ID，这些字段应该使用值PCI_ANY_ID
            * __u32 subvendor;
            * __u32 subdevice;
                * 以上两字段指定设备的PCI子系统厂商和子系统设备ID，如果驱动程序可以处理任何类型的子系统ID，这些字段应该使用值PCI_ANY_ID
            * __u32 class;
            * __u32 class_mask;
                * 这两个值使驱动程序可以指定它支持一种PCI类（class）设备，如果驱动程序可以处理任何类型的子系统ID，这些字段应该使用值PCI_ANY_ID
            * kernel_ulong_t driver_data
                * 用来保存PCI驱动程序用于区分不同设备的信息
        * 初始化
            * PCI_DEVICE(vendor, device)
            * PCI_DEVICE_CLASS(device_class, device_class_mask)
    * MODULE_DEVICE_TABLE
        * MODULE_DEVICE_TABLE(pci, i810_ids);
            * 创建一个名为__mod_pci_device_table的局部变量，指向struct pci_device_id数组
            * 在内核构建过程中，depmod程序在所有的模块中搜索符号__mod_pci_device_table
            * 如果找到了该符号，它把数据从该模块中抽出，添加到文件/lib/modules/KERNEL_VERSION/modules.pcimap中
            * 当内核告知热插拔系统一个新的PCI设备已经被发现时，热插拔系统使用modules.pcimap文件来寻找要装载的恰当的驱动程序
    * 注册PCI驱动程序
        * 所以的PCI驱动程序都必须创建的主要结构休是struct pci_driver
            * const char *name;
                * 驱动程序的名字
                * 当驱动程序运行在内核中时，它会出现在sysfs的/sys/bus/pci/drivers/下面
            * const struct pci_device_id *id_table
            * int (*probe) (struct pci_dev *dev, const struct pci_device_id *id);
                * 指向PCI驱动程序中的探测函数的指针同，当PCI核心有一个它认为驱动程序需要控制的struct pci_dev时，就会调用该函数
            * void (*remove) (struct pci_dev *dev);
                * 指向一个移除函数的指针，当struct pci_dev被从系统中移除，或者PCI驱动程序正在从内核中卸载时，PCI核心调用该函数
            * void (*suspend) (struct pci_dev *dev, u32 state);
                * 指向一个恢复函数的指针，当struct pci_dev被恢复时PCI核心调用该函数
        * int pci_register_driver(struct pci_driver *drv);
            * 注册成功返回0，否则，返回一个负的错误编号
        * void pci_unregister_driver(struct pci_driver *drv);
        * 在支持PCI热插拔的系统或者CardBus系统上，PCI设备可以在任何时刻出现或者消失
        * 2.6内核允许在驱动程序被装载之后动态地分配新的PCI ID给它
    * 老式PCI探测
        * struct pci_dev *pci_get_device(unsigned int vendor, unsigned int device, struct pci_dev *from);
        * struct pci_dev *pci_get_subsys(unsigned int vendor, unsigned int device, unsigned int ss_vendor, unsigned int ss_device, struct pci_dev *from);
        * struct pci_dev *pci_get_slot(struct pci_bus *bus, unsigned int devfn);
    * 激活PCI设备
        * int pci_enable_device(struct pci_dev *dev);
    * 访问配置空间
        * 在驱动程序检测到设备之后，通常需要读取或写入三个地址空间
            * 内存
            * 端口
            * 配置
        * &lt;linux/pci.h&gt;
            * int pci_read_config_byte(struct pci_dev *dev, int where, u8 *val);
            * int pci_read_config_word(struct pci_dev *dev, int where, u16 *val);
            * int pci_read_config_dword(struct pci_dev *dev, int where, u32 *val);
            * int pci_write_config_byte(struct pci_dev *dev, int where, u8 *val);
            * int pci_write_config_word(struct pci_dev *dev, int where, u16 *val);
            * int pci_write_config_dword(struct pci_dev *dev, int where, u32 *val);
            * int pci_bus_read_config_byte (struct pci_bus *bus, unsigned int devfn, int where, u8 *val);
            * int pci_bus_read_config_word (struct pci_bus *bus, unsigned int devfn, int where, u16 *val);
            * int pci_bus_read_config_dword (struct pci_bus *bus, unsigned int devfn, int where, u32 *val);
            * int pci_bus_write_config_byte (struct pci_bus *bus, unsigned int devfn, int where, u8 *val);
            * int pci_bus_write_config_word (struct pci_bus *bus, unsigned int devfn, int where, u16 *val);
            * int pci_bus_write_config_dword (struct pci_bus *bus, unsigned int devfn, int where, u32 *val);
    * 访问I/O和内存空间
        * 一个PCI设备可实现多达6个I/O地址区域
        * 一个接口板通过配置寄存器报告其区域的大小和当前位置，它们的符号名称为PCI_BASE_ADDRESS_0到PCI_BASE_ADDRESS_5
        * 在内核中，PCI设备的I/O区域已经被集成到通用资源管理，我们无需访问配置变量来了解设备被映射到内存或I/O空间的何处
        * unsigned long pci_resource_start(struct pci_dev *dev, int bar);
        * unsigned long pci_resource_end(struct pci_dev *dev, int bar);
        * unsinged long pci_resource_flags(struct pci_dev *dev, int bar);
        * &lt;linux/ioport.h&gt;
            * IORESOURCE_IO
            * IORESOURCE_MEM
            * IORESOURCE_PREFETCH
            * IORESOURCE_READONLY
        * 中断号保存在配置寄存器60（PCI_INTERRUPT_LINE）中，该寄存器为一个字节宽
        * 如果设备不支持中断，寄存器61（PCI_INTERRUPT_PIN）是0
    * 硬件抽象
        * 在PCI管理中，唯一依赖于硬件的操作是读取和写入配置寄存器
        * 用于配置寄存器访问的相关结构仅包含2个字段
            * struct pci_ops
                * int (*read) (struct pci_bus *bus, unsigned int devfn, int where, int size, u32 *val);
                * int (*write) (struct pci_bus *bus, unsigned int devfn, int where, int size, u32 val);
        * 该结构在&lt;linux/pci.h&gt;中定义，并由drivers/pci/pci.c使用，后者定义了实际的公共函数
* ISA回顾
    * ISA总线在设计上相当陈旧而且其差劲的性能臭名昭著
    * 当要支持老主板而速度又不是非常重要时，ISA比起PCI要占些优势
    * 如果你是一位电子爱好者，你可以非常容易地设计开发自己的ISA设备
    * ISA的最大不足在于它被紧紧绑定在PC架构上
    * ISA设计的另外一个大问题是缺少地理寻址
    * 硬件资源
        * 一个ISA设备可配备有I/O端口、内存区域以及中断线
    * 即插即用规范
        * 某些新的ISA设备板遵循特殊的设计原则，需要一个特殊的初始化序列，以便简化附加接口板的安装和配置，这些接口板的设计规范称为PnP（Plug and Play，即插即用）。
        * PnP的目标是获得类似PCI设备那样的灵活性，而无需修改底层的电气接口（即ISA总线）。为此，该规范定义了一组设备无关的配置寄存器，以及地址寻址接口板的方法。
* PC/104和PC/104+
    * 这两个标准都规定了印刷电路板的外形，以及板间互连的电气/机械规范，这些总线的实际好处在于，它们可以使用在设备一面的插头-插座类型的连接器把多个电路板垂直堆叠起来
    * 这两个总线的电子和逻辑布局和ISA（PC/104）及PCI（PC/104+）一样
* 其他的PC总线
    * MCA
        * MCA（Micro Channel Architecture，微通道结构）是在PS/2计算机和某些笔记本电脑使用的IBM标准
        * 支持多主DMA、32位地址和数据线、共享中断线和用来访问板载配置寄存器的地理寻址等
    * EISA
        * 扩展ISA（EISA）总线是对ISA总线的32扩展，同时具有兼容的接口连接器
        * 为无跳线设备而设计
        * 32位地址和数据线、多主DMA和共享中断线
    * VLB
        * VLB（VESA Local Bus，VESA局部总线）接口总线，它通过添加第三个纵向插槽对ISA连接器进行了扩展
* SBus
    * 存在很长一段时间了，具有相当高级的设计
    * 尽管只有SPARC计算机使用该总线，但它的初衷却是处理器无关的，并针对I/O外设板进行了优化
* NuBus
    * 可以在老式的Mac计算机（使用M68k系列CPU）中找到它
    * 所有的总线都是内存映射的，而且设备只能被地理寻址
* 外部总线
    * 外部总线包括：USB、FireWire和IEEE1284
    * 这些总线既不是功能完整的接口总线（比如PCI），也是哑的通信通道（比如串口）
    * 通常可划分为两个级别
        * 硬件控制器的驱动程序
        * 针对特定“客户”设备的驱动程序
