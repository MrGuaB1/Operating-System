/*
buddy.h
**/

#ifndef __KERN_MM_BUDDY_H__
#define  __KERN_MM_BUDDY_H__

#include <pmm.h>

//定义一些宏
#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)
#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
//让a右移n位 
#define UINT32_SHR_OR(a,n) ((a)|((a)>>(n))) 
#define UINT32_MASK(a) (UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(a,1),2),4),8),16))    
//大于a的最小的2^k
#define UINT32_REMAINDER(a) ((a)&(UINT32_MASK(a)>>1))
//小于a的最大的2^k
#define UINT32_ROUND_DOWN(a) (UINT32_REMAINDER(a)?((a)-UINT32_REMAINDER(a)):(a))

extern const struct pmm_manager buddy_pmm_manager;


#endif /* ! __KERN_MM_BUDDY_H__ */