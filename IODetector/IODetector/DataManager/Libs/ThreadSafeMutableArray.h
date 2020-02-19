//
//  ThreadSafeMutableArray.h
//  LBSOfflineSDK
//
//  Created by HU Siyan on 12/11/2018.
//  Copyright © 2018 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThreadSafeMutableArray : NSMutableArray

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;

- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
