//
//  FileHandler.h
//  LBSNetworkHandler
//
//  Created by HU Siyan on 2/4/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileHandler : NSObject

+ (FileHandler *)instance;
- (NSString *)documentDirectory;
- (NSString *)tempDirectory;

#pragma mark - Other FileOperations
- (NSFileManager *)fileManager;

#pragma mark - File Operations
- (BOOL)fileExistAt:(NSString *)filePath isDirectory:(BOOL)isDirectory;
- (BOOL)deleteFile:(NSString *)filePath;
- (BOOL)deleteAllFilesInFolder:(NSString *)folderPath;
- (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)toPath;
- (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)toPath;
- (BOOL)saveFile:(NSString *)filePath toPath:(NSString *)toPath;

#pragma mark - File Editor
- (void)appendText:(NSString *)str toFile:(NSString *)filePath;

#pragma mark - Folder Operations
- (BOOL)createFolder:(NSString *)folderName underPath:(NSString *)parentPath;

@end

NS_ASSUME_NONNULL_END
