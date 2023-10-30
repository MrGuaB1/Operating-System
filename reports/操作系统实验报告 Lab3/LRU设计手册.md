#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）

#### 1、算法设计

​	LRU算法是大部分操作系统为最大化页面命中率而广泛采用的一种页面置换算法。该算法的思路是利用局部性原理，根据一个作业在执行过程中过去的页面访问历史来推测未来的行为。它认为过去一段时间里不曾被访问过的页面，在最近的将来可能也不会再被访问。

​	所以，这种算法的实质是：当需要淘汰一个页面时，总是选择在最近一段时间内最久不用的页面予以淘汰。

​	对于LRU算法在Ucore的具体实现，事实上逻辑并不困难，我们可以通过维护Page结构体中一个访问字段，记录每个页面自上次被访问以来所经历的时间t。

```c++
struct Page {
    int ref;                        // page frame's reference counter
    uint_t flags;                 // array of flags that describe the status of the page frame
    uint_t visited;
    unsigned int property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
    list_entry_t pra_page_link;     // used for pra (page replace algorithm)
    uintptr_t pra_vaddr;            // used for pra (page replace algorithm)
};
```

​	这里，我们以先前用于Clock算法的visited成员作为访问字段，记录自上次访问以来所经历的时间t。

​	而相关的数据结构，由于不考虑开销，事实上我们同样可以修改Clock算法中的链表结构，在每次需要换出的时候，遍历找到访问字段中存储的时间t最大的页面，将它作为换出页（victim）来实现我们的LRU算法

​	但是实现的难点在于，如何在Ucore中监视是否有访问页操作呢？在我们的Ucore中并未提供相关的接口，因此难以真正意义上实现对页的监视。但是，我们可以通过封装对页的访问，模拟硬件支持，每次访问后对每个页面的访问字段进行更新，以此来实现LRU算法。

​	

#### 2、代码分析

​	下面，我们给出具体的代码实现，结合代码来分析我们做了哪些方面的工作，实现了LRU算法：

**（1）模拟硬件支持接口：**

​	这里，我们在swap.c中实现了两个模拟LRU硬件支持的接口，lru_update()为LRU更新计数器的模拟接口，通过调用全局变量check_mm_struct，对其内部成员的sm_priv（存储LRU链表头）进行遍历来实现LRU计数器的更新和管理。

​	我们首先获取了当前访问地址addr（参数）对应的物理页，通过和链表上物理页进行比对实现对是否是访问的页的处理，若为我们正在访问的页，则将访问字段visited置为0，若不为我们正在访问的页，则将访问字段visited加一。

​	lru_write_memory()是模拟的写存接口，两个参数分别为要写入的虚拟地址和它的值。

```c++
//模拟硬件的lru计数器
void lru_update(int addr){
    extern struct mm_struct *check_mm_struct;
    struct Page* page2 = get_page(check_mm_struct->pgdir, addr, NULL);
    if(check_mm_struct!=NULL){
        list_entry_t *head=(list_entry_t*) check_mm_struct->sm_priv;
        assert(head != NULL);
        list_entry_t *le = head->next;
        // 遍历mm的链表，visited加1,若是刚刚访问的addr，visited改为0
        while (le!=head) {
            struct Page* page = le2page(le,pra_page_link);
            if(page!=page2) page->visited++;
            else page->visited =0;
            le = le->next;
        }
        return;
    }
    return;
}

//模拟硬件的访存接口
void lru_write_memory(int addr, int value){
    *(unsigned char *)addr = value;
    lru_update(addr);
}
```

​	这里，我们调用了一个比较重要的api：get_page方法，该方法的代码结构如下，用于从一个虚拟地址获得其对应的物理页（若存在）。

```c++
// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL) {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V) {
        return pte2page(*ptep);
    }
    return NULL;
}

```

**（2）换入换出具体实现：**

​	这里，我们修改了clock算法中的链表结构，在_lru_map_swappable完成设置页面可交换，通过将新页面加入链表最前面实现。

​	而对于换出页面的选择，则需要对链表结构进行遍历，找到visited最大的页面，将它作为换出页（victim）来返回，并在链表中删除该页面来实现。

​	这里，为了方便检验，我们在每次换页发生时，输出每个页面的状态和最终选定的换出页是哪一个页。

```c++
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);

    list_add(head, entry);
    //visited为距离上一次访问的访问次数
    page->visited = 0;
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
    list_entry_t *le = head->next;
    uint_t max = 0;
    // 遍历mm的链表，找出最后一个visited最大的值
    cprintf("\nPage swap out begin\n");
    while (le!=head) {
        struct Page* page = le2page(le,pra_page_link);
        if(page->visited >= max){
            max = page->visited;
            curr_ptr = le;
            struct Page* page2 = le2page(curr_ptr,pra_page_link);
        }
        cprintf("Page:%x,Page.visited:%d\n",page2ppn(page),page->visited);
        le = le->next;
    }
    *ptr_page = le2page(curr_ptr,pra_page_link);
    cprintf("vitim Page:%x,Page.visited:%d\n\n",page2ppn(*ptr_page),(*ptr_page)->visited);
    list_del(curr_ptr);
    return 0;
}
```



#### 3、检验测试

​	这里，我们考察swap.c中的check_swap函数，对其进行修改，来实现我们对LRU算法的检验。

​	在check_swap函数中，进行换出之前，我们完成了如下的初始化：

- 构建了一个大小从0x1000到0x6000的虚拟空间，由一个mm结构体进行管理，其中只含由一个vma结构体。
- 将free_list这个物理页表管理结构初始化，只保留了四个页在其中。
- 调用check_content_set()函数，对页面进行初步的访问，使物理页刚好用完。

​	这里，我们首先对check_content_set()函数进行修改，更改为LRU算法下采用LRU模拟硬件支持的写存接口进行写存操作：

```c++
static inline void
check_content_set(void)
{
     if (sm == &swap_manager_lru){
          lru_write_memory(0x1000 , 0x0a);
          assert(pgfault_num==1);
          lru_write_memory(0x1010 , 0x0a);
          assert(pgfault_num==1);
          lru_write_memory(0x2000 , 0x0b);
          assert(pgfault_num==2);
          lru_write_memory(0x2010 , 0x0b);
          assert(pgfault_num==2);
          lru_write_memory(0x3000 , 0x0c);
          assert(pgfault_num==3);
          lru_write_memory(0x3010 , 0x0c);
          assert(pgfault_num==3);
          lru_write_memory(0x4000 , 0x0d);
          assert(pgfault_num==4);
          lru_write_memory(0x4010 , 0x0d);
          assert(pgfault_num==4);
     }
     else{
          *(unsigned char *)0x1000 = 0x0a;
          assert(pgfault_num==1);
          *(unsigned char *)0x1010 = 0x0a;
          assert(pgfault_num==1);
          *(unsigned char *)0x2000 = 0x0b;
          assert(pgfault_num==2);
          *(unsigned char *)0x2010 = 0x0b;
          assert(pgfault_num==2);
          *(unsigned char *)0x3000 = 0x0c;
          assert(pgfault_num==3);
          *(unsigned char *)0x3010 = 0x0c;
          assert(pgfault_num==3);
          *(unsigned char *)0x4000 = 0x0d;
          assert(pgfault_num==4);
          *(unsigned char *)0x4010 = 0x0d;
          assert(pgfault_num==4);
     }
}
```

​	随后，check_swap会调用check_content_access()函数，进行换出页的判断，其封装了sm即swap_manager内部的接口，也就是其成员_lru_check_swap()函数。

​	同样的，我们将其更改为特定的模拟硬件支持的访存接口，并按照我们对LRU算法的理解，修改assert函数中的条件判断，使其能够满足LRU算法。

```c++
static int
_lru_check_swap(void) {
    cprintf("write Virt Page c in lru_check_swap\n");
    lru_write_memory(0x3000,0x0c);
    assert(pgfault_num==4);
    cprintf("write Virt Page a in lru_check_swap\n");
    lru_write_memory(0x1000,0x0a);
    assert(pgfault_num==4);
    cprintf("write Virt Page d in lru_check_swap\n");
    lru_write_memory(0x4000 ,0x0d);
    assert(pgfault_num==4);
    cprintf("write Virt Page b in lru_check_swap\n");
    lru_write_memory(0x2000 ,0x0b);
    assert(pgfault_num==4);
    cprintf("write Virt Page e in lru_check_swap\n");
    lru_write_memory(0x5000 ,0x0e);
    assert(pgfault_num==5);
    cprintf("write Virt Page b in lru_check_swap\n");
    lru_write_memory(0x2000 ,0x0b);
    assert(pgfault_num==5);
    cprintf("write Virt Page a in lru_check_swap\n");
    lru_write_memory(0x1000 ,0x0a);
    assert(pgfault_num==5);
    cprintf("write Virt Page b in lru_check_swap\n");
    lru_write_memory(0x2000 ,0x0b);
    assert(pgfault_num==5);
    cprintf("write Virt Page c in lru_check_swap\n");
    lru_write_memory(0x3000 ,0x0c);
    assert(pgfault_num==6);
    cprintf("write Virt Page d in lru_check_swap\n");
    lru_write_memory(0x4000 ,0x0d);
    assert(pgfault_num==7);
    cprintf("write Virt Page e in lru_check_swap\n");
    lru_write_memory(0x5000 ,0x0e);
    assert(pgfault_num==8);
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    lru_write_memory(0x1000 ,0x0a);
    assert(pgfault_num==9);
    return 0;
}
```

​	接下来，我们结合make qemu的结果，检验LRU算法是否成功执行，这里，虚拟地址和物理页起初有0x1000对应80457到0x4000对应8045a的顺次映射关系：

![](img\1.jpg)

​	**第一次换出**：可以看到，第一次换出发生在对虚拟地址0x5000的访问处，这里，0x1000、0x2000、0x3000、0x4000都在前不久访问过，各自对应了一个物理页，因此此时物理页不够分配，会发生一次换页。

​	可以看到，此时0x3000对应的Page：80459此时的visited最大，将其作为换出页换出，随后对0x2000和0x1000访问，都没有发生任何异常，能够正常执行。

​	0x5000处地址变为对应80459处的物理页。

​	**第二次换出：**当代码执行到对0x3000的访问时，就会发生第二次换出操作，pgfault_num加一。这时候，一直没有被访问的0x4000就会作为换出页被传出。

​	0x3000处地址变为对应8045a处的物理页。

![](img\2.jpg)

​	**第三次换出：**继续执行，紧接着需要访问0x4000，而该虚拟地址对应的物理页刚刚被换出，于是又会发生缺页，此时，最久没有访问的0x5000就会被换出。

​	0x4000处地址变为对应80459处的物理页。

​	**第四次换出：**继续执行，紧接着需要访问0x5000，同样的，这里0x5000将最久没有访问的0x1000换出。

​	0x5000处地址变为对应80457处的物理页。

​	最终，调用assert函数，再次访问0x1000，观察其数值是否正常，在换入换出过程中有没有发生数值的丢失。

​	经检验，表明LRU算法能够正常执行。

