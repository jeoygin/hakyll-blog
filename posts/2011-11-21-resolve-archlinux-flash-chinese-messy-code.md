---
title: archlinux下flash中文乱码解决之道
tags:
  - arch
  - flash
  - Linux
  - 中文
  - 乱码
id: 488
categories:
  - 计算机技术
  - 操作系统
date: 2011-11-21 20:25:58
---

中午打开豆瓣FM听歌，发现页面上的专辑、歌曲信息中的中文显示不出来，还以为是页面编码的问题，扫了一眼源码，发现播放器是flash，于是上Google找解决方法，主要有如下方法。

删除/etc/fonts/conf.d/49-sansserif.conf，或是将该配置文件中的最后一个sans-serif改成其它字体。经试验，使用这个方法后，有些地方的中文能正常显示了，但依然有乱码，因此这个方法并没有解决根本的问题。

我安装的中文字体是WenQuanYi Zen Hei，于是我用grep命令在/etc/fonts/conf.d目录所有文件中查找“WenQuanYi Zen Hei”，除了wqy本身的配置文件，还有另外一个配置文件也包含查找的字符串，它是65-nonlatin.conf，顾名思义，是用来配置非拉丁字符的字体。

65-nonlatin中对serif、sans-serif和monospace三个字体家族进行配置，每一种字体的配置如下所示：

```
<alias>
    <family>serif</family>
    <prefer>
        <family>Artsounk</family> <!-- armenian -->
        <family>BPG UTF8 M</family> <!-- georgian -->
        <family>Kinnari</family> <!-- thai -->
        <family>Norasi</family> <!-- thai -->
        <family>Frank Ruehl</family> <!-- hebrew -->
        <family>WenQuanYi Zen Hei</family> <!-- han (zh-cn,zh-tw) -->
        <family>WenQuanYi Bitmap Song</family> <!-- han (zh-cn,zh-tw) -->
    </prefer>
</alias>
```

这段配置使用alias指令来设置不同字体的优先级，作用是让fontconfig在匹配serif字体名时，将其它字体放到serif之前，按顺序优先匹配。对我来说，非拉丁字符使用最多的当数中文了，于是把WenQuanYi Zen Hei换到第一个，完成配置之后，豆瓣FM的播放器能正常显示中文了。

后来分析了一下，因为我装系统时配置了zh_HK和zh_TW编码,，所以有可能在匹配字体时找到了非简体中文的字体，造成显示不正常。
