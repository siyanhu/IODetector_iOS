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
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <ifaddrs.h>
#import <arpa/inet.h>


@interface DataCollector () <CLLocationManagerDelegate> {
    NSTimer *redoTimer;
    CLLocationManager *locManager;
    Reachability *reachManager;
    CMMotionManager *mtManager;
    CMAltimeter *altManager;
    HKHealthStore *healthStore;
    
    DataUtil *data_util;
    UIViewController *currentVC;
}

@end

@implementation DataCollector

# pragma mark - Public Functions
- (void)initEngines:(UIViewController *)vc {
    currentVC = vc;
    [self initLocationEngine];
    [self initNetworkEngine];
    [self initBarometerEngine];
    [self initMotionEngine];
    [self initHealthKitEngine];
}

- (void)startCollection {
    
    if (!data_util) {
        data_util = [[DataUtil alloc]init];
    }
    data_util.idinfo.user_id = [NSNumber numberWithInt: 2333];
    data_util.idinfo.dev_id = [self phone_App_vendor_ID];
    [self startLocationEngine];
    
    redoTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        [self startNetworkEngine];
        [self startBarometerEngine];
        [self startMotionEngine];
//        [self startHealthKitEngine];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self dataChecking]) {
                NSMutableDictionary *uploadDict = [NSMutableDictionary dictionary];
                [uploadDict setValue:self->data_util.idinfo.user_id forKey:@"userId"];
                [uploadDict setObject:self->data_util.idinfo.dev_id forKey:@"devId"];
                [uploadDict setObject:[NSString stringWithFormat:@"%@", self->data_util.idinfo.user_id] forKey:@"dataId"];
                [uploadDict setValue:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];
                
                NSDictionary *geoloc = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"CoreLocation", @"src",
                                        [NSNumber numberWithFloat:self->data_util.location_data.y], @"latitude",
                                        [NSNumber numberWithFloat:self->data_util.location_data.x], @"longitude",
                                        [NSNumber numberWithFloat:self->data_util.location_data.floor], @"altitude",
                                        [NSNumber numberWithFloat:0.0], @"accuracy",
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
                            [NSNumber numberWithInteger:1], @"mcc",
                            [NSNumber numberWithInteger:2], @"mnc",
                            [NSNumber numberWithInteger:3], @"lac",
                            [NSNumber numberWithInteger: self->data_util.cell_data.cid], @"cid",
                            [NSNumber numberWithInteger: self->data_util.cell_data.rssi], @"ss",
                            [NSNumber numberWithUnsignedInteger:self->data_util.cell_data.type], @"type",
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
                NSDictionary *nearbyWLANs = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSArray arrayWithObjects:nearbyWLAN, nil], @"list",
                                             nil];
                NSDictionary *nearbyMags = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSArray arrayWithObjects:
                                             [NSNumber numberWithFloat:self->data_util.sensor_data.mx], [NSNumber numberWithFloat:self->data_util.sensor_data.my], [NSNumber numberWithFloat:self->data_util.sensor_data.mz], [NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.0], nil], @"values",
                                            nil];
                NSDictionary *nearbyBaros = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSArray arrayWithObjects:[NSNumber numberWithFloat:self->data_util.sensor_data.pressure], [NSNumber numberWithFloat:self->data_util.sensor_data.height], nil], @"values",
                                             nil];
                NSDictionary *nearby = [NSDictionary dictionaryWithObjectsAndKeys:
                                        nearbyWLANs, @"wlan",
                                        nearbyMags, @"magnetic",
                                        nearbyBaros, @"baro",
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
    //Uninstall App, Switch Phone will lead to a different vendor id.
    NSString *strIDFV = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; //0FD77009-C837-4E3B-AD08-FD1B2E9D7F48
    return strIDFV;
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
}

- (void)startLocationEngine {
    [locManager startUpdatingLocation];
}

- (void)endLocationEngine {
    [locManager stopUpdatingLocation];
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
            if (cellularList.count == 4) {
                self->data_util.cell_data.NSP = [cellularList objectAtIndex:3];
                self->data_util.cell_data.cid = [[cellularList objectAtIndex:0] integerValue];
            }
            self->data_util.cell_data.rssi = [self getSignalStrength:NO];

        }
        if (self->reachManager.isReachable == NO) {
            self->data_util.type = NTNone;
        }
    });

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

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
    NSString *CountryCode = carrier.isoCountryCode;
    NSString *NetworkCode = carrier.mobileNetworkCode;
    NSString *NetworkCountryCode = carrier.mobileCountryCode;
    NSString *CarrierName = [[NSString stringWithFormat:@"%@" ,carrier.carrierName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSString *CellularService = networkInfo.serviceCurrentRadioAccessTechnology;
    NSArray *carrierArray = [NSArray arrayWithObjects:NetworkCountryCode, CountryCode, NetworkCode, CarrierName, nil];
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
                NSLog(@"%d", signalStrength);
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
//            NSLog(@"Can get Step Counter");
            [self fetchSumOfSamplesTodayForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount] unit:[HKUnit dayUnit] completion:^(double value, NSError *error) {
                self->data_util.sensor_data.steps = value;
                NSLog(@"%@", error.description);
                [self startNetworkEngine];
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
            NSLog(@"bundleIdentifier:%@",result.sourceRevision.source.bundleIdentifier);
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
            NSLog(@"Distance：%.f",stepCount);
            
        });
    }];
}

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
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

@end
