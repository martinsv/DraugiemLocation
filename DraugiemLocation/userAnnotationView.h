//
//  userAnnotationView.h
//  DraugiemLocation
//
//  Created by Armands Lazdiņš on 10/06/14.
//  Copyright (c) 2014 Armands Lazdiņš. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface UserAnnotationView : MKAnnotationView

@property (nonatomic) UIView *contentView;

//Notifies UserAnotation to start loading image
- (void)notifyToLoadImage;

@end
