---
title: 《Linux设备驱动程序》第一章 设备驱动程序简介读书笔记
tags:
  - Brief
  - Driver
  - Linux
  - Reading Note
id: 892
categories:
  - 学习笔记
date: 2012-06-15 09:18:05
---

* 设备驱动程序的作用
    * 大多数编译问题实际上都可以分成两部分
        * 需要提供什么功能（机制）
        * 如何使用这些功能（策略）
    * 驱动程序同样存在机制和策略的分享问题
    * 驱动程序设计主要考虑三个方面的因素
        * 提供给用户尽量多的选项
        * 编写驱动程序要占用的时间
        * 尽量保持程序简单而不至于错误丛生
    * 不带策略的驱动程序包括一些典型的特征
        * 同时支持同步和异步操作
        * 驱动程序能够被多次打开
        * 充分利用硬件特性
* 内核功能划分
    * 功能模块
        * 进程管理
            * 创建进程
            * 销毁进程
            * 进程间通信
                * 信号
                * 管道
                * 进程间通信原语
        * 内存管理
            * 虚拟地址空间
        * 文件系统
            * Unix的每个对象都可以当作文件来看待
        * 设备控制
            * 几乎每一个系统操作都会映射到物理设备上
            * 所有设备控制操作都由与被控制设备相关的代码来完成，这段代码就叫做驱动程序
        * 网络功能
    * 可装载模块
        * 内核提供的特性可在运行时进行扩展
        * 运行时添加到内核中的代码被称为“模块”
        * 每个模块由目标代码组成
        * insmod, rmmod
* 设备和模块的分类
    * 字符设备
        * 字符设备是个能够像字节流一样被访问的设备
        * 至少实现open、close、read和write系统调用
        * 字符终端（/dev/console）和串口（/dev/ttys0）
    * 块设备
        * 通过/dev目录下的文件系统节点来访问
        * 传输一个或多个完整的块，每块包含512字节
    * 网络接口
        * 任何网络事务都经过一个网络接口形成，即一个能够和其他主机交换数据的设备
        * 接口是个硬件设备，但也可能是个纯软件设备，比如回环（loopback）接口
    * 通用串行总线（USB）模块、串行模块、SCSI模块
    * 文件系统不是设备驱动程序
    * 文件系统类型是个软件驱动程序，文件系统模块必须实现访问目录和文件的最底层系统调用
* 安全问题
    * 缓冲区溢出
    * 小心对待未初始化的内存
    * 小心使用第三方获得的软件