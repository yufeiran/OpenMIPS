# OpenMIPS

## 简介
一个基础但功能完善的计算机系统，包含：CPU、外设、操作系统。

视频演示 [自制CPU和外设运行贪吃蛇](https://www.bilibili.com/video/BV1Rf4y1t7Wo)
### CPU
CPU使用MIPS32 release 1指令集，采用五级流水线结构, 实现了协处理器CP0、内存管理单元TLB ，在FPGA开发板Nexys4 DDR上运行主频为50Mhz。使用硬件描述语言Verilog实现。CPU结构如下图。
![CPU结构](https://github.com/yufeiran/OpenMIPS/assets/22091612/89407f55-31fe-4ec7-84e0-4121223fe8b7)


(tlb正准备实装)
### 外设
CPU使用总线与外设连接的方式如下图所示
![image](https://github.com/yufeiran/OpenMIPS/assets/22091612/891cdfd5-a7a7-4b40-80ca-8c4853c77957)

外设实现了：DDR2 RAM控制器、SPI FLASH控制器、PS/2键盘和VGA显示模块，
使用wishbone总线协议。使用硬件描述语言Verilog实现。

### 外设物理地址映射
|外设名称|物理地址|
|--------|--------|
| DDR2 RAM控制器| 0x0000_0000 ~ 0x07FF_FFFF |
| UART控制器 | 0x0800_0000 ~ 0x0800_0007 |
| GPIO | 0x0900_0000 ~ 0x0900_000F |
| FLASH ROM控制器 | 0x0A00_0000 ~ 0x0AFF_FFFF |
| VGA控制器 | 0x0B00_0000 ~ 0x0B00_1800 |
| KEYBOARD | 0x0C00_0000 ~ 0x0C00_0010 |
### 操作系统
操作系统基于MIT开发的类UNIX的xv6操作系统进行改进，改进包括：

进程调度：为每个进程实现独立内核页表，避免大量的内存地址翻译

内存管理：实现了Lazy Page Allocation和Copy-On-Write内存机制

文件系统：实现多级数据索引块，实现软链接，实现了mmap文件内存映射功能

中断管理：提供更多的中断服务，异常时显示错误定位

用户程序：实现了xargs、find命令

使用C和汇编实现。

(xv6操作系统待移植，这部分代码请参考[
xv6-labs-2020](https://github.com/yufeiran/xv6-labs-2020))

## PS
原先的FLASH ROM由于物理地址映射修改已经失效，所以被删除，新的FLASH ROM存放于./ROM/中

## 参考书籍
《自己动手写CPU》 -雷思磊





 
