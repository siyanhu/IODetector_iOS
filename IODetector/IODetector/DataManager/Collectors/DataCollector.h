//
//  DataCollector.h
//  IODetector
//
//  Created by mtrecivy on 17/2/2020.
//  Copyright © 2020 mtrecivy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataCollector : NSObject

- (void)initEngines:(UIViewController *)vc;
- (void)startCollection;
- (void)finishCollection;

@end

NS_ASSUME_NONNULL_END
