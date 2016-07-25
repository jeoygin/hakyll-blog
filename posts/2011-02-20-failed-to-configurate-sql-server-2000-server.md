---
title: SQL Server 2000安装程序配置服务器失败
tags:
  - SQL Server
id: 341
categories:
  - 计算机技术
  - 虚拟化
date: 2011-02-20 06:05:09
---

周五由于工作需要，要在虚拟机中安装Oracle、Mysql、SQL Server，原以为安装软件嘛，问题不大。安装个Mysql倒是挺顺利的，毕竟装过N次了；没装过Oracle，网上找个攻略，按着步骤做，也安装成功；SQL Server是MS的产品，Windows的软件一搬一直点下一步就成了，无奈在配置服务器时出错，提示：安装程序配置服务器失败。参考服务器错误日志和 C:WINNTsqlstp.log 了解更多信息。

折腾了两天，在Windows XP上安装开发版，在Windows Server 2003上安装企业版，都出现同样的错误，最后终于找到问题所在，原来Windows的计算机名（我的电脑-右键属性-计算机名）要大写，原本很美好的周末，就因这个小小的问题给破坏了。

如果安装失败了需要清理一下现场：

1、卸载SQL Server（有可能在控制面板的删除程序中没有，那就不管它了）；

2、删除Microsoft SQL  Server文件夹；

3、运行注册表,删除如下项：

* HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Microsoft SQL Server     

* HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/MSSQLServer

4、重新启动系统。
