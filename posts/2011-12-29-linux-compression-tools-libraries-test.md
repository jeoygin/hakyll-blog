---
title: Linux几种压缩工具或库的简单测试
tags:
  - Compression
  - Linux
  - Test
id: 525
categories:
  - 计算机技术
  - 操作系统
date: 2011-12-29 22:15:14
---

Linux系统下可用的压缩工具或库很多，我找了几个我所知的做了个简单测试，为以后硬盘压力太大需要压缩数据时做个参考。共测试了lzop、quicklz、gzip、bzip2、xz、p7zip这6个工具或库，据说Google的snappy也不错，可惜没有命令行程序，就没进行测试。

**1\. 测试环境**

OS：CentOS 5.6 x86-64

Kernel：CentOS 5.6 x86-64

CPU：16 * Intel(R) Xeon(R) CPU 2.4G

Memory：16GB +

Disk：SATA

Compiler：gcc 4.1.2

**2\. 安装**

```
yum install gzip bzip2 xz
```

<!--more-->


lzop：

```
cd /opt
wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.06.tar.gz
tar zxvf lzo-2.06.tar.gz
cd lzo-2.06
./configure
make
make install

cd ..
wget http://www.lzop.org/download/lzop-1.03.tar.gz
tar zxvf lzop-1.03.tar.gz
cd lzop-1.03
./configure
make
make install
```

quicklz：

```
cd /opt
mkdir quicklz
cd quicklz
wget http://www.quicklz.com/quicklz.h
wget http://www.quicklz.com/quicklz.c
wget http://www.quicklz.com/compress_file.c
wget http://www.quicklz.com/decompress_file.c
gcc -c quicklz.c
gcc -o compress_file compress_file.c quicklz.c
gcc -o decompress_file decompress_file.c quicklz.c
```

p7zip：

从http://sourceforge.net/projects/p7zip下载p7zip_9.20.1_src_all.tar.bz2，保存到/opt。

```
cd /opt
tar -jxvf p7zip_9.20.1_src_all.tar.bz2
cd p7zip_9.20.1
make
./install.sh
```

**3\. 准备测试数据**

找了一些文本数据，用tar打包这些数据，存放到/opt/test.tar，大小为1.1GB。

**4\. 测试**

**　　lzop：**

```
cd /opt
# compress:
time lzop -f -o test.tar.lzo test.tar
# decompress:
time lzop -d -f -o test.lzo.tar test.tar.lzo
```

**　　quicklz：**

```
cd /opt/
# compress:
time quicklz/compress_file test.tar test.tar.qz
# decompress:
time quicklz/decompress_file test.tar.qz test.qz.tar
```

**　　gzip：**

```
cd /opt/
# compress:
time gzip -c  test.tar > test.tar.gz
# decompress:
time gzip -cd test.tar.gz > test.gz.tar
```

**　　bzip2：**

```
cd /opt/
# compress:
time bzip2 -kfc test.tar > test.tar.bz2
# decompress:
time bunzip2 -kfc test.tar.bz2 > test.bz2.tar
```

**　　xz：**

```
cd /opt/
# compress:
time xz -kfc test.tar > test.tar.xz
# decompress:
time xz -dkfc test.tar.xz test.xz.tar
```

**　　p7zip：**

```
cd /opt/
# compress:
time 7za a test.tar.7z test.tar
# decompress:
time 7za e test.tar.7z
```

**5\. 测试结果**

<table>

* * *

<td>压缩算法</td>
<td>压缩后数据大小</td>
<td>压缩速率（MB/s）</td>
<td>解压缩速率（MB/s）</td>
</hr>
<tr>
<td>lzop</td>
<td>28.7%</td>
<td>268.8</td>
<td>266.0</td>
</tr>
<tr>
<td>quicklz</td>
<td>22.6%</td>
<td>107.0</td>
<td>95.0</td>
</tr>
<tr>
<td>gzip</td>
<td>16.1%</td>
<td>36.4</td>
<td>116.6</td>
</tr>
<tr>
<td>bzip2</td>
<td>11.3%</td>
<td>3.1</td>
<td>25.2</td>
</tr>
<tr>
<td>xz</td>
<td>11.4%</td>
<td>0.3</td>
<td>58.1</td>
</tr>
<tr>
<td>p7zip</td>
<td>11.8%</td>
<td>3.6</td>
<td>56.3</td>
</tr>
</table>

从上表可看出每种压缩算法、工具都有其倾向性，有的倾向于高压缩比，有的倾向于高速率。可以明显地看出lzop和quicklz的压缩和解压缩速率都比较高，而压缩后的数据也相对要大很多，quicklz的官方网站号称其是最快的压缩库，但我测出来的结果却和官方的测试结果差很多，或许是我的测试方式不恰当。bzip2、xz和p7zip的压缩比很高，但压缩过程却很漫长，好在解压缩速度还可忍受，适合用于存储压力较大、不对数据做更新或更新频率较低的场景，比如在网盘上存储的文件用7z压缩就挺好的。gzip采用比较折衷的方案，压缩比和压缩速率处于平均水平，既能减少文件占用的空间，又不带来太大的时间开销，或许这也是gzip用得比较多的缘故吧。

**6\. 后记**

文中若有错误或疏漏之处，烦请批评指正。
