#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

// Ex1：分析 default_init default_init_memmap default_alloc_pages default_free_pages 等函数

// First-fit算法：在收到内存请求时，沿着列表扫描足以满足请求的第一个块，
// 并且如果选择的块明显大于请求的块，那么通常会对其进行分割，并将剩余的块作为另一个空闲块添加到列表中

// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.

/*
 * Details of FFMA
 * (1) Prepare: 为了实现 First-Fit Mem Alloc (FFMA)，我们应该使用一些列表来管理空闲内存块
 *              结构体 free_area_t 用于管理空闲内存块，首先你应该熟悉list.h中的struct list。
 *              struct list 是一个简单的双向链表实现。
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              另一个棘手的method是将通用列表结构转换为特殊结构（例如结构页）：
 *              你可以找到一些宏：le2page（在memlayout.h中），（在未来的实验中：le2vma（在vmm.h中），le2proc（在proc.h中）等）
 *
 * (2) default_init: 您可以重用演示default_init 函数来初始化free_list并将nr_free（空闲内存块数量）设置为0
 *                   free_list用于记录空闲mem块。 nr_free 是空闲内存块的总数。
 *
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              该函数用于初始化一个空闲块（带参数：addr_base，page_number）
 *              首先，您应该初始化此空闲块中的每个页面（在 memlayout.h 中），包括：
 *                  1.p->flags 应该被设置为 PG_property 位（意味着这个页面是有效的。
 *                  在 pmm_init fun 中（在 pmm.c 中），PG_reserved 位被设置在 p->flags 中）
 *
 *                  2.如果该页是空闲的并且不是空闲块的第一页，则 p->property 应设置为 0
 *                  3.如果此页是空闲的并且是空闲块的第一页，则 p->property 应设置为块的总数量。
 *                  4.p->ref 应该为 0，因为现在 p 是空闲的并且没有引用。
 *                  5.我们可以使用 p->page_link 将此页面链接到 free_list，（如：list_add_before(&free_list, &(p->page_link)); ）
 *             最后，我们应该对空闲内存块的数量求和：nr_free+=n
 *
 * (4) default_alloc_pages: 在空闲列表中搜索找到第一个空闲块（块大小> = n）并调整空闲块的大小，返回分配的块的地址
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) 如果我们找到这个p，那么就意味着我们找到了一个空闲块（块大小> = n），并且前n页可以被分配。
 *                          我们应该设置该页的一些标志位：PG_reserved = 1，PG_property = 0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) 如果(p->property >n)，我们应该重新计算这个空闲块剩余的数量，(如：le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  重新计算nr_free（剩余的所有空闲块的数量）
 *                 (4.1.4)  return p
 *               (4.2) 如果找不到空闲块（块大小 >=n），则返回 NULL
 *
 * (5) default_free_pages: 将页面重新链接到空闲列表中，也许会将小空闲块合并为大空闲块。
 *               (5.1) 根据提取块的基地址，查找空闲列表，找到正确的位置（从低地址到高地址），插入页面。（可以使用list_next、le2page、list_add_before）
 *               (5.2) 重置页面的字段，例如p->ref、p->flags（PageProperty）
 *               (5.3) 尝试合并低地址或高地址块。 注意：应正确更改某些页面的 p->property。
 */
free_area_t free_area; //管理空闲内存块的结构

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0; //空闲内存块的总数初始化为0
}

static void
default_init_memmap(struct Page *base, size_t n) { //初始化一个空闲块
    assert(n > 0);
    struct Page *p = base; // 创建一个指向页面块的指针p，初始指向传入的base地址
    for (; p != base + n; p ++) {
        assert(PageReserved(p)); 
        p->flags = p->property = 0; //如果该页是空闲的并且不是空闲块的第一页，则 p->property 应设置为 0
        set_page_ref(p, 0);  //将页块的引用计数设置为0
    }
    base->property = n; //如果此页是空闲的并且是空闲块的第一页，则p->property(空闲块数量)应设置为块的总数量
    SetPageProperty(base);
    nr_free += n;  //增加系统的空闲页数
    if (list_empty(&free_list)) {  //如果空闲页列表为空，那么直接将base加到表头
        list_add(&free_list, &(base->page_link));
    } else { // 否则需要遍历列表，找到合适的位置
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) { //已到达末尾，直接add即可
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n) { //在空闲列表中搜索找到第一个空闲块并调整空闲块的大小，返回分配的块的地址
    assert(n > 0);
    if (n > nr_free) { //比系统剩的还多，直接返回空
        return NULL;
    }

    struct Page *page = NULL;  // 用于存储分配的页块的指针
    list_entry_t *le = &free_list; //指向空闲页块链表头的指针

    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) { //找到了第一个大于n的块，直接退出循环
            page = p;
            break;
        }
    }
    if (page != NULL) { //代表找到了块
        list_entry_t* prev = list_prev(&(page->page_link)); //获取分配页块的前一个页块
        list_del(&(page->page_link)); //把要分配的这个块从链表中删除
        if (page->property > n) { //如果该页块的大小大于要分配的页数，就计算出剩余未分配的页块的地址
            struct Page *p = page + n;
            p->property = page->property - n; // 更新剩余页块的大小
            SetPageProperty(p); //设置标志位：PG_property = 0 PG_reserved = 1
            list_add(prev, &(p->page_link)); // 将剩余页块添加到空闲页块链表中
        }
        nr_free -= n; //总页数-n
        ClearPageProperty(page); // 清除被分配的页块的property标志位，表示已被分配
    }
    return page;
}

static void
default_free_pages(struct Page *base, size_t n) { //内存释放函数，将页面重新链接到空闲列表中
    assert(n > 0);
    struct Page *p = base;  // 指向要释放的页块
    for (; p != base + n; p ++) { // 遍历要释放的页块，确保它们不是保留页块或带有属性
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0; //清除标志位和引用次数
        set_page_ref(p, 0);
    }
    //和初始化类似，如果此页是空闲的并且是空闲块的第一页，则 p->property 应设置为块的总数量
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link)); // 获取释放的页块的前一个链表项
    if (le != &free_list) { // 如果前一个链表项不是空闲页块链表头，还要和前面的合并
        p = le2page(le, page_link);
        // 如果 p 是 base 的前一个内存页块，并且它们的大小相加等于 base 内存页块的地址，那么它们就是相邻的内存页块，需要合并
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base); //清除当前页块的peoperty位
            list_del(&(base->page_link)); //删除页块
            base = p; //返回合并后的页块
        }
    }
    // 无论是不是表头，和后面的合并，并删除后一个页面
    le = list_next(&(base->page_link)); // 获取释放的页块的后一个链表项
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

