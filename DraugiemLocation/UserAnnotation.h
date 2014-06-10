//
//  UserAnnotation.h
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 09/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//NSNotification macro
#define USER_IMAGE_DID_END_LOADING @"USER_IMAGE_DID_END_LOADING"

@interface UserAnnotation : NSObject

//User atributes
@property (nonatomic) NSString *userID, *userName, *userImageURLString, *userLocationLatitude, *userLocationLongitude;

//MKAnnotation protocol properties
@property (nonatomic) NSString *title, *subtitle;
@property (nonatomic) CLLocationCoordinate2D coordinate;

//Downloaded data
@property (nonatomic) UIImage *userImage;

//Performs user image downloading
- (void)loadUserImage;

//Custom initialization
- (instancetype)initWithArray:(NSArray *)userArray;

@end
