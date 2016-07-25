---
title: 《Linux设备驱动程序》第十三章 USB驱动程序读书笔记
tags:
  - Driver
  - Linux
  - Reading Note
  - USB
id: 974
categories:
  - 学习笔记
date: 2012-07-04 19:17:26
---

* 简介
    * 通用串行总线（USB）是主机和外围设备之间的一种连接
    * 从拓扑上来看，一个USB子系统并不是以总线的方式来布置的；它是一棵由几个点对点的连接构建而成的树
    * 这些连接是连接设备和集线器（hub）的四线电缆（地线、电源线和两根信号线）
    * USB协议规范定义了一套任何特定类型的设备都可以遵循的标准，如果一个设备遵循该标准，就不需要一个特殊的驱动程序
    * Linux内核支持两种主要类型的USB驱动程序
        * 宿主系统上的驱动程序
            * 控制插入其中的USB设备
        * 设备上的驱动程序
            * 控制该设备如何作为一个USB设备和主机通信
* USB设备基础
    * Linux内核提供了一个称为USB核心的子系统来处理大部分的复杂性
    * 端点
        * USB通信最基本的形式是通过一个名为端点（endpoint）的东西
        * USB端点只能往一个方向传送数据，从主机到设备（输出端点）或者从设备到主机（输入端点）
        * USB端点有四种不同的类型
            * 控制
                * 控制端点用来控制对USB设备不同部分的访问
                * 每个USB设备都有一个名为“端点0”的控制端点
            * 中断
                * 每当USB宿主要求设备传输数据时，中断端点就以一个固定的速率来传送少量的数据
            * 批量
                * 批量（bulk）端点传输大批量的数据
            * 等时
                * 等时（isochronous）端点同样可以传送大批量的数据，但数据是否到达是没有保证的
        * 控制和批量端点用于异步的数据传输，只要驱动程序决定使用它们
        * 内核中使用struct usb_host_endpoint结构体来描述USB端点，该结构体在另一个名为struct usb_endpoint_descriptor的结构体中包含了真正的端点信息
        * struct usb_host_endpoint
            * bEndpointAddress
            * bmAttributes
            * wMaxPacketSize
            * bInterval
    * 接口
        * USB端口被捆绑为接口
        * USB接口只处理一种USB逻辑连接
        * struct usb_interface
            * struct usb_host_interface *altsetting
            * unsigned num_altsetting
            * struct usb_host_interface *cur_altsetting
            * int minor
    * 配置
        * USB接口本身被捆绑为配置
        * 一个USB设备可以有多个配置，而且可以配置之间切换以改变设备的状态
        * struct usb_host_config
        * struct usb_device
        * include/linux/usb.h.
        * USB设备是非常复杂的，它由许多不同的逻辑单元组成
            * 设备通常具有一个或者更多的配置
            * 配置经常具有一个或者更多的接口
            * 接口通常具有一个或者更多的设置
            * 接口没有或者具有一个以上的端口
<!--more-->
* USB和Sysfs
    * 无论是物理USB设备还是单独的USB接口，在sysfs中均表示为单独的设备
    * 第一个USB设备是一个根集线器，这是一个USB控制器，通常包含在一个PCI设备中，该控制器是连接PCI总线和USB总线的桥，也是该总线上的第一个USB设备
    * 所有的根集线器都由USB核心分配了一个独特的编号
    * USB sysfs设备命名方案为：根集线器-集线器端口号:配置.接口
    * /proc/bus/usb/
    * /proc/bus/usb/devices
* USB urb
    * Linux内核中的USB代码通过一个称为urb（USB请求块）的东西和所有的USB设置通信
    * include/linux/usb.h
    * struct urb
    * urb被用来以一种异步的方式往/从特定的USB设备上的特定USB端口发送/接收数据
    * 一个urb的典型生命周期如下
        * 由USB设备驱动程序创建
        * 分配给一个特定USB设备的特定端点
        * 由USB设备驱动程序递交到USB核心
        * 由USB核心递交到特定设备的特定USB主控制器驱动程序
        * 由USB主控制器驱动程序处理，它从设备进行USB传送
        * 当urb结束之后，USB主控制器驱动程序通知USB设备驱动程序
    * struct urb
        * struct urb
            * struct usb_device *dev
            * unsigned int pipe
                * 必须使用下列恰当的函数来设置该结构体的字段
                * unsigned int usb_sndctrlpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_rcvctrlpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_sndbulkpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_rcvbulkpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_sndintpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_rcvintpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_sndisocpipe(struct usb_device *dev, unsigned int endpoint)
                * unsigned int usb_rcvisocpipe(struct usb_device *dev, unsigned int endpoint)
            * unsigned int transfer_flags
                * URB_SHORT_NOT_OK
                * URB_ISO_ASAP
                * URB_NO_TRANSFER_DMA_MAP
                * URB_NO_SETUP_DMA_MAP
                * URB_ASYNC_UNLINK
                * URB_NO_FSBR
                * URB_ZERO_PACKET
                * URB_NO_INTERRUPT
            * void *transfer_buffer
            * dma_addr_t transfer_dma
            * int transfer_buffer_length
            * unsigned char *setup_packet
            * dma_addr_t setup_dma
            * usb_complete_t complete
                * typedef void (*usb_complete_t) (struct urb *, struct pt_regs *);
            * void *context
            * int actual_length
            * int status
                * 0
                * -ENOENT
                * -ECONNRESET
                * -EINPROGRESS
                * -EPROTO
                * -EILSEQ
                * -EPIPE
                * -ECOMM
                * -ENOSR
                * -EOVERFLOW
                * -EREMOTEIO
                * -ENODEV
                * -EXDEV
                * _EINVAL
                * -ESHUTDOWN
            * int start_frame
            * int interval
            * int number_of_packets
            * int error_count
            * struct usb_iso_packet_descriptor iso_frame_desc[0]
        * struct usb_iso_packet_descriptor
            * unsigned int offset
            * unsigned int length
            * unsigned int actual_length
            * unsigned int status
    * 创建和销毁urb
        * struct urb *usb_alloc_urb(int iso_packets, int mem_flags);
        * void usb_free_urb(struct urb *urb);
        * 中断urb
            * void usb_file_int_urb(struct urb *urb, struct usb_device *dev, unsigned pipe, void *transfer_buffer, int buffer_length, usb_complete_t complete, void *context, int interval);
        * 批量urb
            * void usb_fill_bulk_urb(struct urb *urb, struct usb_device *dev, unsigned int pipe, void *transfer_buffer, int buffer_length, usb_complete_t complete, void *context);
        * 控制urb
            * void usb_fill_control_urb(struct urb *urb, struct usb_device *dev, unsigned int pipe, unsigned char *setup_packet, void *transfer_buffer, int buffer_length, usb_complete_t complete, void *context);
        * 等时urb
            * 没有和中断、控制和批量urb类似的初始化函数，因此它们在被提交到USB核心之前，必须驱动程序中“手工地”进行初始化
            * drivers/usb/media/konicawc.c
    * 提交urb
        * int usb_submit_urb(struct urb *urb, int mem_flags);
    * 结束urb：结束回调处理例程
        * 只有三种结束urb和调用结束函数的情形
            * urb被成功地发送到了设备，设备返回了正确的确认
            * 发送数据到设备或者从设备接收数据时发生了某种错误
            * urb从USB核心中被“解开链接”
    * 取消urb
        * int usb_kill_urb(struct urb *urb);
        * int usb_unlink_urb(struct urb *urb);
* 编写USB驱动程序
    * 驱动程序支持哪些设备
        * struct usb_device_id结构体提供了一列不同类型的该驱动程序支持的USB设备
        * struct usb_device_id
            * __u16 match_flags
                * include/linux/mod_devicetable.h中的USB_DEVICE_ID_MATCH_*
            * __u16 idVendor
            * __u16 idProduct
            * __u16 bcdDevice_lo
            * __u16 bcdDevice_hi
            * __u8 bDeviceClass
            * __u8 bDeviceSubClass
            * __u8 bDeviceProtocol
            * __u8 bInterfaceClass
            * __u8 bInterfaceSubClass
            * __u8 bInterfaceProtocol
            * kernel_ulong_t driver_info
        * USB_DEVICE(vendor, product)
        * USB_DEVICE_VER(vendor, product, lo, hi);
        * USB_DEVICE_INFO(class, subclass, protocol);
        * USB_INTERFACE_INFO(class, subclass, protocol);
    * 注册USB驱动程序
        * struct usb_driver
            * struct module *owner
            * const char *name
            * const struct usb_device_id *id_table
            * int (*probe) (struct usb_interface *intf, const struct usb_device_id *id);
            * void (*disconnect) (struct usb_interface *intf);
            * int (*ioctl) (struct usb_interface *intf, unsigned int code, void *buf);
            * int (*suspend) (struct usb_interface *intf, u32 state);
            * int (*resume) (struct usb_interface *intf);
        * usb_register_driver(struct usb_driver *driver)
        * usb_deregister(struct usb_driver *driver);
    * 探测和断开的细节
        * usb_set_intfdata(interface, dev);
        * dev = usb_get_intfdata(interface);
        * usb_register_dev(struct usb_interface * interface, struct usb_class_driver * class);
        * usb_deregister_dev(struct usb_interface * interface, struct usb_class_driver * class);
        * struct usb_class_driver
            * char *name
            * struct file_operations *fops
            * mode_t mode
            * int minor_base
    * 提交和控制urb
        * 当驱动程序有数据要发送到USB设备时，必须分配一个urb来把数据传输给设备
            * urb = usb_alloc_urb(0, GFP_KERNEL);
        * 在urb被成功地分配之后，还应该创建一个DMA缓冲区来以最高效的方式发送数据到设备，传递给驱动程序的数据应该复制到该缓冲区中
            * buf = usb_buffer_alloc(dev-&gt;udev, count, GFP_KERNEL, &urb-&gt;transfer_dma);
        * 一旦数据从用户空间正确地复制到了局部缓冲区中，urb必须在可以被提交给USB核心之前被正确地初始化
            * usb_fill_bulk_urb(urb, dev-&gt;udev, usb_sndbulkpipe(dev-&gt;udev, dev-&gt;bulk_out_endpointAddr), buf, count, skel_write_bulk_callback, dev);
        * urb被正确地分配了，数据被正确地复制了，urb被正确地初始化了，它就可以被提交给USB核心以传输到设备
            * retval = usb_submit_urb(urb, GFP_KERNEL);
        * static void skel_write_bulk_callback(struct urb *urb, struct pt_regs *regs)
        * {
            * usb_buffer_free(urb-&gt;dev, urb-&gt;transfer_buffer_length, urb-&gt;transfer_buffer, urb-&gt;transfer_dma);
        * }
* 不使用urb的USB传输
    * usb_bulk_msg
        * int usb_bulk_msg(struct usb_device *usb_dev, unsigned int pipe, void *data, int len, int *actual_length, int timeout);
    * usb_control_msg
        * int usb_control_msg(struct sub_device *dev, unsigned int pipe, __u8 request, __u8 requesttype, __u16 value, __u16 index, void *data, __u16 size, int timeout);
    * 其他USB数据函数
        * int usb_get_descriptor(struct usb_device *dev, unsigned char type, unsigned char index, void *buf, int size);
            * type
                * USB_DT_DEVICE
                * USB_DT_CONFIG
                * USB_DT_STRING
                * USB_DT_INTERFACE
                * USB_DT_ENDPOINT
                * USB_DT_DEVICE_QUALIFIER
                * USB_DT_OTHER_SPEED_CONFIG
                * USB_DT_INTERFACE_POWER
                * USB_DT_OTG
                * USB_DT_DEBUG
                * USB_DT_INTERFACE_ASSOCIATION
                * USB_DT_CS_DEVICE
                * USB_DT_CS_CONFIG
                * USB_DT_CS_STRING
                * USB_DT_CS_INTERFACE
                * USB_DT_CS_ENDPOINT
        * int usb_get_string(struct usb_device *dev, unsigned short langid, unsigned char index, void *buf, int size);
