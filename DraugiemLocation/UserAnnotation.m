//
//  UserAnnotation.m
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 09/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import "UserAnnotation.h"
#import "UserImageDownloader.h"

@interface UserAnnotation() <MKAnnotation>

@property (nonatomic) BOOL loadingInProgress;

@end

@implementation UserAnnotation

-(instancetype)initWithArray:(NSArray *)userArray
{
    self = [super init];
    //Convert userArray to properties
    self.userID = userArray[0];
    self.userName = userArray[1];
    self.userImageURLString = userArray[2];
    self.userLocationLatitude = userArray[3];
    self.userLocationLongitude = userArray[4];
    
    //Set MKAnnotation coordinates
    self.coordinate = CLLocationCoordinate2DMake([self.userLocationLatitude doubleValue], [self.userLocationLongitude doubleValue]);
    
    return self;
}

#pragma mark - Image Downloading

- (void)loadUserImage
{
    //Check if loading is not in progress
    if (self.loadingInProgress) return;
    self.loadingInProgress = YES;
    
    //Check if image image doesn't exists
    if (self.userImage) [self imageLoadingComplete];
    else [self performImageLoading];
}

- (void)performImageLoading
{
    //Load user image if URL is available
    if (self.userImageURLString) {
        [UserImageDownloader downloadUserImageDataFromString:self.userImageURLString completion:^(NSData *imageData, NSError *error) {
            //Dispatch no main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    //Success
                    self.userImage = [UIImage imageWithData:imageData];
                    [self imageLoadingComplete];
                } else {
                    //Error occoured, load default
                    self.userImage = [UIImage imageNamed:@"noUserImage"];
                    [self imageLoadingComplete];
                }
            });
        }];
    } else {
        //No URL available, load default
        self.userImage = [UIImage imageNamed:@"noUserImage"];
        [self imageLoadingComplete];
    }
}

- (void)imageLoadingComplete
{
    //Post NSNotification and update BOOL
    self.loadingInProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_IMAGE_DID_END_LOADING
                                                        object:nil];
}



@end
