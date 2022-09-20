// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
  uint64 pgcnt;
} kmems[NCPU];


void
kinit()
{
  char namebuf[10] = "kmem0";
  for(int i = 0; i < NCPU; i++)
  {
    kmems[i].pgcnt = 0;
    initlock(&(kmems[i].lock), "kmem");
    namebuf[4] += 1;
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;
  int cid;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
  
  r = (struct run*)pa;

  push_off();
  cid = cpuid();
  //cid = 0;

  acquire(&(kmems[cid].lock));
  r->next = kmems[cid].freelist;
  kmems[cid].freelist = r;
  kmems[cid].pgcnt += 1;
  release(&(kmems[cid].lock));
  pop_off();
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;
  int cid;
  int most_free_cid;
  uint64 most_free_pgcnt;
  uint64 now_free_pgcnt;

  push_off();
  cid = cpuid();
  //cid = 0;

  acquire(&(kmems[cid].lock));
  r = kmems[cid].freelist;
  if(r)
  {
    kmems[cid].freelist = r->next;
    kmems[cid].pgcnt -= 1;
  }
  else
  {
    most_free_cid = cid;
    most_free_pgcnt = 0;
    for(int i = 1; i < NCPU*2; i++)
    {
      now_free_pgcnt = lockfree_read8(&(kmems[(i+cid)%NCPU].pgcnt));
      if(now_free_pgcnt > most_free_pgcnt)
      {
        most_free_pgcnt = now_free_pgcnt;
        most_free_cid = (i+cid)%NCPU;
      }
    }
    if(most_free_cid == cid)
    {
        r = 0;
    }
    else
    {
        acquire(&kmems[most_free_cid].lock);
        most_free_pgcnt = kmems[most_free_cid].pgcnt;
        if(most_free_pgcnt)
        {
            kmems[cid].freelist = kmems[most_free_cid].freelist;
            for(int i = 0; i < (1+most_free_pgcnt)/2; i++)
            {
                r = kmems[most_free_cid].freelist;
                kmems[most_free_cid].freelist = kmems[most_free_cid].freelist->next;
            }
            r->next = 0;
            kmems[most_free_cid].pgcnt -= (1+most_free_pgcnt)/2;
            kmems[cid].pgcnt += (1+most_free_pgcnt)/2;

            release(&kmems[most_free_cid].lock);
            kmems[cid].pgcnt -= 1;
            r = kmems[cid].freelist;
            kmems[cid].freelist = r->next;
        }
        else
        {
            r = 0;
        }
    }
  }
  release(&(kmems[cid].lock));
  pop_off();

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
