//
//  DataUtil.m
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import "DataUtil.h"

@interface DataUtil () {
    
}

@property (nonatomic, strong) IDUtil *idinfo;

@property (nonatomic, strong) LocationUtil *location_data;
@property (nonatomic, strong) WiFiUtil *wifi_data;
@property (nonatomic, strong) CellularUtil *cell_data;
@property (nonatomic, strong) SensorUtil *sensor_data;

@end

@implementation DataUtil

- (IDUtil *)idinfo {
    if (!_idinfo) {
        _idinfo = [[IDUtil alloc]init];
    }
    return _idinfo;
}

- (LocationUtil *)location_data {
    if (!_location_data) {
        _location_data = [[LocationUtil alloc]init];
    }
    return _location_data;
}

- (WiFiUtil *)wifi_data {
    if (!_wifi_data) {
        _wifi_data = [[WiFiUtil alloc]init];
    }
    return _wifi_data;
}

- (CellularUtil *)cell_data {
    if (!_cell_data) {
        _cell_data = [[CellularUtil alloc]init];
    }
    return _cell_data;
}

- (SensorUtil *)sensor_data {
    if (!_sensor_data) {
        _sensor_data = [[SensorUtil alloc]init];
    }
    return _sensor_data;
}

@end
