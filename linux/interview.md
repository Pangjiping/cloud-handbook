# **Linux**

## **Unix和Linux有什么区别**

* 开源性。Linux是一款开源操作系统，不需要付费即可使用；Unix是一款对源码实行产权保护的传统商业软件，需要付费授权使用。
* 跨平台性。Linux具有良好的跨平台性，可运行在多种硬件平台上；Unix操作系统跨平台性能较弱，大多需要与硬件配套使用。
* 可视化界面。Linux除了进行命令行操作，还有窗体管理系统；Unix只是命令行下的系统。
* 硬件环境。Linux操作系统对硬件的要求较低，安装方法更易掌握；Unix对硬件要求比较苛刻，安装难度较大。
* 用户群体。Linux的用户群体很广泛，个人和企业均可使用；Unix的用户群体比较窄，多是安全性要求高的大型企业使用，如银行、电信部门等，或者Unix硬件厂商使用，如Sun等。

<br>

## **Linux内核**

Linux系统的核心是内核，内核控制着计算机系统上的所有硬件与软件，在必要时分配硬件，并根据需要执行软件。

* 系统内存管理
* 应用程序管理
* 硬件设备管理
* 文件系统管理

<br>

## **Linux的体系结构**

从大的方向讲，Linux的体系结构可以分成两块:

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3d2f4c1ec6a14eca9553784df58d61eb~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

* 用户空间: 用户空间又包括用户的应用程序和C库
* 内核空间: 内核空间又包括系统调用接口(System Call Interface)、内核(Kernel)、平台架构相关的代码(Architecture-Dependent Kernel Code)

为什么Linux体系结构要分为用户空间和内核空间？

* 现代CPU实现了不同的工作模式，不同模式下CPU可以执行的指令和访问的寄存器不同
* Linux从CPU的角度出发，为了保护内核的安全，把系统分成了两部分
* 用户空间和内核空间是程序执行的两种不同的状态，我们可以通过两种方式完成用户空间到内核空间的转移:
  * 系统调用
  * 硬件中断

<br>

## **BASH和DOS之间的基本区别是什么?**

BASH和DOS控制台之间的主要区别在于3个方面:

* BASH命令区分大小写，而DOS命令不区分
* 在BASH下，/ character是目录分隔符，\作为转义字符。在DOS下，/用作命令参数分隔符，\是目录分隔符
* DOS遵循命名文件中的约定，即8个字符的文件名后跟一个点，扩展名为3个字符。BASH没有遵循这样的惯例

<br>

## **Linux系统日志**

比较重要的是`/var/log/messages`日志文件，该日志文件是许多进程日志文件的汇总，从该文件可以看出任何入侵企图或成功的入侵。

<br>

## **swap空间**

交换空间是Linux使用的一定空间，用于临时保存一些并发运行的程序。当RAM没有足够的内存来容纳正在执行的所有程序时，就会发生这种情况。

<br>

## **grep**

grep善于查找

```bash
用法: grep [选项]... PATTERN [FILE]...
在每个 FILE 或是标准输入中查找 PATTERN。
默认的 PATTERN 是一个基本正则表达式(缩写为 BRE)。
例如: grep -i 'hello world' menu.h main.c

正则表达式选择与解释:
  -E, --extended-regexp     PATTERN 是一个可扩展的正则表达式(缩写为 ERE)
  -F, --fixed-strings       PATTERN 是一组由断行符分隔的定长字符串。
  -G, --basic-regexp        PATTERN 是一个基本正则表达式(缩写为 BRE)
  -P, --perl-regexp         PATTERN 是一个 Perl 正则表达式
  -e, --regexp=PATTERN      用 PATTERN 来进行匹配操作
  -f, --file=FILE           从 FILE 中取得 PATTERN
  -i, --ignore-case         忽略大小写
  -w, --word-regexp         强制 PATTERN 仅完全匹配字词
  -x, --line-regexp         强制 PATTERN 仅完全匹配一行
  -z, --null-data           一个 0 字节的数据行，但不是空行

Miscellaneous:
  -s, --no-messages         suppress error messages
  -v, --invert-match        select non-matching lines
  -V, --version             display version information and exit
      --help                display this help text and exit

输出控制:
  -m, --max-count=NUM       NUM 次匹配后停止
  -b, --byte-offset         输出的同时打印字节偏移
  -n, --line-number         输出的同时打印行号
      --line-buffered       每行输出清空
  -H, --with-filename       为每一匹配项打印文件名
  -h, --no-filename         输出时不显示文件名前缀
      --label=LABEL         将LABEL 作为标准输入文件名前缀
  -o, --only-matching       show only the part of a line matching PATTERN
  -q, --quiet, --silent     suppress all normal output
      --binary-files=TYPE   assume that binary files are TYPE;
                            TYPE is 'binary', 'text', or 'without-match'
  -a, --text                equivalent to --binary-files=text
  -I                        equivalent to --binary-files=without-match
  -d, --directories=ACTION  how to handle directories;
                            ACTION is 'read', 'recurse', or 'skip'
  -D, --devices=ACTION      how to handle devices, FIFOs and sockets;
                            ACTION is 'read' or 'skip'
  -r, --recursive           like --directories=recurse
  -R, --dereference-recursive
                            likewise, but follow all symlinks
      --include=FILE_PATTERN
                            search only files that match FILE_PATTERN
      --exclude=FILE_PATTERN
                            skip files and directories matching FILE_PATTERN
      --exclude-from=FILE   skip files matching any file pattern from FILE
      --exclude-dir=PATTERN directories that match PATTERN will be skipped.
  -L, --files-without-match print only names of FILEs containing no match
  -l, --files-with-matches  print only names of FILEs containing matches
  -c, --count               print only a count of matching lines per FILE
  -T, --initial-tab         make tabs line up (if needed)
  -Z, --null                print 0 byte after FILE name

文件控制:
  -B, --before-context=NUM  打印以文本起始的NUM 行
  -A, --after-context=NUM   打印以文本结尾的NUM 行
  -C, --context=NUM         打印输出文本NUM 行
  -NUM                      same as --context=NUM
      --group-separator=SEP use SEP as a group separator
      --no-group-separator  use empty string as a group separator
      --color[=WHEN],
      --colour[=WHEN]       use markers to highlight the matching strings;
                            WHEN is 'always', 'never', or 'auto'
  -U, --binary              do not strip CR characters at EOL (MSDOS/Windows)
  -u, --unix-byte-offsets   report offsets as if CRs were not there
                            (MSDOS/Windows)

‘egrep’即‘grep -E’。‘fgrep’即‘grep -F’。
直接使用‘egrep’或是‘fgrep’均已不可行了。
若FILE 为 -，将读取标准输入。不带FILE，读取当前目录，除非命令行中指定了-r 选项。
如果少于两个FILE 参数，就要默认使用-h 参数。
如果有任意行被匹配，那退出状态为 0，否则为 1；
如果有错误产生，且未指定 -q 参数，那退出状态为 2。
```

* 包含root: `grep -n root`
* 不包含root: `grep -nv root`
* s开头: `grep ^s`
* n结尾: `grep -n n$`

<br>

## **sed**

sed取行进行打印、替换

```bash
用法: sed [选项]... {脚本(如果没有其他脚本)} [输入文件]...

  -n, --quiet, --silent
                 取消自动打印模式空间
  -e 脚本, --expression=脚本
                 添加“脚本”到程序的运行列表
  -f 脚本文件, --file=脚本文件
                 添加“脚本文件”到程序的运行列表
  --follow-symlinks
                 直接修改文件时跟随软链接
  -i[SUFFIX], --in-place[=SUFFIX]
                 edit files in place (makes backup if SUFFIX supplied)
  -c, --copy
                 use copy instead of rename when shuffling files in -i mode
  -b, --binary
                 does nothing; for compatibility with WIN32/CYGWIN/MSDOS/EMX (
                 open files in binary mode (CR+LFs are not treated specially))
  -l N, --line-length=N
                 指定“l”命令的换行期望长度
  --posix
                 关闭所有 GNU 扩展
  -r, --regexp-extended
                 在脚本中使用扩展正则表达式
  -s, --separate
                 将输入文件视为各个独立的文件而不是一个长的连续输入
  -u, --unbuffered
                 从输入文件读取最少的数据，更频繁的刷新输出
  -z, --null-data
                 separate lines by NUL characters
  --help
                 display this help and exit
  --version
                 output version information and exit

如果没有 -e, --expression, -f 或 --file 选项，那么第一个非选项参数被视为
sed脚本。其他非选项参数被视为输入文件，如果没有输入文件，那么程序将从标准
输入读取数据。
```

* 打印第2行: `sed -n 2p passwd`
* 打印2-5行: `sed -n 2,5p passwd`
* root全替换为abc: `sed -i 's/root/abc/g' passwd`

<br>

## **awk**

awk取列进行打印

```bash
Usage: awk [POSIX or GNU style options] -f progfile [--] file ...
Usage: awk [POSIX or GNU style options] [--] 'program' file ...
POSIX options:          GNU long options: (standard)
        -f progfile             --file=progfile
        -F fs                   --field-separator=fs
        -v var=val              --assign=var=val
Short options:          GNU long options: (extensions)
        -b                      --characters-as-bytes
        -c                      --traditional
        -C                      --copyright
        -d[file]                --dump-variables[=file]
        -e 'program-text'       --source='program-text'
        -E file                 --exec=file
        -g                      --gen-pot
        -h                      --help
        -L [fatal]              --lint[=fatal]
        -n                      --non-decimal-data
        -N                      --use-lc-numeric
        -O                      --optimize
        -p[file]                --profile[=file]
        -P                      --posix
        -r                      --re-interval
        -S                      --sandbox
        -t                      --lint-old
        -V                      --version

To report bugs, see node `Bugs' in `gawk.info', which is
section `Reporting Problems and Bugs' in the printed version.

gawk is a pattern scanning and processing language.
By default it reads standard input and writes standard output.

Examples:
        gawk '{ sum += $1 }; END { print sum }' file
        gawk -F: '{ print $1 }' /etc/passwd
```

* 打印文件第1列: `awk -F ':' '{print $1}' passwd`
* 输出字段1,3,6，然后以制表符作为分隔符: `awk -F ':' '{print $1,$2,$3}' OFS="\t" passwd`

<br>

## **进程状态**

![img](https://img2018.cnblogs.com/blog/875796/201909/875796-20190926175737431-422827153.png)

ps命令 flag详解

![img](https://img2018.cnblogs.com/blog/875796/201909/875796-20190926175914732-761997808.png)

<br>

## **文件指令**

* vi 文件名 #编辑方式查看，可修改
* cat 文件名 #显示全部文件内容
* more 文件名 #分页显示文件内容
* less 文件名 #与 more 相似，更好的是可以往前翻页
* tail 文件名 #仅查看尾部，还可以指定行数
* head 文件名 #仅查看头部,还可以指定行数

https://www.cnblogs.com/aganippe/p/16038422.html

<br>

## **网络指令**

https://www.cnblogs.com/aganippe/p/16036119.html

<br>
