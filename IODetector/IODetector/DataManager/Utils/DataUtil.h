//
//  DataUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IDUtil.h"
#import "WiFiUtil.h"
#import "CellularUtil.h"
#import "SensorUtil.h"
#import "LocationUtil.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum NetworkType : NSUInteger {
    NTWiFi,
    NTCellular,
    NTNone
} NetworkType;

@interface DataUtil : NSObject

@property (nonatomic) NetworkType type;

- (IDUtil *)idinfo;

- (LocationUtil *)location_data;

- (WiFiUtil *)wifi_data;
- (CellularUtil *)cell_data;

- (SensorUtil *)sensor_data;

@end

NS_ASSUME_NONNULL_END
