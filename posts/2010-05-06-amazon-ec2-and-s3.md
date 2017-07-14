---
title: 玩玩Amazon EC2 和 S3
tags:
  - EC2
id: 286
categories:
  - 计算机技术
  - 网络
date: 2010-05-06 02:58:39
---

在网上找找翻wall的方法，有提到用EC2(Elastic Compute Cloud)，我就去试了一试，弄了两天(因为要收钱，每天不敢上太久)，终于突破限制，注册了Twitter(@wrjchn)和facebook，以下简单说说怎么玩。


<!--more-->


按着[GettingStartedGuide](http://docs.amazonwebservices.com/AWSEC2/2008-05-05/GettingStartedGuide/index.html)一步一步做，就能使用EC2和S3服务，要建立证书，配置环境变量，如果在windows上用putty的话，还得将密钥转换成putty支持的密钥格式，挺麻烦的，就不一一说了，想玩的话到官网看看指导，我的英语水平都能看懂，大部人应该没问题的。

EC2使用的命令行工具Amazon EC2 API Tools(也可以在网页上操作，毕竟执行一个脚本比在网页上操作快吧)，S3使用的工具是S3cmd(工具还有其他的，我主要用它来创建bucket,存我自己定制的image)。

最便宜的EC2 instance是每小时$0.085，分配一个IP地址是$0.01，S3存储数据是每月每G$0.150，上传数据不收钱，下载数据每月头1G免费，之后每G$0.150。

配置完了就可以开始了，先选择AMI，如果有自己的AMI，就选择它，不然就选Amazon或其他人公开的AMI，Amazon提供的是Fedora Core发行版，我很少用，最终找了一个CentOS(AMI ID: ami-cb52b6a2)；Key Pair就用自己原先创建的，之后连接Instance就靠它登陆了，不用Key Pair的话就使用操作系统里的用户名、密码登陆；防火墙一定要添加SSH(22),不然都连不上去了，如果想开web服务的话还要添加HTTP(80)。这样基本就能运行了，等个几分钟，就可以用SSH登陆服务器了。

为了把服务器做成一个代理服务器，还需要下载额外的软件，我使用了squid，在服务器上使用以下命令下载squid：

```
wget http://www.squid-cache.org/Versions/v3/3.0/squid-3.0.STABLE25.tar.gz
```

解压并进入squid安装目录：

```
Tar zxvf squid-3.0.STABLE25.tar.gz
Cd squid-3.0.STABLE25
```

安装squid：

```
./configure --prefix=/usr/local/squid
make all
make install
```

如果看到Build Successful就说明安装成功了。假设squid的路径为squid_home，那么squid的配置文件在squid_home/etc中，执行程序在squid_home/sbin中，cache和log文件在squid_home/var中。

修改squid配置文件 (squid_home/etc/squid.conf)：

```
acl all src all
acl localhost src 127.0.0.1/32

http_access allow localhost

# NETWORK OPTIONS
http_port 3128

# MEMORY CACHE OPTIONS

cache_mem 8 MB
cache_dir ufs /usr/local/squid/var/cache 100 16 256

cache_swap_low 90
cache_swap_high 95

access_log /usr/local/squid/var/logs/access.log squid
cache_log /usr/local/squid/var/logs/cache.log
cache_store_log /usr/local/squid/var/logs/store.log

cache_mgr <your email>
client_netmask 255.255.255.255 

```

如果var的所有者和所属组为root，那么使用以下命令修改：

```
Chown –R nobody:nobody /usr/local/squid/var
```

现在可以启动cache和代理服务器了：

```
/usr/local/squid/sbin/squid –z
/usr/local/squid/sbin/squid
```

使用以下命令查看squid是否正常运行：

```
netstat –ntl | grep 3128
```

如果能看不到任何信息，说明squid没启动。

之后就能用SSH建立通道来做代理，可以使用以下命令建立通道：

```
ssh -f user@server -L local-port:host:remote-port –N
```

那么对本地端口local-port的访问将会跳转到远程端口remote-port。

如果使用putty，那么在Connection-SSH-Tunnels中，填写Source port(本地端口)、Destination（远程端口，格式为host:remote-port），之后点击Add按钮，否则无效。

然后就设置网络代理啦，代理服务器设置为localhost:local-port，就可以……
