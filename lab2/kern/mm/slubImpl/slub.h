#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <list.h>
#include <memlayout.h>

struct kmem_cache {
     	/*per-cpu变量，用来实现每个CPU上的slab缓存。好处如下：
        1.促使cpu_slab->freelist可以无锁访问，避免了竞争，提升分配速度
        2.使得本地cpu缓存中分配出的objects被同一cpu访问，提升TLB对object的命中率(因为一个page中有多个object，他们共用同一个PTE)
        3.这里我们默认只有一个cpu，单核下进行slub算法实现
        */
        struct kmem_cache_cpu *cpu_slab;
        /*下面这些是初始化kmem_cache时会设置的一些变量 */
    	/*kmem_cache_shrink缩减partial slabs时，将被保有slab的最小值。由函数set_min_partial(s, ilog2(s->size)/2)设置。*/
        unsigned long min_partial;
    	/*object的实际大小，其实可以细分，这里不做细分了*/
        size_t size;

        //所在的页
        struct Page* page;
    	
	    /*kmem_cache的链表结构，通过此成员串在slab_caches链表上*/
    	list_entry_t list;   
	    /*每个node对应一个数组项，kmem_cache_node中包含partial slab链表*/
        int free_node;
        struct kmem_cache_node *node[20];
};

#define le2cache(le, member)                 \
    to_struct((le), struct kmem_cache, member)

struct kmem_cache_cpu {
    	/*指向下面page指向的slab中的第一个free object*/
        void **freelist;      
    	/*指向当前正在使用的slab*/
        struct page *page;      
	    /*本地slab缓存池中的partial slab链表*/
        struct page *partial; 
};

struct kmem_cache_node {
    	/*node中slab的数量*/
        unsigned long nr_partial;
    	/*指向partial slab链表*/
        list_entry_t partial;  
};

#define le2node(le, member)                 \
    to_struct((le), struct kmem_cache_node, member)


void cache_list_init();
/*分配一块给某个数据结构使用的缓存描述符 kmem_cache
  name:对象的名字   size:对象的实际大小*/
struct kmem_cache *kmem_cache_create(size_t size,struct Page * p,struct Page * p2);
/*销毁kmem_cache_create分配的kmem_cache*/
void kmem_cache_destroy( struct kmem_cache *cachep);

/*从kmem_cache中分配一个object  */
struct object* kmem_cache_alloc(struct kmem_cache* cachep);
/*释放object,把它返还给原先的slab*/
void kmem_cache_free(struct kmem_cache* cachep,  struct object* objp);

struct object* slub_alloc(size_t size,struct Page * p,struct Page * p2);

#endif /* ! __KERN_MM_SLUB_H__ */