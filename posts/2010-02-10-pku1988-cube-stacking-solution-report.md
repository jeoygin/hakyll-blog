---
title: PKU1988 Cube Stacking 解题报告
tags:
  - ACM
  - 解题报告
id: 82
categories:
  - 陈年旧事
date: 2010-02-10 23:22:43
---

**写于2007-08-26 19:23**

**题目大意：**

一开始有Ｎ个标号为１到Ｎ的立方体，它们各成一堆，给出两种操作:

1.Ｍ　Ｘ　Ｙ　：将Ｘ所在的堆叠在Ｙ所在的堆上面，保证Ｘ和Ｙ不在同一堆。

2.Ｃ　Ｘ　：计算在Ｘ所在的堆中在Ｘ下方的有多少立方块，并输出。

**输入：**

第一行输入P，表示下面有多少个操作

第２到p＋1行，每行输入一个操作，或Ｍ　Ｘ　Ｙ或Ｃ　Ｘ

**输出：**

当有Ｃ　Ｘ操作时输出


<!--more-->


**解法类型：**并查集

**解题思路：**

将每一堆看成是一个集合，将一个堆叠到另一个堆上面即是将两个集合并起来，很快就能想到用并查集来做，此题只需并查集简单的查和并操作就能实现功能，再用两个数组就能很快计算出Ｘ所在的堆中在Ｘ下方的立方块个数。

**数据结构：**

Pre[ MAX ]：每个立方块所在堆中最上面的立方块的标号

Up[MAX]：在Ｘ立方块所在的堆中在Ｘ上面的立方块个数

Down[MAX]：在每个堆中最上面的立方块下面的立方块个数

**算法实现：**

1.初始化

Pre[ i ] = i; i = {1&hellip;MAX} , 每堆只有一个立方块，即立方块所在堆最顶上立方块是其本身

Up[ i ] = Down[ i ] = 0; i = {1&hellip;MAX}

2.执行M操作

![](http://lh6.ggpht.com/_Npc6IElQ2gU/S-ls1Gmoe_I/AAAAAAAAAFc/DC5nfSy1j3k/cube_stacking.jpg)

如上图，Pre[ 1 ] = 2, Pre[ 2 ] = 3, Pre[ 3 ] = 4, Pre[ 4 ] = 4;

 　　　Up[ 1 ] = 3, Up[ 2 ] = 4, Up[ 3 ] = 2,Up[ 4 ] = 0;

显然方块１所在的堆最上边是方块4,即Pre[ 1 ] = 4 , Up[ 1 ] = 9,所以需要在查找１所在堆最上边方块时对Pre[ 1 ]和Up[ 1 ]进行更新.

这里用到find( x )函数来找x所在堆最顶上立方块

```
int find( int x ){
    int r = x, q, h = 0;

    while ( pre[ r ] != -1 ){
        h += Up[ r ];    //对每一组方块长度进行叠加
        r = pre[ r ]; 
    }

    //退出循环时，r就是x所在堆最上边的方块，h是x上边的方块数
    while ( x != r ){
        h -= Up[ x ];//将已计算过的方块数目减去
        Up[ x ] += h;//更新每一方块上面的方块数
        q = pre[ x ];
        pre[ x ] = r;
        x = q;      
    }

    return r;
}
```

输入x和y时，通过调用函数x=find(x),y=find(y)就能找出两个堆的最顶上方块，并更新一些方块的pre和up值。接着将两个堆进行合并就完成操作，先将y所在堆的最顶上方块设为x,即Pre[ y ] = x, 再更新y的Up值和x的Down值，Up[ y ] = Down[ x ] + 1, Down[ x ] += Down[ y ] + 1，y上边的方块数就是原来X所在堆的方块数，x下边的方块数就是x原来所在堆的方块数加上y原来所在堆的方块数减１。

3.执行C操作

在Ｘ下面的方块数即是Ｘ所在堆的方块数减去在Ｘ上面的方块数再减１，而Ｘ所在堆的方块数=在堆最顶上方块下面的方块数＋１，所以调用y=find(x)函数找出最顶上方块，Down[ x ] = Down[ y ] &ndash; Up[ x ]就是所求