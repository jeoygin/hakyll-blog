---
title: 完美解决PHP中文乱码
id: 122
categories:
  - 陈年旧事
date: 2010-02-11 00:20:41
tags:
---

**写于2008-09-10 22:22**

这两天在赶小学期的作业，开发了一个小型的音乐网站，就两三千行，功能很简单，只能上传、下载歌曲，在线听歌，所谓在线听歌不过是在网页中放了一个对象，做这几个小功能遇到的最大问题就是中文乱码，经过一天上网查资料与探索，总算找到比较好的解决方法。 PHP中文乱码一般是字符集问题，编码主要有下面几个问题。

**一.首先是PHP网页的编码**

1. php文件本身的编码与网页的编码应匹配

    * 如果欲使用gb2312编码，那么php要输出头：header(&ldquo;Content-Type: text/html; charset=gb2312&quot;)，静态页面添加，所有文件的编码格式为ANSI，可用记事本打开，另存为选择编码为ANSI，覆盖源文件。

    * 如果欲使用utf-8编码，那么php要输出头：header(&ldquo;Content-Type: text/html; charset=utf-8&quot;)，静态页面添加，所有文件的编码格式为utf-8。保存为utf-8可能会有点麻烦，一般utf-8文件开头会有BOM，如果使用session就会出问题，可用editplus来保存，在editplus中，工具-&gt;参数选择-&gt;文件-&gt;UTF-8签名，选择总是删除，再保存就可以去掉BOM信息了。

2. php本身不是Unicode的，所有substr之类的函数得改成mb_substr（需要装mbstring扩展）；或者用iconv转码。


<!--more-->


**二.PHP与Mysql的数据交互**

PHP与数据库的编码应一致

1.修改mysql配置文件my.ini或my.cnf，mysql最好用utf8编码  

```
[mysql]

default-character-set=utf8

[mysqld]

default-character-set=utf8

default-storage-engine=MyISAM
```

在[mysqld]下加入:

default-collation=utf8_bin

init_connect=&#39;SET NAMES utf8&#39;


2.在需要做数据库操作的php程序前加mysql_query(&quot;set names &#39;编码&#39;&quot;);，编码和php编码一致，如果php编码是gb2312那mysql编码就是gb2312，如果是utf-8那mysql编码就是utf8，这样插入或检索数据时就不会出现乱码了

**三.PHP与操作系统相关**

Windows和Linux的编码是不一样的，在Windows环境下，调用PHP的函数时参数如果是utf-8编码会出现错误，比如move_uploaded_file()、filesize()、readfile()等，这些函数在处理上传、下载时经常会用到，调用时可能会出现下面的错误:

Warning: move_uploaded_file()[function.move-uploaded-file]:failed to open stream: Invalid argument in &hellip;

Warning: move_uploaded_file()[function.move-uploaded-file]:Unable to move &#39;&#39; to &#39;&#39; in &hellip;

Warning: filesize() [function.filesize]: stat failed for &hellip; in &hellip;

Warning: readfile() [function.readfile]: failed to open stream: Invalid argument in ..


在Linux环境下用gb2312编码虽然不会出现这些错误，但保存后的文件名出现乱码导致无法读取文件，这时可先将参数转换成操作系统识别的编码，编码转换可用mb_convert_encoding(字符串,新编码,原编码)或iconv(原编码,新编码,字符串)，这样处理后保存的文件名就不会出现乱码，也可以正常读取文件，实现中文名称文件的上传、下载。

其实还有更好的解决方法，彻底与系统脱离，也就不用考虑系统是何编码。可以生成一个只有字母和数字的序列作为文件名，而将原来带有中文的名字保存在数据库中，这样调用move_uploaded_file()就不会出现问题，下载的时候只需将文件名改为原来带有中文的名字。实现下载的代码如下


header(&quot;Pragma: public&quot;);

header(&quot;Expires: 0&quot;);

header(&quot;Cache-Component: must-revalidate, post-check=0, pre-check=0&quot;);

header(&quot;Content-type: $file_type&quot;);

header(&quot;Content-Length: $file_size&quot;);

header(&quot;Content-Disposition: attachment; filename=&quot;$file_name&quot;&quot;);

header(&quot;Content-Transfer-Encoding: binary&quot;);

readfile($file_path);

$file_type是文件的类型，$file_name是原来的名字，$file_path是保存在服务上文件的地址。
