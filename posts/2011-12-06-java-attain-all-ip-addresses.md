---
title: Java获得所有网卡IP地址
tags:
  - Address
  - IP地址
  - Java
  - NetworkInterface
  - 网卡
id: 498
categories:
  - 计算机技术
  - 编程
date: 2011-12-06 10:42:14
---

早上写程序时遇到要判断一个IP地址是否是本地地址的情况，本来想用InetAddress.getLocalHost()得到的地址和目标地址进行比较，但在Linux下得到的地址是127.0.0.1，没辙，想了个土办法，先获得本地所有IPV4地址，再拿目标地址去匹配，在网上找到如下方法。

```
Enumeration<NetworkInterface> interfaces = null;
try {
    interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
        NetworkInterface ni = interfaces.nextElement();
        Enumeration<InetAddress> addresses = ni.getInetAddresses();
        while (addresses.hasMoreElements()) {
            InetAddress addr = addresses.nextElement();
            if (addr != null && addr instanceof Inet4Address) {
                System.out.println("IP:" + addr.getHostAddress());
            }
        }
    }
} catch (Exception e) {
    e.printStackTrace();
}
```

这段代码比较好懂，得到所有网卡后遍历每个网卡，再判断网卡的每个地址是否满足要求。
