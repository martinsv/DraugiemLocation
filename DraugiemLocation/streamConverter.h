//
//  streamConverter.h
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 09/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamConverter : NSObject

//Convert NSStream output - NSString to NSArray
+ (void)convertUserDataToArray:(NSString *)newUsers completion:(void(^)(NSArray *result))completion;

@end
