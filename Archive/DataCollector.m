//
//  DataCollector.m
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import "DataCollector.h"

#import "AIBBeaconRegionAny.h"
#import "ThreadSafeMutableArray.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#import <ifaddrs.h>
#import <arpa/inet.h>


@interface DataCollector () <CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate> {
    CLLocationManager *locManager;
    CBCentralManager *bthManager;
    AIBBeaconRegionAny *bleRegion;
//    CLBeaconRegion *bleRegion;
 
    dispatch_queue_t threadsafe_queue;
    ThreadSafeMutableArray *magCache, *baroCache, *bleCache, *uuidCache;
    CBPeripheral *referencedBT;
    BOOL isEnrollmentMode;
    BOOL isScaningMode;
    BOOL isRuning;
}

@end

@implementation DataCollector

# pragma mark - Public Functions


- (instancetype)initForWristBandEnrollment {
    self = [super init];
    if (self) {
        threadsafe_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        isEnrollmentMode = YES;
        isScaningMode = NO;
        isRuning = NO;
        [self initBLE];
    }
    return self;
}

- (instancetype)initForWristBandScaning {
    self = [super init];
    if (self) {
        threadsafe_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        isEnrollmentMode = NO;
        isScaningMode = YES;
        isRuning = NO;
        [self initLocationEngine];
        [self initBLE];
    }
    return self;
}


- (void)initBLE {
    if (!bthManager) {
        bthManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        bthManager.delegate = self;
    }
}

- (void)enrollmentWristBand {
    if (!isEnrollmentMode && [bthManager isScanning]) {
        return;
    }
    isRuning = YES;
    [bthManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
}

- (void)startWristBandCollectionWithUuids:(NSArray<NSString *> *)uuids {
    if (!isScaningMode && [bthManager isScanning]) {
        return;
    }
    [self uuidRemoveObject:nil];
    NSMutableArray *cbuuids = [NSMutableArray new];
    for (NSString *uuid in uuids) {
        CBUUID *cbuuid = [CBUUID UUIDWithString:uuid];
        [cbuuids addObject:cbuuid];
        [self uuidAdd:cbuuid];
    }
    isRuning = YES;
    if (uuidCache.count == 0) {
        [bthManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
    } else {
        [bthManager scanForPeripheralsWithServices:uuidCache options:nil];
    }
    //    [self startLocationEngine];
}

- (void)stopBLEService {
    isRuning = NO;
    [bthManager stopScan];
}

#pragma mark - Bluetooth Engine
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOn:
            if (bthManager.isScanning && !isRuning) {
                return;
            }
            if (isEnrollmentMode) {
                [bthManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
            } else {
                if (uuidCache.count == 0) {
                    [bthManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
                } else {
                    [bthManager scanForPeripheralsWithServices:uuidCache options:nil];
                }
            }
            break;
        case CBManagerStateUnknown:
            NSLog(@"Bluetooth Status Unknown");
            break;
        case CBManagerStateResetting:
            NSLog(@"Bluetooth Status resetting");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Bluetooth Status unsupported");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"Bluetooth Status unauthorised");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Bluetooth Status power off");
            break;
        default:
            NSLog(@"Bluetooth Status error: %ld", central.state);
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *uuidstr = peripheral.identifier.UUIDString;
    NSData *data = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    if (data) {
        [self parseAdvertisementData:data withRSSI:RSSI.integerValue uuid:uuidstr peripheral: peripheral];
    }
}

- (void)parseAdvertisementData:(NSData *)data withRSSI:(NSInteger)rssi uuid:(NSString *)uuid peripheral:(CBPeripheral *)peripheral {
    //AD0:no
    //AD1: have no Length(1Byte), Indicator (1Byte)
    @try {
//        NSData *company2Data = [data subdataWithRange:NSMakeRange(0, 1)];
//        NSData *company1Data = [data subdataWithRange:NSMakeRange(1, 1)];
//        NSData *protocolData = [data subdataWithRange:NSMakeRange(2, 1)];
        NSData *modelData = [data subdataWithRange:NSMakeRange(3, 1)];
        NSData *majorData = [data subdataWithRange:NSMakeRange(4, 2)];
        NSData *minorData = [data subdataWithRange:NSMakeRange(6, 2)];
        NSData *txData = [data subdataWithRange:NSMakeRange(8, 1)];
//        NSData *contentData = [data subdataWithRange:NSMakeRange(9, 2)];
//        NSString *company2Hex = [self convertDataToHexStr:company2Data];
//        NSString *company1Hex = [self convertDataToHexStr:company1Data];
//        NSString *protocolHex = [self convertDataToHexStr:protocolData];
        NSString *modelHex = [self convertDataToHexStr:modelData];
        NSString *majorHex = [self convertDataToHexStr:majorData];
        NSString *minorHex = [self convertDataToHexStr:minorData];
//        NSString *txHex = [self convertDataToHexStr:txData];
//        NSString *contentHex = [self convertDataToHexStr:contentData];
          
        uint8_t txByte;
        [txData getBytes:&txByte length:1];
        int32_t txTC = (int8_t)txByte;
        NSString *txNew = [NSString stringWithFormat:@"%d", txTC];
        
        if (_delegate && [_delegate respondsToSelector:@selector(dataCollector:didScanBLE:modelID:major:minor:rssi:)]) {
            BOOL shouldConnect =  [self.delegate dataCollector:self
                                                    didScanBLE:uuid
                                                       modelID:modelHex
                                                         major:majorHex
                                                         minor:minorHex
                                                          rssi:rssi];
            if (shouldConnect) {
                [bthManager connectPeripheral:peripheral options:nil];
            }
        }
    } @catch (NSException *exception) {
        
    } @finally {
    }
 
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Bluetooth fail: %@", error.description);
}

- (void)connectToPerperialWithIdentifier:(NSString *)identifier {
    for (CBPeripheral *ble in bleCache) {
        if ([identifier isEqualToString:ble.identifier.UUIDString]) {
            ble.delegate = self;
            [bthManager connectPeripheral:ble options:nil];
            break;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (!error) {
        NSMutableArray *services = [NSMutableArray new];
        for (CBService *service in peripheral.services) {
            [services addObject:service.UUID.UUIDString];
        }
         if (_delegate && [_delegate respondsToSelector:@selector(dataCollector:didDiscoverBLE:withServicesID:)]) {
                [self.delegate dataCollector:self
                              didDiscoverBLE:peripheral.identifier.UUIDString
                              withServicesID:services];
            }
    }
}


- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    @try {
         [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
               unsigned char *dataBytes = (unsigned char*)bytes;
               for (NSInteger i = 0; i < byteRange.length; i++) {
                   NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
                   if ([hexStr length] == 2) {
                       [string appendString:hexStr];
                   } else {
                       [string appendFormat:@"0%@", hexStr];
                   }
               }
           }];
    } @catch (NSException *exception) {
    } @finally {
        return string;
    }
}

- (NSString *)convertHEXToDecimalStr:(NSString *)Hex {
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:Hex];

    [scanner setScanLocation:0];
    [scanner scanHexInt:&result];
    NSString *str = [NSString stringWithFormat:@"%d",  result];
    return str;
}

- (NSString *)dataToString:(NSData *)data {
    SignedByte *bytes = (SignedByte *)[data bytes];
    NSMutableString *string = [[NSMutableString alloc] init];
    for(int i = 0; i< [data length]; i++) {
        if (i == 0) {
            [string appendString:[NSString stringWithFormat:@"%hhu",bytes[i]]];
        }else {
            [string appendString:[NSString stringWithFormat:@", %hhu",bytes[i]]];
        }
    }
    return string;
}

#pragma mark - Location Engine
- (void)initLocationEngine {
    if (!locManager) {
        locManager = [[CLLocationManager alloc]init];
        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locManager.allowsBackgroundLocationUpdates = YES;
        locManager.delegate = self;
    }
}

- (void)startLocationEngine {
    for (CBUUID *cbUuid in self->uuidCache) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:cbUuid.UUIDString];
        AIBBeaconRegionAny *bleRegion;
        if (@available(iOS 13.0, *)) {
            bleRegion = [[AIBBeaconRegionAny alloc] initWithUUID:uuid  identifier:uuid.UUIDString];
        } else {
            bleRegion = [[AIBBeaconRegionAny alloc] initWithProximityUUID:uuid identifier:uuid.UUIDString];
        }
        bleRegion.notifyEntryStateOnDisplay = YES;
        bleRegion.notifyOnExit = YES;
        bleRegion.notifyOnEntry = YES;
        
        [locManager requestAlwaysAuthorization];
        [locManager startMonitoringForRegion:bleRegion];
        [locManager startRangingBeaconsInRegion:bleRegion];
    }
}

- (void)endLocationEngine {
    [locManager stopUpdatingLocation];
    locManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if ([locations count]) {
        CLLocation *newLoc = [locations lastObject];
        if (newLoc) {
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Range Error: %@", error.description);
    [manager stopRangingBeaconsInRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)beaconRegion {

//    if (self.delegate && [_delegate respondsToSelector:@selector(dataCollector:didRangeBeacons:)]) {
//        [self.delegate dataCollector:self didRangeBeacons:beacons];
//    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [locManager startRangingBeaconsInRegion:beaconRegion];
    }
    if (self.delegate && [_delegate respondsToSelector:@selector(dataCollector:didEnterRegion:)]) {
        [self.delegate dataCollector:self didEnterRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [locManager startRangingBeaconsInRegion:beaconRegion];
    }
    if (self.delegate && [_delegate respondsToSelector:@selector(dataCollector:didExitRegion:)]) {
        [self.delegate dataCollector:self didExitRegion:region];
    }
}


- (void)authorityNotify:(UIViewController *)vc {
    if (!vc) {
        vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if (![CLLocationManager locationServicesEnabled]) {
        }
        if([locManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            [locManager performSelector:@selector(requestWhenInUseAuthorization)];
    } else if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        
        UIAlertController *locsrvDisabledAlert = [UIAlertController alertControllerWithTitle:@"Location service permission denied" message:@"Please visit Settings -> Privacy and turn on access permission." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [locsrvDisabledAlert dismissViewControllerAnimated:YES completion:^{
                
            }];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            //[[UIApplication sharedApplication] openURL:url];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                
            }];
            [locsrvDisabledAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        [locsrvDisabledAlert addAction:action1];
        [locsrvDisabledAlert addAction:action2];
        [vc presentViewController:locsrvDisabledAlert animated:YES completion:nil];
    }
}


#pragma mark - Threadsafe Operations

- (void)uuidAdd:(NSObject *)obj {
    if (!uuidCache) {
        uuidCache = [[ThreadSafeMutableArray alloc]init];
    }
    dispatch_async(threadsafe_queue, ^{
        [self->uuidCache addObject:obj];
    });
}

- (void)uuidRemoveObject:(NSObject *)obj {
    if (!uuidCache) {
        return;
    }
    dispatch_async(threadsafe_queue, ^{
        if (!obj) {
            [self->uuidCache removeAllObjects];
        } else {
            NSInteger index = [self->uuidCache indexOfObject:obj];
            if(-1 != index) {
                NSLog(@"[threadsafe] Cache remove obj: %ld from %lu",index, [self->uuidCache count]);
                [self->uuidCache removeObjectAtIndex:index];
            }
        }
    });
}

- (void)bleAdd:(NSObject *)obj {
    if (!bleCache) {
        bleCache = [[ThreadSafeMutableArray alloc]init];
    }
    dispatch_async(threadsafe_queue, ^{
        [self->bleCache addObject:obj];
    });
}

- (void)bleRemoveObject:(NSObject *)obj {
    if (!bleCache) {
        return;
    }
    dispatch_async(threadsafe_queue, ^{
        if (!obj) {
            [self->bleCache removeAllObjects];
        } else {
            NSInteger index = [self->bleCache indexOfObject:obj];
            if(-1 != index) {
                NSLog(@"[threadsafe] baro Cache remove obj: %ld from %lu",index, [self->bleCache count]);
                [self->bleCache removeObjectAtIndex:index];
            }
        }
    });
}

- (void)getObject:(void(^)(NSObject *))completion AtIndex:(int)index fromThreadSafeArray:(ThreadSafeMutableArray *)safeArr {
    if (!safeArr) {
        return;
    }
    if (index >= safeArr.count) {
        return;
    }
    dispatch_async(threadsafe_queue, ^{
        completion([safeArr objectAtIndex:index]);
    });
}


@end
