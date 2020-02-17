//
//  CellularUtil.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum CellularType : NSUInteger {
    Cellular4G,
    Cellular3G,
    Cellular2G
} CellularType;

@interface CellularUtil : NSObject

# pragma mark - Required
@property (nonatomic, strong) NSString *NSP;
@property (nonatomic) CellularType type;

# pragma mark - Optional
@property (nonatomic, strong) NSString *basestation;
@property (nonatomic, strong) NSString *bsss;

@end

NS_ASSUME_NONNULL_END
