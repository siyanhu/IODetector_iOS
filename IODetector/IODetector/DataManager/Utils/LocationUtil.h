//
//  LocationUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationUtil : NSObject

@property (nonatomic) float x, y;
@property (nonatomic) NSInteger floor; //default -1, means no floor data;

@end

NS_ASSUME_NONNULL_END
