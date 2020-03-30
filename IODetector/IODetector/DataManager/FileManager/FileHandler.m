//
//  FileHandler.m
//  LBSNetworkHandler
//
//  Created by HU Siyan on 2/4/2019.
//  Copyright © 2019 HU Siyan. All rights reserved.
//

#import "FileHandler.h"

#define FILEMANAGER_ERROR_FLAG @"FILEMANAGER ERROR"

@interface FileHandler () <NSFileManagerDelegate> {
    NSFileManager *_manager;
    NSFileHandle *_editer;
}

@end

@implementation FileHandler

static FileHandler *_instance = nil;

+ (FileHandler *)instance {
    if (_instance)
        return _instance;
    @synchronized([FileHandler class]) {
        if (!_instance) {
            _instance = [[self alloc]init];
            [_instance initiate];
        }
        return _instance;
    }
    return nil;
}

- (void)initiate {
    _manager = [NSFileManager defaultManager];
    [_manager setDelegate:self];
    
    [_instance createFolder:@"prepkg" underPath:[_instance documentDirectory]];
}

#pragma mark - Other FileOperations
- (NSFileManager *)fileManager {
    return _manager;
}

#pragma mark - Macro folders
- (NSString *)documentDirectory {
    NSString *temp = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    temp = [temp stringByAppendingString:@"/"];
    return temp;
}

- (NSString *)tempDirectory {
    return NSTemporaryDirectory();
}

- (NSString *)homeDirectory {
    return NSHomeDirectory();
}

- (NSString *)cacheDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

- (NSString *)libraryDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

#pragma mark - File Operations
- (BOOL)fileExistAt:(NSString *)filePath isDirectory:(BOOL)isDirectory {
    BOOL ifDirectory = isDirectory;
    return [_manager fileExistsAtPath:filePath isDirectory:&ifDirectory];
}

- (BOOL)deleteFile:(NSString *)filePath {
    NSError *error = nil;
    if (![_instance fileExistAt:filePath isDirectory:NO]) {
        NSLog(@"%@ - DELETE: %@", FILEMANAGER_ERROR_FLAG, @"File does not exist.");
        return NO;
    }
    if ([_manager isDeletableFileAtPath:filePath]) {
        BOOL success = [_manager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"%@ - DELETE: %@", FILEMANAGER_ERROR_FLAG, error.description);
            return NO;
        }
        return YES;
    } else {
        NSLog(@"%@ - DELETE: %@", FILEMANAGER_ERROR_FLAG, @"File is not deletable");
        return NO;
    }
}

- (BOOL)deleteAllFilesInFolder:(NSString *)folderPath {
    if (![_instance fileExistAt:folderPath isDirectory:YES]) {
        NSLog(@"%@ - DELETE ALL: %@", FILEMANAGER_ERROR_FLAG, @"Folder does not exist.");
        return NO;
    }
    NSDirectoryEnumerator *enumerator = [_manager enumeratorAtPath:folderPath];
    NSString *file;
    while (file = [enumerator nextObject]) {
        NSError *error = nil;
        BOOL result = [_instance deleteFile:[folderPath stringByAppendingPathComponent:file]];
        if (!result && error) {
            NSLog(@"%@ - DELETE ALL: %@", FILEMANAGER_ERROR_FLAG, error.description);
            return NO;
        }
    }
    return YES;
}

- (BOOL)copyFile:(NSString *)filePath toPath:(NSString *)toPath {
    NSError *error = nil;
    if (![_manager copyItemAtPath:filePath toPath:toPath error:&error]) {
        NSLog(@"%@ - COPY: %@", FILEMANAGER_ERROR_FLAG, error.description);
        return NO;
    }
    return YES;
}

- (BOOL)moveFile:(NSString *)filePath toPath:(NSString *)toPath {
    NSError *error = nil;
    if (![_manager moveItemAtPath:filePath toPath:toPath error:&error]) {
        NSLog(@"%@ - MOVE: %@", FILEMANAGER_ERROR_FLAG, error.description);
        return NO;
    }
    return YES;
}

- (BOOL)saveFile:(NSString *)filePath toPath:(NSString *)toPath {
    return NO;
}

#pragma mark - File Editor
- (void)appendText:(NSString *)str toFile:(NSString *)filePath {
//    NSError *error = nil;
//    [str writeToFile:filePath atomically:NO encoding: NSStringEncodingConversionAllowLossy  error: &error];
    
    _editer = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [_editer seekToEndOfFile];
    NSError *error = nil;
    if (@available(iOS 13.0, *)) {
        [_editer writeData:[str dataUsingEncoding:NSUTF8StringEncoding] error:&error];
//        NSLog(@"%@", error.description);
    } else {
        // Fallback on earlier versions
        [_editer writeData:[str dataUsingEncoding:NSUTF8StringEncoding] ];
    }

    [_editer closeFile];
}

#pragma mark - Folder Operations
- (BOOL)createFolder:(NSString *)folderName underPath:(NSString *)parentPath {
    NSString *folderPath = [NSString stringWithFormat:@"%@/%@", parentPath, folderName];
    BOOL isDirectory = YES;
    NSError *error = nil;
    
    if (![_manager fileExistsAtPath:folderPath isDirectory:&isDirectory]) {
        [_manager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"%@ - CREATE: %@", FILEMANAGER_ERROR_FLAG, error.description);
            return NO;
        }
    } else {
        NSLog(@"%@ - CREATE: %@", FILEMANAGER_ERROR_FLAG, @"Folder existed");
    }
    return YES;
}

@end
