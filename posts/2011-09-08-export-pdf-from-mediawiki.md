---
title: 从MediaWiki导出PDF
tags:
  - MediaWiki
  - mwlib
  - PDF
  - wkhtmltopdf
id: 404
categories:
  - 计算机技术
  - 网络
date: 2011-09-08 00:08:04
---

搞了一早上才琢磨出怎么将MediaWiki中的文章导出PDF，一开始在CentOS玩，由于yum源上的python版本比较低，有些python库装不上，之后就在自己本的Debian上玩，还算比较顺利，将方法总结一下。

最开始用了一个Extension叫“Pdf Export”，使用htmldoc来转成pdf，对于英文的文章看起来还不错，无奈遇到中文就全乱码了，查了一下，说是htmldoc暂时还不支持亚洲的unicode编码。

于就是试其它的Extension了，有个Collection看着不错，不过装完后进去wiki就直接给我报HTTP 500错误，这样就不能在wiki界面上导出，只能找工具线下导出，先试Collection中用到的mwlib。

首先要安装phthon2.5以上版本，如果是Redhat系列，参照[CentOS 5 安装python2.6和Python setuptools 2.6](http://blog.jeoygin.org/archives/396)。

先准备python环境

```
apt-get install g++ perl python python-dev python-setuptools python-imaging libxslt-dev
```
<!--more-->

安装mwlib及可用的writer

```
easy_install mwlib mwlib.rl mwlib.xhtml
```

其中mwlib.rl用于导出pdf，mwlib.xhtml用于导出xhtml。

在CentOS上安装就费了点劲，python-imaging要手动编译源码，本以为用easy_install安装PIL就行了，可装完后没效果。

```
yum install gcc gcc-c++ perl python-dev libxslt-devel
cd /usr/local/src
wget http://effbot.org/downloads/Imaging-1.1.7.tar.gz
tar zxvf Imaging-1.1.7.tar.gz
cd Imaging-1.1.7
python setup.py install
```

装好mwlib后，就可以使用mw-render来导出

```
mw-render --config=http://lingcloud.org/wiki/en/ -w rl -o "test.pdf"  Requirements
```

但是导出中文有两个问题，一是缺少字体，标点符号全是小框框，二是不会自动换行。

解决第一个问题可以安装字体，执行mw-render --list-writers这个命令后提示找不到字体，把这些字体装上，并做软连接就可以了。

```
apt-get install ttf-indic-fonts ttf-unfonts-core ttf-farsiweb ttf-arphic-uming ttf-gfs-artemisia ttf-sil-ezra ttf-thai-arundina
ln -s /usr/share/fonts/truetype/* /usr/local/lib/python2.6/dist-packages/mwlib.rl-0.12.8-py2.6.egg/mwlib/fonts/
```

CentOS从源上装不了字体，把Debian安装完的字体拷贝到CentOS系统中能正常工作，只是python库的位置不太一样。

```
ln -s /usr/share/fonts/truetype/* /usr/local/python2.6/lib/python2.6/site-packages/mwlib.rl-0.12.8-py2.6.egg/mwlib/fonts/
```

解决第二个问题采用了曲线救国，使用mw-render命令导出xhtml，再用wkhtmltopdf将xhtml导出pdf。

安装wkhtmltopdf

```
cd /tmp
wget http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.10.0_rc2-static-amd64.tar.bz2
cd /usr/local/bin
tar jxvf /tmp/wkhtmltopdf-0.10.0_rc2-static-amd64.tar.bz2
ln -s /usr/bin/wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf
```

使用以下命令导出pdf

```
mw-render --config=http://lingcloud.org/wiki/en/ -w xhtml -o "test.xhtml"  Requirements
wkhtmltopdf test.xhtml test.pdf
```
