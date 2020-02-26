//
//  BleUtil.h
//  IODetector
//
//  Created by mtrecivy on 26/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BleUtil : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic) long long timestamp;
@property (nonatomic) NSInteger rssi;
@property (nonatomic, strong) NSNumber *major, *minor;

@end

NS_ASSUME_NONNULL_END
