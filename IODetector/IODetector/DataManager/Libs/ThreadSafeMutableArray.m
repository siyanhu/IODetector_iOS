//
//  ThreadSafeMutableArray.m
//  LBSOfflineSDK
//
//  Created by HU Siyan on 12/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import "ThreadSafeMutableArray.h"

@interface ThreadSafeMutableArray () {
    CFMutableArrayRef _array;
}

@property dispatch_queue_t concurrent_queue;

@end

@implementation ThreadSafeMutableArray

/*
 Sample:
 - (void)viewDidLoad {
    [super viewDidLoad];
    NSKSafeMutableArray *safeArr = [[NSKSafeMutableArray alloc] init];
 
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for ( int i = 0; i < 5; i ++) {
        dispatch_async(queue, ^{
            NSLog(@"add index no. %d",i);
            [safeArr addObject:[NSString stringWithFormat:@"%d",i]];
        });
        dispatch_async(queue, ^{
            NSLog(@"delete index no. %d",i);
            [safeArr removeObjectAtIndex:i];
        });
    }
 }
*/

- (instancetype)initWithCapacity:(NSUInteger)numItems {
    self = [super init];
    if (self) {
        _array = CFArrayCreateMutable(kCFAllocatorDefault, numItems,  &kCFTypeArrayCallBacks);
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    }
    return self;
}

#pragma mark - Public Functions
- (NSUInteger)count {
    __block NSUInteger result;
    dispatch_sync(self.syncQueue, ^{
        result = CFArrayGetCount(self->_array);
    });
    return result;
}

- (id)objectAtIndex:(NSUInteger)index {
    __block id result;
    dispatch_sync(self.syncQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        result = index<count ? CFArrayGetValueAtIndex(self->_array, index) : nil;
    });
    
    return result;
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    __block NSUInteger blockindex = index;
    dispatch_barrier_async(self.syncQueue, ^{
        
        if (!anObject)
            return;
        
        NSUInteger count = CFArrayGetCount(self->_array);
        if (blockindex > count) {
            blockindex = count;
        }
        CFArrayInsertValueAtIndex(self->_array, index, (__bridge const void *)anObject);
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    
    dispatch_barrier_async(self.syncQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        NSLog(@"count:%lu,index:%lu",(unsigned long)count,(unsigned long)index);
        if (index < count) {
            CFArrayRemoveValueAtIndex(self->_array, index);
        }
    });
}

- (void)addObject:(id)anObject {
    dispatch_barrier_async(self.syncQueue, ^{
        if (!anObject)
            return;
        CFArrayAppendValue(self->_array, (__bridge const void *)anObject);
    });
}

- (void)removeLastObject {
    dispatch_barrier_async(self.syncQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        if (count > 0) {
            CFArrayRemoveValueAtIndex(self->_array, count-1);
        }
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    dispatch_barrier_async(self.syncQueue, ^{
        if (!anObject)
            return;
        //NSUInteger count = CFArrayGetCount(self->_array);
        CFArraySetValueAtIndex(self->_array, index, (__bridge const void*)anObject);
    });
}

#pragma mark Optional
- (void)removeAllObjects {
    
    dispatch_barrier_async(self.syncQueue, ^{
        CFArrayRemoveAllValues(self->_array);
    });
}

- (NSUInteger)indexOfObject:(id)anObject {
    
    if (!anObject)
        return NSNotFound;
    
    __block NSUInteger result;
    dispatch_sync(self.syncQueue, ^{
        NSUInteger count = CFArrayGetCount(self->_array);
        result = CFArrayGetFirstIndexOfValue(self->_array, CFRangeMake(0, count), (__bridge const void *)(anObject));
    });
    return result;
    
    
    return result;
}

#pragma mark - Private
- (dispatch_queue_t)syncQueue {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("org.hkust.mtrec.wherami.safemutablearray", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;

}

@end
