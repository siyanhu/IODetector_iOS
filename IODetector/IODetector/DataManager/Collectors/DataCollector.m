//
//  DataCollector.m
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import "DataCollector.h"
#import "DataUtil.h"

#import "Reachability.h"
#import "ThreadSafeMutableArray.h"
#import "AIBBeaconRegionAny.h"

#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <HealthKit/HealthKit.h>

#import <ifaddrs.h>
#import <arpa/inet.h>


@interface DataCollector () <CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSTimer *redoTimer, *uploadTimer;
    CLLocationManager *locManager;
    CBCentralManager *bthManager;
    AIBBeaconRegionAny *bleRegion;
//    CLBeaconRegion *bleRegion;
    Reachability *reachManager;
    CMMotionManager *mtManager;
    CMAltimeter *altManager;
    HKHealthStore *healthStore;
    
    DataUtil *data_util;
    UIViewController *currentVC;
    ThreadSafeMutableArray *magCache, *baroCache, *bleCache;
    dispatch_queue_t threadsafe_queue;
    CBPeripheral *referencedBT;
}

@end

@implementation DataCollector

# pragma mark - Public Functions
- (void)initEngines:(UIViewController *)vc {
    currentVC = vc;
    threadsafe_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self initLocationEngine];
    [self initNetworkEngine];
    [self initBarometerEngine];
    [self initMotionEngine];
    [self initHealthKitEngine];
}

- (void)inputProfile:(NSInteger)userId globalAddr:(NSString *)globalAddr {
    //22.312711,114.1691448
    data_util.idinfo.user_id = [NSNumber numberWithInteger: userId];
    data_util.idinfo.gcoor = globalAddr;
}

- (void)registerWristBand {
    if (!bthManager) {
        bthManager = [[CBCentralManager alloc]init];
        bthManager.delegate = self;
    }
   
}

- (void)startCollection {

    if (!data_util) {
        data_util = [[DataUtil alloc]init];
    }
    data_util.idinfo.user_id = [NSNumber numberWithInt: 2333];
    data_util.idinfo.dev_id = [self phone_App_vendor_ID];
    [self startLocationEngine];
    redoTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self startNetworkEngine];
        [self startBarometerEngine];
        [self startMotionEngine];
        [self startHealthKitEngine];
    }];
    
    
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self dataChecking]) {
                NSMutableDictionary *uploadDict = [NSMutableDictionary dictionary];
                [uploadDict setValue:[NSNumber numberWithInteger:1234567] forKey:@"userId"];
                [uploadDict setObject:self->data_util.idinfo.dev_id forKey:@"devId"];
                [uploadDict setObject:[NSString stringWithFormat:@"%@_%@", [NSNumber numberWithInteger:54287123], [self getDataId]] forKey:@"dataId"];
                [uploadDict setValue:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];
                
                NSDictionary *geoloc = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"apple", @"src",
                                        [NSNumber numberWithFloat:self->data_util.location_data.y], @"latitude",
                                        [NSNumber numberWithFloat:self->data_util.location_data.x], @"longitude",
                                        [NSNumber numberWithFloat:self->data_util.location_data.floor], @"altitude",
                                        [NSNumber numberWithInt:self->data_util.location_data.haccuracy], @"accuracy",
                                        nil];
                NSDictionary *wlan;
                if (self->data_util.wifi_data) {
                    wlan = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], @"connection",
                            self->data_util.wifi_data.ipaddr, @"ip",
                            self->data_util.wifi_data.ssid, @"ssid",
                            self->data_util.wifi_data.mac, @"bssid",
                            [NSNumber numberWithInteger: self->data_util.wifi_data.rssi], @"rssi",
                            [NSNumber numberWithInteger: 3600], @"duration",
                            nil];
                } else {
                    wlan = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:NO], @"connection",
                            @"", @"ip",
                            @"", @"ssid",
                            @"", @"bssid",
                            [NSNumber numberWithInteger: 0], @"rssi",
                            [NSNumber numberWithInteger: 0], @"duration",
                            nil];
                }
                
                NSDictionary *cellular;
                if (self->data_util.cell_data) {
                    cellular = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], @"connection",
                            [NSNumber numberWithInteger:self->data_util.cell_data.mcc.integerValue], @"mcc",
                            [NSNumber numberWithInteger:self->data_util.cell_data.mnc.integerValue], @"mnc",
//                            [NSNumber numberWithInteger:3], @"lac",
//                            [NSNumber numberWithInteger: self->data_util.cell_data.cid], @"cid",
                            [NSNumber numberWithInteger: self->data_util.cell_data.rssi], @"ss",
                            self->data_util.cell_data.type, @"type",
                            nil];
                } else {
                    cellular = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES], @"connection",
                            [NSNumber numberWithInteger:1], @"mcc",
                            [NSNumber numberWithInteger:2], @"mnc",
                            [NSNumber numberWithInteger:3], @"lac",
                            [NSNumber numberWithInteger:4], @"cid",
                            [NSNumber numberWithInteger:-100], @"ss",
                            [NSNumber numberWithInteger:1], @"type",
                            nil];
                    
                }
                
                NSDictionary *nearbyWLAN = [NSDictionary dictionaryWithObjectsAndKeys:
                                            self->data_util.wifi_data.ssid, @"ssid",
                                            self->data_util.wifi_data.mac, @"bssid",
                                            [NSNumber numberWithInteger: self->data_util.wifi_data.rssi], @"rssi",
                                            nil];
//                NSDictionary *nearbyWLANs = [NSDictionary dictionaryWithObjectsAndKeys:
//                                             [NSArray arrayWithObjects:nearbyWLAN, nil], @"list",
//                                             nil];
//                NSDictionary *nearbyMags = [NSDictionary dictionaryWithObjectsAndKeys:
//                                            [NSArray arrayWithObjects:
//                                             [NSNumber numberWithFloat:self->data_util.sensor_data.mx], [NSNumber numberWithFloat:self->data_util.sensor_data.my], [NSNumber numberWithFloat:self->data_util.sensor_data.mz], [NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.0], nil], @"values",
//                                            nil];
                NSDictionary *nearbyMags = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSArray arrayWithArray:self->magCache], @"values",
                                                nil];
                [self magRemoveObject:nil];
                NSDictionary *nearbyBaros = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSArray arrayWithArray:self->baroCache], @"values",
                                             nil];
                [self baroRemoveObject:nil];
                NSDictionary *nearbyBle = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithArray:self->bleCache], @"list", nil];
                [self bleRemoveObject:nil];
                NSDictionary *nearby = [NSDictionary dictionaryWithObjectsAndKeys:
                                        //nearbyWLANs, @"wlan",
                                        nearbyMags, @"magnetic",
                                        nearbyBaros, @"baro",
                                        nearbyBle, @"beacon",
                                        nil];
                
                NSDictionary *activity = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:self->data_util.sensor_data.steps], @"step", nil], @"activity"
                                          , nil];
                
                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      geoloc, @"geoloc",
                                      wlan, @"wlan",
                                      cellular, @"cellular",
                                      nearby, @"nearby",
                                      activity, @"activity",
                                      nil];
                [uploadDict setObject:data forKey:@"data"];
                [self.delegate didUpdateData:uploadDict];
            }
        });
    }]; 

}

- (void)finishCollection {
    [uploadTimer invalidate];
    [redoTimer invalidate];
    [self endLocationEngine];
    [self endBarometerEngine];
    [self endMotionEngine];
    [self endHealthKitEngine];
//    data_util = nil;
}

- (BOOL)dataChecking {
    if (!data_util) {
        return NO;
    }
//    if (data_util.idinfo) {
//        if (!data_util.idinfo.user_id) {
//            return NO;
//        }
//    }
    if (data_util.location_data) {
        if (data_util.location_data.x == 0 || data_util.location_data.y == 0) {
            return NO;
        }
    }
    BOOL networkValid = NO;
    if (data_util.wifi_data) {
        networkValid = YES;
    }
    if (data_util.cell_data) {
        networkValid = YES;
    }
    if (!networkValid) {
        return NO;
    }
    if (!data_util.sensor_data) {
        return NO;
    }
    return YES;
}

#pragma mark - Device Indetification
- (NSString *)phone_App_vendor_ID {
    //Test use: DE3BC84C-F19B-406E-A402-ECEF0643B622 (Ivy's personal iPhone XS, app version 2020-02-20-16-57)
    //Uninstall App, Switch Phone will lead to a different vendor id.
    NSString *strIDFV = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return strIDFV;
}

- (NSString *)getDataId {
    NSDate *date = [NSDate date];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    [formatter setDateStyle:NSDateFormatterMediumStyle];

    [formatter setTimeStyle:NSDateFormatterShortStyle];

    [formatter setDateFormat:@"YYYY-MM-dd-hh-mm-ss"];

    NSString *DateTime = [formatter stringFromDate:date];
    return DateTime;
}

#pragma mark - Bluetooth Engine
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOn:
             [bthManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
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
    NSString *title = peripheral.name;
//    if (![uuidstr isEqualToString:@"964348DF-A7D6-3A4E-CA37-9AAE37564131"]) {
//        return;
//    }
    if (![uuidstr isEqualToString:@"C9161687-FCEB-315A-CF01-057CA54007E4"]) {
        return;
    }
//    if (![uuidstr isEqualToString:@"619356C9-23F2-1BF6-A1EE-1BDFD8CE88C3"]) {
//        return;
//    }
    if (RSSI.integerValue < -40)
        return;
    if (![advertisementData objectForKey:@"kCBAdvDataManufacturerData"])
        return;
    if (title == (id)[NSNull null] || title.length == 0) {
        NSLog(@"Name: %@- BLE UUID: %@ with RSSI %ld \n Details: %@", peripheral.name, uuidstr, (long)RSSI.integerValue, advertisementData);
        referencedBT = peripheral;
        [bthManager connectPeripheral:referencedBT options:nil];
//        [bthManager stopScan];
        
        [self parseAdvertisementData:[advertisementData objectForKey:@"kCBAdvDataManufacturerData"] withRSSI:RSSI.integerValue andUUID:uuidstr];
    }
}

- (void)parseAdvertisementData:(NSData *)data withRSSI:(NSInteger)rssi andUUID:(NSString *)uuidStr {
    //AD0:no
    //AD1: have no Length(1Byte), Indicator (1Byte)
    if (data.length < 11) {
        return;
    }
    NSData *company2Data = [data subdataWithRange:NSMakeRange(0, 1)];
    NSData *company1Data = [data subdataWithRange:NSMakeRange(1, 1)];
    NSData *protocolData = [data subdataWithRange:NSMakeRange(2, 1)];
    NSData *modelData = [data subdataWithRange:NSMakeRange(3, 1)];
    NSData *majorData = [data subdataWithRange:NSMakeRange(4, 2)];
    NSData *minorData = [data subdataWithRange:NSMakeRange(6, 2)];
    NSData *txData = [data subdataWithRange:NSMakeRange(8, 1)];
    NSString *company2Hex = [self convertDataToHexStr:company2Data];
    NSString *company1Hex = [self convertDataToHexStr:company1Data];
    NSString *protocolHex = [self convertDataToHexStr:protocolData];
    NSString *modelHex = [self convertDataToHexStr:modelData];
    NSString *majorHex = [self convertDataToHexStr:majorData];
    NSString *minorHex = [self convertDataToHexStr:minorData];
    NSString *txHex = [self convertDataToHexStr:txData];
    
    uint8_t txByte;
    [txData getBytes:&txByte length:1];
    int32_t txTC = (int8_t)txByte;
    NSString *txNew = [NSString stringWithFormat:@"%d", txTC];
    
    NSData *fstContent = [data subdataWithRange:NSMakeRange(9, 1)];
    NSString *fstRBit = [self OneByte2bit:[fstContent bytes]];
    NSString *fstBit = [self reverseString:fstRBit];
    NSData *secContent = [data subdataWithRange:NSMakeRange(10, 1)];
    NSString *secRBit = [self OneByte2bit:[secContent bytes]];
    NSString *secBit = [self reverseString:secRBit];
    NSString *content = [NSString stringWithFormat:@"%@%@", secBit, fstBit];
    
    NSString *strapStr = [content substringWithRange:NSMakeRange(5, 1)];
    NSString *batteryStr = [fstRBit substringWithRange:NSMakeRange(1, 7)];
    long strap = strtol([strapStr UTF8String], NULL, 2);
    long battery = strtol([batteryStr UTF8String], NULL, 2);
 
    NSString *result = [NSString stringWithFormat:@"%@\nBLE Scan Result:\nCompany %@%@ = %@, \nProtocol %@ = %@, \nModel %@ = %@, \nMajor %@ = %@, \nMinor %@ = %@, \nTx %@ = %@, \nRSSI: %ld\nstrap:%ld\nbattery:%ld",
                        uuidStr,
                        company1Hex, company2Hex, [self convertHEXToDecimalStr:[NSString stringWithFormat:@"%@%@", company1Hex, company2Hex]],
                        protocolHex, [self convertHEXToDecimalStr:protocolHex],
                        modelHex, [self convertHEXToDecimalStr:modelHex],
                        majorHex, [self convertHEXToDecimalStr:majorHex],
                        minorHex, [self convertHEXToDecimalStr:minorHex],
                        txHex, txNew,
                        (long)rssi,
                        strap,
                        battery];
    NSLog(@"%@", result);
    [self.delegate didUpdateBLE:result];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Bluetooth fail: %@", error.description);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
//    if ([referencedBT isEqual:peripheral]) {
//        [bthManager connectPeripheral:peripheral options:nil];
//    }
    [referencedBT setDelegate:self];
    [referencedBT discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *s in peripheral.services) {
        NSLog(@"Service UUID: %@", s.UUID);
    }
}

- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
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
    
    return string;
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

- (NSString *)OneByte2bit:(const char *)byte {
    char n = byte[0];
    char buffer[9];
    buffer[8] = 0; //for null
    int j = 8;
    while(j > 0) {
        if(n & 0x01) {
            buffer[--j] = '1';
        } else {
            buffer[--j] = '0';
        }
        n >>= 1;
    }
    NSString *test = [NSString stringWithUTF8String:buffer];
    return test;
}

- (NSString *)reverseString:(NSString *)myString {
    NSMutableString *reversedString = [NSMutableString string];
    NSInteger charIndex = [myString length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subStrRange = NSMakeRange(charIndex, 1);
        [reversedString appendString:[myString substringWithRange:subStrRange]];
    }
    return reversedString;
}

#pragma mark - Location Engine
- (void)initLocationEngine {
    if (!locManager) {
        locManager = [[CLLocationManager alloc]init];
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locManager.allowsBackgroundLocationUpdates = YES;
        locManager.headingFilter = 1;
        locManager.delegate = self;
    }
    [self locationAccess:currentVC];
    bleRegion = [[AIBBeaconRegionAny alloc] initWithIdentifier:@"Any"];
//    NSUUID *uuid = [[NSUUID alloc]initWithUUIDString:@"2650C178-B268-DE90-AA9C-BACBA2CE5BFF"];
//    NSString *identifier = [NSString stringWithFormat:@"org.hkust.mtrec.wherami.%@", uuid];
//    bleRegion = [[CLBeaconRegion alloc]initWithProximityUUID:uuid identifier:identifier];
}

- (void)startLocationEngine {
    [locManager startUpdatingLocation];
    [locManager startUpdatingHeading];
    
//    [locManager startRangingBeaconsInRegion:bleRegion];
}

- (void)endLocationEngine {
    [locManager stopUpdatingLocation];
    [locManager stopUpdatingHeading];
    locManager = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if ([locations count]) {
        CLLocation *newLoc = [locations lastObject];
        if (newLoc) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->data_util.location_data.x = newLoc.coordinate.longitude;
                self->data_util.location_data.y = newLoc.coordinate.latitude;
                self->data_util.location_data.floor = newLoc.floor.level;
                self->data_util.location_data.haccuracy = newLoc.horizontalAccuracy;
            });
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        //再重新获取ssid
//        self->data_util.wifi_data.ssid = [self WiFiChecking_ios13];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self->headings addObject:[NSNumber numberWithFloat:newHeading.magneticHeading]];
    });
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Range Error: %@", error.description);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)beaconRegion {
    for (CLBeacon* beacon in beacons) {
//        NSLog(@"Beacon uuid: %@\nmajor:%ld\nminor:%\ld\n151, 1, 81, 24, 0, 0, 1, 195, 219, 60, 80", beacon.proximityUUID, beacon.major.longValue, beacon.minor.longValue);
           if (beacon.rssi <= -50) {
               continue;
           }
           if (beacon.rssi == 0) {
               continue;
           }
//            if (![beacon.proximityUUID.UUIDString isEqualToString:@"2650C178-B268-DE90-AA9C-BACBA2CE5BFF"]) {
//                return;
//            }

           dispatch_async(dispatch_get_main_queue(), ^{
               long long currentTS = [[NSDate date] timeIntervalSince1970] * 1000;
               self->data_util.ble_data.uuid = beacon.proximityUUID.UUIDString;
               self->data_util.ble_data.major = beacon.major;
               self->data_util.ble_data.minor = beacon.minor;
               self->data_util.ble_data.rssi = beacon.rssi;
               self->data_util.ble_data.timestamp = currentTS;
               NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:
                                        self->data_util.ble_data.uuid, @"uuid",
                                        self->data_util.ble_data.major, @"major",
                                        self->data_util.ble_data.minor, @"minor",
                                        [NSNumber numberWithInteger: self->data_util.ble_data.rssi], @"rssi",
                                        nil];
               [self bleAdd:content];
           });
        
    }
}

//- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons satisfyingConstraint:(nonnull CLBeaconIdentityConstraint *)beaconConstraint  API_AVAILABLE(ios(13.0)){
//    for (CLBeacon* beacon in beacons) {
//        if (beacon.rssi <= (-1) * 90) {
//            continue;
//        }
//        if (beacon.rssi == 0) {
//            continue;
//        }
//        if (@available(iOS 13.0, *)) {
//            if (![beacon.UUID.UUIDString isEqualToString:@"2650C178-B268-DE90-AA9C-BACBA2CE5BFF"]) {
//                return;
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            long long currentTS = [[NSDate date] timeIntervalSince1970] * 1000;
//            self->data_util.ble_data.uuid = beacon.UUID.UUIDString;
//            self->data_util.ble_data.major = beacon.major;
//            self->data_util.ble_data.minor = beacon.minor;
//            self->data_util.ble_data.rssi = beacon.rssi;
//            self->data_util.ble_data.timestamp = currentTS;
//            NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     self->data_util.ble_data.uuid, @"uuid",
//                                     self->data_util.ble_data.major, @"major",
//                                     self->data_util.ble_data.minor, @"minor",
//                                     [NSNumber numberWithInteger: self->data_util.ble_data.rssi], @"rssi",
//                                     nil];
//            [self bleAdd:content];
//        });
//    }
//}

- (void)locationAccess:(UIViewController *)vc {
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

#pragma mark - Network Engine
- (void)initNetworkEngine {
    reachManager = [Reachability reachabilityWithHostname:@"www.google.com"];
    reachManager.reachableOnWWAN = YES;
}

- (void)startNetworkEngine {
//    [self->reachManager startNotifier];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self->reachManager.isReachableViaWiFi) {
            
            NSDictionary *wifi_dict = [self WiFiChecking];
            if (wifi_dict) {
                self->data_util.type = NTWiFi;
                self->data_util.wifi_data.type = WiFiConnected;
                self->data_util.wifi_data.ssid = [wifi_dict valueForKey:@"SSID"];
            }
            self->data_util.wifi_data.mac = [wifi_dict valueForKey:@"BSSID"];
            self->data_util.wifi_data.ipaddr = [self getIPAddress];
            self->data_util.wifi_data.timestamp = [[NSDate date] timeIntervalSince1970];
            self->data_util.wifi_data.rssi = -1 * (130 - [self getSignalStrength:YES] * 100 / 5);
        } else if (self->reachManager.isReachable == YES) {
            self->data_util.type = NTCellular;
        }
        if (self->reachManager.isReachable== YES) {
            NSArray *cellularList = [self CellularChecking];
            if (cellularList.count == 5) {
                self->data_util.cell_data.mcc = [cellularList objectAtIndex:0];
                self->data_util.cell_data.mnc = [cellularList objectAtIndex:1];
                self->data_util.cell_data.NSP = [cellularList objectAtIndex:3];
                self->data_util.cell_data.type = [cellularList objectAtIndex:4];
            }
            self->data_util.cell_data.rssi = -1 * (200 - [self getSignalStrength:NO] * 100 / 5);
            self->data_util.cell_data.rssi = 1;

        }
        if (self->reachManager.isReachable == NO) {
            self->data_util.type = NTNone;
        }
    });
}

//- (void)updateInterfaceWithReachability:(Reachability *)reachability {
//    NetworkStatus netStatus = [reachability currentReachabilityStatus];
//    switch (netStatus) {
//        case NotReachable:
//            break;
//        case ReachableViaWiFi:
//            break;
//        case ReachableViaWWAN:
//            break;
//    }
//}
//
//- (void) reachabilityChanged:(NSNotification *)note {
//    Reachability* curReach = [note object];
//    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
//    [self updateInterfaceWithReachability:curReach];
//}

- (void)authorityOthers:(UIViewController *)vc {
    if (!vc) {
        vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
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

- (NSDictionary *)WiFiChecking {
    if (@available(iOS 13.0, *)) {
        [locManager requestWhenInUseAuthorization];
        
    }
    if (locManager) {
        CFArrayRef myArray = CNCopySupportedInterfaces();
        if (myArray != nil) {
            CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
            if (myDict != nil) {
                NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
                return dict;
            }
        }
    }
    return nil;
}

- (NSArray *)CellularChecking {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSDictionary *carriers = networkInfo.serviceSubscriberCellularProviders;
    CTCarrier *carrier;
    for (CTCarrier *cr in carriers.allValues) {
        if ([cr.isoCountryCode isEqualToString:@"hk"]) {
            carrier = cr;
            break;
        }
    }
    if (!carrier) {
        carrier = [[carriers allValues] firstObject];
    }
    
    NSString *mcc = carrier.mobileCountryCode;
    NSString *mnc = carrier.mobileNetworkCode;
//    NSString *
    
    NSString *CountryCode = carrier.isoCountryCode;
//    NSString *NetworkCode = carrier.mobileNetworkCode;
//    NSString *NetworkCountryCode = carrier.mobileCountryCode;
    NSString *CarrierName = [[NSString stringWithFormat:@"%@" ,carrier.carrierName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSNumber *netconnType = [NSNumber numberWithInt:0];
    NSDictionary *CellularTech = networkInfo.serviceCurrentRadioAccessTechnology;
    NSString *currentStatus = CellularTech.allValues.firstObject;
    if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
        netconnType = [NSNumber numberWithInt:0];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
//        netconnType = @"2.75G EDGE";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
        netconnType = [NSNumber numberWithInt:1];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
//        netconnType = @"3.5G HSDPA";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
//        netconnType = @"3.5G HSUPA";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
        netconnType = [NSNumber numberWithInt:3];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
        netconnType = [NSNumber numberWithInt:3];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
        netconnType = [NSNumber numberWithInt:3];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
        netconnType = [NSNumber numberWithInt:3];
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){
//        netconnType = @"HRPD";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
        netconnType = [NSNumber numberWithInt:2];
    }
    
    NSArray *carrierArray = [NSArray arrayWithObjects:mcc, mnc, CountryCode, CarrierName, netconnType, nil];
    return carrierArray;
}


- (int)getSignalStrength:(BOOL)WiFi {
    id statusBar;
    int signalStrength = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
//        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            id localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([localStatusBar respondsToSelector:@selector(statusBar)]) {
                statusBar = [localStatusBar performSelector:@selector(statusBar)];
//            }
        }
        if (statusBar) {
            id currentData = [[statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"currentData"];
            id wifiEntry = [currentData valueForKeyPath:@"wifiEntry"];
            id cellularEntry = [currentData valueForKeyPath:@"cellularEntry"];
            if (wifiEntry && [[wifiEntry valueForKeyPath:@"isEnabled"] boolValue] && WiFi) {
                signalStrength = [[wifiEntry valueForKeyPath:@"displayValue"] intValue];
                signalStrength = signalStrength == 3 ? 4 : signalStrength;
            } else if (cellularEntry && [[cellularEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                signalStrength = [[cellularEntry valueForKey:@"displayValue"] intValue];
//                NSLog(@"%d", signalStrength);
            }
        }
        return signalStrength;
        
    } else {
        NSString *deviceName = [[UIDevice currentDevice] name];
        if ([deviceName containsString:@"10"]) {
            
        }
        BOOL iphoneXup = YES;
        if (iphoneXup) {
            id statusBarView = [statusBar valueForKeyPath:@"statusBar"];
            UIView *foregroundView = [statusBarView valueForKeyPath:@"foregroundView"];
            NSArray *subviews = [[foregroundView subviews][2] subviews];
            for (id subview in subviews) {
                if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")] && WiFi) {
                    signalStrength = [[subview valueForKey:@"numberOfActiveBars"] intValue];
                    break;
                } else if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarStringView")]) {
                    signalStrength = [[subview valueForKey:@"numberOfActiveBars"] intValue];
                    break;
                }
            }
            return signalStrength;
        } else {
            UIApplication *app = [UIApplication sharedApplication];
            NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
            NSString *dataNetworkItemView = nil;
            for (id subview in subviews) {
                if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]] && WiFi) {
                    dataNetworkItemView = subview;
                    signalStrength = [[dataNetworkItemView valueForKey:@"_wifiStrengthBars"] intValue];
                    break;
                }
                if ([subview isKindOfClass:[NSClassFromString(@"UIStatusBarSignalStrengthItemView") class]]) {
                    dataNetworkItemView = subview;
                    signalStrength = [[dataNetworkItemView valueForKey:@"_signalStrengthRaw"] intValue];
                    break;
                }
            }
            return signalStrength;
        }
    }
    return signalStrength;
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - Barometer Engine
- (void)initBarometerEngine {
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return;
    }
    altManager = [[CMAltimeter alloc]init];
}

- (void)startBarometerEngine {
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return;
    }
    [altManager startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error) {
        self->data_util.sensor_data.pressure = [altitudeData.pressure floatValue];
        self->data_util.sensor_data.height = [altitudeData.relativeAltitude floatValue];
        [self baroAdd:[NSNumber numberWithFloat:[altitudeData.pressure floatValue]]];
    }];
}

- (void)endBarometerEngine {
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return;
    }
    [altManager stopRelativeAltitudeUpdates];
    altManager = nil;
}

# pragma mark - Motion Engine
- (void)initMotionEngine {
    
    if (!mtManager) {
        mtManager = [[CMMotionManager alloc]init];
    }
    mtManager.magnetometerUpdateInterval = 2;
}

- (void)startMotionEngine {
    if (!mtManager.isMagnetometerAvailable) {
        return;
    }
    [mtManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        CMMagneticField field = magnetometerData.magneticField;
        self->data_util.sensor_data.mx = field.x;
        self->data_util.sensor_data.my = field.y;
        self->data_util.sensor_data.mz = field.z;
        self->data_util.sensor_data.total = sqrtf(powf(field.x, 2) + powf(field.y, 2) + powf(field.z, 2));
        [self magAdd:[NSNumber numberWithFloat:self->data_util.sensor_data.total]];
    }];
}

- (void)endMotionEngine {
    if (mtManager.isMagnetometerActive) {
        [mtManager stopMagnetometerUpdates];
    }
}

#pragma mark - HealthKit Engine
- (void)initHealthKitEngine {
    if(![HKHealthStore isHealthDataAvailable]) {
        return;
    }
    if (!healthStore) {
        healthStore = [[HKHealthStore alloc] init];
    }
}

- (void)startHealthKitEngine {
    NSSet *healthSet = [NSSet setWithObjects:
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned],
                            [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],nil];
    [healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self fetchSumOfSamplesTodayForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount] unit:HKUnit.countUnit completion:^(double value, NSError *error) {
                self->data_util.sensor_data.steps =  value;
//                NSLog(@"%@", error.description);
            }];
        }
        else {
            NSLog(@"Cannot get Step Counter");
        }
    }];
}

- (void)endHealthKitEngine {
    healthStore = nil;
}

- (void)readStepCount {
    //sampling enquiry
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    //NSSortDescriptors用来告诉healthStore怎么样将结果排序。
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    NSPredicate *pre = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];


    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:pre limit:HKObjectQueryNoLimit sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        NSLog(@"%@",results);
        double steps = 0;

        for (HKQuantitySample *result in results) {
//            NSLog(@"bundleIdentifier:%@",result.sourceRevision.source.bundleIdentifier);
            HKQuantity *quantity = result.quantity;
            HKUnit *heightUnit = [HKUnit countUnit];
            double usersHeight = [quantity doubleValueForUnit:heightUnit];
            steps += usersHeight;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->data_util.sensor_data.steps = steps;
        }];
        
    }];
    [healthStore executeQuery:sampleQuery];
}

- (void)getDistancesFromHealthKit {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    [self fetchSumOfSamplesTodayForType:stepType unit:[HKUnit meterUnit] completion:^(double stepCount, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"Distance：%.f",stepCount);
            
        });
    }];
}

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:60 * 60 * 24 toDate:startDate options:0];
    NSPredicate *pre = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];

    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:pre options:HKStatisticsOptionSeparateBySource completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = nil;
        
//        NSLog(@"result ==== %@",result.sources);
        for (HKSource *source in result.sources) {
//            NSLog(@"%@",source.bundleIdentifier);
//            if ([source.bundleIdentifier containsString:appleHealth]) {
                sum = [result sumQuantityForSource:source];
//            }
        }
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
//            NSLog(@"sum ==== %@",sum);
//            NSLog(@"value ===%f",value);
            
            completionHandler(value, error);
        }
    }];
    
    [healthStore executeQuery:query];
}

#pragma mark - Threadsafe Operations
- (void)magAdd:(NSObject *)obj {
    if (!magCache) {
        magCache = [[ThreadSafeMutableArray alloc]init];
    }
    dispatch_async(threadsafe_queue, ^{
        [self->magCache addObject:obj];
    });
}

- (void)magRemoveObject:(NSObject *)obj {
    if (!magCache) {
        return;
    }
    dispatch_async(threadsafe_queue, ^{
        if (!obj) {
            [self->magCache removeAllObjects];
        } else {
            NSInteger index = [self->magCache indexOfObject:obj];
            if(-1 != index) {
                NSLog(@"[threadsafe] mag Cache remove obj: %ld from %lu",index, [self->magCache count]);
                [self->magCache removeObjectAtIndex:index];
            }
        }
    });
}

- (void)baroAdd:(NSObject *)obj {
    if (!baroCache) {
        baroCache = [[ThreadSafeMutableArray alloc]init];
    }
    dispatch_async(threadsafe_queue, ^{
        [self->baroCache addObject:obj];
    });
}

- (void)baroRemoveObject:(NSObject *)obj {
    if (!baroCache) {
        return;
    }
    dispatch_async(threadsafe_queue, ^{
        if (!obj) {
            [self->baroCache removeAllObjects];
        } else {
            NSInteger index = [self->baroCache indexOfObject:obj];
            if(-1 != index) {
                NSLog(@"[threadsafe] baro Cache remove obj: %ld from %lu",index, [self->baroCache count]);
                [self->baroCache removeObjectAtIndex:index];
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
