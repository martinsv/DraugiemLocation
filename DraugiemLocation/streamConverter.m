//
//  streamConverter.m
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 09/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "StreamConverter.h"

@implementation StreamConverter

+ (void)convertUserDataToArray:(NSString *)newUsers completion:(void(^)(NSArray *result))completion
{
    //Cleanup string
    NSString *cleanedUserString = newUsers;
    cleanedUserString = [cleanedUserString stringByReplacingOccurrencesOfString:@"USERLIST " withString:@""];
    cleanedUserString = [cleanedUserString stringByReplacingOccurrencesOfString:@"UPDATE " withString:@""];
    cleanedUserString = [cleanedUserString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    //Seperate users
    NSMutableArray *undividedUsers = [[NSMutableArray alloc] init];
    undividedUsers = [[cleanedUserString componentsSeparatedByString:@";"] mutableCopy];
    //Remove last empty object created by line break
    [undividedUsers removeLastObject];
    
    //Divide user attributes
    NSMutableArray *dividedUsers = [[NSMutableArray alloc] init];
    for (NSString *user in undividedUsers) {
        //Divide
        NSArray *singleUserArray = [user componentsSeparatedByString:@","];
        //Add to array
        [dividedUsers addObject:singleUserArray];
    }
    //Post completion
    completion(dividedUsers);
    
}

@end
