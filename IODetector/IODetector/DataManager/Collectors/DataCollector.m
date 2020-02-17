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
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <ifaddrs.h>
#import <arpa/inet.h>


@interface DataCollector () <CLLocationManagerDelegate> {
    CLLocationManager *locManager;
    Reachability *reachManager;
    
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
}

- (void)startCollection {
    
    if (!data_util) {
        data_util = [[DataUtil alloc]init];
    }
    data_util.idinfo.user_id = [self phone_App_vendor_ID];
    
    [self startLocationEngine];
    [self startNetworkEngine];
}

- (void)finishCollection {
    [self endLocationEngine];
    data_util = nil;
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
//        locManager.allowsBackgroundLocationUpdates = YES;
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
            self->data_util.wifi_data.timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
            self->data_util.wifi_data.rssi = [self getSignalStrength:YES] / 5 * 100 * -1;
        } else if (self->reachManager.isReachable == YES) {
            self->data_util.type = NTCellular;
        }
        if (self->reachManager.isReachableViaWWAN == YES) {
            NSArray *cellularList = [self CellularChecking];
            if (cellularList.count == 3) {
                self->data_util.cell_data.NSP = [cellularList objectAtIndex:3];
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
    
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            return dict;
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
    NSString *CarrierName = [[NSString stringWithFormat:@"%@" ,carrier.carrierName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSString *CellularService = networkInfo.serviceCurrentRadioAccessTechnology;
    NSArray *carrierArray = [NSArray arrayWithObjects:CountryCode, NetworkCode, CarrierName, nil];
    return carrierArray;
}


- (int)getSignalStrength:(BOOL)WiFi {
    id statusBar;
    int signalStrength = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            UIView *localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([localStatusBar respondsToSelector:@selector(statusBar)]) {
                statusBar = [localStatusBar performSelector:@selector(statusBar)];
            }
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

@end
