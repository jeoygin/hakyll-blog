---
title: 硬盘安装openSuse后无法进入Win7
tags:
  - openSuse
  - Win7
  - xen
id: 330
categories:
  - 计算机技术
  - 虚拟化
date: 2011-01-26 07:35:29
---

最近又在做测试，无奈我的本本上的ubuntu只要装了显卡驱动就无法启动带Xen的kernel，今天一时兴起就装了个openSuse，依然用硬盘安装。openSuse用硬盘安装还算不太麻烦，将下载的iso解压出来，其中有一个openSUSE11_3_LOCAL.exe，运行之后一直点next，最后提示重启，重启之后会添加一个安装openSuse的启动项，就可以开始安装啦。

<!--more-->

安装系统后，修改了软件源，安装上Xen，重启之后发现带Xen的kernel无法启动，难道这是N卡的悲剧，无奈了，再进其它系统，这会又发现Win7进不去了，真是赔了夫人又折兵，可能是openSUSE11_3_LOCAL.exe这玩意弄坏了启动顺序，这会又忘了Win7各种启动手段的优先级，之后是各种乱试。先是进Ubuntu，把今天创建的文件备份后给删了，依然不行，又进Ubuntu，如此反复，折腾了一两个小时，连从备份的gho文件中把BCD给提取出来都试过了，最后终于有一尝试成功了。

删除根目录下的grldr和grldr.mbr，能见到启动项了，最下边还有个安装openSuse的选项，俺知道openSuse安装是用grub，俺也知道grub4dos会用到grldr和grldr.mbr，怎么它们的优先级这么高呢？

接下来就是要干掉openSuse的启动项啦，删除根目录的menu.lst、openSUSE_hitme.txt、openSUSE，之后还要删除BCD中的启动项，打开命令行窗口，用bcdedit查看所有的启动项，然后用bcdedit /delete {id}删除启动项，{id}为看到的具体的id，注意两边要有大括号。
