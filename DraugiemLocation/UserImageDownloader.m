//
//  UserImageDownloader.m
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "UserImageDownloader.h"

@implementation UserImageDownloader

/* SVARIGI

    Oriģināli biju paredzējis katru lejuplādēto lietotāja bildi saglabāt gan NSCache, gan ierīcē, izmantojot NSFileManager.
    Diemžēl, šķiet, ka Xcode 6 ir bugs ar metožu return type un input parameters, nav iespējams ievietot UI objektus.
    Pastāv iespēja, ka šis bugs ir tikai uz manas sistēmas, tāpēc Models - > cahceControllet mapītē Jūs atradīsiet cacheController failus.
    Faili nav pievienoti šim projektam.
    
    Sīkāk: http://stackoverflow.com/questions/24147741/xcode-6-cant-return-uiimage-from-method
 
*/
+(void)downloadUserImageDataFromString:(NSString *)urlString completion:(void (^)(NSData *imageData, NSError *error))completion
{
    //Check if arguments are provided
    if (urlString == nil) {
        NSError *error = [[NSError alloc] init];
        NSData *noData = nil;
        //Post completion
        completion(noData, error);
        return;
    }
    
    //Download user image from urlString
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSData *data;
        //Success
        if (!error) data = [NSData dataWithContentsOfURL:location];
        //Post completion
        completion(data, error);
    }];
    [downloadTask resume];
}

@end
