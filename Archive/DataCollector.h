//
//  DataCollector.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class DataCollector;
@protocol DataCollectionDelegate <NSObject>
@optional

- (BOOL)dataCollector:(DataCollector *) collector didScanBLE:(NSString *)uuid modelID:(NSString *)model
                major:(NSString *)major minor:(NSString *)minor rssi:(NSInteger) rssi;

- (void)dataCollector:(DataCollector *) collector didDiscoverBLE:(NSString *)uuid withServicesID:(NSArray<NSString*>*)services;

- (void)dataCollector:(DataCollector *) collector didRangeBeacons: (NSArray<CLBeacon*> *)beacons;
- (void)dataCollector:(DataCollector *) collector didEnterRegion: (CLRegion*) region;
- (void)dataCollector:(DataCollector *) collector didExitRegion: (CLRegion*) region;
@end


@interface DataCollector : NSObject

@property (nonatomic, weak) id <DataCollectionDelegate> delegate;

- (instancetype)initForWristBandEnrollment;
- (instancetype)initForWristBandScaning;

- (void)enrollmentWristBand; // for enrollment
- (void)startWristBandCollectionWithUuids:(NSArray<NSString*> *)uuids; // for scaning

- (void)stopBLEService;

@end

NS_ASSUME_NONNULL_END
