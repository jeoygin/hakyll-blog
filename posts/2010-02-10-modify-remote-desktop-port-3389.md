---
title: 更改远程桌面端口3389
id: 99
categories:
  - 精品转载
date: 2010-02-10 23:47:09
tags:
---

系统中的远程终端服务是一项功能非常强大的服务，同时也成了入侵者长驻主机的通道，入侵者可以利用一些手段得到管理员账号和密码并入侵主机。下面，我们来看看如何通过修改默认端口，防范黑客入侵。

远程终端服务基于端口3389。入侵者一般先扫描主机开放端口，一旦发现其开放了3389端口，就会进行下一步的入侵，所以我们只需要修改该务默认端口就可以避开大多数入侵者的耳目。


<!--more-->


步骤：打开&ldquo;开始&rarr;运行&rdquo;，输入&ldquo;&rdquo;，打开注册表，进入以下路径：

**windows 2000xp改法：**

HKEY_LOCAL_MACHINESYSTEMCurrentControlSetControlTerminal ServerWdsrdpwdTdstcp，看见PortNamber值了吗？其默认值是3389，修改成所希望的端口即可，例如6001。

**windows 2003改法：**

再打开HKEY_LOCAL_MACHINESYSTEMCurrentControlSetControlTenninal ServerWinStationsRDP-Tcp，将PortNumber的值（默认是3389）修改成端口6001。

修改完毕，重新启动电脑，以后远程登录的时候使用端口6001就可以了。
