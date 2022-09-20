// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NSLOT 13

struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf * slots[NSLOT];
  struct spinlock slot_locks[NSLOT];
} bcache;

static uint my_hash(uint dev, uint blockno)
{
    uint hash = (uint)2166136261L;
    hash = (hash * 16777619) ^ blockno;
    hash += dev;
    return hash%NSLOT;
}

void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  for(int i = 0; i < NSLOT; i++)
  {
      initlock(&bcache.slot_locks[i], "bcache.slot");
      //namebuffer[6] += 1;
      bcache.slots[i] = (uint64)0L;
  }

  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    initsleeplock(&b->lock, "buffer");
    uint idx = my_hash(b->dev, b->blockno);
    if(bcache.slots[idx])
      bcache.slots[idx]->prev = b;
    b->next = bcache.slots[idx];
    b->prev = 0;
    bcache.slots[idx] = b;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  uint idx = my_hash(dev, blockno);
  acquire(&(bcache.slot_locks[idx]));

  // Is the block already cached?
  for(b = bcache.slots[idx]; b != 0; b = b->next){
    if(b->dev == dev && b->blockno == blockno){

      b->refcnt++;
      release(&bcache.slot_locks[idx]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  
  release(&bcache.slot_locks[idx]);
  acquire(&bcache.lock);
  for(b = bcache.slots[idx]; b != 0; b = b->next){
    if(b->dev == dev && b->blockno == blockno){

      acquire(&(bcache.slot_locks[idx]));
      b->refcnt++;
      release(&bcache.slot_locks[idx]);
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  
  uint least_use_t;
  int least_use_idx;

RETRY:
  least_use_t = lockfree_read4((int*)(&ticks));
  least_use_idx = NBUF;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
  {
    if(b->refcnt == 0)
    {
      if(b->t_release <= least_use_t)
      {
        least_use_t = b->t_release;
        least_use_idx = b - bcache.buf;
      }
    }
  }

  if(least_use_idx == NBUF)
    panic("bget: no buffers");

  b = bcache.buf+least_use_idx;
  uint target_idx = my_hash(b->dev, b->blockno);
  {
    acquire(&(bcache.slot_locks[target_idx]));
    
    //if(b->refcnt != 0 || my_hash(b->dev, b->blockno) != target_idx)
    if(b->refcnt != 0)
    {
        release(&(bcache.slot_locks[target_idx]));
        goto RETRY;
    }
  }

  if(target_idx != idx)
  {

    if(b == bcache.slots[target_idx])
    {
      //b is head
      bcache.slots[target_idx] = b->next;
      if(b->next) b->next->prev = 0;
    }
    else
    {
      b->prev->next = b->next;
      if(b->next) b->next->prev = b->prev;
    }

    b->next = bcache.slots[idx];
    b->prev = 0;
    b->dev = dev;
    b->blockno = blockno;
    b->valid = 0;
    b->refcnt = 1;
    acquire(&(bcache.slot_locks[idx]));
    if(b->next) b->next->prev = b;
    bcache.slots[idx] = b;

    release(&bcache.slot_locks[idx]);
    release(&bcache.slot_locks[target_idx]);
    release(&bcache.lock);

    acquiresleep(&b->lock);
    return b;
  }
  else
  {
    b->dev = dev;
    b->blockno = blockno;
    b->valid = 0;
    b->refcnt = 1;

    release(&bcache.slot_locks[idx]);
    release(&bcache.lock);
    acquiresleep(&b->lock);
    return b;
  }
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");
  

  releasesleep(&b->lock);

  uint idx = my_hash(b->dev, b->blockno);
  acquire(&(bcache.slot_locks[idx]));

  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->t_release = lockfree_read4((int*)(&ticks));
  }

  release(&bcache.slot_locks[idx]);
}

void
bpin(struct buf *b) {
  uint idx = my_hash(b->dev, b->blockno);
  acquire(&(bcache.slot_locks[idx]));
  b->refcnt++;
  release(&bcache.slot_locks[idx]);
}

void
bunpin(struct buf *b) {
  uint idx = my_hash(b->dev, b->blockno);
  acquire(&(bcache.slot_locks[idx]));
  b->refcnt--;
  release(&bcache.slot_locks[idx]);
}


