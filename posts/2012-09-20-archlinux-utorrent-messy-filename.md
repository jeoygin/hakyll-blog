---
title: 解决ArchLinux的utorrent文件名中文乱码问题
tags:
  - ArchLinux
  - Chinese
  - filename
  - messy
  - utorrent
id: 1011
categories:
  - 计算机技术
  - 操作系统
date: 2012-09-20 23:19:58
---

晚上看师弟机器上的新版utorrent的界面看起来比我机器上的友好，于是用yaourt utorrent安装了新版的utorrent（aur/utserver 27079-1），安装很顺利，安装完成后修改/etc/conf.d/utserver文件中的以下内容：

	UTSERVER_USER="utserver"

将utserver换成我的用户名，然后运行以下命令启动utserver：

	sudo rc.d start utserver

<!--more-->

然后在浏览器输入地址http://127.0.0.1:8080/gui/，很正常，修改下载目录和临时目录。找了几个种子进行试验，界面能显示中文信息，也能正常下载，下载完成后，发现问题来了：文件名中的中文字符全成了问号（???）？好像很久很久之前也遇到这个问题，但忘了怎么解决，只悔当时没做笔记。

接着，逐步排查问题，先看看utserver的日志文件/var/log/utserver/utserver.log，发现第一行如下所示：

	Using locale C

这样原因就很明确了，locale没设置正确，utserver启动后，我期望能看到的第一条日志是下面这样：

	Using locale en_US.UTF-8

有目标就好办了，首先，我尝试在命令行运行utserver，我所期待的结果出现了，进一步确定是运行后台daemon时locale没设置正确，与该问题相关的是/etc/rc.conf配置文件中的两个环境变量：

	LOCALE="en_US.UTF-8"
	DAEMON_LOCALE="yes"

如果DAEMON_LOCALE设置为"yes"，那么运行daemon时使用$LOCALE，如果$LOCALE为空，使用locale C；如果DAEMON_LOCALE设置为"no"，使用locale C。但是我的/etc/rc.conf配置文件没有问题。

接着我想是不是应该在运行utserver时设置环境变量LANG，于是在/etc/conf.d/utserver文件中添加以下内容：

	LANG=en_US.UTF-8

发现不奏效，最后只能去看/etc/rc.d/utserver这个脚本里的内容，内容不多， 很快就将目标锁定到下面这条命令：

	su -l -s /bin/sh -c "/usr/bin/utserver $UTSERVER_ARGS >/dev/null 2>&1" $UTSERVER_USER

这条命令的作用是切换到$UTSERVER_USER这个用户，利用/bin/sh来运行utserver，那问题就应该出在切换用户后locale没正确设置，于是我将命令改为：

 	su -l -s /bin/sh -c "export LANG=en_US.UTF-8; /usr/bin/utserver $UTSERVER_ARGS >/dev/null 2>&1" $UTSERVER_USER

重新启动utserver，我所期待的结果出现了，至此，问题解决了。

在Linux系统上，出现各种问题是很正常的现象，在这种情况下不要慌，先查看日志，寻找解决之道，也可以上Google搜索已观察到的现象，看看别人是如何解决我们所遇到的问题。
