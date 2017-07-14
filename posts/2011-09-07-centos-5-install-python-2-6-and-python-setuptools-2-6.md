---
title: CentOS 5 安装python2.6和Python setuptools 2.6
tags:
  - centos
  - python
  - setuptools
id: 396
categories:
  - 计算机技术
  - 操作系统
date: 2011-09-07 11:35:06
---

安装开发包，以便编译python的modules

```
yum install openssl-devel, bzip2-devel, readline-devel, gdbm-devel, \
sqlite-devel, ncurses-devel, tk-devel
```

下载phtyon2.6源码包Python-2.6.7.tgz：

```
cd /usr/local/src
wget http://www.python.org/ftp/python/2.6.7/Python-2.6.7.tgz
```

解压缩及编译配置：

```
tar zxvf Python-2.6.7.tgz
cd Python-2.6.7
./configure --prefix=/usr/local/python2.6
```

<!--more-->


修改Python的Modules配置：

```
vim Modules/Setup
```

查找zlib zlibmodule.c，将找到如下一行：

```
#zlib zlibmodule.c -I$(prefix)/include -L$(exec_prefix)/lib -lz
```

将前边的#号去掉，然后编译安装：

```
make
make install
```

编辑环境变量

```
vim ~/.bashrc
```

在最后添加

```
export PATH=$PATH:/usr/local/python2.6/bin
```

下载并安装setuptools

```
cd ..
wget http://pypi.python.org/packages/2.6/s/setuptools/setuptools-0.6c11-py2.6.egg#md5=bfa92100bd772d5a213eedd356d64086
sh setuptools-0.6c11-py2.6.egg
```
