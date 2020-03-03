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

- (void)didUpdateData:(NSDictionary *)dataDict;
- (void)didUpdateBLE:(NSString *)bleDetail;

@end


@interface DataCollector : NSObject

@property (nonatomic, strong) id <DataCollectionDelegate> delegate;

- (NSString *)phone_App_vendor_ID;

- (void)initEngines:(UIViewController *)vc;
- (void)inputProfile:(NSInteger)userId globalAddr:(NSString *)globalAddr;
- (void)registerWristBand;
- (void)startCollection;
- (void)finishCollection;

@end

NS_ASSUME_NONNULL_END
