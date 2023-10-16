#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <default_pmm.h>
#include "buddy_pmm.h"

// 调整参数为不小于它的最小的2的幂次方
static unsigned fixsize(unsigned size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1; //得到2的幂次方
}

// buddy-system 数据结构：
struct buddy2 {
    unsigned size; //实际大小
    unsigned longest;  //记录实际分配的占用的块的大小
};
struct buddy2 root[80000]; //存放完全二叉树的数组，用于内存分配

free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

struct allocRecord//记录分配块的信息
{
    struct Page* base;
    int offset; //记录偏移量，告诉系统在所选块内的哪个位置分配了页面，便于分配和释放
    size_t nr;//块大小
};

struct allocRecord rec[80000];//存放偏移量的数组
int nr_block;//已分配的块数

static void buddy_init()
{
    list_init(&free_list);
    nr_free = 0;
}

//初始化二叉树上的节点
void buddy2_new(int size) {
    unsigned node_size = size * 2;
    nr_block = 0; //初始化已分配的块数为0
    root[0].size = size;

    for (int i = 0; i < 2 * size - 1; i++) {
        if (IS_POWER_OF_2(i + 1))
            node_size /= 2;
        root[i].longest = node_size;
    }
    return;
}

static void
buddy_init_memmap(struct Page* base, size_t n)
{
    assert(n > 0);
    struct Page* p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 1;
        set_page_ref(p, 0);
        SetPageProperty(p);
        list_add_before(&free_list, &(p->page_link));
    }
    nr_free += n;
    int allocpages = UINT32_ROUND_DOWN(n);
    buddy2_new(allocpages);
}

//内存分配
int buddy2_alloc(struct buddy2* self, int size) {
    unsigned index = 0;//节点的标号
    unsigned node_size;
    unsigned offset = 0;

    if (size <= 0) 
        size = 1;
    else if (!IS_POWER_OF_2(size)) //不为2的幂时，取比size大的，最接近的2的n次幂
        size = fixsize(size);
    if (self[index].longest < size) //可分配内存不足
        return -1;

    for (node_size = self->size; node_size != size; node_size /= 2) {
        if (self[LEFT_LEAF(index)].longest >= size)
        {
            if (self[RIGHT_LEAF(index)].longest >= size)
                //找到两个相符合的节点中内存较小的结点
                index = self[LEFT_LEAF(index)].longest <= self[RIGHT_LEAF(index)].longest ? LEFT_LEAF(index) : RIGHT_LEAF(index);            
            else
                index = LEFT_LEAF(index);
        }
        else
            index = RIGHT_LEAF(index);
    }

    self[index].longest = 0;//标记节点为已使用
    offset = (index + 1) * node_size - self->size;
    while (index) {
      // 向上遍历树，确保树中的其他节点也被正确标记为已使用或空闲
        index = PARENT(index);
        self[index].longest =
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
    }
    return offset;
}

static struct Page*
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free)
        return NULL;
    struct Page* page = NULL;
    struct Page* p;
    list_entry_t* le = &free_list, * len;
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
        le = list_next(le);
    page = le2page(le, page_link);
    int allocpages = fixsize(n); //根据需求n得到块大小
    rec[nr_block].base = page;//记录分配块首页
    rec[nr_block].nr = allocpages;//记录分配的页数
    nr_block++;
    //修改每一页的状态
    for (int i = 0; i < allocpages; i++)
    {
        len = list_next(le);
        p = le2page(le, page_link);
        ClearPageProperty(p);
        le = len;
    }
    nr_free -= allocpages;//减去已被分配的页数
    page->property = n;
    return page;
}

void buddy_free_pages(struct Page* base, size_t n) {
    unsigned node_size, index = 0;
    unsigned left_longest, right_longest;
    struct buddy2* self = root;

    list_entry_t* le = list_next(&free_list);
    int i = 0;
    for (i = 0; i < nr_block; i++)//找到块
        if (rec[i].base == base)
            break;
    int offset = rec[i].offset; //找到偏移量
    int pos = i; //暂存i
    i = 0;
    while (i++ < offset)
        le = list_next(le);
    int allocpages = fixsize(n);

    node_size = 1;
    index = offset + self->size - 1;
    nr_free += allocpages;//更新空闲页的数量
    struct Page* p;
    self[index].longest = allocpages; //恢复longest字段

    for (i = 0; i < allocpages; i++)//回收已分配的页
    {
        p = le2page(le, page_link);
        p->flags = 0;
        p->property = 1;
        SetPageProperty(p);
        le = list_next(le);
    }
    while (index) { //向上合并，修改祖先节点的记录值
        index = PARENT(index);
        node_size *= 2;

        left_longest = self[LEFT_LEAF(index)].longest;
        right_longest = self[RIGHT_LEAF(index)].longest;

        if (left_longest + right_longest == node_size)
            self[index].longest = node_size;
        else
            self[index].longest = MAX(left_longest, right_longest);
    }

    // 恢复结构体
    for (i = pos; i < nr_block - 1; i++)
        rec[i] = rec[i + 1];
    nr_block--; //更新分配块数的值
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
buddy_check(void) {
    struct Page* p0, * A, * B, * C, * D;
    p0 = A = B = C = D = NULL;

    // 检验是否分配成功
    assert((p0 = alloc_page()) != NULL);
    assert((A = alloc_page()) != NULL);
    assert((B = alloc_page()) != NULL);

    //检验分配是否不重复
    assert(p0 != A && p0 != B && A != B);

    // 多重合并检验，最终的效果是A和P0都指向含1024页的块的首地址
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
    free_page(p0);
    free_page(A);
    free_page(B);
    A = alloc_pages(500);
    B = alloc_pages(500);
    cprintf("A %p\n", A);
    cprintf("B %p\n", B);
    free_pages(A, 250);
    free_pages(B, 500);
    free_pages(A + 250, 250);
    p0 = alloc_pages(1024);
    cprintf("p0 %p\n", p0);
    assert(p0 == A);
    assert(p0 + 512 == B);

    //检验buddy分配规则
    A = alloc_pages(70);
    B = alloc_pages(35);
    assert(A + 128 == B);
    cprintf("A %p\n", A);
    cprintf("B %p\n", B);
    C = alloc_pages(80);
    assert(A + 256 == C);
    cprintf("C %p\n", C);
    free_pages(A, 70);
    cprintf("B %p\n", B);
    D = alloc_pages(60);
    cprintf("D %p\n", D);
    assert(B + 64 == D);
    free_pages(B, 35);
    cprintf("D %p\n", D);
    free_pages(D, 60);
    cprintf("C %p\n", C);
    free_pages(C, 80);
    free_pages(p0, 1000);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};