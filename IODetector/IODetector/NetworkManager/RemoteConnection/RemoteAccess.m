//
//  RemoteAccess.m
//  LBSDataHandler
//
//  Created by HU Siyan on 11/9/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import "RemoteAccess.h"

@interface RemoteAccess () <NSURLSessionDelegate>

@end

@implementation RemoteAccess

static RemoteAccess *_instance = nil;

+ (RemoteAccess *)instance {
    if (_instance) {
        return _instance;
    }
    @synchronized ([RemoteAccess class]) {
        if (!_instance) {
            _instance = [[self alloc]init];
        }
        return _instance;
    }
    return nil;
}

#pragma mark - download
- (void)downloadFrom:(NSString *)download_link to:(NSString *)filePath success:(void (^)(NSString *fileName))success failure:(void (^)(NSError *error))failure {
    NSURL *url = [NSURL URLWithString:download_link];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
        } else {
            NSString *destination_file_path = [NSString stringWithFormat:@"%@/%@", filePath, [response suggestedFilename]];
            NSData *fileData = [NSData dataWithContentsOfURL:location];
            BOOL saved = [fileData writeToFile:destination_file_path atomically:NO];
            if (saved) {
                success([response suggestedFilename]);
            } else {
                failure(nil);
            }
        }
    }];
    [downloadTask resume];
}

- (void)readFrom:(NSString *)remote_link success:(void (^)(NSData *remoteData))success failure:(void (^)(NSError *error))failure {
    NSURL *url = [NSURL URLWithString:remote_link];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
                                     @"Content-Type"  : @"application/json"
                                     };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
        } else {
            success(data);
        }
    }];
    [dataTask resume];
}

- (void)readFrom:(NSString *)remote_link withParameters:(NSDictionary *)parameters success:(void (^)(NSData *remoteData))success failure:(void (^)(NSError *error))failure {
    
    NSURL *url = [NSURL URLWithString:remote_link];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = parameters;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
        } else {
            success(data);
        }
    }];
    [dataTask resume];
}

- (void)uploadJSONTo:(NSString *)remote_link withContent:(NSData *)content success:(void (^)(NSData *response))success failure:(void (^)(NSError *error))failure {
    
    NSURL *url = [NSURL URLWithString:remote_link];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
        @"Content-Type": @"application/json",
        @"Accept": @"application/json",
    };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
//    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    NSURLSessionUploadTask * uploadTask = [session uploadTaskWithRequest:request fromData:content completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Upload Fail: %@", error.description);
            failure(error);
        } else {
            success(data);
        }
    }];
    [uploadTask resume];
}

@end
