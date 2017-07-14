---
title: VMWare虚拟机迁移到Xen
tags:
  - VMWare
  - xen
id: 317
categories:
  - 计算机技术
  - 虚拟化
date: 2010-08-27 07:17:41
---

最近由于项目需要，要将VMWare安装的Windows虚拟机迁移到XEN，将VMWare的虚拟机镜像经过转换之后没有问题，能正确识别磁盘（在虚拟机中用WinPE启动能看到C盘中的内容），但是无法进入Windows系统，用Xen启动虚拟机会出黑屏后关机，用KVM启动虚拟机后会出现蓝屏，错误信息是：

```
STOP: 0x0000007B (0xF741B84C,0xC0000034,0x00000000,0x00000000)
INACCESSIBLE_BOOT_DEVICE
```

<!--more-->


在网上看到一篇文章《[Converting a VMWare image to Xen HVM](http://ian.blenke.com/vmware/vmdk/xen/hvm/qemu)》，按照作者所说的做，解决了问题，在此与大家分享这个解决方法。

首先，需要确定是SCSI还是IDE虚拟磁盘，如果在VMWare下建立SCSI磁盘并且安装Windows，那么Windows没有适用于Xen HVM的IDE驱动，需要在Windows系统中进行以下操作：

1.在%SystemRoot%Driver CacheI386Driver.cab文件中提取Atapi.sys, Intelide.sys, Pciide.sys, and Pciidex.sys四个文件，并复制到%SystemRoot%System32Drivers中；

2.将以下内容写入记事本中，并且保存为Mergeide.reg

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\primary_ide_channel]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="atapi"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\secondary_ide_channel]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="atapi"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\*pnp0600]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="atapi"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\*azt0502]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="atapi"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\gendisk]
"ClassGUID"="{4D36E967-E325-11CE-BFC1-08002BE10318}"
"Service"="disk"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#cc_0101]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_0e11&dev_ae33]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1039&dev_0601]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1039&dev_5513]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1042&dev_1000]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_105a&dev_4d33]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0640]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0646]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0646&REV_05]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0646&REV_07]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0648]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1095&dev_0649]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1097&dev_0038]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_10ad&dev_0001]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_10ad&dev_0150]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_10b9&dev_5215]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_10b9&dev_5219]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_10b9&dev_5229]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="pciide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_1106&dev_0571]
"Service"="pciide"
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_1222]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_1230]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_2411]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_2421]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_7010]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_7111]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CriticalDeviceDatabase\pci#ven_8086&dev_7199]
"ClassGUID"="{4D36E96A-E325-11CE-BFC1-08002BE10318}"
"Service"="intelide"

;Add driver for Atapi (requires Atapi.sys in Drivers directory)

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\atapi]
"ErrorControl"=dword:00000001
"Group"="SCSI miniport"
"Start"=dword:00000000
"Tag"=dword:00000019
"Type"=dword:00000001
"DisplayName"="Standard IDE/ESDI Hard Disk Controller"
"ImagePath"=hex(2):53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,44,00,\ 
  52,00,49,00,56,00,45,00,52,00,53,00,5c,00,61,00,74,00,61,00,70,00,69,00,2e,\ 
  00,73,00,79,00,73,00,00,00

;Add driver for intelide (requires intelide.sys in drivers directory)

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\IntelIde]
"ErrorControl"=dword:00000001
"Group"="System Bus Extender"
"Start"=dword:00000000
"Tag"=dword:00000004
"Type"=dword:00000001
"ImagePath"=hex(2):53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,44,00,\ 
  52,00,49,00,56,00,45,00,52,00,53,00,5c,00,69,00,6e,00,74,00,65,00,6c,00,69,\ 
  00,64,00,65,00,2e,00,73,00,79,00,73,00,00,00

;Add driver for Pciide (requires Pciide.sys and Pciidex.sys in Drivers directory)

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PCIIde]
"ErrorControl"=dword:00000001
"Group"="System Bus Extender"
"Start"=dword:00000000
"Tag"=dword:00000003
"Type"=dword:00000001
"ImagePath"=hex(2):53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,44,00,\ 
  52,00,49,00,56,00,45,00,52,00,53,00,5c,00,70,00,63,00,69,00,69,00,64,00,65,\ 
  00,2e,00,73,00,79,00,73,00,00,00
```

3.双击Mergeide.reg，会提示是否将Mergeide.reg中的信息添加到注册表，点击确定；

4.退出Windows，用Xen或KVM启动虚拟机镜像将不会出现Stop 0x0000007B。

在确保Windows镜像有合适的IDE驱动后，需要转换磁盘镜像，这里需要用到VMWare的一个小工具vmware-vdiskmanager，来将比较新的VMWare VMDK文件转换成一种可兼容Xen的格式，安装VMWare Workstation或VMWare Server会自带这个工具。

VMDK虚拟磁盘镜像有几种不同的组织方式：

1.单个可动态增长文件

2.单个预分配（在创建磁盘时即分配物理磁盘空间）文件

3.多个2G的可动态增长文件（第一个.vmdk文件名字以-0001样式结束）

4.多个2G的预分配文件

假如磁盘文件是windows2003.vmdk，执行以下命令能创建一个单文件可动态增长的虚拟磁盘

vmware-vdiskmanager -r windows2003.vmdk -t 0 windows2003-flattened.vmdk 

接下来使用qemu-img工具将vmdk格式的虚拟磁盘转换成raw格式的虚拟磁盘

qemu-img convert windows-2003-flattened.vmdk windows2003.img 

完成以上操作之后，windows2003.img文件应该能够正常启动，不过很不幸的是Windows系统在安装时对你的PC硬件做了很多假设，如果你要迁移这个镜像，你可能需要修改硬件抽象层(HAL)。Windows 2003有以下6个HAL：

```
HALMACPI.DLL - ACPI Multi processor PC
HALAACPI.DLL - ACPI Uniprocessor PC
HALACPI.DLL - Advanced Configuration and PowerInterface (ACPI)
HALMPS.DLL - MPS Multiprocessor PC
HALAPIC.DLL - MPS Uniprocessor PC
HAL.DLL - Standard PC
```

在安装操作系统时，只有一个被选择并且被安装为WINDOWSSYSTEM32HAL.DLL。

如果你拷贝其他的DLL，可以修改C:boot.ini来指定不同的DLL”/HAL=HAL.DLL”。如果你创建Xen配置文件，你可以设置4种标记与以上的HAL交互：

```
# enable/disable HVM guest PAE, default=0 (disabled) 
pae=0 
# enable/disable HVM guest ACPI, default=0 (disabled) 
acpi=0 
# enable/disable HVM guest APIC, default=0 (disabled) 
apic=0 
# The number of CPUs to assign to this domU 
vcpus=1 
```

对于MPS HAL，应该启用APIC；对于ACPI HAL，应该启用ACPI。

当使用VMWare来创建Windows镜像时，它检测到ACPI并且使用ACPI HAL。为了将其恢复到”Standard PC” HAL.DLL，可以将安装光盘中的i386/hal.dl_文件用windows的expand命令展开，然后将hal.dll文件拷贝到虚拟机中的%SystemRoot%WINDOWS/system32/hal.dll。

现在，所有转换工作已完成，可以启动虚拟机啦！
