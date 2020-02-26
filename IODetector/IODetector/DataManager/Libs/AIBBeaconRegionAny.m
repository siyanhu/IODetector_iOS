//
//  AIBBeaconRegionAny.m
//  AnyiBeacon
//
//  Created by Siyan HU on 12/9/2019.
//  Copyright (c) 2019 Siyan HU. All rights reserved.
//

#import "AIBBeaconRegionAny.h"

//Ref: https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/CoreLocation.framework/CLRegion.h

struct ClientRegion {
    BOOL identifier[512];
    BOOL onBehalfOfIdentifier[512];
    int type;
    bool notifyOnEntry;
    bool notifyOnExit;
    bool conservativeEntry;
    union {
        struct {
            BOOL proximityUUID[512];
            unsigned short major;
            unsigned short minor;
            int definitionMask;
            bool notifyEntryStateOnDisplay;
        } beaconAttributes;
        struct {
            struct {
                double latitude;
                double longitude;
            } center;
            double radius;
            double desiredAccuracy;
            int referenceFrame;
        } circularAttributes;
    } ;
};

@interface CLBeaconRegion (Hidden)

- (id)initWithIdentifier:(NSString *)identifier;
- (struct ClientRegion)clientRegion;

@end

@implementation AIBBeaconRegionAny

- (id)initWithIdentifier:(NSString *)identifier;
{
    return (self = [super initWithIdentifier:identifier]);
}

- (struct ClientRegion)clientRegion
{
    struct ClientRegion clientRegion = [super clientRegion];
    
    // definitionMask:
    //                  1 => uuid
    //                  3 => uuid + major
    //                  7 => uuid + major + minor
    
    clientRegion.beaconAttributes.definitionMask = ~0x07;
    
    return clientRegion;
}

@end
