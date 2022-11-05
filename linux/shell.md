# **shell编程**

## **Shebang**

计算机程序中，`shebang`指的是出现在文本文件的第一行前两个字符`#!`

在Unix系统中，程序会分析`shebang`后面的内容，作为解释器的指令，例如：

* 以`#!/bin/sh`开头的文件，程序在执行时会调用`/bin/sh`，也就是bash解释器
* 以`#!/usr/bin/python`开头的文件，代表执行python解释器去执行
* 以`#!/usr/bin/env 解释器名称`，是一种在不同平台上都能正确找到解释器的方法

<br>

## **脚本注释、脚本开发规范**

```shell
#!/bin/bash

# Date : 2022-11-2 13:46:00
# Author : created by epha
# Email : 13626376642@163.com
```

<br>
