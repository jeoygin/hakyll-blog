---
title: Python 2.6与OpenCV 2.0
tags:
  - opencv
  - python
id: 254
categories:
  - 计算机技术
  - 编程
date: 2010-02-25 17:04:54
---

最近一直在学习Python，今天突然萌发用Python来写一个图像处理的小程序，于是想到用OpenCV，以前曾在VS中用过OpenCV，做图像处理太方便了，几乎把常用的操作和算法给封装起来，效率还挺不错的，也想把它用到Python中。

在网上找了一些资料，说是在命令行(cmd)先进入OpenCVinterfacesswigpython目录，然后执行python setup-for-win.py install，之后会生成python源文件和库，有__init__.py、_cv.pyd、_highgui.pyd、_ml.pyd、adaptors.py、cv.py、highgui.py、matlab_syntax.py、ml.py。如果成功会在、Python26Libsite-packages下建立opencv目录，并将生成的文件拷贝到其中，否则会提示错误信息。但我执行python setup-for-win.py install命令后出现了如下错误：

<!--more-->

![](http://lh4.ggpht.com/_Npc6IElQ2gU/S-ls3Qit9FI/AAAAAAAAAFg/MMZG4DVOx_c/python_opencv.jpg)

在这里说明一下，VS 2008以下版本未支持Python 2.6，如果安装了VS 2005，会提示找不到vcvarsall.bat，因此只能安装VS 2008，如果觉得太麻烦，可以安装Express版本。上述错误说明未能找到cxcore.h文件，主要还是include路径没设好，在网上搜了好久也没找到半点线索，似乎别人没出现这个错误，难道我RP真那么差。后来没办法打开setup-for-win.py瞧了一下，发现include_dirs设置有问题，比如OpenCVcvinclude、OpenCVcxcoreinclude，OpenCV 1.0才这么设，2.0只需设置成OpenCVincludeopencv即可，里面包含了cv、cxcore和highgui等。改了改，重新安装，等了一会时间没出现错误，又在Python26Libsite-packages新建python.pth，里面写上opencv，再写了一个测试程序：

```
import cv
import highgui

if __name__=='__main__':
    image=highgui.cvLoadImage("image.png",1)
    highgui.cvNamedWindow("picwin")
    highgui.cvShowImage("picwin",image)
    highgui.cvWaitKey(0)
    highgui.cvDestroyWindow("picwin")
```

运行成功，显示一幅图像，到此安装OpenCV成功。
