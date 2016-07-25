---
title: Actor模型
tags:
  - Actor
  - model
id: 477
categories:
  - 计算机技术
  - 分布式系统
date: 2011-10-30 20:19:45
---

最近在看Yahoo的S4: distributed stream computing platform，主要是结合了MapReduce和Actor模型，于是找了些资料学习Actor模型，在这里简单介绍一下，S4等后续文章再介绍。

Actor这个模型由Carl Hewitt在1973年提出，Gul Agha在1986年发表技术报告“Actors: A Model of Concurrent Computation in Distributed Systems”，至今已有不少年头了。在计算机科学中，它是一个并行计算的数学模型，最初为由大量独立的微处理器组成的高并行计算机所开发，Actor模型的理念非常简单：天下万物皆为Actor。

Actor之间通过发送消息来通信，消息的传送是异步的，通过一个邮件队列（mail queue）来处理消息。每个Actor是完全独立的，可以同时执行它们的操作。每一个Actor是一个计算实体，映射接收到的消息到以下动作：

*   发送有限个消息给其它Actor；
*   创建有限个新的Actor；
*   为下一个接收的消息指定行为。
<!--more-->

以上三种动作并没有固定的顺序，可以并发地执行。Actor会根据接收到的消息进行不同的处理。

在一个Actor系统中，包含一个未处理的任务集，每一个任务由以下三个属性标识：

*   tag：用以区别于系统中的其它任务；
*   target：通信到达的地址；
*   communication：包含在target上的Actor处理任务时可获取的信息，。

简单起见，可以把一个任务视为一个消息，在Actor之间传递包含以上三个属性的值的消息。

Actor模型有两种任务调度方式：基于线程的调度以及基于事件的调度：

*   基于线程的调度：为每个Actor分配一个线程，在接收一个消息时，如果当前Actor的邮箱（mail box）为空，则会阻塞当前线程。基于线程的调度实现较为简单，但线程数量受到操作的限制，现在的Actor模型一般不采用这种方式；
*   基于事件的调试：事件可以理解为上述任务或消息的到来，而此时才会为Actor的任务分配线程并执行。

综上，我们知道可以把系统中的所有事物都抽象成一个Actor：

*   Actor的输入是接收到的消息。
*   Actor接收到消息后处理消息中定义的任务。
*   Actor处理完成任务后可以发送消息给其它的Actor。

那么在一个系统中，可以将一个大规模的任务分解为一些小任务，这些小任务可以由多个Actor并发处理，从而减少任务的完成时间。

举个简单的例子，比如现在要在3台物理节点上运行一个WordCount作业，可以将这个作业细分为Split、Count和Merge三种任务（任务的target是物理节点的地址，communication可能包含文本、单词及计数等），根据需求要有Split Actor、Count Actor和Merge Actor。整个作业的处理流程以下：

*   Split Actor接收到消息后可以文本分割成10份，每份发送给一个Count Actor；
*   Count Actor统计好单词的数目后发送消息给Merge Actor；
*   Merge Actor收集完Count Actor发送的10个消息后，合并每个单词的数目，完成WordCount任务。

从以上例子可以看出，Actor系统跟数据驱动系统比如数据流相近，可以自定义任务的流向及其处理过程。Actor模型被广泛使用在很多并发系统中，比如Email、Web Service等等。

**参考资料**

(1) G. Agha, Actors: A Model of Concurrent Computation in Distributed Systems. Cambridge, MA, SA: MIT Press,1986.

(2) Wikipedia: [http://en.wikipedia.org/wiki/Actor_model](http://en.wikipedia.org/wiki/Actor_model)

(3) [ActorLite：一个轻量级Actor模型实现（上）](http://blog.zhaojie.me/2009/05/a-simple-actor-model-implementation.html)
