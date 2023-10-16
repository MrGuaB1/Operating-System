#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <slub.h>


#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    // 初始化物理页地址起点
    struct Page *p = base;
    for (; p != base + n; p ++) {
        //判断该页是否为内核保留页
        assert(PageReserved(p));
        //初始化页内容
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    //把基址页作为这个内存块的headpage，记录了内存块的页数
    base->property = n;
    SetPageProperty(base);
    //此时全局变量增加n个可用的页数
    nr_free += n;
    if (list_empty(&free_list)) {
        //若链表(管理内存块)为空，将该内存块基址加入
        list_add(&free_list, &(base->page_link));
    } else {
        //若链表(管理内存块)不为空，按照地址高低将该内存块基址加入
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
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    //如果需要的页数超过可分配的，返回null
    if (n > nr_free) {
        return NULL;
    }
    //遍历链表，找一个大于n个页的块分配
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        //在bestfit基础上更改得到
        if (p->property >= n) {
            if(page == NULL) 
                page = p;
            else if(p->property< page->property) 
                page = p;
        }
    }
    //如果找到了，裂解块(二分裂解)直至合适，并调整链表
    if (page != NULL) {
        //注意由于二分裂特性，从后往前加是符合地址增长规律的
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        while (page->property/2 >= n) {
            struct Page *p = page + page->property/2;
            p->property = page->property/2;
            SetPageProperty(p);
            //标记page是p的伙伴位
            p->friend = &(page->page_link);
            list_add(prev , &(p->page_link));
            page->property = page->property/2;
        }
        nr_free -= page->property;
        //把基址的标记去掉
        ClearPageProperty(page);
    }
    return page;
}

//找一个64位数最近的大于它的二进制幂
uint64_t smallest_power(uint64_t N)
{
    if(N==1) return 1;
    uint64_t temp = N;
    N = N | (N>>1);
    N = N | (N>>2);
    N = N | (N>>4);
    N = N | (N>>8);
    N = N | (N>>16);
    N = N | (N>>32);
    if(N+1==2*temp)return temp;
    return (N + 1);
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    //需要把n处理成大于n的最小二次幂
    n = smallest_power(n);
    struct Page *p = base;
    //恢复初始化
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    //类似于初始化的处理即可，按照地址高低加入
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

    //难点：连续合并
    //同时先向左再向右检查相邻区块，若地址相连且大小相等则合并，如果两边都和不了，才结束
    list_entry_t* le = list_prev(&(base->page_link));
    list_entry_t* le2 = list_next(&(base->page_link));
    struct Page *p2 = base;
    while (1) {
        p = le2page(le, page_link);
        p2 = le2page(le2, page_link);
        if (le!=&free_list && base->friend==&(p->page_link) &&base->property==p->property) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
            le = list_prev(le);
        }
        else if ((le2!= &free_list) &&(p2->friend==&(base->page_link) &&base->property==p2->property)) {
            base->property += p2->property;
            ClearPageProperty(p2);
            list_del(&(p2->page_link));
            le2 = list_next(le2);
        }
        else break;
    }
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void
basic_check(void) {
    // 看看能不能正常分配页
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    // 确保分配的页不重复
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    // ref是引用counter，这时候应该都被置为零了
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    // 检验虚拟内存映射
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 检验分配后链表是不是正常裂解
    list_entry_t *le = &free_list;
    le = list_next(le);
    struct Page *p = le2page(le, page_link);
    assert(p->property==1);
    le = list_next(le);
    p = le2page(le, page_link);
    assert(p->property==4);
    le = list_next(le);
    p = le2page(le, page_link);
    assert(p->property==8);

    // 暂时存储链表状态方便进行检查
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // 此时list空空，null
    assert(alloc_page() == NULL);

    // 这时候我们再释放刚刚拿掉的三个页，应该可以恢复链表，且空闲页为3
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);


    //也可以继续拿下来用
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    //拿完之后空空了
    assert(alloc_page() == NULL);

    //释放一个页，这时候链表不空
    free_page(p0);
    assert(!list_empty(&free_list));

    //再用一个页去申请页，此时p0没有改变，指向相同，链表空空
    // struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);

    le = list_next(&free_list);
    p = le2page(le, page_link);
    assert(p->property>10000);
}

extern list_entry_t* caches_list;

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_check(void) {
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;

    //测试能否正常分配小字节
    int pagenum = 1;
    struct Page * p = alloc_pages(pagenum);
    struct Page * p2 = alloc_pages(2);
    struct Page * p3 = alloc_pages(pagenum);
    struct Page * p4 = alloc_pages(2);
    struct Page * p5 = alloc_pages(pagenum);
    struct Page * p6 = alloc_pages(2);
    struct Page * p7 = alloc_pages(pagenum);
    struct Page * p8 = alloc_pages(2);
     struct Page * p9 = alloc_pages(pagenum);
    struct Page * p10 = alloc_pages(2);
    cache_list_init();
    struct object* o = slub_alloc(256,p,p2);
    struct object* o2 = slub_alloc(256,p3,p4);
    struct object* o3 = slub_alloc(256,p5,p6);
    struct object* o4 = slub_alloc(512,p7,p8);
    struct object* o5 = slub_alloc(512,p9,p10);
    cprintf("分配的第一个256的小内存在%x\n",o);
    cprintf("分配的第一个256的小内存在%x\n",o2);
    cprintf("分配的第一个256的小内存在%x\n",o3);
    cprintf("分配的第一个512的小内存在%x\n",o4);
    cprintf("分配的第一个512的小内存在%x\n",o5);
    return ;

    //检验空闲页数是否正确，每块的头页标记是否正确
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());
    assert(count==1);
    
    //基础测试，基本和best_fit中一致
    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif

    //检验分配是否正常
    struct Page *P0 = alloc_pages(7);
    assert(P0->property==8);
    struct Page *P1= alloc_pages(3), *P2= alloc_pages(70),*P3= alloc_pages(3);
    assert(P1->property==4);
    assert(P2->property==128);
    assert(P3->property==4);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif

    //检验释放是否正常，需要注意只能一个块一个块是释放
    free_pages(P2, 70);
    assert(PageProperty(P2));
    assert(P2->property==128);
    free_pages(P3,3);
    assert(P3->property==4);
    free_pages(P1,3);
    //发生单次合并
    assert(P1->property==8);
    //发生迭代合并
    free_pages(P0,6);
    assert(P0->property== nr_free_pages());
    
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif

    //检验特殊情况的释放页，即128，128，128，128中是否会出现中间两个合并
    //导致两边的2无法合并的现象(通过伙伴标记判断)
    P0 = alloc_pages(70);
    P1 = alloc_pages(69);
    P2 = alloc_pages(90);
    P3 = alloc_pages(121);

    free_pages(P1, 69);
    free_pages(P2, 90);
    //此时P1和P2应该不合并
    assert(P1->property==128);
    free_pages(P0,70);
    //此时P1和P0合并
    assert(P0->property==256);
    free_pages(P3, 121);
    //此时四个一起合并，全部合并
    assert(P0->property== nr_free_pages());


    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif


    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
//这个结构体在
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

