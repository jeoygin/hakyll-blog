---
title: iozone测试文件系统
tags:
  - benchmark
  - filesystem
  - iozone
id: 295
categories:
  - 精品转载
date: 2010-05-09 02:27:34
---

**iozone介绍：**

iozone（[www.iozone.org](http://www.iozone.org))是一个文件系统的benchmark工具，可以测试不同的操作系统中文件系统的读写性能。

可以测试 Read, write, re-read,re-write, read backwards, read strided, fread, fwrite, random read, pread,mmap, aio_read, aio_write 等等不同的模式下的硬盘的性能。


<!--more-->


测试参数： -i # 用来指定测试内容.

```
0=write/rewrite
1=read/re-read
2=random-read/write
3=Read-backwards
4=Re-write-record
5=stride-read
6=fwrite/re-fwrite
7=fread/Re-fread
8=random mix
9=pwrite/Re-pwrite
10=pread/Re-pread
11=pwritev/Re-pwritev
12=preadv/Re-preadv
```

测试格式为-i #，比如测试写：-i 0,测试读和写：-i 0 -i 1。

```
-R 产生execl格式的输出日志。
-b 将产生二进制的execl的日志文件名。
-s 测试的文件大小。
-r 文件块大小。
-a 在希望的文件系统上测试，不过只有-a的话会进行全面测试，要花费很长时间，最好用-i指定测试范围。
-g 指定最大测试文件大小。
-n 指定最小测试文件大小。
-f 指定测试文件。
-C 显示每个节点的吞吐量。
-c 测试包括文件的关闭时间。
```

用tee命令生成log信息。

```
./iozone -g 2G -n 512M -i 0 -i 1 -f /mnt/test -Rab /home/iozone.xls -C | tee /home/iozone.log
```

iozone的日志文件写入到了iozone.log内。

**测试实例**

```
  $ iozone -i 0 -i 1 -Rab ~/test-iozone.xls -g 4M -n 1M -C
```

通过iozone测试硬盘性能

通过iozone测试硬盘性能

---------------------------------------------------------------

iozone的确是一款不错的文件系统性能测试工具，可以就文件系统的很多方面作自动测试。地址：www.iozone.org

用法：

在希望进行测试的文件系统上运行：

```
/opt/iozone/bin/iozone -a
```

即可进行全面的自动测试，不过通常需要很长的时间，要耐心等待。

```
/opt/iozone/bin/iozone -a -i 1
```

只对write, rewrite进行性能测试

```
/opt/iozone/bin/iozone -a -i 1 -i 0
```

对读写进行性能测试

```
/opt/iozone/bin/iozone -a -g 1G -i 0 -i 1
```

对读写进行性能测试,并且最大测试文件为1G

```
/opt/iozone/bin/iozone -Ra
```

测试所有方面,并且生成excel文件

上面的命令在执行时,最好通过重定向保存到另外一个文件中.

```
/opt/iozone/bin/iozone –Rab output.wks
```

测试小文件

```
/opt/iozone/bin/iozone -a -s 512m -y 1k -q 8k -b minfile_result.xls
```

测试普通文件

如果2G内存测试，时间太长，先在grub.conf里把内存变成256m，这时使用512m的文件测试，就不会使用缓存了。

可以保证测试的准确性

```
/opt/iozone/bin/iozone -a -s 512m -y 8k -q 512k -b comfile_result.xls
```

测试大文件

```
/opt/iozone/bin/iozone -a -s 512m -y 1024k -q 10240k -i 0 -i 1 -i 2 -b largefile_result.xls
```

测试-i命令的使用

```
/opt/iozone/bin/iozone -Rab output.wks -g 1G -i 0 -i 1 -i 2 -i 8
```

-R 创建 Excel 报告

-g 设置自动模式下最大文件大小

Set maximum file size (in Kbytes) for auto mode.

-s 指定文件大小

```
-s 512k or -s 512M or -s 1G
```

-f filename

指定临时文件

-F filename filename filename

指定临时文件组

-t #

线程数

-q 指定最大记录大小

```
-q 512K or -q 512M or -q 1g
```

-y 指定最小记录大小

```
-y 512K or -q 512M or -q 1g
```

-U mountpoint

Mount point to unmount and remount between tests. Iozone will unmount and remount this mount point before beginning each test. This guarantees that the buffer cache does not contain any of the file under test.

通常情况下，测试的文件大小要求至少是系统cache的两倍以上，这样，测试的结果才是真是可信的。如果小于cache的两倍，文件的读写测试读写的将是cache的速度，测试的结果大打折扣。
