//
//  UserCacheController.m
//  Photo Bombers
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "UserCacheController.h"

static UserCacheController *sharedCache = nil;

@interface UserCacheController()

@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic) NSString *directory;
@end

@implementation UserCacheController

//Lazy load
-(NSFileManager *)fileManager
{
    if (!_fileManager) _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}
//

+(UserCacheController *)sharedCache
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

-(id)init
{
    if (self = [super init]) {
        //Create cache
        self.cache = [[NSCache alloc] init];
        //Create path for fileManager directory
        if (!self.directory) {
            NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            self.directory = [cachesDirectory stringByAppendingFormat:@"/com.armandslazdins.draugiemlocation/sharedCache"];
        }
        //Create cache directory
        if (![self.fileManager fileExistsAtPath:self.directory]) {
            NSError *error;
            [self.fileManager createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:nil error:&error];
            
            if (error) NSLog(@"Failed to create caches directory: %@", error);
        }
    }
    return self;
}

-(void)clearCache
{
    //Remove all objects from cache
    [self.cache removeAllObjects];
    //Remove all objects from disk
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *path in [self.fileManager contentsOfDirectoryAtPath:self.directory error:nil]) {
            [self.fileManager removeItemAtPath:[self.directory stringByAppendingPathComponent:path] error:nil];
        }
    });
}

-(void)setImage:(UIImage *)image forKey:(NSString *)key
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Create path
        NSString *path = [self pathForKey:key];
        //Save to cache
        [self.cache setObject:image forKey:key];
        // Save to disk
        [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    });
    
    [self.cache setObject:image forKey:key];
}

-(UIImage *)getImageForKey:(NSString *)key
{
    //Check if there's image in cache. Block
    __block UIImage *image = [self.cache objectForKey:key];
    //Image in cache, return.
    if (image)return image;
    
    // Get path if object exists
    NSString *path = [self pathForKey:key];
    if (!path) return nil;
    
    //Load object from disk
    image = [UIImage imageWithContentsOfFile:path];
    
    //Save to cache
    [self.cache setObject:image forKey:key];
    
    return image;
}

#pragma mark - Helper Methods

- (NSString *)cleanupKey:(NSString *)fileName
{
    //Cleanup string from illegal character
    static NSCharacterSet *illegalFileNameCharacters = nil;
    static dispatch_once_t illegalCharacterCreationToken;
    dispatch_once(&illegalCharacterCreationToken, ^{
        illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString: @"\\?%*|\"<>:"];
    });
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}


- (NSString *)pathForKey:(NSString *)key
{
    //Cleanup string from illegal characters
    key = [self cleanupKey:key];
    //Add filepath to key and return
    return [self.directory stringByAppendingPathComponent:key];
}


@end
