//
//  WiFiUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum WiFiType : NSUInteger {
    WiFiNearby,
    WiFiConnected
} WiFiType;

@interface WiFiUtil : NSObject

# pragma mark - Required
@property (nonatomic, strong) NSString *mac;
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic) WiFiType type;

# pragma mark - Connected
@property (nonatomic) long long timestamp;
@property (nonatomic, strong) NSString *ipaddr;

# pragma mark - Optional
@property (nonatomic) NSInteger rssi;

@end

NS_ASSUME_NONNULL_END
