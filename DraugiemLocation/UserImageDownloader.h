//
//  UserImageDownloader.h
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserImageDownloader : NSObject

//Download user image from urlString
+ (void)downloadUserImageDataFromString:(NSString *)urlString completion:(void(^)(NSData *imageData, NSError *error))completion;

@end
