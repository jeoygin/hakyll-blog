---
title: 数据结构-并查集
tags:
  - 并查集
  - 数据结构
id: 73
categories:
  - 精品转载
date: 2010-02-10 18:24:02
---

**不相交集合（即并查集，_disjoint set_）**一般有两种操作：（1）查找某元素属于哪个集合；（2）合并两个集合。最常用的数据结构是并查集的森林实现。也就是说，在森林中每棵树代表一个集合。用树根来标识一个集合。 开始时，每个元素就是一个集合

```
void InitSet(int n)
{
    int i;

    for(i=0;i<n;i++)
    {
        Father[i]=i;
        rank[i]=0;
    }
}
```

<!--more-->

**查找(FindRoot)**：寻找某一个元素所在集合的根。使用路径压缩来优化该函数。

```
int FindRoot(int p)
{
    if (father[p]!=p) father[p]=Findroot(father[p]);
    return father[p];
}
```

**合并</strong>(Union)**：将集合S1与S2合并，即把S1的根的父亲设置为S2的根。定义rank作为合并的启发函数值，刚建立的新集合rank为0，当两个rank相同的集合合并时，随便选一棵树拥有新根，并把它的rank加1；否则rank大的树拥有新根(启发式合并)。

```
void Union(int p,int q)
{
    int a,b;
    a=Find(p); b=Find(q);
    if(rank[a]>rank[b]) father[b]=a;
    else if(rank[a]<rank[b]) father[a]=b;
    else
    {
        father[b]=a;
        rank[a]++;
    }
}
```

**并查集模板：**

```
int set[MAXN],rank[MAXN];
int FindSet(int x)
{
    if(set[x]!=x)
        set[x]=FindSet(set[x]);

    return set[x];
}

void MakeSet(int x)

{
    set[x]=x;
    rank[x]=0;
}

void Link(int a,int b)
{
    if(rank[a]>rank[b])
        set[b]=a;
    else if(rank[a]<rank[b])
        set[a]=b;
    else
    {
        set[a]=b;
        rank[b]++;
    }
}

void Union(int a,int b)
{
    Link(FindSet(a),FindSet(b));
}
```
