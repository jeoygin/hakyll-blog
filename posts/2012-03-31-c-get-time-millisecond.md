---
title: C语言如何获得精确到毫秒的时间
tags:
  - c++
  - Linux
  - millisecond
  - time
  - Windows
id: 814
categories:
  - 计算机技术
  - 编程
date: 2012-03-31 20:38:26
---

在做测试或性能优化时，经常要知道程序运行的时间，在Linux系统可以使用time命令来计算程序运行运行所消耗的时间，能精确到毫秒，如果要精确到代码块或某个操作运行时所消耗的时间，time命令就不给力了。如果对时间的精度要求不高的话，可以调用标准C的接口time来得到开始和结束的时间，再调用difftime接口来计算时间差，精度是秒，代码如下所示：

```
#include <stdio.h>
#include <time.h>

int main(){
    time_t t_start, t_end; 
    t_start = time(NULL) ;
    sleep(3000);
    t_end = time(NULL) ;
    printf("time: %.0f s\n", difftime(t_end,t_start)) ;
    return 0;
}
```

如果要让程序休眠3秒，Windows使用Sleep(3000)，Linux使用sleep(3)，即Windows的Sleep接口的参数的单位是毫秒，Linux的sleep接口的参数的单位是秒。


<!--more-->


如果需要精确到毫秒，以上程序就发挥不了作用，如果在Java要达到这要求就很简单了，代码如下所示：

```
public class Time {
    public static void main(String[] args) {
        try {
            long startTime = System.currentTimeMillis();
            Thread.sleep(3000);
            long endTime = System.currentTimeMillis();
            System.out.println("time: " + (endTime - startTime) + " ms");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

通过Google找了一些资料后，发现C语言里没有标准的接口可以获得精确到毫秒的时间，都会调用到与操作系统相关的API，下面会分别介绍在Linux和Windows系统下的多种实现方法，希望对大家有帮助。

## Linux系统 ##

**使用gettimeofday接口：**

```
#include <stdio.h>
#include <sys/time.h>

int main() {
    struct timeval start, end;
    gettimeofday( &start, NULL );
    sleep(3); 
    gettimeofday( &end, NULL );
    int timeuse = 1000000 * ( end.tv_sec - start.tv_sec ) + end.tv_usec - start.tv_usec; 
    printf("time: %d us\n", timeuse);
    return 0;
}
```

gettimeofday能得到微秒数，比毫秒还要更精确。

**使用ftime接口：**

```
#include <stdio.h>
#include <sys/timeb.h>

long long getSystemTime() {
    struct timeb t;
    ftime(&t);
    return 1000 * t.time + t.millitm;
}

int main() {
    long long start=getSystemTime();
    sleep(3);
    long long end=getSystemTime();

    printf("time: %lld ms\n", end-start);
    return 0;
}
```

## Windows系统 ##

**使用GetTickCount接口：**

```
#include <windows.h>
#include <stdio.h>

int main() {
    DWORD start, stop; 
    start = GetTickCount();
    Sleep(3000);
    stop = GetTickCount();
    printf("time: %lld ms\n", stop - start);
    return 0;
}
```

Windows系统下有些编译器使用printf输出64位整数参数要使用%I64d，比如VC。

**使用QueryPerformanceX接口：**

```
#include <windows.h>
#include <stdio.h>

int main(){
    LARGE_INTEGER li;
    LONGLONG start, end, freq;
    QueryPerformanceFrequency(&li);
    freq = li.QuadPart;
    QueryPerformanceCounter(&li);
    start = li.QuadPart;
    Sleep(3000);
    QueryPerformanceCounter(&li);
    end = li.QuadPart;
    int useTime =(int)((end - start) * 1000 / freq);
    printf("time: %d ms\n", useTime);
    return 0;
}
```

**使用GetSystemTime接口：**

```
#include <windows.h>
#include <stdio.h>

int main(){
    SYSTEMTIME currentTime;
    GetSystemTime(&currentTime);
    printf("time: %u/%u/%u %u:%u:%u:%u %d\n",            
     currentTime.wYear,currentTime.wMonth,currentTime.wDay,
     currentTime.wHour,currentTime.wMinute,currentTime.wSecond,
     currentTime.wMilliseconds,currentTime.wDayOfWeek);
    return 0;
}
```

这种方法没给出计算时间差的实现，只给出如何用GetSystemTime调用得到当前时间，计算时间差比较简单，根据年、月、日、时、分秒和毫秒计算出一个整数，再将两整数相减即可。

## 后记 ##

以上是通过Google找到一些用C语言获得精确到毫秒的实现方法，对比Linux和Windows的方法，发现两个系统的API命名很不一样，Linux接口名要么都是小写要么使用下划线（_）来分隔单词，而Windows接口名中的单词首字母大写。

文中若有错误或疏漏之处，烦请批评指正。