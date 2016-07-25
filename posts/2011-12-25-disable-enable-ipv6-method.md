---
title: 禁用和启用IPv6的方法
tags:
  - disable
  - enable
  - IPv6
  - Linux
  - Windows
id: 517
categories:
  - 计算机技术
  - 操作系统
date: 2011-12-25 11:54:14
---

前段时间突然发现谷歌音乐不能用了，提示“暂时没有对您所在的地区提供下载和试听服务”，之后用了一小段时间百度音乐，最后还是随机播放本地音乐了。

昨晚在宿舍听晓明童鞋说是因为IPv6的原因导致谷歌音乐不能用，于是早上到实验室就找禁用IPv6的方法，试验了一下，发现可以用谷歌音乐听歌了，将方法总结如下。

**1\. Linux系统**

**方法一：**

我安装的Linux系统是Arch，在官方wiki上找到禁用IPv6的方法，主要是禁用自动加载ipv6模块，在有需要时可以手动加载该模块。修改/etc/modprobe.d/modprobe.conf文件，添加以下内容：

```
# disable autoload of ipv6
alias net-pf-10 off
```

重新启动系统后IPv6就被禁止了。

**方法二：**

在blacklist中添加ipv6模块，我认为这种方法在多种Linux系统发行版中更为通用，执行以下命令即可：

```
echo "blacklist ipv6" >> /etc/modprobe.d/blacklist.conf
```

**启用IPv6：**

有时候还想使用IPv6怎么办？把它启用就可以了，使用以下命令加载IPv6模块：

```
modprobe ipv6
```

**2\. Windows XP**

Windows XP默认是没有启用IPv6。

**禁用IPv6：**

```
ipv6 uninstall
```

**启用IPv6：**

```
ipv6 install
```

**3\. 后记**

文中若有错误或疏漏之处，烦请批评指正。

**4\. 参考资料**

(1) Disabling IPv6: [https://wiki.archlinux.org/index.php/Disabling_IPv6](https://wiki.archlinux.org/index.php/Disabling_IPv6)
