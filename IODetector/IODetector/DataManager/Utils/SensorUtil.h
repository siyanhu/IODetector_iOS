//
//  SensorUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SensorUtil : NSObject

# pragma mark - Barometer
@property (nonatomic) float height;
@property (nonatomic) float pressure;

# pragma mark - Magnetometer
@property (nonatomic) float mx, my, mz;

# pragma mark - HealthKit
@property (nonatomic) NSInteger steps;

@end

NS_ASSUME_NONNULL_END
