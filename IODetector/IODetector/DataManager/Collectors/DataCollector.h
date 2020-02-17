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

@protocol DataCollectionDelegate <NSObject>
@optional

- (void)didUpdateData:(NSString *)dataString;

@end


@interface DataCollector : NSObject

@property (nonatomic, strong) id <DataCollectionDelegate> delegate;

- (void)initEngines:(UIViewController *)vc;
- (void)startCollection;
- (void)finishCollection;

@end

NS_ASSUME_NONNULL_END
