//
//  IDUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IDUtil : NSObject

@property (nonatomic, strong) NSNumber *user_id;
@property (nonatomic, strong) NSString *dev_id;
@property (nonatomic, strong) NSString *addr;
@property (nonatomic, strong) NSString *gcoor;

- (BOOL)valid;

@end

NS_ASSUME_NONNULL_END
