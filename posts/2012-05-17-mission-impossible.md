---
title: Mission Impossible：北大校赛一题之联想
tags:
  - ACM
  - algorithm
id: 865
categories:
  - 计算机技术
  - 算法与数据结构
date: 2012-05-17 00:26:23
---

上周日与两大牛参加北大校赛，很久没写题，本着打酱油的心态去参赛，最后也真打酱油了，没写过一题代码，就在赛场上坐着、看着、想着，有两个题目我还不知道是啥队友就已经把它过了。回来后，听身边的哥们在讨论“Mission Impossible”这道题，我也就去看了一下，题目地址：http://poj.openjudge.cn/practice/1030/。

这个题目的意思很清晰，给定一个整数_N_（_N_ &gt; 1），找出满足以下条件的_K_<sub>1</sub>, _K_<sub>2</sub>, _K_<sub>3</sub>, ... _K__<sub>N </sub>_：

* 对于 i ≠ j，_K<sub>i</sub>_和_K<sub>j</sub>_互质（最大公约数为1）；
* K<sub>i </sub>&gt; 1；
* ∏_<sub>i=1..N</sub>_(_K<sub>i</sub>_) = _a_<sup>2 </sup>+ _a _+ 1。

很明显，这是一道数论的题目，以前我在役时，这类型的题目是我的最爱，总想把它给征服了，不过这个题目对N的要求不大，不超过9，可以先暴力求解，再打表，现场有很多队就这么过的，当然暴力也有技巧，不然也不会还有一半的队伍没过，不然我们队刚开始时也不会等很久没等待出结果。周一细细想了许久，找到了一些门道，下面先从最简单的暴力方法开始，慢慢进阶到通关秘诀。

<!--more-->

**1\. 朴素的暴力**

想法很简单，枚举_a_，从1开始，计算v=_a_<sup>2 </sup>+ _a _+ 1，然后对v分解质因子，这个过程也很暴力，令f=2..sqrt(v)，判断v能否整除f，如果可以将v除以f，直到v不能整除f。最后看v的质因子个数（n），如果最后v不等于1，那么N=n+1，否则N=n。

这个方法很直接，用long long就能求出N=9的情况，很容易实现，就是时间开销太大，对于比赛现场那些性能不高的机器，可能一场比赛结束了结果还没出来呢。因此需要优化。

**2\. 生成素数表**

大体思路和方法1一致，只是在分解质因子时不去暴力枚举所有数，而是只枚举素数，我写了一个程序，大概15分钟能跑出想要的结果，但一直等不出N=10的情况。

**3\. 枚举素数组合**

由以上方法求出的_a_<sup>2 </sup>+ _a _+ 1分析质因子后，每个因子的数目都是1，那么我想换个角度，枚举因子来构造出a，在24个素数中选取素数进行组合，计算出来的乘积判断是否等于_a_<sup>2 </sup>+ _a _+ 1，这样也是可以求出来的，而且速度还挺快的，只是计算出来的N还不能很大。经过对计算过程的中间结果进行分析，发现有些素数从没出现过，即不能满足已知的条件，可以将其剔除，经过这样的处理，N也能不断增大。

**4\. 奇思妙想**

对以上几种方法生成的结果进行观察，发现有些素数总是频繁出现，于是猜想在求解N=n+1时能不能在N=n的基础上多加1个素数作为因子，结果证明这种想法是不对。我再退一步，把N=n求解出来的_K_<sub>n</sub>给换了，再加入一个新的素数，这种方法很神奇地发挥作用了，而且能在1秒内跑出N=10的结果，且结果是正确的，但想求出更多的解只怕long long不能满足精度要求，而且越到后边时间复杂度越大。

**5\. 通关秘诀**

第4种方法的尝试说明这种思路是可取，那么有没有数学证明呢？有没有方法能快速求出N=100或更大的解呢？我的直觉告诉我有，于是又一次开启了神秘的数论之旅。

首先，我将问题稍微给转换了一下：∏_<sub>i=1..N</sub>_(_F<sub>i</sub>_) * x - 1 = _a_ * (_a _ + 1)，等式1

其中_F<sub>i</sub>_是素数，x是个变量，对于给定的_F<sub>i</sub>_，是否存在x能够满足等式1，等式1可以得出以下结论：

* _a_ * (_a _ + 1) % ∏_<sub>k=i..j</sub>_(_F<sub>k</sub>_) = ∏_<sub>k=i..j</sub>_(_F<sub>k</sub>_) - 1，j &gt;= i，等式2；
* 并不是所有的素数都能满足等式2；
* 对于能满足等式2的素数_F<sub>i</sub>_，a在[0, _F<sub>i</sub>_)，有两个值满足等式2，如果_a<sub>i</sub>_满足等式2，那么_F<sub>i</sub>_-1-_a<sub>i</sub>_和_a<sub>i</sub>_+_F<sub>i</sub>_*x必然也满足等式2；

有了以上的先验知识，我们可以先剔除不满足条件的素数，用剩下的素数构造解：

* 当N=1时，_F<sub>1</sub>_ = 3，_a<sub>1..1</sub>_ = 3；
* 假设有N=n的可行解：_F<sub>1</sub>_, _F<sub>2</sub>_, ... _F<sub>n</sub>_和_a<sub>1, n</sub>_，可以由这些解来构造N=n+1的解。

由等式2，我们可以知道：

* _a<sub>1, n+1</sub>_ * (_a<sub>1, n+1</sub>_ + 1) % ∏_<sub>k=1..n+1</sub>_(_F<sub>k</sub>_) = ∏_<sub>k=1, n+1</sub>_(_F<sub>k</sub>_) - 1，等式3
* _a<sub>1, n</sub>_ * (_a<sub>1, n</sub>_ + 1) % ∏_<sub>k=1..n</sub>_(_F<sub>k</sub>_) = ∏_<sub>k=1, n</sub>_(_F<sub>k</sub>_) - 1，等式4
* _a<sub>n+1</sub>_ * (_a<sub>n+1</sub>_ + 1) % _F<sub>n+1</sub>_ = _F<sub>n+1</sub>_ - 1，等式5

我们能很容易想到：能满足等式3的_a<sub>1, n+1</sub>_肯定能满足等式4和等式5，也即是说_a<sub>n+1</sub>_和_a<sub>1, n</sub>_的所有可行解包括了_a<sub>1, n+1</sub>_的所有可行解。

由以上的推导，我们知道存在以下的两个等式：

* _a<sub>1, n+1</sub>_ = _a<sub>n+1</sub>_ + _F<sub>n+1</sub>_ * x
* _a<sub>1, n+1</sub>_ = _a<sub>1, n</sub>_ + ∏_<sub>k=1..n</sub>_(_F<sub>k</sub>_)  * y

由以上两个等式，可以推出以下的等式：_F<sub>n+1</sub>_ * x － ∏_<sub>k=1..n</sub>_(_F<sub>k</sub>_)  * y = _a<sub>1, n</sub>_ - _a<sub>n+1</sub>_，等式6

看到等式6，很快就想到了求解模线性方程和扩展欧几里德，因为_F<sub>k</sub>_两两互质，所以等式6有解，假设我们找到一个可行解_x<sub>0</sub>_，那么：_a<sub>1, n+1</sub>_ = _a<sub>n+1</sub>_ + _F<sub>n+1</sub>_ * _x<sub>0</sub>_。

有了_a<sub>1, n</sub>_和(_F<sub>k</sub>_)就很好构造出原问题的解了，先计算出v=_a<sub>1, n</sub>_<sup>2 </sup>+ _a<sub>1, n</sub>_+ 1，再对其分解质因子：对于前n-1个_F<sub>i</sub>_，将所有质因子_F<sub>i</sub>_相乘作为_K<sub>i</sub>_，v中剩下的所有不等于_F<sub>i</sub>_ (i &lt; n) 的质因子相乘作为_K<sub>n</sub>_。

**6\. 通关后的快感**

上大学后，上过的数学相关的课程很少，平时也比较少接触到数学。对数学有种莫名的爱，却与之逐行逐远，如同对某个女孩有种莫名的喜欢，在与之擦肩而过后逐行逐远。

**方法5的java实现代码如下：**

```
/* ==========================================================================
 *  Copyright (c) 2012 by Institute of Computing Technology,
 *                          Chinese Academic of Sciences, Beijing, China.
 * ==========================================================================
 * file :       Test.java
 * author:      Jeoygin Wang
 *
 * last change: date:       5/17/12 9:37 AM
 *              by:         Jeoygin Wang
 *              revision:   1.0
 * --------------------------------------------------------------------------
 */
import java.math.BigInteger;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Scanner;

/**
 * DOCUMENT ME!
 *
 * @author Jeoygin Wang
 * @version 1.0
 */
public class Test {
    //~ Static fields/initializers ---------------------------------------------

    static final int N = 100000;
    static final int SOLUTIONS = 100;
    static final BigInteger ZERO = BigInteger.ZERO;
    static final BigInteger ONE = BigInteger.ONE;
    static final BigInteger MINUS_ONE = BigInteger.valueOf(-1);
    static final BigInteger TWO = BigInteger.valueOf(2);
    static final BigInteger THREE = BigInteger.valueOf(3);
    static final boolean outputInfo = false;

    //~ Instance fields --------------------------------------------------------

    int[] fac = new int[N + 1];
    List<Factor> K = new ArrayList<Factor>();
    List<Factor> avails = new ArrayList<Factor>();

    //~ Methods ----------------------------------------------------------------

    void genPrimes() {
        Arrays.fill(fac, 1);
        fac[0] = fac[1] = 0;

        for (int i = 2; i <= N; i++) {
            if (fac[i] == 1) {
                int t = i + i;

                while (t <= N) {
                    if (fac[t] == 1) {
                        fac[t] = i;
                    }

                    t += i;
                }
            }
        }
    }

    int check(int p) {
        for (int i = p / 2; i > 0; i--) {
            if (((i * (i + 1)) % p) == (p - 1)) {
                return i;
            }
        }

        return -1;
    }

    int cmp(BigInteger a, BigInteger b) {
        return a.compareTo(b);
    }

    int cmp(BigInteger a, int b) {
        return a.compareTo(BigInteger.valueOf(b));
    }

    boolean positive(BigInteger d) {
        return cmp(d, ZERO) > 0;
    }

    boolean negative(BigInteger d) {
        return cmp(d, ZERO) < 0;
    }

    boolean zero(BigInteger d) {
        return cmp(d, ZERO) == 0;
    }

    BigInteger negate(BigInteger d) {
        return d.negate();
    }

    BigInteger toBig(int d) {
        return BigInteger.valueOf(d);
    }

    Triple extendEuclid(BigInteger a, BigInteger b) {
        if (zero(b)) {
            boolean pos = positive(a);

            return new Triple(pos ? a : a.negate(), pos ? ONE : MINUS_ONE, ZERO);
        }

        boolean neg = negative(b);

        if (neg) {
            b = b.negate();
            a = a.negate();
        }

        Triple res = extendEuclid(b, a.mod(b));

        return new Triple(res.d, res.y,
                          res.x.subtract(a.divide(b).multiply(res.y))
                         );
    }

    List<BigInteger> modularLinearEquationSolver(BigInteger a, BigInteger b,
                                                 BigInteger d
                                                ) {
        Triple res = extendEuclid(a, b);

        if (zero(d.mod(res.d))) {
            List<BigInteger> list = new ArrayList<BigInteger>();

            BigInteger x0 = res.x.multiply(d).divide(res.d).mod(b);
            int up = res.d.intValue();

            for (int i = 0; i < up; i++) {
                list.add(x0.add(toBig(i).multiply(b.divide(res.d)).mod(b)));
            }

            return list;
        }

        return null;
    }

    Factor calculate(Factor f1, Factor f2) {
        List<BigInteger> list = modularLinearEquationSolver(f1.n.negate(),
                                                            f2.n,
                                                            f1.p.subtract(f2.p)
                                                           );

        if (list != null) {
            BigInteger x = list.get(0).mod(f2.n);

            if (negative(x)) {
                x = x.add(f2.n);
            }

            return new Factor(f1.n.multiply(f2.n), f1.n.multiply(x).add(f1.p));
        }

        return null;
    }

    BigInteger update(Factor res, Factor f1, Factor f2, BigInteger p) {
        Factor next = calculate(f1, f2);

        if (cmp(next.p, next.n.divide(TWO)) > 0) {
            next.flipItself();
        }

        if ((next != null) && (cmp(next.p, p) < 0)) {
            p = next.p;
            res.copy(next);
        }

        return p;
    }

    void prepare() {
        genPrimes();

        if (outputInfo) {
            System.out.println("Done!");
        }

        for (int i = 2; i <= N; i++) {
            if (fac[i] == 1) {
                int res = check(i);

                if (res != -1) {
                    Factor fac = new Factor(toBig(i), toBig(res));
                    avails.add(fac);
                }
            }
        }

        if (outputInfo) {
            System.out.println("Available Factors: " + avails.size());
        }

        K.add(new Factor(THREE, ONE));

        if (outputInfo) {
            System.out.println("1: 3, 3, 1");
        }

        for (int i = 1; i < SOLUTIONS; i++) {
            Factor now = K.get(i - 1);
            Factor f = avails.get(i);
            BigInteger p = now.n.multiply(f.n);
            Factor res = new Factor(MINUS_ONE, MINUS_ONE);
            p = update(res, now, f, p);
            p = update(res, now, f.flip(), p);
            p = update(res, now.flip(), f, p);
            p = update(res, now.flip(), f.flip(), p);

            if (cmp(res.n, MINUS_ONE) == 0) {
                if (outputInfo) {
                    System.out.println("Error!");
                }

                break;
            }

            K.add(res);

            if (outputInfo) {
                System.out.println((i + 1) + ": " + f.n + ", " + res.n + ", "
                                   + res.p
                                  );
            }
        }
    }

    void analyze(int n) {
        if ((n <= 0) || (n > K.size())) {
            return;
        }

        Factor k = K.get(n - 1);

        BigInteger v = k.p.multiply(k.p).add(k.p).add(ONE);

        for (int i = 0; i < (n - 1); i++) {
            BigInteger pf = avails.get(i).n;
            BigInteger out = ONE;

            while (zero(v.mod(pf))) {
                out = out.multiply(pf);
                v = v.divide(pf);
            }

            System.out.println(out);
        }

        System.out.println(v);
        System.out.println(k.p);
    }

    void solve() {
        prepare();

        Scanner scan = new Scanner(System.in);
        int cases = scan.nextInt();

        while (cases-- > 0) {
            int n = scan.nextInt();
            analyze(n);
        }
    }

    /**
     * DOCUMENT ME!
     *
     * @param args DOCUMENT ME!
     */
    public static final void main(final String[] args) {
        new Test().solve();
    }

    //~ Inner Classes ----------------------------------------------------------

    class Factor {
        BigInteger n;
        BigInteger p;

        Factor(BigInteger n, BigInteger p) {
            this.n = n;
            this.p = p;
        }

        Factor flip() {
            return new Factor(n, n.subtract(ONE).subtract(p));
        }

        void flipItself() {
            p = n.subtract(ONE).subtract(p);
        }

        void copy(Factor f) {
            n = f.n;
            p = f.p;
        }
    }

    class Triple {
        BigInteger d;
        BigInteger x;
        BigInteger y;

        Triple(BigInteger d, BigInteger x, BigInteger y) {
            this.d = d;
            this.x = x;
            this.y = y;
        }

        void negate() {
            d = d.negate();
            x = x.negate();
            y = y.negate();
        }
    }
}
```
