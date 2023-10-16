#include<buddy_pmm.h>
#include<slub.h>

#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>


free_area_t free_area;
#define cache_list (free_area.free_list)

// 为了存放我们slub所需的数据结构，从buddy system申请几个页实现(简化)
// 但是写入页疑似有问题,只能直接生成了
void cache_list_init(){
    list_init(&cache_list);
}

struct kmem_cache * cache_int(size_t size,struct Page * p2){
    struct kmem_cache * cache;
    cache = (struct kmem_cache *)(page2pa(p2)+PHYSICAL_MEMORY_OFFSET);
    // cache = &kmem_caches[now];
    // now++;
    cache->size = size;
    cache->min_partial = 30; 
    cache->free_node =0;
    cache->page = p2;
    cache->node[0] = (struct kmem_cache_node *)(page2pa(p2+1)+PHYSICAL_MEMORY_OFFSET);
    return cache;
}

//考虑到slub算法在linux中实现相当复杂,共6000多行代码,在我们的实现中，进行了几处简化：
//1，由于只使用单核cpu和非NUMA模式，不必要分为per_node和per_cpu，
//因此我们这次实验只对node作处理，实现简单的任意大小内存分配即可
//2，事实上，每个per_node会形成一个类似于hash链表的结构来存储slab
//这里，我们利用per_node本身遗留的指针数组(本来应该指向不同node)实现存储
//3,对于obejct的实现,其内部还有较为复杂的结构,这里我们忽略了object的内部结构
//4,slub算法的核心就是以下四个接口,我们对其进行了实现,还需要进一步的外部封装才能简洁的使用
//现在使用的时候需要先在buddy system中进行页的分配,比较麻烦,但是能够实现功能


//对一个内存块更新/创建一个cache
struct kmem_cache *kmem_cache_create(size_t size,struct Page * p,struct Page * p2)
{
    //保证每个小内存块能放下object结构体
    assert(size>=128);
    //接下来找到合适的cache
    uintptr_t p_address = page2pa(p);
    list_entry_t* le = &cache_list;
    struct kmem_cache* cache =NULL;
    if (list_empty(&cache_list)) {
        //若链表为空，caches初始化一个新的
        cache = cache_int(size,p2);
        list_add(&cache_list, &(cache->list));
    } 
    else {
        //否则遍历链表，有size相同就拿，否则加入新的
        while ((le = list_next(le)) != &cache_list) {
            struct kmem_cache* cache2 = le2cache(le, list);
            if (cache2->size == size) {
                cache = cache2;
                cache->free_node ++;
                cache->node[cache->free_node] = (struct kmem_cache_node *)(cache->node[cache->free_node-1]+sizeof(struct kmem_cache_node));
                return cache;
            }
        }
        cache = cache_int(size,p2);
        list_add(le, &(cache->list));
    }
    struct kmem_cache_node* node = cache->node[cache->free_node];
    // 接下来处理node管理的object链表（简化：cpu不作处理）
    list_init(&node->partial);
    // 遍历这些页，按照size划分，通过结构体object实现链表和寻址
    le = &node->partial;
    for(int i=0;i<p->property*PGSIZE;i+=size){
        struct object * o = (struct object *)(p_address+PHYSICAL_MEMORY_OFFSET+i);
        list_add(le, &(o->object_link));
        le = &o->object_link;
        node->nr_partial++;
    }
    return cache;
}

//销毁一个cache
void kmem_cache_destroy( struct kmem_cache *cachep){
    list_del(&cachep->list);
    for(int i =0;i<=cachep->free_node;i++){
        list_del_init(&cachep->node[i]->partial);
    }
}

//根据cache分配一个slab的object
struct object* kmem_cache_alloc(struct kmem_cache* cachep){
    //遍历所有slab,找到第一个合适的块返回
    for(int i =0;i<=cachep->free_node;i++){
        struct kmem_cache_node* node = cachep->node[i];
        if(!list_empty(&node->partial)){
            struct object*o = le2object(node->partial.next,object_link);
            list_del(node->partial.next);
            return o;
        }
    }
    return NULL;
}

//返回一个slab的obejct
void kmem_cache_free(struct kmem_cache* cachep,  struct object* objp){
    //遍历所有slab,找到等于object指针的加入即可
    for(int i =0;i<cachep->free_node;i++){
        struct kmem_cache_node* node = cachep->node[i];
        if(list_prev(&objp->object_link)==&node->partial){
            list_add(&node->partial,&objp->object_link);
        }
    }
}

//整合：以申请几个字节为例子：
struct object* slub_alloc(size_t size, struct Page * p,struct Page * p2){
    //如果有相同大小的slab的cache，就不再新建了
    struct kmem_cache* cache;
    if (!list_empty(&cache_list)) {
        //遍历链表，有size相同就拿，否则再申请几个页创建一个
        list_entry_t* le = &cache_list;
        while ((le = list_next(le)) != &cache_list) {
            cache = le2cache(le, list);
            if (cache->size == size) {
                break;
            } 
        }
    }
    cache = kmem_cache_create(size,p,p2);
    struct object* o =kmem_cache_alloc(cache);
    return o;
}
