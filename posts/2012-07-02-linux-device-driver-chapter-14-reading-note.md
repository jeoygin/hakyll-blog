---
title: 《Linux设备驱动程序》第十四章 Linux设备模型读书笔记
tags:
  - Device Model
  - Driver
  - Linux
  - Reading Note
id: 961
categories:
  - 学习笔记
date: 2012-07-02 16:49:34
---

* 简介
    * 2.6内核的设备模型提供一个对系统结构的一般性抽象描述，用以支持多种不同的任务
        * 电源管理和系统关机
        * 与用户空间通信
        * 热插拔设备
        * 设备类型
        * 对象生命周期
* kobject、kset和子系统
    * kobject是组成设备模型的基本结构
        * 对象的引用计数
        * sysfs表述
        * 数据结构关联
        * 热插拔事件处理
    * kobject基础知识
        * &lt;linux/kobject.h&gt;
        * 嵌入的kobject
            * 内核代码很少去创建一个单独的kobject对象，kobject用于控制对大型域相关对象的访问
        * kobject的初始化
            * 首先将kobject设置为0，通常使用memset
            * void kobject_init(struct kobject *kobj);
            * int kobject_set_name(struct kobject *kobj, const char *format, ...);
            * ktype、kset和parent
        * 对引用计数的操作
            * struct kobject *kobjct_get(struct kobject *kobj);
            * void kobject_put(struct kobject *kobj);
        * release函数和kobject类型
            * void my_object_readse(struct kobject *kobj)
                * struct my_object *mine = container_of(kobj, struct my_object, kobj);
                * kfree(mine);
            * struct kobj_type
                * void (*release) (struct kobject *);
                * struct sysfs_ops *sysfs_ops;
                * struct attribute **default_attrs;
            * struct kobj_type *get_ktype(struct kobject *kobj);
    * kobject层次结构、kset和子系统
        * 内核用kobject结构将各个对象连接起来组成一个分层的结构体系，有两种独立的机制用于连接：parent指针和kset
        * 在kobject结构的parent成员中，保存了另外一个kobject结构的指针，这个结构表示了分层结构中上一层的节点
        * kset
            * 一个kset是嵌入相同类型结构的kobject的集合
            * kset结构关心提对象的聚焦与集合
            * 可以认为kset是kobject的顶层容器类
            * kset总是在sysfs中出现
            * 先把kobject的kset成员指向目的kset，然后使用下面函数添加kobject
            * int kobject_add(struct kobject *kobj);
            * extern int kobject_register(struct kobject *kobj);
                * kobject_init和kobject_add的简单组合
            * void kobject_del(struct kobject *kobj);
            * kset在一个标准的内核链表中保存了它的子节点
        * kset上的操作
            * void kset_init(struct kset *kset);
            * int kset_add(struct kset *kset);
            * int kset_register(struct kset *kset);
            * void kset_unregister(struct kset *kset);
        * 子系统
            * 子系统通常显示在sysfs分层结构中的顶层
            * 内核中的子系统
                * block_subsys（对块设备来说是/sys/block）
                * devices_subsys（/sys/devices，设备分层结构的核心）
                * 内核所知晓的用于各种总线的特定子系统
                * decl_subsys(name, struct kobj_type *type, struct kset_hotplug_ops *hotplug_ops);
                * void subsysstem_init(struct subsystem *subsys);
                * int subsystem_register(struct subsystem *subsys);
                * void subsystem_unregister(struct subsystem *subsys);
                * struct subsystem *subsys_get(struct subsystem *subsys);
                * void subsys_put(struct subsystem *subsys);

<!--more-->

* 低层sysfs操作
    * kobject是隐藏在sysfs虚拟文件系统后的机制，对于sysfs中的每个目录，内核中都会存在一个对应的kobject
    * &lt;linux/sysfs.h&gt;
    * sysfs入口
        * kobject在sysfs中的入口始终是一个目录
        * 分配阀给kobject的名字是sysfs中的目录名
        * sysfs入口在目录中的位置对应于kobject的parent指针
    * 默认属性
        * kobject默认属性保存在kobj_type结构中
        * default_attrs成员保存了属性列表
        * sysfs_ops提供了实现这些属性的方法
        * struct attribute
            * char *name
            * struct module *owner
            * mode_t mode
                * 只读：S_IRUGO
                * 可写：S_IWUSR
                * &lt;linux/stat.h&gt;
        * struct sysfs_ops
            * ssize_t (*show) (struct kobject * kobj, struct attribute *attr, char *buffer);
            * ssize_t (*store) (struct kobject *kobj, struct attribute *attr, const char *buffer, size_t size);
    * 非默认属性
        * int sysfs_create_file(struct kobject *kobj, struct attribute *attr);
        * int sysfs_remove_file(struct kobject *kobj, struct attribute *attr);
    * 二进制属性
        * struct bin_attribute
            * struct attribute attr;
            * size_t size;
            * ssize_t (*read) (struct kobject *kobj, char *buffer, loff_t pos, size_t size);
            * ssize_t (*write) (struct kobject *kobj, char *buffer, loff_t pos, size_t size);
        * int sysfs_create_bin_file(struct kobject *kobj, struct bin_attribute *attr);
        * int sysfs_remove_bin_file(struct kobject *kobj, struct bin_attribute *attr);
    * 符号链接
        * int sysfs_create_link(struct kobject *kobj, struct kobject *target, char *name);
        * void sysfs_remove_link(struct kobject *kobj, char *name);
* 热插拔事件的产生
    * 一个热插拔事件是从内核空间发送到用户空间的通知，它表明系统配置出现了变化
    * 无论kobject被创建还是被删除，都会产生这种事件
    * 热插拔操作
        * struct kset_hotplug_ops
            * int (*filter) (struct kset *kset, struct kobject *kobj);
            * char * (*name) (struct kset *kset, struct kobject *kobj);
            * int (*hotplug) (struct kset *kset, struct kobject *kobj, char **envp, int num_envp, char *buffer, int buffer_size);
        * 当内核要为指定的kobject产生事件时，都要调用filter函数，如果返回0，将不产生事件
* 总线、设备和驱动程序
    * 总线
        * 总线是处理器与一个或者多个设备之间的通道
        * &lt;linux/device.h&gt;
            * struct bus_type
                * char *name;
                * struct subsystem subsys;
                * struct kset drivers;
                * struct kset devices;
                * int (*match) (struct device *dev, struct device_driver *drv);
                * struct device *(*add) (struct device *parent, char *bus_id);
                * int (*hotplug) (struct device *dev, char **envp, int num_envp, char *buffer, int buffer_size);
        * 每个总线都有自己的子系统
        * 一个总线包含两个kset，分别代表了总线的驱动程序和插入总线的所有设备
        * 总线的注册
            * example
                * struct bus_type ldd_bus_type = {.name="ldd", .match=ldd_match, .hotplug=ldd_hotplug,};
                * ret = bus_register(&ldd_bus_type);
                * if (res) return ret;
            * void bus_unregister(struct bus_type *bus);
        * 总线方法
            * 当一个总线上的新设备或者新驱动程序被添加时，会一次或多次调用match函数
            * 在为用户空间产生热插拔事件前，hotplug方法允许总线添加环境变量
            * 在调用真实的硬件时，match函数通常对设备提供的硬件ID和驱动所支持的ID做某种类型的比较
        * 对设备和驱动程序的迭代
            * int bus_for_each_dev(struct bus_type *bus, struct device *start, void *data, int (*fn) (struct device *, void *));
            * int bus_for_each_drv(struct bus_type *bus, struct device_driver *start, void *data, int (*fn)(struct device_driver *, void *));
        * 总线属性
            * &lt;linux/device.h&gt;
                * struct bus_attribute
                    * struct attribute attr;
                    * ssize_t (*show) (struct bus_type *bus, char *buf);
                    * ssize_t (*store) (struct bus_type *bus, const char *buf, size_t count);
            * BUS_ATTR(name, mode, show, store);
            * int bus_create_file(struct bus_type *bus, struct bus_attribute *attr);
            * void bus_remove_file(struct bus_tyep *bus, struct bus_attribute *attr);
    * 设备
        * struct device
            * struct device *parent;
            * struct kobject kobj;
            * char bus_id[BUS_ID_SIZE];
            * struct bus_type *bus;
            * struct device_driver *driver;
            * void *driver_data
            * void (*release) (struct device *dev);
        * 设备注册
            * int device_register(struct device *dev);
            * void device_unregister(struct device *dev);
        * 设备属性
            * struct device_attribute
                * struct attribute attr;
                * ssize_t (*show) (struct device *dev, char *buf);
                * ssize_t (*store) (struct device *dev, const char *buf, size_t count);
            * DEVICE_ATTR(name, mode, show, store);
            * int device_create_file(struct device *device, struct device_attribute *entry);
            * void device_remove_file(struct device *dev, struct device_attribute *attr);
        * 设备结构的嵌入
            * device结构中包含了设备模型核心用来模拟系统的信息
            * 通常，底层驱动程序并不知道device结构
    * 设备驱动程序
        * struct device_driver
            * char *name;
            * struct bus_type *bus;
            * struct kobject kobj;
            * struct list_head devices;
            * int (*probe) (struct device *dev);
            * int (*remove) (struct device *dev);
            * void (*shutdown) (struct device *dev);
        * probe是用来查询特定设备是否存在的函数
        * 当设备从系统中删除的时候要调用remove函数
        * 在关机的时候调用shutdown函数关闭设备
        * int driver_register(struct device_driver *drv);
        * void driver_unregister(struct device_driver *drv);
        * struct driver_attribute
            * struct attribute attr;
            * ssize_t (*show) (struct device_driver *drv, char *buf);
            * ssize_t (*store) (struct device_driver *drv, const char *buf, size_t count);
        * int driver_create_file(struct device_driver *drv, struct driver_attribute *attr);
        * void driver_remove_file(struct device_driver *drv, struct driver_attribute *attr);
        * 驱动程序结构的嵌入
            * device_driver结构通常被包含在高层和总结相关的结构中
* 类
    * 类是一个设备的高层视图，它抽象出了低层的实现细节
    * 几乎所有类都显示在/sys/class目录中
        * /sys/class/net
        * /sys/class/input
        * /sys/class/tty
        * /sys/block
    * class_simple接口
        * 创建类本身
            * struct class_simple *class_simple_create(struct module *owner, char *name);
        * 销毁一个简单类
            * void class_simple_destroy(struct class_simple *cs);
        * 为一个简单类添加设备
            * struct class_device *class_simple_device_add(struct class_simple *cs, dev_t devnum, struct device *device, const char *fmt, ...);
        * int class_simple_set_hotplug(struct class_simple *cs, int (*hotplug) (struct class_device *dev, char **envp, int num_envp, crah *buffer, int buffer_size));
        * void class_simple_device_remove(dev_t dev);
    * 完整的类接口
        * 管理类
            * struct class
                * char *name;
                * struct class_attribute *class_attrs;
                * struct class_device_attribute *class_dev_attrs;
                * int (*hotplug) (struct class_device *dev, char **envp, int num_envp, char *buffer, int buffer_size);
                * void (*release) (struct class_device *dev);
                * void (*class_release) (struct class *class);
            * int class_register(struct class *cls);
            * void class_unregister(struct class *cls);
            * struct class_attribute
                * struct attribute attr;
                * ssize_t (*show) (struct class *cls, char *buf);
                * ssize (*store) (struct class *cls, const char *buf, size_t count);
            * CLASS_ATTR(name, mode, show, store);
            * int class_create_file(struct class *cls, const struct class_attribute *attr);
            * void class_remove_file(struct class *cls, const struct class_attribute *attr);
        * 类设备
            * strict class_device
                * struct kobject kobj;
                * struct class *class;
                * struct device *dev;
                * void *class_data;
                * char class_id[BUS_ID_SIZE];
            * int class_device_register(struct class_device *cd);
            * void class_device_unregister(struct class_device *cd);
            * int class_device_renmae(struct class_device *cd, char *new_name);
            * struct class_device_attribute
                * struct attribute attr;
                * ssize_t (*show) (struct class_device *cls, char *buf);
                * ssize_t (*store) (struct class_device *cls, const char *buf, size_t count);
            * CLASS_DEVICE_ATTR(name, mode, show, store);
            * int class_deivce_create_file(struct class_device *cls, const struct class_device_attribute *attr);
            * void class_device_remove_file(struct class_device *cls, const struct class_device_attribute *attr);
        * 类接口
            * struct class_interface
                * struct class *class;
                * int (*add) (struct class_device *cd);
                * void (*remove) (struct class_device *cd);
            * int class_interface_register(struct class_interface *intf);
            * void class_interface_unregister(struct class_interface *intf);
* 各环节的整合
    * 添加一个设备
        * PCI子系统声明了一个bus_type结构，称为pci_bus_type
            * struct bus_type pci_bus_type
                * .name = "pci",
                * .match = pci_bus_match,
                * .hotplug = pci_hotplug,
                * .suspend = pci_device_suspend,
                * .resume = pci_device_resume,
                * .dev_attrs = pci_dev_attrs,
        * 注册后，将会创建一个sysfs目录/sys/bus/pci，其中包含了两个目录：devices和drivers
        * 所有的PCI驱动程序都必须定义一个pci_driver结构变量，这个结构中包含了一个device_driver结构，在注册PCI驱动程序时，这个结构将被初始化
            * drv-&gt;driver.name = drv-&gt;name;
            * drv-&gt;driver.bus = &pci_bus_type;
            * drv-&gt;driver.probe = pci_device_probe;
            * drv-&gt;driver.remove = pci_device_remove;
            * drv-&gt;driver.kobj.ktype = &pci_deiver_kobj_type;
            * error = driver_register(&drv-&gt;driver);
        * 当一个PCI设备被找到时，PCI核心在内存中创建一个pci_dev类型的结构变量
            * struct pci_dev
                * unsigned int devfn;
                * unsigned short vendor;
                * unsigned short device;
                * unsigned short subsystem_vendor;
                * unsigned short subsystem_device;
                * unsigned int class;
                * struct pci_driver *driver;
                * struct device dev;
            * 初始化时，device结构变量的parent变量被设置为PCI设备所在的总线设备
        * device_register(&dev-&gt;dev);
        * device_register函数中，驱动程序核心向kobject核心注册设备的kobject
        * 接着设备将被添加到与总线相关的所有设备链表中，遍历这个链表，并且为每个驱动程序调用该总线的match函数，同时指定该设备
        * 如果匹配工作圆满完成，函数向驱动程序核心返回1，驱动程序核心将device结构中的driver指针指向这个驱动程序，然后调用device_driver结构中指定的probe函数
    * 删除设备
        * 调用pci_remove_bus_device函数
        * 该函数做些PCI相关的清理工作，然后使用指向pci_dev中的device结构的指针，调用device_unregister函数
        * device_unregister函数中，驱动程序核心只是删除了从绑定设备的驱动程序到sysfs文件的符号链接，从内部设备链表中删除了该设备，并且以device结构中的kobject结构指针为参数，调用kobject_del函数
        * kobject_del函数删除了设备的kobject引用，如果该引用是最后一个，就要调用该PCI设备的release函数
    * 添加驱动程序
        * 调用pci_register_driver函数时，一个PCI驱动程序被添加到PCI核心中
        * 该函数只是初始化了包含在pci_driver结构中的device_driver结构
        * PCI核心用包含在pci_driver结构的device_driver结构指针作为参数，在驱动程序核心内调用driver_register函数
        * driver_reigster函数初始化了几个device_driver中的锁，然后调用bus_add_driver函数，该函数按以下步骤操作
            * 查找与驱动程序相关的总线
            * 根据驱动程序的名字以及相关的总线，创建驱动程序的sysfs目录
            * 获取总线内部的锁，接着遍历所有向总线注册的设备，为这些设备调用match函数
    * 删除驱动程序
        * 调用pci_unregister_driver函数
        * 该函数用包含在pci_driver结构中的device_driver结构作为参数，调用驱动程序核心函数driver_unregister
        * driver_unregister函数清除在sysfs树中属于驱动程序的sysfs属性
        * 遍历所有属于该驱动程序的设备，并为其调用release函数
* 处理固件
    * 将固件代码放入驱动程序会使驱动程序代码膨胀，使得固件升级困难，并容易导致许可证问题
    * 不要把包含固件的驱动程序放入内核，或者包含在Linux发行版中
    * 内核固件接口
        * &lt;linux/firmware.h&gt;
            * int request_firmware(const struct firmware **fw, char *name, struct device *device);
            * struct firmware
                * size_t size;
                * u8 *data;
            * void release_firmware(struct firmware *fw);
            * int request_firmware_nowait(struct module *module, char *name, struct device *device, void *context, void (*cont)(const struct firmware *fw, void *context));
    * 工作原理
        * 固件子系统使用sysfs和热插拔机制工作
        * 调用request_firmware时，在/sys/class/firmware下将创建一个目录，该目录使用设备名作为它的目录名，该目录包含三个属性
            * loading
                * 由负责装载固件的用户空间进程设置为1
            * data
                * 是一个二进制属性，用来接收固件数据
            * device
                * 该属性是到/sys/devices下相应入口的符号链接
        * 一旦sysfs入口被创建，内核将为设备产生热插拔事件，传递给热插拔处理程序的环境包括一个FIRMWARE变量，它将设置为提供给request_firmware的名字
        * 处理程序定位固件文件，使用所提供的属性把固件文件拷贝到内核，如果不能发现固件文件，处理程序将设置loading属性为-1
        * 如果在10秒钟之内不能为固件的请求提供服务，内核将放弃努力并向驱动程序返回错误状态，这个超时值可以通过修改sysfs属性/sys/class/firmware/timeout来改变
        * 不能在没有制造商许可的情况下发行设备的固件
