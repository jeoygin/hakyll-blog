---
title: C++ STL 生成全排序
tags:
  - c++
id: 131
categories:
  - 计算机技术
  - 编程
date: 2010-02-11 00:36:20
---

使用STL的next_permutation（）可以非常方便地生成全排序

```
#include <iostream>
#include <vector>
#include <algorithm>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
using namespace std;
int main()
{ 
    char str[20];
    char tmp[20];
    int len, i, cnt=1;
    char flag[20];

    scanf("%s", str);
    len=strlen(str);

    sort(str,str+len);

    vector<int> que(len);
    que[0]=1;
    flag[1]=str[0];
    for(i=1;i<len;i++)
    {
        if (str[i]==str[i-1])
        {
            que[i]=que[i-1];
        }
        else
        {
            que[i]=++cnt;
            flag[cnt]=str[i];
        }
    }
    for (i=0;i<len;i++)
    {
        printf("%c", str[i]);
    }
    printf("n");
    while(next_permutation(que.begin(),que.end()))
    {
        for(i=0;i<len;i++)
        {
            tmp[i]=flag[que[i]];
        }
        tmp[len]=0;

        printf("%s\n", tmp);
    }
    return 0;
}
```