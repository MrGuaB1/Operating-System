#### Lab2 说明

- 完成了全部 exercise 和 challenge
- docs：[实验报告](https://github.com/MrGuaB1/Operating-System/blob/main/reports/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A%20Lab2/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A%20%20Lab2.md)  &emsp; [Buddy-System设计文档](https://github.com/MrGuaB1/Operating-System/blob/main/reports/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A%20Lab2/Buddy-System%20%E8%AE%BE%E8%AE%A1%E6%96%87%E6%A1%A3.md)  &emsp; [Slub设计文档](https://github.com/MrGuaB1/Operating-System/blob/main/reports/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A%20Lab2/Slub%20%E8%AE%BE%E8%AE%A1%E6%96%87%E6%A1%A3.md)
- 由于测试 `Buddy-System` 以及 `Slub`，对脚本和 `pmm_manager` 做了修改，当前默认为测试 `Buddy-System` 
- `/lab2/kern/mm/slubImpl` 下存放了我们 `Buddy-System` 的另外一种实现，以及 `Slub` 的实现，若要测试 `Slub`，请将 `slub.c,slub.h` 以及 `memlayout.c`(修改了 `Page` 结构体) 复制到 `kern/mm/` 下，`make qemu` 进行测试