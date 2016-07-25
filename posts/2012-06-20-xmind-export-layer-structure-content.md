---
title: 从xmind中提取具有层级结构的内容
tags:
  - extract
  - freemind
  - layer structure
  - xmind
id: 926
categories:
  - 计算机技术
  - 编程
date: 2012-06-20 21:37:56
---

自从接触了思维导图工具后，真心觉得这工具不错，做报告或是读书，用上它可以使思维更加清晰。对此类工具进行一番调研之后，选择了xmind，xmind是用java开发的，具有跨平台性，在Linux和Windows平台都能使用，其专业版是要收费的，不过免费版本的功能已足够使用了。

最近在看《Linux设备驱动》，主要使用xmind来做笔记，用来回顾已学过的知识很方便，但当我想把记录的内容发表到博客上时，就比较费力了，因为xmind导出的文本是没有层级结构的，这样的内容发表出来对读者来说是很困惑的。因为我的博客使用了“MediaWiki Markup for WordPress”这个插件，可以使用一部分wiki语法来写文章，相比用html标记简单高效，比如说我要使用符号列表，那么可以使用以下的语法：

```
*一级
**二级
***三级
****四级
*又回到了一级
**二级
```

最后的显示效果就是：

* 一级
    * 二级
        * 三级
            * 四级
* 又回到了一级
    * 二级

<!--more-->

那么如果我能知道xmind中内容的层级结构的话，只需要在每一条记录前加上相应数目的*号，就可以直接发表到博客上。

一开始，傻傻地手动地边看xmind边在每一条记录前加上相应数据的*号，最后发现这样很浪费时间，作为程序员，我们有责任让这种手工劳动变成自动化，于是开始想方设法来达到这一目标。

不断地进行，当发现用xmind导出成FreeMind格式的文件是个xml时，我顿时找到了希望，因为xml文件本身就是一种层级结构的格式。很快就想到dom4j，于是开始动手写代码，代码很简短，稍加调试就达成预期的目的。代码如下所示：

```
/* ==========================================================================
 *  Copyright (c) 2012 by Institute of Computing Technology,
 *                          Chinese Academic of Sciences, Beijing, China.
 * ==========================================================================
 * file :       Extracter.java
 * author:      Jeoygin Wang
 *
 * last change: date:       6/20/12 6:56 PM
 *              by:         Jeoygin Wang
 *              revision:   1.0
 * --------------------------------------------------------------------------
 */

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import java.io.File;
import java.util.Iterator;

/**
 * Extract content from a FreeMind format file.
 *
 * @author Jeoygin Wang
 * @version 1.0
  */
public class Extracter {
    //~ Methods ----------------------------------------------------------------
    private void traverse(Element e, int depth) {
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < depth; i++) {
            sb.append("*");
        }

        for (Iterator it = e.elementIterator("node"); it.hasNext();) {
            Element node = (Element) it.next();
            String text = node.attributeValue("TEXT").replaceAll("<", "&lt;")
                              .replaceAll(">", "&gt;");
            System.out.println(sb.toString() + text);
            traverse(node, depth + 1);
        }
    }

    /**
     * Extract content from a xml file.
     *
     * @param filename xml file name
     */
    public void extract(String filename) {
        // load XML document from file
        File inputXml = new File(filename);
        SAXReader saxReader = new SAXReader();
        Document document = null;

        try {
            document = saxReader.read(inputXml);
        } catch (DocumentException e) {
            throw new RuntimeException(e);
        }

        Element map = document.getRootElement();

        traverse(map, 0);
    }

    public static final void main(final String[] args) {
        new Extracter().extract("input.mm");
    }
}

```

将导出的文件保存到与编译生成的Extracter.class同个目录下，文件名为input.mm，运行程序即可将内容打印出来。