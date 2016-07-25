---
title: emacs 24 + cedet + ecb + jdee
tags:
  - cedet
  - ecb
  - emacs
  - jdee
id: 922
categories:
  - 计算机技术
  - 操作系统
date: 2012-06-20 20:11:56
---

刚升级了一下我的arch，emacs由23升级到了24，升级后发现很多插件出问题了，包括cedet、ecb和jdee等，在Google搜了一小时，终于把问题给解决了。下面就把解决的方法分享出来，希望对大家有所帮助。

**1\. cedet**

这个问题比较好解决，升级到1.1就能和emacs 24兼容。

**2\. ecb**

ecb已多年没更新了，最新的ecb-2.40只兼容cedet版本 1.0.6pre ~ 1.0.9，解决的方法是修改/path/to/ecb-2.40/ecb-upgrade.el，将1146行的

	(defconst ecb-required-cedet-version-max '(1 0 4 9))

改为

	(defconst ecb-required-cedet-version-max '(1 1 4 9))

这样就OK了。

**3\. jdee**

问题之一也是jdee不兼容cedet 1.1，解决方法同ecb，修改支持的最大版本号，修改/path/to/jdee-2.4.0.1/lisp/jde.el文件，将43行的

	(defconst jde-cedet-max-version "1.0"

修改为

	(defconst jde-cedet-max-version "1.1"

然后删除/path/to/jdee-2.4.0.1/lisp/jde.elc，如果想编译jde.elc，可以打开emacs，输入M-x byte-compile-file，文件是/path/to/jdee-2.4.0.1/lisp/jde.el，如果编译成功就会生成jde.elc。

另外的问题是jdee使用了emacs 24不再支持的函数，解决方法是在~/.emacs文件中添加以下内容：

	(defun screen-width nil -1)
	(define-obsolete-function-alias 'make-local-hook 'ignore "21.1")

**4\. done**

完成以上三步就大功告成，又可以使用emacs来写java程序了。

如果有问题，欢迎批评指正。

**5\. 参考资料**

1. [Emacs24+cedet+ecb+jdee配置时出现的若干问题](http://blog.csdn.net/donglin425/article/details/7075976)
2. [installing JDEE and CEDET with Emacs 24](http://forums.fedoraforum.org/showthread.php?t=280711)