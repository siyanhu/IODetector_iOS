//
//  RemoteAccess.h
//  LBSDataHandler
//
//  Created by HU Siyan on 11/9/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RemoteAccess : NSObject

+ (RemoteAccess *)instance;
- (void)downloadFrom:(NSString *)download_link to:(NSString *)filePath success:(void (^)(NSString *fileName))success failure:(void (^)(NSError *error))failure;
- (void)readFrom:(NSString *)remote_link success:(void (^)(NSData *remoteData))success failure:(void (^)(NSError *error))failure;
- (void)readFrom:(NSString *)remote_link withParameters:(NSDictionary *)parameters success:(void (^)(NSData *remoteData))success failure:(void (^)(NSError *error))failure;

- (void)uploadJSONTo:(NSString *)remote_link withContent:(NSData *)content success:(void (^)(NSData *response))success failure:(void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
