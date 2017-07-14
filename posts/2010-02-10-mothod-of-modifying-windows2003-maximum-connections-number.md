---
title: 更改windows2003最大连接数的方法
id: 101
categories:
  - 精品转载
date: 2010-02-10 23:48:35
tags:
---

XP和2003中的远程桌面功能非常方便，不像以往需要安装。所以我一直使用，不过由于只允许2个用户登陆，有些时候因为在公司连接后断开，同事在家里用 其他用户登陆后断开，我就不能连接了。总是报错&ldquo;终端服务超过最大连接数&rdquo;，这时候我和同事都不能登陆，有没有什么办法可以达到以下几个目的中的一个：

1. 为账号设定权限，管理员登陆的时候强制注销多余的用户。
2. 管理员登陆的时候自动接管在其他地方断开的状态（本来这个功能具备，但有些时候不行）。
3. 不安装总段服务的时候增加连接数（不是临时授权）


<!--more-->


我们来增加连接数

运行：services.msc，启用license logging。

![](http://lh6.ggpht.com/_Npc6IElQ2gU/S-luCqlaB5I/AAAAAAAAAGE/iX1OF0BYWu8/sql_server_p1.jpg)

打开win2k3的控制面板中的&quot;授权&quot;，点&quot;添加许可&quot;，输入要改的连接数。

![](http://lh3.ggpht.com/_Npc6IElQ2gU/S-luCgUHlVI/AAAAAAAAAGI/XGhLik9VGSk/sql_server_p2.jpg)

![](http://lh4.ggpht.com/_Npc6IElQ2gU/S-luC2EDNwI/AAAAAAAAAGM/pomWrNdMgu8/sql_server_p3.jpg)

别忘了添加完毕后再关闭 License Logging。

开始－运行－gpedit.msc－计算机配置－管理模板－windows组件－终端服务－会话

右边窗口选择 为断开的会话设置时间限制 －选择已启用，选择一个时间

问题解决

另建议：

开始－管理工具－终端服务配置－服务器配置－限制每个用户使用一个会话.

现象及原因：用远程桌面连接登录到终端服务器时经常会遇到&ldquo;终端服务器超出最大允许连接数&rdquo; 诸如此类错误导致无法正常登录终端服务器，引起该问题的原因在于Windows Server 2003中设置终端服务的缺省连接数为2个链接，并且当登录远程桌面后如果不是采用注销方式退出，而是直接关闭远程桌面窗口，那么实际上会话并没有释放 掉，而是继续保留在服务器端，这样就会占用总的链接数，当这个数量达到最大允许值时就会出现上面的提示。

解决方案：

法一：用&ldquo;注销&rdquo;方式退出远程桌面而不是直接关闭窗口

法二：踢出已经断开连接的用户

1. 首先telnet到此主机上(不管你用什么方法)，当然如果能直接操作机器更好，不过直接操作就不必用命令行了，用控制台更直观(略过)。

2. Telnet上去后,先看登陆的用户：

输入命令：query user 系统返回：

用户名Username      会话名Session Name      ID   状态State    空闲时间Idle Time     登录时间Logon Time

administrator            console                               0   运行中               .                           2007-1-12 10:24

lucy                                                                           1   唱片            无                            2007-1-12 10:35

&gt; administrator         rdp-tcp#35                      2   已断开               .                          2007-1-25 18:09

此时可以看出的可能跟我的不一样，根据你的具体情况而定。

ID 0 的用户是本地登陆的

ID 1 和 ID 2是3389登陆的用户，前者在运行中， 后者已经断开了，但是断开了仍然占用系统资源和通道，我们要把它踢掉，如下进行操作即可。 

输入命令：logoff 1

再看看

C:Documents and SettingsAdministrator.AD>query user

用户名Username      会话名Session Name      ID   状态State    空闲时间Idle Time     登录时间Logon Time

administrator          console                                0   运行中               .                          2007-1-12 10:24

&gt; administrator       rdp-tcp#35                       2   已断开               .                          2007-1-25 18:09

3、如果服务器关闭了telnet功能（这是默认的），还可以通过SqlServer的xp_cmdshell扩展存储过程，使用格式： master.dbo.xp_cmdshell &#39;&#39;&#39;&#39;命令内容&#39;&#39;&#39;&#39;，其余可参考第二步。此方式要求有访问xp_cmdshell的权限。

法三（最佳方法－推荐）：限制已断开链接的会话存在时间

一般情况下，我们在维护远程服务器时，不可能长时间在线，但是系统默认的却是只要登录就不再断开。因此，我们可以修改这一默认设置，给它指定一个自动断开的时间即可。

可以在Windows 2003 服务器上通过组策略中设置一下来解决问题：单击&quot;开始&rarr;运行&quot;，输入&quot;gpedit.msc&quot;，回车后打开组策略窗口，然后依次定位到&quot;计算机配置&rarr;管理 模板&rarr;Windows 组件&rarr;终端服务&rarr;会话&quot;，然后在右侧窗口中双击&quot;为断开的会话设置时间限制&quot;，在打开的窗口中将&quot;结束断开连接的会话&quot;时间设置为5分钟，或者设置为空闲 就断开。

在远程服务器上打开&ldquo;运行&rdquo;窗口，输入&ldquo;tscc.msc&rdquo;连接设置窗口。然后双击&ldquo;连接&rdquo;项右侧的&ldquo;RDP-Tcp&rdquo;，切换到&ldquo;会话&rdquo;标签，选中&ldquo;替代用户设置&rdquo;选项，再给&ldquo;结束已断开的会话&rdquo;设置一个合适的时间即可。

法四：增加连接数量，即设置可连接的数量多些

默认情况下允许远程终端连接的数量是2个用户，我们可以根据需要适当增加远程连接同时在线的用户数。

单击&ldquo;开始&rarr;运行&rdquo;，输入&ldquo;gpedit.msc&rdquo;打开组策略编辑器窗口，依次定位到&ldquo;计算机配置&rarr;管理模板&rarr;Windows 组件&rarr;终端服务&rdquo;，再双击右侧的&ldquo;限制连接数量&rdquo;，将其TS允许的最大连接数设置大一些即可。

经过上面两个配置(法三&amp;法四)，基本上就可以保证远程终端连接时不再受限。但仍有人反映，当前同时只有一个用户进行连接，却提示超出最大允许链 接数，这又是什么原因呢？出现这种情况是因为操作不当所造成的。在上一个帐户登录远程桌面后退出时，没有采用注销的方式，而是直接关闭远程桌面窗口，那么 导致该会话并没有被释放，而是继续保留在服务器端，占用了连接数，这样就会影响下一个用户的正常登录了。

对Terminal Services进行限制，使得一个用户仅仅能够连接一次

对于Windows Server 2003，请在Terminal Services Configuration（Terminal Services配置）中将&ldquo;限制每位用户只有拥有一个会话&rdquo;（Restrict each user to one session）设置为&ldquo;是&rdquo;（Yes）。此外，您可以将&ldquo;限制终端服务用户使用单个远程会话&rdquo;组策略设置为&ldquo;启用&rdquo;。
